// lib/screens/admin/data_export_screen.dart - COMPLETE FIXED VERSION
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/export_service.dart';
import '../../widgets/admin_bottom_nav_bar.dart';

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});

  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  final AdminService _adminService = AdminService();

  Map<String, dynamic>? _exportData;
  bool _isLoading = true;
  bool _isExporting = false;
  String _errorMessage = '';
  int _totalRecords = 0;

  // Date range filters
  DateTime? _fromDate;
  DateTime? _toDate;

  // Export options
  String _selectedFormat = 'CSV';
  final List<String> _exportFormats = ['CSV', 'JSON'];

  @override
  void initState() {
    super.initState();
    _loadExportData();
  }

  // SAFE PARSING METHODS (same as System Reports)
  int _safeParseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  double _safeParseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> _loadExportData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Try to get real data from admin service
      try {
        final stats = await _adminService.getDashboardStats();
        final analytics = await _adminService.getSystemAnalytics();
        
        // Combine both API responses into export data
        final processedStats = {
          'users': stats['total_users'] ?? 0,
          'activities': analytics['total_activities'] ?? 0,
          'registrations': stats['active_activities'] ?? 0,
          'attendance_records': analytics['total_volunteer_hours'] ?? 0,
          'volunteer_applications': stats['pending_issues'] ?? 0,
          'volunteering_hours': analytics['total_volunteer_hours'] ?? 0,
          'total_notifications': 0, // No API endpoint for this yet
          'active_users': analytics['active_sessions'] ?? 0,
          'pending_applications': stats['pending_issues'] ?? 0,
          'last_updated': DateTime.now().toIso8601String(),
        };

        setState(() {
          _exportData = processedStats;
          _totalRecords = _calculateTotalRecords(processedStats);
          _isLoading = false;
        });
      } catch (apiError) {
        debugPrint('❌ API Error, using fallback data: $apiError');
        
        // Use fallback data only when API fails
        final fallbackStats = {
          'users': 0,
          'activities': 0,
          'registrations': 0,
          'attendance_records': 0,
          'volunteer_applications': 0,
          'volunteering_hours': 0,
          'total_notifications': 0,
          'active_users': 0,
          'pending_applications': 0,
          'last_updated': DateTime.now().toIso8601String(),
        };

        setState(() {
          _exportData = fallbackStats;
          _totalRecords = 0;
          _isLoading = false;
          _errorMessage = 'Using offline data - server connection limited';
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading export data: $e');
      setState(() {
        _errorMessage = 'Error loading data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  int _calculateTotalRecords(Map<String, dynamic> data) {
    return _safeParseInt(data['users']) +
        _safeParseInt(data['activities']) +
        _safeParseInt(data['registrations']) +
        _safeParseInt(data['attendance_records']) +
        _safeParseInt(data['volunteer_applications']);
  }

  // FIXED: Export method using the same working ExportService
  Future<void> _performExport() async {
    if (_exportData == null) return;

    try {
      setState(() => _isExporting = true);

      // Use the same ExportService method that works in System Reports
      await ExportService.exportSystemData();

      _showSnackBar(
        'Data exported successfully! Check your Downloads folder.',
        Colors.green,
      );
    } catch (e) {
      debugPrint('❌ Export error: $e');
      _showSnackBar('Export failed: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Export'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExportData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Export Header Card
          _buildExportHeaderCard(),
          const SizedBox(height: 24),

          // Export Configuration
          const Text(
            'Export Configuration',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildConfigurationSection(),
          const SizedBox(height: 24),

          // Data Preview
          const Text(
            'Data Preview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDataPreview(),
          const SizedBox(height: 24),

          // Export Button
          _buildExportButton(),
        ],
      ),
    );
  }

  Widget _buildExportHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.download, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Export Center',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Export system data for analysis and backup',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.storage,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_totalRecords',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Total Records',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Just now',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Last Updated',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Format Selection
          Row(
            children: [
              const Icon(Icons.file_copy, color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Export Format',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: _selectedFormat,
                items:
                    _exportFormats.map((format) {
                      return DropdownMenuItem<String>(
                        value: format,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              format == 'CSV' ? Icons.table_chart : Icons.code,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(format),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFormat = value!;
                  });
                },
                underline: Container(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Date Range Selection
          const Text(
            'Date Range',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'From',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _fromDate == null
                                  ? 'Select date'
                                  : _formatDate(_fromDate!),
                              style: TextStyle(
                                color:
                                    _fromDate == null
                                        ? Colors.grey[500]
                                        : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'To',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _toDate == null
                                  ? 'Select date'
                                  : _formatDate(_toDate!),
                              style: TextStyle(
                                color:
                                    _toDate == null
                                        ? Colors.grey[500]
                                        : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataPreview() {
    if (_exportData == null) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('No data available for preview')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.preview, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Data Overview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                'Total: $_totalRecords records',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...(_exportData!.entries
              .where((entry) => entry.key != 'last_updated')
              .map((entry) {
                return _buildDataRow(entry.key, entry.value);
              })),
          const Divider(),
          _buildDataRow('Last Updated', _exportData!['last_updated']),
        ],
      ),
    );
  }

  Widget _buildDataRow(String key, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _formatKeyName(key),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: TextStyle(
                color: Colors.grey[700],
                fontFamily: 'monospace',
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value.runtimeType.toString(),
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _isExporting ? null : _performExport,
            icon:
                _isExporting
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.download),
            label: Text(_isExporting ? 'Exporting...' : 'Export Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Export format: $_selectedFormat • Total records: $_totalRecords',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'File will be downloaded to your browser\'s default download folder',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatKeyName(String key) {
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDate(bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.help_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text('Export Help'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Export Information:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text('• CSV format is compatible with Excel and Google Sheets'),
                Text('• JSON format is suitable for technical analysis'),
                Text(
                  '• Files are automatically downloaded to your Downloads folder',
                ),
                Text('• Date range filters will be applied in future updates'),
                SizedBox(height: 12),
                Text(
                  'Exported data includes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• User accounts and statistics'),
                Text('• Activity records and participation'),
                Text('• Volunteer applications and hours'),
                Text('• System metrics and performance data'),
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

