// lib/widgets/admin_export_widget.dart
import 'package:flutter/material.dart';
import '../services/export_service.dart';

class AdminExportWidget extends StatelessWidget {
  final String exportType;
  final List<dynamic> data;
  final String? department;

  const AdminExportWidget({
    super.key,
    required this.exportType,
    required this.data,
    this.department,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _handleExport(context),
      icon: const Icon(Icons.download, size: 16),
      label: Text('Export $exportType'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _handleExport(BuildContext context) {
    try {
      if (data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No data available to export'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Perform the actual export based on type
      switch (exportType.toLowerCase()) {
        case 'activities':
          ExportService.exportActivities(data);
          break;
        case 'users':
          ExportService.exportUsers(data);
          break;
        case 'volunteers':
        case 'volunteer applications':
          ExportService.exportVolunteerApplications(data);
          break;
        case 'student reports':
        case 'reports':
          ExportService.exportStudentReports(data, department: department);
          break;
        default:
          // Generic export for other data types
          final List<Map<String, dynamic>> exportData =
              data.map((item) => _convertToMap(item)).toList();
          ExportService.exportToCSV(
            data: exportData,
            filename:
                '${exportType.replaceAll(' ', '_').toLowerCase()}_export_${DateTime.now().millisecondsSinceEpoch}',
            headers: _getHeadersForType(exportType),
          );
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('$exportType data exported successfully!')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'View Info',
            textColor: Colors.white,
            onPressed: () => _showDownloadInfo(context),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, dynamic> _convertToMap(dynamic item) {
    if (item is Map<String, dynamic>) {
      return item;
    } else {
      // Try to convert object to map using toJson if available
      try {
        if (item.runtimeType.toString().contains('toJson')) {
          return item.toJson();
        }
      } catch (e) {
        debugPrint('Error converting item to JSON: $e');
      }

      // Fallback: create a simple map with available properties
      return {
        'id': _getProperty(item, 'id') ?? item.hashCode.toString(),
        'name':
            _getProperty(item, 'name') ??
            _getProperty(item, 'title') ??
            'Unknown',
        'type': item.runtimeType.toString(),
        'data': item.toString(),
      };
    }
  }

  dynamic _getProperty(dynamic item, String propertyName) {
    try {
      switch (propertyName) {
        case 'id':
          return item.id;
        case 'name':
          return item.name;
        case 'title':
          return item.title;
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  List<String> _getHeadersForType(String type) {
    switch (type.toLowerCase()) {
      case 'activities':
        return [
          'id',
          'title',
          'description',
          'location',
          'start_time',
          'end_time',
          'coordinator',
          'enrolled_count',
          'status',
          'is_volunteering',
          'points',
          'created_at',
        ];
      case 'users':
        return [
          'id',
          'username',
          'email',
          'first_name',
          'last_name',
          'role',
          'department',
          'registration_number',
          'date_joined',
          'is_active',
        ];
      case 'volunteers':
      case 'volunteer applications':
        return [
          'id',
          'activity_title',
          'student_name',
          'student_email',
          'specific_role',
          'availability',
          'motivation',
          'status',
          'hours_completed',
          'applied_date',
          'completed_date',
        ];
      case 'student reports':
      case 'reports':
        return [
          'student_id',
          'student_name',
          'department',
          'registration_number',
          'activities_participated',
          'total_hours',
          'volunteer_hours',
          'attendance_rate',
          'last_activity_date',
          'points_earned',
        ];
      default:
        return ['id', 'name', 'type', 'data'];
    }
  }

  void _showDownloadInfo(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text('Download Information'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your file has been downloaded to your browser\'s default download folder.',
                ),
                const SizedBox(height: 12),
                const Text(
                  '📁 File details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text('• Format: CSV (Comma-Separated Values)'),
                Text(
                  '• Filename: ${exportType.replaceAll(' ', '_').toLowerCase()}_export_[timestamp].csv',
                ),
                const Text('• Location: Downloads folder'),
                const SizedBox(height: 12),
                const Text('You can open the file with:'),
                const Text('• Microsoft Excel'),
                const Text('• Google Sheets'),
                const Text('• LibreOffice Calc'),
                const Text('• Any spreadsheet application'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: Colors.blue.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Tip: If you don\'t see the download, check your browser\'s download bar or downloads folder.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }
}
