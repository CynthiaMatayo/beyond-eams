// lib/services/qr_code_service.dart - FIXED VERSION
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/activity.dart';

class QRCodeService {
  // Generate QR code data for an activity
  static String generateQRData(Activity activity) {
    final qrData = {
      'type': 'activity_checkin',
      'activity_id': activity.id,
      'activity_title': activity.title,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'location': activity.location,
    };
    return jsonEncode(qrData);
  }

  // Parse QR code data
  static Map<String, dynamic>? parseQRData(String qrString) {
    try {
      final data = jsonDecode(qrString);
      if (data['type'] == 'activity_checkin') {
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Validate QR code timing (e.g., only allow check-in 30 mins before/after)
  static bool isQRCodeValid(Map<String, dynamic> qrData, Activity activity) {
    final qrTimestamp = qrData['timestamp'] as int;
    final qrTime = DateTime.fromMillisecondsSinceEpoch(qrTimestamp);
    final now = DateTime.now();
    final activityTime =
        activity.startTime; // FIXED: Use startTime instead of dateTime

    // Allow check-in 30 minutes before and 2 hours after activity start
    final validStart = activityTime.subtract(const Duration(minutes: 30));
    final validEnd = activityTime.add(const Duration(hours: 2));

    return now.isAfter(validStart) && now.isBefore(validEnd);
  }
}
