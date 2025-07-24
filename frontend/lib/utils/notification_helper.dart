// lib/utils/notification_helper.dart - FIXED VERSION
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize notifications
  static Future<void> initialize() async {
    try {
      // Initialize timezone
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
        },
      );
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  // Show notification for new opportunity
  static Future<void> showNewOpportunityNotification({
    required String title,
    required String body,
    required int activityId,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'new_opportunities',
          'New Opportunities',
          channelDescription: 'Notifications for new activity opportunities',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _notificationsPlugin.show(
      activityId, // Use activity ID as notification ID
      title,
      body,
      notificationDetails,
    );
  }

  // ✅ FIXED: Show notification for activity reminder (Fixed TZDateTime issue)
  static Future<void> showActivityReminderNotification({
    required String title,
    required String body,
    required int activityId,
    DateTime? scheduledDate,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'activity_reminders',
          'Activity Reminders',
          channelDescription: 'Reminders for upcoming activities',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    if (scheduledDate != null) {
      // ✅ FIXED: Convert DateTime to TZDateTime properly
      final tz.TZDateTime scheduledTZDateTime = tz.TZDateTime.from(
        scheduledDate,
        tz.local,
      );

      // ✅ FIXED: Use new androidScheduleMode parameter instead of deprecated androidAllowWhileIdle
      await _notificationsPlugin.zonedSchedule(
        activityId + 1000, // Offset for reminder notifications
        title,
        body,
        scheduledTZDateTime,
        notificationDetails,
        androidScheduleMode:
            AndroidScheduleMode.exactAllowWhileIdle, // ✅ NEW PARAMETER
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else {
      // Show immediately
      await _notificationsPlugin.show(
        activityId + 1000,
        title,
        body,
        notificationDetails,
      );
    }
  }

  // Show notification for registration confirmation
  static Future<void> showRegistrationConfirmationNotification({
    required String activityTitle,
    required int activityId,
  }) async {
    await showNotification(
      id: activityId + 2000,
      title: 'Registration Confirmed',
      body: 'You have successfully registered for "$activityTitle"',
      channelId: 'registration_confirmations',
      channelName: 'Registration Confirmations',
      channelDescription: 'Confirmations for activity registrations',
    );
  }

  // Show notification for achievement unlocked
  static Future<void> showAchievementNotification({
    required String achievementTitle,
    required String description,
    required int achievementId,
  }) async {
    await showNotification(
      id: achievementId + 3000,
      title: 'Achievement Unlocked! 🏆',
      body: '$achievementTitle - $description',
      channelId: 'achievements',
      channelName: 'Achievements',
      channelDescription: 'Notifications for unlocked achievements',
    );
  }

  // Show notification for points earned
  static Future<void> showPointsEarnedNotification({
    required int points,
    required String reason,
    required int activityId,
  }) async {
    await showNotification(
      id: activityId + 4000,
      title: 'Points Earned! ⭐',
      body: 'You earned $points points for $reason',
      channelId: 'points_earned',
      channelName: 'Points Earned',
      channelDescription: 'Notifications for points earned',
    );
  }

  // Generic show notification method
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) async {
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _notificationsPlugin.show(id, title, body, notificationDetails);
  }

  // Cancel notification
  static Future<void> cancelNotification(int notificationId) async {
    await _notificationsPlugin.cancel(notificationId);
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // ✅ FIXED: Schedule daily reminder (corrected importance enum)
  static Future<void> scheduleDailyReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    // ✅ FIXED: Changed Importance.medium to Importance.defaultImportance
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'daily_reminders',
          'Daily Reminders',
          channelDescription: 'Daily reminder notifications',
          importance:
              Importance
                  .defaultImportance, // ✅ FIXED: This is the correct enum value
          priority: Priority.defaultPriority,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);

    await _notificationsPlugin.zonedSchedule(
      0, // Use 0 for daily reminder
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
  }

  // Helper method to get next instance of specific time
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Request notification permissions (for Android 13+)
  static Future<bool> requestPermissions() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        final bool? granted =
            await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }

      return true; // Assume granted for older Android versions
    } catch (e) {
      print('Error requesting notification permissions: $e');
      return false;
    }
  }

  // Show notification with custom channel settings
  static Future<void> showCustomNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    String? channelDescription,
    Importance importance =
        Importance.defaultImportance, // ✅ FIXED: Use correct default
    Priority priority = Priority.defaultPriority,
    String? icon,
  }) async {
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription ?? 'Notifications',
          importance: importance,
          priority: priority,
          icon: icon ?? '@mipmap/ic_launcher',
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _notificationsPlugin.show(id, title, body, notificationDetails);
  }

  // Show big text notification
  static Future<void> showBigTextNotification({
    required int id,
    required String title,
    required String body,
    required String bigText,
    String channelId = 'big_text',
    String channelName = 'Big Text Notifications',
  }) async {
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Notifications with expanded text',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(
            bigText,
            contentTitle: title,
            summaryText: 'Tap to expand',
          ),
          icon: '@mipmap/ic_launcher',
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _notificationsPlugin.show(id, title, body, notificationDetails);
  }

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        return await androidImplementation.areNotificationsEnabled() ?? false;
      }

      return true; // Assume enabled for other platforms
    } catch (e) {
      print('Error checking notification status: $e');
      return false;
    }
  }
}
