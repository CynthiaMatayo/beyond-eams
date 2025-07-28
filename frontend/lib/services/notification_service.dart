import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/notification.dart';

class NotificationService {
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<String?> _getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<List<NotificationItem>> getUserNotifications() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/user-notifications/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['notifications'] is List) {
          return (data['notifications'] as List)
              .map((item) => NotificationItem.fromJson(item))
              .toList();
        }
      }
    } catch (e) {
      print('Error getting user notifications: $e');
    }
    return [];
  }

  Future<bool> sendNotification({
    required List<int> userIds,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications/send-notification/'),
        headers: await _getHeaders(),
        body: json.encode({
          'user_ids': userIds,
          'title': title,
          'message': message,
          'type': type,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  Future<bool> testEmail({
    required String recipientEmail,
    required String subject,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications/test-email/'),
        headers: await _getHeaders(),
        body: json.encode({
          'recipient_email': recipientEmail,
          'subject': subject,
          'message': message,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error testing email: $e');
      return false;
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications/$notificationId/mark-read/'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications/mark-all-read/'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(int notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/notifications/$notificationId/'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 204;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final notifications = await getUserNotifications();
      return notifications.where((n) => !n.isRead).length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }
}
