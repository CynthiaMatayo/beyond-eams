import 'package:flutter/material.dart';
import '../services/attendance_service.dart';

class AttendanceProvider with ChangeNotifier {
  List<dynamic> _attendances = [];
  List<Map<String, dynamic>> _qrRecords = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get attendances => _attendances;
  List<Map<String, dynamic>> get qrRecords => _qrRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Mark attendance via QR code scanning
  Future<bool> markAttendanceViaQR(String qrCode) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await AttendanceService.scanAttendanceQR(qrCode);

      if (result['success'] == true) {
        // Add to QR records
        _qrRecords.add({
          'qr_code': qrCode,
          'timestamp': DateTime.now(),
          'student_name': result['data']['student_name'] ?? 'Unknown',
          'activity_name': result['data']['activity_name'] ?? 'Unknown',
        });
        _setLoading(false);
        return true;
      } else {
        _setError(result['error'] ?? 'Failed to scan QR code');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error: $e');
      _setLoading(false);
      return false;
    }
  }

  // Get attendance records for an activity
  Future<void> getActivityAttendance(int activityId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await AttendanceService.getAttendanceByActivity(
        activityId,
      );

      if (result['success'] == true) {
        _attendances = result['data'] ?? [];
        _setError(null);
      } else {
        _setError(result['error'] ?? 'Failed to load attendance');
        _attendances = [];
      }
    } catch (e) {
      _setError('Network error: $e');
      _attendances = [];
    }

    _setLoading(false);
  }

  // Mark attendance manually
  Future<bool> markAttendanceManual(
    int activityId,
    int studentId, {
    String status = 'attended',
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await AttendanceService.markAttendance(
        activityId: activityId,
        userId: studentId,
        status: status,
      );

      if (result['success'] == true) {
        // Refresh the attendance list
        await getActivityAttendance(activityId);
        _setLoading(false);
        return true;
      } else {
        _setError(result['error'] ?? 'Failed to mark attendance');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error: $e');
      _setLoading(false);
      return false;
    }
  }

  // Get user participation history
  Future<Map<String, dynamic>?> getUserParticipation(int userId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await AttendanceService.getUserParticipation(userId);

      if (result['success'] == true) {
        _setLoading(false);
        return result['data'];
      } else {
        _setError(result['error'] ?? 'Failed to load participation');
        _setLoading(false);
        return null;
      }
    } catch (e) {
      _setError('Network error: $e');
      _setLoading(false);
      return null;
    }
  }

  // Get activity participants
  Future<List<dynamic>> getActivityParticipants(int activityId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await AttendanceService.getActivityParticipants(
        activityId,
      );

      if (result['success'] == true) {
        _setLoading(false);
        return result['data'] ?? [];
      } else {
        _setError(result['error'] ?? 'Failed to load participants');
        _setLoading(false);
        return [];
      }
    } catch (e) {
      _setError('Network error: $e');
      _setLoading(false);
      return [];
    }
  }

  // Generate QR code for attendance
  Future<Map<String, dynamic>?> generateAttendanceQR(int activityId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await AttendanceService.generateAttendanceQR(activityId);

      if (result['success'] == true) {
        _setLoading(false);
        return result['data'];
      } else {
        _setError(result['error'] ?? 'Failed to generate QR code');
        _setLoading(false);
        return null;
      }
    } catch (e) {
      _setError('Network error: $e');
      _setLoading(false);
      return null;
    }
  }

  // Verify QR code
  Future<bool> verifyQRCode(String qrCode, int activityId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await AttendanceService.verifyAttendanceQR(
        qrCode,
        activityId,
      );

      if (result['success'] == true) {
        _setLoading(false);
        return result['data']['valid'] ?? false;
      } else {
        _setError(result['error'] ?? 'Failed to verify QR code');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Network error: $e');
      _setLoading(false);
      return false;
    }
  }

  // Get attendance statistics
  Future<Map<String, dynamic>?> getAttendanceStatistics(int activityId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await AttendanceService.getAttendanceStatistics(
        activityId,
      );

      if (result['success'] == true) {
        _setLoading(false);
        return result['data'];
      } else {
        _setError(result['error'] ?? 'Failed to load statistics');
        _setLoading(false);
        return null;
      }
    } catch (e) {
      _setError('Network error: $e');
      _setLoading(false);
      return null;
    }
  }

  // Clear all data
  void clearData() {
    _attendances = [];
    _qrRecords = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Update attendance status (placeholder - not implemented in service yet)
  Future<bool> updateAttendanceStatus(
    int attendanceId,
    String newStatus,
    int activityId,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      // TODO: Implement this in AttendanceService
      // For now, just refresh the list
      await getActivityAttendance(activityId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Network error: $e');
      _setLoading(false);
      return false;
    }
  }

  // Export attendance to CSV (basic implementation)
  Future<String?> exportAttendanceCSV(int activityId) async {
    _setLoading(true);
    _setError(null);

    try {
      // Get attendance data first
      await getActivityAttendance(activityId);

      if (_attendances.isEmpty) {
        _setError('No attendance data to export');
        _setLoading(false);
        return null;
      }

      // Create basic CSV
      String csv = 'Student ID,Student Name,Status,Marked At\n';
      for (var record in _attendances) {
        if (record is Map<String, dynamic>) {
          csv +=
              '${record['user_id'] ?? 'N/A'},'
              '"${record['student_name'] ?? 'Unknown'}",'
              '${record['status'] ?? 'attended'},'
              '${record['marked_at'] ?? DateTime.now().toIso8601String()}\n';
        }
      }

      _setLoading(false);
      return csv;
    } catch (e) {
      _setError('Failed to export CSV: $e');
      _setLoading(false);
      return null;
    }
  }

  // Get multiple activity attendance summary (basic implementation)
  Future<List<Map<String, dynamic>>> getMultipleActivitySummary(
    List<int> activityIds,
  ) async {
    _setLoading(true);
    _setError(null);

    List<Map<String, dynamic>> summaries = [];

    try {
      for (int activityId in activityIds) {
        try {
          final stats = await getAttendanceStatistics(activityId);
          summaries.add({'activity_id': activityId, 'statistics': stats});
        } catch (e) {
          summaries.add({'activity_id': activityId, 'error': e.toString()});
        }
      }

      _setLoading(false);
      return summaries;
    } catch (e) {
      _setError('Failed to load activity summaries: $e');
      _setLoading(false);
      return [];
    }
  }
}
