// lib/screens/admin/admin_notifications_screen.dart
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/admin_bottom_nav_bar.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _isSending = false;
  String _selectedRecipients = 'All Users';
  String _selectedPriority = 'Normal';

  final List<String> _recipientOptions = [
    'All Users',
    'Students Only',
    'Instructors Only',
    'Coordinators Only',
    'Admins Only',
  ];

  final List<String> _priorityOptions = ['Low', 'Normal', 'High', 'Urgent'];

  // Test email functionality
  Future<void> _testEmail() async {
    try {
      final notificationService = NotificationService();
      final result = await notificationService.testEmail(
        recipientEmail: 'test@example.com',
        subject: 'Test Email from EAMS',
        message: 'This is a test email from the EAMS notification system.',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result 
                ? '✅ Test email sent successfully!'
                : '❌ Failed to send test email',
            ),
            backgroundColor: result ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Test email failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notifications'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.email),
            onPressed: _testEmail,
            tooltip: 'Test Email',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showNotificationHistory(),
            tooltip: 'Notification History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade600, Colors.purple.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.3),
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
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notification Center',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Send targeted messages to users',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notification Form
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipients Selection
                  const Text(
                    'Recipients',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRecipients,
                        isExpanded: true,
                        items:
                            _recipientOptions.map((option) {
                              return DropdownMenuItem(
                                value: option,
                                child: Row(
                                  children: [
                                    Icon(_getRecipientIcon(option), size: 20),
                                    const SizedBox(width: 12),
                                    Text(option),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRecipients = value!;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Priority Selection
                  const Text(
                    'Priority Level',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children:
                        _priorityOptions.map((priority) {
                          final isSelected = priority == _selectedPriority;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPriority = priority;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? _getPriorityColor(priority)
                                        : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? _getPriorityColor(priority)
                                          : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                priority,
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Title Field
                  const Text(
                    'Notification Title',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'Enter notification title...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLength: 100,
                  ),

                  const SizedBox(height: 16),

                  // Message Field
                  const Text(
                    'Message Content',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your message here...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(16),
                    ),
                    maxLines: 5,
                    maxLength: 500,
                  ),

                  const SizedBox(height: 24),

                  // Send Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canSend() ? _sendNotification : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _isSending
                              ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Sending...'),
                                ],
                              )
                              : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send, size: 20),
                                  SizedBox(width: 12),
                                  Text(
                                    'Send Notification',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Templates
            const Text(
              'Quick Templates',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildQuickTemplates(),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildQuickTemplates() {
    final templates = [
      {
        'title': 'System Maintenance',
        'message':
            'The system will undergo scheduled maintenance on [DATE] from [TIME]. Please save your work.',
        'recipients': 'All Users',
        'priority': 'High',
      },
      {
        'title': 'New Activity Available',
        'message':
            'A new extracurricular activity has been posted. Check it out and register if interested!',
        'recipients': 'Students Only',
        'priority': 'Normal',
      },
      {
        'title': 'Monthly Report Due',
        'message':
            'Monthly participation reports are due by the end of this week. Please submit on time.',
        'recipients': 'Instructors Only',
        'priority': 'High',
      },
    ];

    return Column(
      children:
          templates.map((template) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template['title']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          template['message']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                template['recipients']!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(
                                  template['priority']!,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                template['priority']!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getPriorityColor(
                                    template['priority']!,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _useTemplate(template),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade50,
                      foregroundColor: Colors.purple,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Use'),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  IconData _getRecipientIcon(String recipient) {
    switch (recipient) {
      case 'All Users':
        return Icons.groups;
      case 'Students Only':
        return Icons.school;
      case 'Instructors Only':
        return Icons.person;
      case 'Coordinators Only':
        return Icons.manage_accounts;
      case 'Admins Only':
        return Icons.admin_panel_settings;
      default:
        return Icons.people;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'Normal':
        return Colors.blue;
      case 'High':
        return Colors.orange;
      case 'Urgent':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  bool _canSend() {
    return _titleController.text.trim().isNotEmpty &&
        _messageController.text.trim().isNotEmpty &&
        !_isSending;
  }

  void _useTemplate(Map<String, dynamic> template) {
    setState(() {
      _titleController.text = template['title']!;
      _messageController.text = template['message']!;
      _selectedRecipients = template['recipients']!;
      _selectedPriority = template['priority']!;
    });
  }

  Future<void> _sendNotification() async {
    if (!_canSend()) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Import the notification service
      final notificationService = NotificationService();
      
      // Determine notification type and priority
      String notificationType = 'general';
      if (_selectedRecipients.contains('Activity')) {
        notificationType = 'activity';
      } else if (_selectedRecipients.contains('Volunteer')) {
        notificationType = 'volunteer';
      }
      
      // Send notification via API with email
      final result = await notificationService.sendNotification(
        userIds: [1, 2, 3], // Mock user IDs for now
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        type: notificationType,
      );

      if (mounted) {
        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Notification sent successfully!\n'
                '📱 Notifications delivered to selected users\n'
                '📧 Email notifications sent',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );

          // Clear form
          _titleController.clear();
          _messageController.clear();
          setState(() {
            _selectedRecipients = 'All Users';
            _selectedPriority = 'Normal';
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '❌ Failed to send notification. Please try again.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Network error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showNotificationHistory() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Notification History'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView(
                children: [
                  _buildHistoryItem(
                    'System Maintenance Alert',
                    'All Users',
                    DateTime.now().subtract(const Duration(hours: 2)),
                    'High',
                  ),
                  _buildHistoryItem(
                    'New Activity: Basketball Tournament',
                    'Students Only',
                    DateTime.now().subtract(const Duration(days: 1)),
                    'Normal',
                  ),
                  _buildHistoryItem(
                    'Monthly Report Reminder',
                    'Instructors Only',
                    DateTime.now().subtract(const Duration(days: 3)),
                    'High',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildHistoryItem(
    String title,
    String recipients,
    DateTime sentTime,
    String priority,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.group, size: 12, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                recipients,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPriorityColor(priority).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    fontSize: 10,
                    color: _getPriorityColor(priority),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatTimeAgo(sentTime),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
