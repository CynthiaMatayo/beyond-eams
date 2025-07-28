// lib/services/coordinator_service.dart - FIXED VERSION
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity.dart';

class CoordinatorService {
  static const String _baseUrl = 'http://127.0.0.1:8000/api';
  static String? _authToken;

  // FIXED: Store promoted activities locally with SharedPreferences
  static const String _promotedActivitiesKey = 'promoted_activities';
  static const String _promotionStatsKey = 'promotion_stats';

  static void setAuthToken(String token) {
    _authToken = token;
  }

  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<Map<String, dynamic>> _get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      Uri url = Uri.parse('$_baseUrl$endpoint');
      if (queryParams != null) {
        url = url.replace(queryParameters: queryParams);
      }
      debugPrint('Making GET request to: $url');
      final response = await http.get(url, headers: await _getHeaders());
      return _handleResponse(response);
    } catch (e) {
      debugPrint('GET Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _post(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      debugPrint('Making POST request to: $url');
      debugPrint('Data: $data');
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: data != null ? json.encode(data) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      debugPrint('POST Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _postMultipart(
    String endpoint,
    Map<String, dynamic> fields, {
    File? imageFile,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      var request = http.MultipartRequest('POST', url);
      debugPrint('Making multipart POST request to: $url');

      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      // Convert boolean values to Django-compatible strings
      fields.forEach((key, value) {
        if (value != null) {
          String stringValue;
          if (value is bool) {
            stringValue = value ? 'True' : 'False';
          } else {
            stringValue = value.toString();
          }
          request.fields[key] = stringValue;
          debugPrint(
            '  $key: $stringValue (converted from ${value.runtimeType})',
          );
        }
      });

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('poster_image', imageFile.path),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final httpResponse = http.Response(responseBody, response.statusCode);
      return _handleResponse(httpResponse);
    } catch (e) {
      debugPrint('Multipart POST Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _delete(String endpoint) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      debugPrint('Making DELETE request to: $url');
      final response = await http.delete(url, headers: await _getHeaders());
      return _handleResponse(response);
    } catch (e) {
      debugPrint('DELETE Error: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');
    try {
      if (response.body.isEmpty) {
        return {'success': true, 'data': [], 'message': 'Empty response'};
      }
      final dynamic decodedData = json.decode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': decodedData,
          'message':
              decodedData is Map
                  ? (decodedData['message'] ?? 'Success')
                  : 'Success',
        };
      } else {
        String errorMessage =
            'Request failed with status ${response.statusCode}';
        if (decodedData is Map) {
          errorMessage =
              decodedData['error'] ??
              decodedData['message'] ??
              decodedData['detail'] ??
              errorMessage;
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid JSON response: ${response.body}');
      }
      rethrow;
    }
  }

  List<dynamic> _extractActivitiesFromResponse(dynamic data) {
    if (data is List) {
      return data;
    } else if (data is Map && data['activities'] != null) {
      return data['activities'];
    } else if (data is Map && data['results'] != null) {
      return data['results'];
    } else {
      debugPrint('Unexpected response structure: $data');
      return [];
    }
  }

  // CRITICAL: Get all activities created by the current coordinator from database
  Future<List<Activity>> getMyActivities() async {
    debugPrint('📡 Fetching coordinator activities from database...');
    try {
      final response = await _get('/coordinator/activities/');
      if (response['success']) {
        debugPrint(
          '✅ Successfully fetched coordinator activities from database',
        );
        final activitiesJson = _extractActivitiesFromResponse(response['data']);
        final activities =
            activitiesJson.map((json) => Activity.fromJson(json)).toList();
        debugPrint('📊 Loaded ${activities.length} coordinator activities');

        // Debug each activity
        for (var activity in activities) {
          debugPrint(
            '🎯 Activity ${activity.id}: "${activity.title}" - Status: "${activity.status}" - Created by: ${activity.createdBy}',
          );
        }

        return activities;
      }
      throw Exception(
        response['message'] ?? 'Failed to fetch coordinator activities',
      );
    } catch (e) {
      debugPrint('❌ Error in getMyActivities: $e');
      rethrow;
    }
  }

  // Get all activities for browsing (from database)
  Future<List<Activity>> getAllActivities({
    String? category,
    String? search,
    bool? isVolunteering,
    String? status,
    int? page,
    int? limit,
  }) async {
    debugPrint('📡 Fetching all activities from database...');
    try {
      Map<String, String> queryParams = {};
      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;
      if (isVolunteering != null)
        queryParams['is_volunteering'] = isVolunteering.toString();
      if (status != null) queryParams['status'] = status;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _get('/activities/', queryParams: queryParams);
      if (response['success']) {
        debugPrint('✅ Successfully fetched all activities from database');
        final activitiesJson = _extractActivitiesFromResponse(response['data']);
        final activities =
            activitiesJson.map((json) => Activity.fromJson(json)).toList();
        debugPrint('📊 Loaded ${activities.length} activities');
        return activities;
      }
      throw Exception(response['message'] ?? 'Failed to fetch activities');
    } catch (e) {
      debugPrint('❌ Error in getAllActivities: $e');
      rethrow;
    }
  }

  // Get recent activities from database
  Future<List<Activity>> getRecentActivities([
    DateTime? startDate,
    DateTime? endDate,
  ]) async {
    debugPrint('📡 Fetching recent activities from database...');
    try {
      Map<String, String> queryParams = {
        'limit': '10',
        'ordering': '-created_at',
      };
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final response = await _get(
        '/activities/recent/',
        queryParams: queryParams,
      );
      if (response['success']) {
        debugPrint('✅ Successfully fetched recent activities from database');
        final activitiesJson = _extractActivitiesFromResponse(response['data']);
        var activities =
            activitiesJson.map((json) => Activity.fromJson(json)).toList();
        if (startDate != null && endDate != null) {
          activities =
              activities.where((activity) {
                return activity.startTime.isAfter(startDate) &&
                    activity.startTime.isBefore(endDate);
              }).toList();
        }
        final recentActivities = activities.take(5).toList();
        debugPrint('✅ Loaded ${recentActivities.length} recent activities');
        return recentActivities;
      }
      throw Exception(
        response['message'] ?? 'Failed to fetch recent activities',
      );
    } catch (e) {
      debugPrint('❌ Error in getRecentActivities: $e');
      rethrow;
    }
  }

  // CRITICAL: Create a new activity in database with proper boolean handling
  Future<Activity> createActivity(
    Activity activity,
    Map<String, dynamic> additionalData,
  ) async {
    debugPrint('➕ Creating activity in database...');
    try {
      final activityData = {
        'title': activity.title,
        'description': activity.description,
        'start_time': activity.startTime.toIso8601String(),
        'end_time': activity.endTime.toIso8601String(),
        'location': activity.location,
        'is_volunteering': activity.isVolunteering,
        'category': additionalData['category'] ?? 'Academic',
        'difficulty': additionalData['difficulty'] ?? 'beginner',
        'max_participants': additionalData['maxParticipants'] ?? 50,
        'points_reward': additionalData['pointsReward'] ?? 10,
        'requirements': additionalData['requirements'] ?? '',
        'is_virtual': additionalData['isVirtual'] ?? false,
        'virtual_link': additionalData['virtualLink'] ?? '',
        'is_featured': additionalData['isFeatured'] ?? false,
        'certificate_available':
            additionalData['certificateAvailable'] ?? false,
        'status': 'upcoming', // IMPORTANT: Set to upcoming instead of draft
      };

      if (additionalData['registrationDeadline'] != null) {
        activityData['registration_deadline'] =
            additionalData['registrationDeadline'].toIso8601String();
      }

      debugPrint('📤 Activity data being sent:');
      activityData.forEach((key, value) {
        debugPrint('  $key: $value (${value.runtimeType})');
      });

      File? posterImage = additionalData['posterImage'] as File?;
      final response = await _postMultipart(
        '/coordinator/activities/create/',
        activityData,
        imageFile: posterImage,
      );

      if (response['success']) {
        debugPrint('✅ Successfully created activity in database');
        Map<String, dynamic> activityJson;
        final data = response['data'];
        if (data is Map && data['activity'] != null) {
          activityJson = Map<String, dynamic>.from(data['activity']);
        } else if (data is Map) {
          activityJson = Map<String, dynamic>.from(data);
        } else {
          throw Exception('Unexpected response structure for created activity');
        }

        final createdActivity = Activity.fromJson(activityJson);
        debugPrint(
          '🎉 Created activity: ${createdActivity.title} with ID: ${createdActivity.id}',
        );
        return createdActivity;
      }
      throw Exception(response['message'] ?? 'Failed to create activity');
    } catch (e) {
      debugPrint('❌ Error in createActivity: $e');
      rethrow;
    }
  }

  // Update an existing activity in database
  Future<void> updateActivity(
    int activityId,
    Activity activity,
    Map<String, dynamic> additionalData,
  ) async {
    debugPrint('✏️ Updating activity in database...');
    try {
      final activityData = {
        'title': activity.title,
        'description': activity.description,
        'start_time': activity.startTime.toIso8601String(),
        'end_time': activity.endTime.toIso8601String(),
        'location': activity.location,
        'is_volunteering': activity.isVolunteering,
        'category': additionalData['category'] ?? 'Academic',
        'difficulty': additionalData['difficulty'] ?? 'beginner',
        'max_participants': additionalData['maxParticipants'] ?? 50,
        'points_reward': additionalData['pointsReward'] ?? 10,
        'requirements': additionalData['requirements'] ?? '',
        'is_virtual': additionalData['isVirtual'] ?? false,
        'virtual_link': additionalData['virtualLink'] ?? '',
        'is_featured': additionalData['isFeatured'] ?? false,
        'certificate_available':
            additionalData['certificateAvailable'] ?? false,
      };

      if (additionalData['registrationDeadline'] != null) {
        activityData['registration_deadline'] =
            additionalData['registrationDeadline'].toIso8601String();
      }

      File? posterImage = additionalData['posterImage'] as File?;
      final response = await _postMultipart(
        '/coordinator/activities/$activityId/update/',
        activityData,
        imageFile: posterImage,
      );

      if (response['success']) {
        debugPrint('✅ Successfully updated activity in database');
      } else {
        throw Exception(response['message'] ?? 'Failed to update activity');
      }
    } catch (e) {
      debugPrint('❌ Error in updateActivity: $e');
      rethrow;
    }
  }

  // Delete an activity from database
  Future<void> deleteActivity(int activityId) async {
    debugPrint('🗑️ Deleting activity from database...');
    try {
      final response = await _delete(
        '/coordinator/activities/$activityId/delete/',
      );
      if (response['success']) {
        debugPrint('✅ Successfully deleted activity from database');
      } else {
        throw Exception(response['message'] ?? 'Failed to delete activity');
      }
    } catch (e) {
      debugPrint('❌ Error in deleteActivity: $e');
      rethrow;
    }
  }

  // Publish a draft activity
  Future<void> publishActivity(int activityId) async {
    debugPrint('📤 Publishing activity in database...');
    try {
      final response = await _post(
        '/coordinator/activities/$activityId/publish/',
        data: {'status': 'published'},
      );
      if (response['success']) {
        debugPrint('✅ Successfully published activity in database');
      } else {
        throw Exception(response['message'] ?? 'Failed to publish activity');
      }
    } catch (e) {
      debugPrint('❌ Error in publishActivity: $e');
      rethrow;
    }
  }

  // Get overview stats with real data from activities
  Future<Map<String, dynamic>> getOverviewStats(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      debugPrint(
        '🔢 Calculating overview stats from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}',
      );
      final activities = await getAllActivities();
      final filteredActivities =
          activities.where((activity) {
            return activity.startTime.isAfter(startDate) &&
                activity.startTime.isBefore(endDate);
          }).toList();

      final totalActivities = filteredActivities.length;
      final totalParticipants = filteredActivities.fold(
        0,
        (sum, activity) => sum + activity.enrolledCount,
      );
      final avgAttendance =
          filteredActivities.isEmpty
              ? 0
              : (filteredActivities.fold(
                        0.0,
                        (sum, activity) =>
                            sum + (activity.enrolledCount.toDouble()),
                      ) /
                      filteredActivities.length)
                  .round();

      final now = DateTime.now();
      final completedActivities =
          filteredActivities.where((a) => now.isAfter(a.endTime)).length;
      final completionRate =
          totalActivities == 0
              ? 0
              : ((completedActivities / totalActivities) * 100).round();

      final stats = {
        'totalActivities': totalActivities,
        'totalParticipants': totalParticipants,
        'avgAttendance': avgAttendance,
        'completionRate': completionRate,
      };

      debugPrint('✅ Overview stats calculated: $stats');
      return stats;
    } catch (e) {
      debugPrint('❌ Error getting overview stats: $e');
      return {
        'totalActivities': 0,
        'totalParticipants': 0,
        'avgAttendance': 0,
        'completionRate': 0,
      };
    }
  }

  // Get coordinator dashboard statistics from database
  Future<Map<String, dynamic>> getCoordinatorStats() async {
    debugPrint('📊 Fetching coordinator stats from database...');
    try {
      final response = await _get('/coordinator/stats/');
      if (response['success']) {
        debugPrint('✅ Successfully fetched coordinator stats from database');
        return response['data'] ?? {};
      }
      throw Exception(
        response['message'] ?? 'Failed to fetch coordinator stats',
      );
    } catch (e) {
      debugPrint('❌ Error in getCoordinatorStats: $e');
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      return await getOverviewStats(startOfMonth, now);
    }
  }

  // Get activity categories from database
  Future<List<Map<String, dynamic>>> getActivityCategories() async {
    debugPrint('📂 Fetching activity categories from database...');
    try {
      final response = await _get('/coordinator/categories/');
      if (response['success']) {
        debugPrint('✅ Successfully fetched categories from database');
        final data = response['data'];
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['categories'] != null) {
          return List<Map<String, dynamic>>.from(data['categories']);
        } else {
          debugPrint('Unexpected categories response: $data');
          return [];
        }
      }
      throw Exception(response['message'] ?? 'Failed to fetch categories');
    } catch (e) {
      debugPrint('❌ Error in getActivityCategories: $e');
      // Return minimal fallback data instead of full mock categories
      return [
        {'id': 0, 'name': 'General', 'description': 'General activities'},
      ];
    }
  }

  // Save promoted activity
  Future<void> savePromotedActivity(
    Activity activity,
    Map<String, dynamic> template,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getStringList(_promotedActivitiesKey) ?? [];

      final alreadyPromoted = existingData.any((recordStr) {
        try {
          final record = jsonDecode(recordStr);
          return record['activity_id'] == activity.id;
        } catch (e) {
          return false;
        }
      });

      final promotionRecord = {
        'activity_id': activity.id,
        'activity_title': activity.title,
        'template_name': template['name'],
        'promoted_at': DateTime.now().toIso8601String(),
        'views': 0, // Real view data would come from analytics API
        'new_enrollments': 0, // Real enrollment data would come from database
        'promotions_sent': alreadyPromoted ? 1 : 1, // Real promotion count from database
      };

      existingData.add(jsonEncode(promotionRecord));
      final success = await prefs.setStringList(
        _promotedActivitiesKey,
        existingData,
      );

      if (success) {
        debugPrint('✅ Promotion saved for activity: ${activity.title}');
        debugPrint('📊 Total promotion records: ${existingData.length}');

        final verification = prefs.getStringList(_promotedActivitiesKey);
        debugPrint(
          '🔍 Verification: Found ${verification?.length ?? 0} records in storage',
        );
      } else {
        debugPrint('❌ Failed to save promotion data to SharedPreferences');
      }

      await _updatePromotionStats();
    } catch (e) {
      debugPrint('❌ Error saving promotion: $e');
      rethrow;
    }
  }

  // Get promoted activities (persistent)
  Future<List<Activity>> getPromotedActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final promotedData = prefs.getStringList(_promotedActivitiesKey) ?? [];

      debugPrint('🔍 Loading promoted activities from storage...');
      debugPrint(
        '📊 Found ${promotedData.length} promotion records in SharedPreferences',
      );

      if (promotedData.isEmpty) {
        debugPrint('⚠️ No promoted activities found in storage');
        return [];
      }

      final allActivities = await getMyActivities();
      debugPrint('📋 Total activities available: ${allActivities.length}');

      final promotedActivityIds = <int>{};
      for (final recordStr in promotedData) {
        try {
          final record = jsonDecode(recordStr);
          final activityId = record['activity_id'];
          if (activityId is int) {
            promotedActivityIds.add(activityId);
          }
        } catch (e) {
          debugPrint('⚠️ Failed to parse promotion record: $e');
        }
      }

      debugPrint('🎯 Unique promoted activity IDs: $promotedActivityIds');

      final promotedActivities =
          allActivities.where((activity) {
            return promotedActivityIds.contains(activity.id);
          }).toList();

      debugPrint('✅ Loaded ${promotedActivities.length} promoted activities');
      return promotedActivities;
    } catch (e) {
      debugPrint('❌ Error loading promoted activities: $e');
      return [];
    }
  }

  // Get activity reports
  Future<Map<String, dynamic>> getActivityReports([
    DateTime? startDate,
    DateTime? endDate,
  ]) async {
    debugPrint('📈 Fetching activity reports from database...');
    try {
      Map<String, String>? queryParams;
      if (startDate != null && endDate != null) {
        queryParams = {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        };
      }
      final response = await _get(
        '/coordinator/reports/',
        queryParams: queryParams,
      );
      if (response['success']) {
        debugPrint('✅ Successfully fetched activity reports from database');
        return response['data'] ?? {};
      }
      throw Exception(response['message'] ?? 'Failed to fetch reports');
    } catch (e) {
      debugPrint('❌ Error in getActivityReports: $e');
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month, 1);
      final end = endDate ?? now;
      return await getOverviewStats(start, end);
    }
  }

  // Check if backend is reachable
  Future<bool> isBackendReachable() async {
    try {
      debugPrint('🔗 Checking backend connectivity...');
      final response = await http
          .get(Uri.parse('$_baseUrl/health/'), headers: await _getHeaders())
          .timeout(const Duration(seconds: 5));
      final isReachable = response.statusCode == 200;
      debugPrint('✅ Backend reachable: $isReachable');
      return isReachable;
    } catch (e) {
      debugPrint('❌ Backend unreachable: $e');
      return false;
    }
  }

  // Helper methods for promotion features
  Future<bool> isActivityPromoted(int activityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final promotedData = prefs.getStringList(_promotedActivitiesKey) ?? [];

      bool isPromoted = false;
      for (final recordStr in promotedData) {
        try {
          final record = jsonDecode(recordStr);
          if (record['activity_id'] == activityId) {
            isPromoted = true;
            break;
          }
        } catch (e) {
          debugPrint('⚠️ Failed to parse promotion record: $e');
        }
      }

      return isPromoted;
    } catch (e) {
      debugPrint('❌ Error checking promotion status: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getPromotionStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final promotedData = prefs.getStringList(_promotedActivitiesKey) ?? [];

      if (promotedData.isEmpty) {
        return {
          'totalPromotions': 0,
          'thisWeek': 0,
          'avgReach': 0,
          'engagement': 0,
        };
      }

      int totalPromotions = promotedData.length;
      int thisWeekPromotions = 0;
      int totalReach = 0;

      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

      for (final recordStr in promotedData) {
        try {
          final record = jsonDecode(recordStr);
          final promotedAtStr = record['promoted_at'] as String?;

          if (promotedAtStr != null) {
            final promotedAt = DateTime.parse(promotedAtStr);
            if (promotedAt.isAfter(oneWeekAgo)) {
              thisWeekPromotions++;
            }
          }

          totalReach += (record['views'] as int? ?? 0);
        } catch (e) {
          debugPrint('⚠️ Failed to parse promotion record for stats: $e');
        }
      }

      final stats = {
        'totalPromotions': totalPromotions,
        'thisWeek': thisWeekPromotions,
        'avgReach':
            totalPromotions > 0 ? (totalReach / totalPromotions).round() : 0,
        'engagement': totalPromotions > 0 ? 0 : 0, // Real engagement would come from analytics API
      };

      return stats;
    } catch (e) {
      debugPrint('❌ Error getting promotion stats: $e');
      return {
        'totalPromotions': 0,
        'thisWeek': 0,
        'avgReach': 0,
        'engagement': 0,
      };
    }
  }

  Future<void> _updatePromotionStats() async {
    debugPrint('📊 Promotion stats updated (calculated on-demand)');
  }

  void clearCache() {
    debugPrint('🧹 Coordinator service cache cleared');
  }

  // Get activity summary with real data from activities
  Future<Map<String, dynamic>> getActivitySummary(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      debugPrint(
        '📊 Calculating activity summary from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}',
      );
      final activities = await getAllActivities();
      final filteredActivities =
          activities.where((activity) {
            return activity.startTime.isAfter(startDate) &&
                activity.startTime.isBefore(endDate);
          }).toList();

      final byCategory = <String, int>{};
      for (var activity in filteredActivities) {
        final category = activity.category ?? 'Uncategorized';
        byCategory[category] = (byCategory[category] ?? 0) + 1;
      }

      final byStatus = <String, int>{};
      final now = DateTime.now();
      for (var activity in filteredActivities) {
        String status;
        if (activity.status.toLowerCase() == 'draft' ||
            activity.status.toLowerCase() == 'cancelled') {
          status = activity.status.toLowerCase();
        } else if (now.isBefore(activity.startTime)) {
          status = 'upcoming';
        } else if (now.isAfter(activity.endTime)) {
          status = 'completed';
        } else {
          status = 'ongoing';
        }
        byStatus[status] = (byStatus[status] ?? 0) + 1;
      }

      final byType = <String, int>{};
      for (var activity in filteredActivities) {
        final type = activity.isVolunteering ? 'Volunteering' : 'Regular';
        byType[type] = (byType[type] ?? 0) + 1;
      }

      final summary = {
        'byCategory': byCategory,
        'byStatus': byStatus,
        'byType': byType,
      };

      debugPrint('✅ Activity summary calculated: $summary');
      return summary;
    } catch (e) {
      debugPrint('❌ Error getting activity summary: $e');
      return {
        'byCategory': <String, int>{},
        'byStatus': <String, int>{},
        'byType': <String, int>{},
      };
    }
  }

  // Get promotion analytics (realistic mock data)
  Future<Map<String, dynamic>> getPromotionAnalytics() async {
    try {
      final promotedData = await _getPromotedRecords();

      debugPrint(
        '📈 Calculating promotion analytics from ${promotedData.length} records',
      );

      if (promotedData.isEmpty) {
        debugPrint('⚠️ No promotion data found for analytics calculation');
        return {
          'totalReach': 0,
          'reachChange': '+0%',
          'engagementRate': 0,
          'engagementChange': '+0%',
          'newEnrollments': 0,
          'enrollmentChange': '+0%',
          'conversionRate': 0,
          'conversionChange': '+0%',
        };
      }

      int totalReach = 0;
      int totalEnrollments = 0;

      for (final record in promotedData) {
        totalReach += (record['views'] as int? ?? 0);
        totalEnrollments += (record['new_enrollments'] as int? ?? 0);
      }

      final conversionRate =
          totalReach > 0 ? ((totalEnrollments / totalReach) * 100) : 0;

      final analytics = {
        'totalReach': totalReach,
        'reachChange': '+0%', // Real data would come from time comparison
        'engagementRate': 0, // Real data would come from analytics API
        'engagementChange': '+0%', // Real data would come from time comparison
        'newEnrollments': totalEnrollments,
        'enrollmentChange': '+0%', // Real data would come from time comparison
        'conversionRate': conversionRate.round(),
        'conversionChange': '+0%', // Real data would come from time comparison
      };
      debugPrint('✅ Calculated promotion analytics: $analytics');
      return analytics;
    } catch (e) {
      debugPrint('❌ Error getting analytics: $e');
      return {};
    }
  }

  // Get detailed promotion data for specific activity
  Future<Map<String, dynamic>> getActivityPromotionDetails(
    int activityId,
  ) async {
    try {
      debugPrint('🔍 Getting promotion details for activity $activityId');
      final promotedData = await _getPromotedRecords();
      final activityPromotions =
          promotedData
              .where((record) => record['activity_id'] == activityId)
              .toList();
      debugPrint(
        '📊 Found ${activityPromotions.length} promotion records for activity $activityId',
      );
      if (activityPromotions.isEmpty) {
        return {
          'promotions_sent': 0,
          'total_views': 0,
          'new_enrollments': 0,
          'last_promoted': null,
        };
      }
      int totalViews = 0;
      int totalEnrollments = 0;
      int totalPromotions = activityPromotions.length;
      String? lastPromoted;
      for (final promotion in activityPromotions) {
        totalViews += (promotion['views'] as int? ?? 0);
        totalEnrollments += (promotion['new_enrollments'] as int? ?? 0);
        final promotedAt = promotion['promoted_at'] as String?;
        if (promotedAt != null) {
          if (lastPromoted == null || promotedAt.compareTo(lastPromoted) > 0) {
            lastPromoted = promotedAt;
          }
        }
      }
      final details = {
        'promotions_sent': totalPromotions,
        'total_views': totalViews,
        'new_enrollments': totalEnrollments,
        'last_promoted': lastPromoted,
      };
      debugPrint('✅ Activity promotion details: $details');
      return details;
    } catch (e) {
      debugPrint('❌ Error getting activity promotion details: $e');
      return {
        'promotions_sent': 0,
        'total_views': 0,
        'new_enrollments': 0,
        'last_promoted': null,
      };
    }
  }

  // Helper method to get promoted records
  Future<List<Map<String, dynamic>>> _getPromotedRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final promotedData = prefs.getStringList(_promotedActivitiesKey) ?? [];
      debugPrint(
        '🗃️ Loading ${promotedData.length} promotion records from storage',
      );
      final records = <Map<String, dynamic>>[];
      for (final recordStr in promotedData) {
        try {
          final record = Map<String, dynamic>.from(jsonDecode(recordStr));
          records.add(record);
        } catch (e) {
          debugPrint('⚠️ Failed to parse promotion record: $e');
        }
      }
      debugPrint('✅ Successfully parsed ${records.length} promotion records');
      return records;
    } catch (e) {
      debugPrint('❌ Error getting promoted records: $e');
      return [];
    }
  }

  // Clear all promotion data (for testing)
  Future<void> clearPromotionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_promotedActivitiesKey);
      await prefs.remove(_promotionStatsKey);
      debugPrint('✅ Promotion data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing promotion data: $e');
    }
  }

  // Get mock top performing activities
  Future<List<Map<String, dynamic>>>
  getTopPerformingActivitiesForPromotions() async {
    try {
      debugPrint('🏆 Getting top performing activities for promotions');
      final promotedActivities = await getPromotedActivities();
      if (promotedActivities.isEmpty) {
        debugPrint(
          '⚠️ No promoted activities found for top performance calculation',
        );
        return [];
      }
      final topActivities =
          promotedActivities.take(3).map((activity) {
            return {
              'title': activity.title,
              'engagement': 0, // Real engagement data would come from analytics API
            };
          }).toList();
      debugPrint('✅ Top performing activities: ${topActivities.length}');
      return topActivities;
    } catch (e) {
      debugPrint('❌ Error getting top performing activities: $e');
      return [];
    }
  }

  // Get mock channel performance data
  Future<List<Map<String, dynamic>>> getChannelPerformance() async {
    debugPrint('📊 Getting channel performance data');
    return [
      {
        'name': 'Social Media',
        'performance': 0, // Real performance data would come from social media API
        'metric': '0 reach', // Real metrics would come from social media analytics
      },
      {
        'name': 'Email',
        'performance': 0, // Real performance data would come from email analytics
        'metric': '0 opens', // Real metrics would come from email service
      },
      {
        'name': 'WhatsApp',
        'performance': 0, // Real performance data would come from WhatsApp analytics
        'metric': '0 views', // Real metrics would come from WhatsApp service
      },
      {
        'name': 'Campus Flyers',
        'performance': 0, // Real performance data would come from tracking system
        'metric': '0 views', // Real metrics would come from tracking system
      },
    ];
  }

  // Placeholder methods for future implementation
  Future<void> duplicateActivity(int activityId) async {
    throw Exception('Duplicate feature not implemented in backend yet');
  }

  Future<Map<String, dynamic>> getAttendanceReports(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return {};
  }

  Future<Map<String, dynamic>> getEngagementReports(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return {};
  }

  Future<Map<String, dynamic>> getPerformanceReports(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return {};
  }

  Future<void> exportReports(DateTime startDate, DateTime endDate) async {
    // Not implemented yet
  }

  Future<Map<String, dynamic>> getAttendanceOverview(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return {};
  }

  Future<List<Map<String, dynamic>>> getAttendanceTrends(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return [];
  }

  Future<List<Map<String, dynamic>>> getAttendanceByActivity(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return [];
  }

  Future<Map<String, dynamic>> getEngagementMetrics(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return {};
  }

  Future<List<Map<String, dynamic>>> getParticipationTrends(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return [];
  }

  Future<List<Map<String, dynamic>>> getEngagementByCategory(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return [];
  }

  Future<Map<String, dynamic>> getPerformanceMetrics(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return {};
  }

  Future<List<Map<String, dynamic>>> getTopPerformingActivities(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return [];
  }

  Future<List<Map<String, dynamic>>> getImprovementAreas(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return [];
  }
}
