// lib/screens/settings/notifications_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotificationSettings();
    });
  }

  Future<void> _loadNotificationSettings() async {
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    await notificationProvider.loadNotificationSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.indigo,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.indigo),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // General Notifications Card
                _buildNotificationCard(
                  title: 'General Notifications',
                  icon: Icons.notifications,
                  children: [
                    _buildSwitchTile(
                      title: 'Push Notifications',
                      subtitle: 'Enable push notifications for all alerts',
                      value: notificationProvider.settings.pushNotifications,
                      onChanged: (value) {
                        notificationProvider.updatePushNotifications(value);
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Email Notifications',
                      subtitle: 'Receive notifications via email',
                      value: notificationProvider.settings.emailNotifications,
                      onChanged: (value) {
                        notificationProvider.updateEmailNotifications(value);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Activities Card
                _buildNotificationCard(
                  title: 'Activities',
                  icon: Icons.event,
                  children: [
                    _buildSwitchTile(
                      title: 'New Opportunities',
                      subtitle:
                          'Get notified when new activities are available',
                      value: notificationProvider.settings.newOpportunities,
                      onChanged: (value) {
                        notificationProvider.updateNewOpportunities(value);
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Activity Reminders',
                      subtitle: 'Reminders for upcoming enrolled activities',
                      value: notificationProvider.settings.activityReminders,
                      onChanged: (value) {
                        notificationProvider.updateActivityReminders(value);
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Registration Confirmations',
                      subtitle:
                          'Confirm when you successfully register for activities',
                      value:
                          notificationProvider
                              .settings
                              .registrationConfirmations,
                      onChanged: (value) {
                        notificationProvider.updateRegistrationConfirmations(
                          value,
                        );
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Activity Updates',
                      subtitle: 'Changes to enrolled activity details',
                      value: notificationProvider.settings.activityUpdates,
                      onChanged: (value) {
                        notificationProvider.updateActivityUpdates(value);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Volunteering Card
                _buildNotificationCard(
                  title: 'Volunteering',
                  icon: Icons.volunteer_activism,
                  children: [
                    _buildSwitchTile(
                      title: 'Volunteer Opportunities',
                      subtitle: 'New volunteer positions available',
                      value:
                          notificationProvider.settings.volunteerOpportunities,
                      onChanged: (value) {
                        notificationProvider.updateVolunteerOpportunities(
                          value,
                        );
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Volunteer Application Status',
                      subtitle: 'Updates on your volunteer applications',
                      value:
                          notificationProvider
                              .settings
                              .volunteerApplicationStatus,
                      onChanged: (value) {
                        notificationProvider.updateVolunteerApplicationStatus(
                          value,
                        );
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Hours Verification',
                      subtitle: 'When your volunteer hours are verified',
                      value: notificationProvider.settings.hoursVerification,
                      onChanged: (value) {
                        notificationProvider.updateHoursVerification(value);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Achievements Card
                _buildNotificationCard(
                  title: 'Achievements',
                  icon: Icons.emoji_events,
                  children: [
                    _buildSwitchTile(
                      title: 'New Achievements',
                      subtitle: 'When you unlock new achievements',
                      value: notificationProvider.settings.newAchievements,
                      onChanged: (value) {
                        notificationProvider.updateNewAchievements(value);
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Points Earned',
                      subtitle: 'When you earn points for activities',
                      value: notificationProvider.settings.pointsEarned,
                      onChanged: (value) {
                        notificationProvider.updatePointsEarned(value);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        notificationProvider.isLoading
                            ? null
                            : () async {
                              await notificationProvider
                                  .saveNotificationSettings();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Notification settings saved!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        notificationProvider.isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'Save Settings',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.indigo, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.indigo,
            activeTrackColor: Colors.indigo.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

// lib/models/notification_settings.dart
class NotificationSettings {
  bool pushNotifications;
  bool emailNotifications;
  bool newOpportunities; // ✅ THIS IS THE KEY FIELD YOU NEED
  bool activityReminders;
  bool registrationConfirmations;
  bool activityUpdates;
  bool volunteerOpportunities;
  bool volunteerApplicationStatus;
  bool hoursVerification;
  bool newAchievements;
  bool pointsEarned;

  NotificationSettings({
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.newOpportunities = true, // ✅ DEFAULT TO TRUE
    this.activityReminders = true,
    this.registrationConfirmations = true,
    this.activityUpdates = true,
    this.volunteerOpportunities = true,
    this.volunteerApplicationStatus = true,
    this.hoursVerification = true,
    this.newAchievements = true,
    this.pointsEarned = true,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushNotifications: json['push_notifications'] ?? true,
      emailNotifications: json['email_notifications'] ?? true,
      newOpportunities: json['new_opportunities'] ?? true, // ✅ PARSE FROM API
      activityReminders: json['activity_reminders'] ?? true,
      registrationConfirmations: json['registration_confirmations'] ?? true,
      activityUpdates: json['activity_updates'] ?? true,
      volunteerOpportunities: json['volunteer_opportunities'] ?? true,
      volunteerApplicationStatus: json['volunteer_application_status'] ?? true,
      hoursVerification: json['hours_verification'] ?? true,
      newAchievements: json['new_achievements'] ?? true,
      pointsEarned: json['points_earned'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'push_notifications': pushNotifications,
      'email_notifications': emailNotifications,
      'new_opportunities': newOpportunities, // ✅ SEND TO API
      'activity_reminders': activityReminders,
      'registration_confirmations': registrationConfirmations,
      'activity_updates': activityUpdates,
      'volunteer_opportunities': volunteerOpportunities,
      'volunteer_application_status': volunteerApplicationStatus,
      'hours_verification': hoursVerification,
      'new_achievements': newAchievements,
      'points_earned': pointsEarned,
    };
  }
}
