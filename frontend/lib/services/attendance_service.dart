import 'dart:convert';
import 'package:http/http.dart' as http;

class AttendanceService {
  // Replace with your actual backend URL
  static const String baseUrl =
      'http://127.0.0.1:8000/api'; // Update to match your backend

  // Helper method to get headers with authentication
  static Map<String, String> _getHeaders() {
    // TODO: Get the auth token from your auth provider/storage
    // You can uncomment this when you implement authentication
    // String? token = AuthProvider.instance.getToken();
    return {
      'Content-Type': 'application/json',
      // 'Authorization': 'Bearer $token', // Uncomment when you have auth
    };
  }

  // GET /api/attendance/{activity_id} - Get attendance by activity
  static Future<Map<String, dynamic>> getAttendanceByActivity(
    int activityId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/$activityId/'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error':
              'Failed to get attendance: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // POST /api/attendance/mark/ - Mark attendance/participation (Updated endpoint)
  static Future<Map<String, dynamic>> markAttendance({
    required int activityId,
    required int userId,
    required String status, // 'attended', 'missed', 'excused'
  }) async {
    try {
      final body = {
        'activity_id': activityId,
        'user_id': userId,
        'status': status,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/attendance/mark/'),
        headers: _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error':
              'Failed to mark attendance: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // POST /api/participation/mark/ - Mark participation (Legacy method for compatibility)
  static Future<Map<String, dynamic>> markParticipation({
    required int activityId,
    required int studentId,
  }) async {
    try {
      final body = {
        'activity_id': activityId,
        'user_id': studentId,
        'status': 'attended', // Default to attended
      };

      final response = await http.post(
        Uri.parse('$baseUrl/attendance/mark/'), // Updated to use new endpoint
        headers: _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error':
              'Failed to mark participation: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // GET /api/participation/user/{user_id}/ - Get participation history for a user
  static Future<Map<String, dynamic>> getUserParticipation(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/participation/user/$userId/'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error':
              'Failed to get user participation: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // GET /api/participation/activity/{activity_id}/ - View who attended an activity
  static Future<Map<String, dynamic>> getActivityParticipants(
    int activityId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/participation/activity/$activityId/'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error':
              'Failed to get activity participants: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // GET /api/participation/report - Get full participation report
  static Future<Map<String, dynamic>> getParticipationReport() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/participation/report/'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error':
              'Failed to get participation report: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // QR Code related methods (Updated for new backend)

  // Generate QR code for an activity - NEW METHOD
  static Future<Map<String, dynamic>> generateAttendanceQR(
    int activityId,
  ) async {
    try {
      final body = {'activity_id': activityId};

      final response = await http.post(
        Uri.parse('$baseUrl/attendance/qr/generate/'),
        headers: _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'QR code generation endpoint not implemented yet',
        };
      } else {
        return {
          'success': false,
          'error':
              'Failed to generate QR code: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'QR code generation not available: $e',
      };
    }
  }

  // Scan QR code to mark attendance - NEW METHOD
  static Future<Map<String, dynamic>> scanAttendanceQR(String qrCode) async {
    try {
      final body = {'qr_code': qrCode};

      final response = await http.post(
        Uri.parse('$baseUrl/attendance/qr/scan/'),
        headers: _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'QR scan endpoint not implemented yet',
        };
      } else {
        return {
          'success': false,
          'error':
              'Failed to scan QR code: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'QR scan functionality not available: $e',
      };
    }
  }

  // Verify QR code validity - NEW METHOD
  static Future<Map<String, dynamic>> verifyAttendanceQR(
    String qrCode,
    int activityId,
  ) async {
    try {
      final body = {'qr_code': qrCode, 'activity_id': activityId};

      final response = await http.post(
        Uri.parse('$baseUrl/attendance/qr/verify/'),
        headers: _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'QR verification endpoint not implemented yet',
        };
      } else {
        return {
          'success': false,
          'error':
              'Failed to verify QR code: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'QR verification not available: $e'};
    }
  }

  // Legacy QR methods (keeping for backward compatibility)

  // Get QR code for an activity (Legacy method)
  static Future<Map<String, dynamic>> getQRCode(int activityId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/activities/$activityId/qr-code/'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'QR code endpoint not implemented yet',
        };
      } else {
        return {
          'success': false,
          'error':
              'Failed to get QR code: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'QR code functionality not available: $e',
      };
    }
  }

  // Generate new QR code (Legacy method)
  static Future<Map<String, dynamic>> generateQRCode(int activityId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/activities/$activityId/generate-qr/'),
        headers: _getHeaders(),
        body: json.encode({}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'QR code generation endpoint not implemented yet',
        };
      } else {
        return {
          'success': false,
          'error':
              'Failed to generate QR code: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'QR code generation not available: $e',
      };
    }
  }

  // Check in with QR code (Legacy method)
  static Future<Map<String, dynamic>> checkInWithQRCode(
    String qrCode,
    int studentId,
  ) async {
    try {
      final body = {'qr_code': qrCode, 'student_id': studentId};

      final response = await http.post(
        Uri.parse('$baseUrl/attendance/qr-checkin/'),
        headers: _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'QR check-in endpoint not implemented yet',
        };
      } else {
        return {
          'success': false,
          'error':
              'Failed to check in with QR code: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'QR check-in functionality not available: $e',
      };
    }
  }

  // Additional helper methods for enhanced functionality

  // Get attendance statistics for an activity
  static Future<Map<String, dynamic>> getAttendanceStatistics(
    int activityId,
  ) async {
    try {
      final attendanceResult = await getAttendanceByActivity(activityId);

      if (!attendanceResult['success']) {
        return attendanceResult;
      }

      final attendanceData = attendanceResult['data'];
      List<dynamic> records = attendanceData['results'] ?? attendanceData;

      int totalParticipants = records.length;
      int attendedCount =
          records.where((r) => r['status'] == 'attended').length;
      int missedCount = records.where((r) => r['status'] == 'missed').length;
      int excusedCount = records.where((r) => r['status'] == 'excused').length;

      double attendanceRate =
          totalParticipants > 0 ? (attendedCount / totalParticipants) * 100 : 0;

      return {
        'success': true,
        'data': {
          'total_participants': totalParticipants,
          'attended': attendedCount,
          'missed': missedCount,
          'excused': excusedCount,
          'attendance_rate': attendanceRate.toStringAsFixed(1),
          'activity_id': activityId,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to calculate attendance statistics: $e',
      };
    }
  }

  // Mark attendance with simplified interface (backward compatibility)
  static Future<Map<String, dynamic>> markStudentAttendance(
    int activityId,
    int studentId,
  ) async {
    return markAttendance(
      activityId: activityId,
      userId: studentId,
      status: 'attended',
    );
  }

  // Mark student as excused
  static Future<Map<String, dynamic>> markStudentExcused(
    int activityId,
    int studentId,
  ) async {
    return markAttendance(
      activityId: activityId,
      userId: studentId,
      status: 'excused',
    );
  }

  // Mark student as missed
  static Future<Map<String, dynamic>> markStudentMissed(
    int activityId,
    int studentId,
  ) async {
    return markAttendance(
      activityId: activityId,
      userId: studentId,
      status: 'missed',
    );
  }
}
