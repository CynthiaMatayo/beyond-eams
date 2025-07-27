// lib/screens/admin/system_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:frontend/services/admin_service.dart';
import 'package:frontend/widgets/admin_bottom_nav_bar.dart';
import 'package:frontend/models/user.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final AdminService _adminService = AdminService();

  Map<String, dynamic> _settings = {};
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isSaving = false;

  // Controllers for text fields
  final TextEditingController _appNameController = TextEditingController();
  final TextEditingController _maxActivitiesController =
      TextEditingController();
  final TextEditingController _notificationTitleController =
      TextEditingController();
  final TextEditingController _notificationMessageController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _maxActivitiesController.dispose();
    _notificationTitleController.dispose();
    _notificationMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final settings = await _adminService.getSystemSettings();
      setState(() {
        _settings = settings;
        _populateControllers();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load settings: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _populateControllers() {
    _appNameController.text = _settings['app_name'] ?? 'Beyond EAMS';
    _maxActivitiesController.text =
        (_settings['max_activities_per_user'] ?? 10).toString();
  }

  Future<void> _saveSettings() async {
    try {
      setState(() => _isSaving = true);

      final updatedSettings = {
        ..._settings,
        'app_name': _appNameController.text,
        'max_activities_per_user':
            int.tryParse(_maxActivitiesController.text) ?? 10,
        'enable_notifications': _settings['enable_notifications'] ?? true,
        'enable_registration': _settings['enable_registration'] ?? true,
        'maintenance_mode': _settings['maintenance_mode'] ?? false,
      };

      final success = await _adminService.updateSystemSettings(updatedSettings);

      if (success) {
        setState(() => _settings = updatedSettings);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      } else {
        throw Exception('Failed to save settings');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _sendSystemNotification() async {
    if (_notificationTitleController.text.isEmpty ||
        _notificationMessageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both title and message')),
      );
      return;
    }

    try {
      final success = await _adminService.sendSystemNotification(
        title: _notificationTitleController.text,
        message: _notificationMessageController.text,
      );

      if (success) {
        _notificationTitleController.clear();
        _notificationMessageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sent to all users')),
        );
      } else {
        throw Exception('Failed to send notification');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending notification: ${e.toString()}')),
      );
    }
  }

  Future<void> _createSystemBackup() async {
    try {
      final backupUrl = await _adminService.backupSystemData();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup created: $backupUrl')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup failed: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSettings),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red.shade400),
                    const SizedBox(height: 16),
                    Text(_errorMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadSettings,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // General Settings
                    _buildSectionCard('General Settings', Icons.settings, [
                      _buildTextField('Application Name', _appNameController),
                      _buildTextField(
                        'Max Activities per User',
                        _maxActivitiesController,
                        isNumber: true,
                      ),
                      _buildSwitchTile(
                        'Enable User Registration',
                        _settings['enable_registration'] ?? true,
                        (value) => setState(
                          () => _settings['enable_registration'] = value,
                        ),
                      ),
                      _buildSwitchTile(
                        'Enable Notifications',
                        _settings['enable_notifications'] ?? true,
                        (value) => setState(
                          () => _settings['enable_notifications'] = value,
                        ),
                      ),
                    ]),

                    const SizedBox(height: 16),

                    // System Control
                    _buildSectionCard(
                      'System Control',
                      Icons.admin_panel_settings,
                      [
                        _buildSwitchTile(
                          'Maintenance Mode',
                          _settings['maintenance_mode'] ?? false,
                          (value) => setState(
                            () => _settings['maintenance_mode'] = value,
                          ),
                          subtitle: 'Prevents users from logging in',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isSaving ? null : _saveSettings,
                                icon:
                                    _isSaving
                                        ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Icon(Icons.save),
                                label: Text(
                                  _isSaving ? 'Saving...' : 'Save Settings',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _createSystemBackup,
                                icon: const Icon(Icons.backup),
                                label: const Text('Create Backup'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Notifications
                    _buildSectionCard(
                      'System Notifications',
                      Icons.notifications,
                      [
                        _buildTextField(
                          'Notification Title',
                          _notificationTitleController,
                        ),
                        _buildTextField(
                          'Notification Message',
                          _notificationMessageController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _sendSystemNotification,
                            icon: const Icon(Icons.send),
                            label: const Text('Send to All Users'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // System Info
                    _buildSectionCard('System Information', Icons.info, [
                      _buildInfoRow(
                        'Version',
                        _settings['app_version'] ?? '1.0.0',
                      ),
                      _buildInfoRow(
                        'Database',
                        _settings['database_type'] ?? 'MySQL',
                      ),
                      _buildInfoRow(
                        'Environment',
                        _settings['environment'] ?? 'Production',
                      ),
                      _buildInfoRow(
                        'Last Backup',
                        _settings['last_backup'] ?? 'Never',
                      ),
                      _buildInfoRow(
                        'Total Users',
                        '${_settings['total_users'] ?? 0}',
                      ),
                      _buildInfoRow(
                        'Total Activities',
                        '${_settings['total_activities'] ?? 0}',
                      ),
                    ]),
                  ],
                ),
              ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    String? subtitle,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: onChanged,
      activeColor: Colors.orange,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
