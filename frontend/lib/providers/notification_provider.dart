// lib/providers/notification_provider.dart 
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings {
  bool pushNotifications;
  bool emailNotifications;
  bool newOpportunities; // ✅ KEY FIELD FOR NEW ACTIVITIES
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

  NotificationSettings copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? newOpportunities,
    bool? activityReminders,
    bool? registrationConfirmations,
    bool? activityUpdates,
    bool? volunteerOpportunities,
    bool? volunteerApplicationStatus,
    bool? hoursVerification,
    bool? newAchievements,
    bool? pointsEarned,
  }) {
    return NotificationSettings(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      newOpportunities: newOpportunities ?? this.newOpportunities,
      activityReminders: activityReminders ?? this.activityReminders,
      registrationConfirmations:
          registrationConfirmations ?? this.registrationConfirmations,
      activityUpdates: activityUpdates ?? this.activityUpdates,
      volunteerOpportunities:
          volunteerOpportunities ?? this.volunteerOpportunities,
      volunteerApplicationStatus:
          volunteerApplicationStatus ?? this.volunteerApplicationStatus,
      hoursVerification: hoursVerification ?? this.hoursVerification,
      newAchievements: newAchievements ?? this.newAchievements,
      pointsEarned: pointsEarned ?? this.pointsEarned,
    );
  }
}

class NotificationProvider with ChangeNotifier {
  final String baseUrl =
      'http://your-backend-url.com'; // Replace with your actual URL

  NotificationSettings _settings = NotificationSettings();
  bool _isLoading = false;
  String? _error;

  // Getters
  NotificationSettings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      debugPrint('❌ NOTIFICATIONS: Error getting token: $e');
      return null;
    }
  }

  // Load notification settings from API
  Future<void> loadNotificationSettings() async {
    _setLoading(true);
    _error = null;

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      debugPrint('🔄 NOTIFICATIONS: Loading settings...');

      final response = await http.get(
        Uri.parse('$baseUrl/api/user/notification-settings/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('🔄 NOTIFICATIONS: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _settings = NotificationSettings.fromJson(data);

        // Cache settings locally
        await _cacheSettings();

        debugPrint('✅ NOTIFICATIONS: Settings loaded successfully');
      } else if (response.statusCode == 404) {
        // Settings don't exist yet, use defaults
        debugPrint('⚠️ NOTIFICATIONS: No settings found, using defaults');
        _settings = NotificationSettings();
      } else {
        throw Exception('Failed to load settings: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ NOTIFICATIONS: Error loading settings: $e');
      _error = e.toString();

      // Try to load from cache
      await _loadCachedSettings();
    } finally {
      _setLoading(false);
    }
  }

  // Save notification settings to API
  Future<void> saveNotificationSettings() async {
    _setLoading(true);
    _error = null;

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      debugPrint('🔄 NOTIFICATIONS: Saving settings...');

      final response = await http.put(
        Uri.parse('$baseUrl/api/user/notification-settings/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(_settings.toJson()),
      );

      debugPrint(
        '🔄 NOTIFICATIONS: Save response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Cache settings locally
        await _cacheSettings();
        debugPrint('✅ NOTIFICATIONS: Settings saved successfully');
      } else {
        throw Exception('Failed to save settings: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ NOTIFICATIONS: Error saving settings: $e');
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Individual setting update methods
  void updatePushNotifications(bool value) {
    _settings = _settings.copyWith(pushNotifications: value);
    notifyListeners();
    _autoSaveSettings();
  }

  void updateEmailNotifications(bool value) {
    _settings = _settings.copyWith(emailNotifications: value);
    notifyListeners();
    _autoSaveSettings();
  }

  void updateNewOpportunities(bool value) {
    debugPrint('🔄 NOTIFICATIONS: Updating new opportunities: $value');
    _settings = _settings.copyWith(newOpportunities: value);
    notifyListeners();
    _autoSaveSettings();
  }

  void updateActivityReminders(bool value) {
    _settings = _settings.copyWith(activityReminders: value);
    notifyListeners();
    _autoSaveSettings();
  }

  void updateRegistrationConfirmations(bool value) {
    _settings = _settings.copyWith(registrationConfirmations: value);
    notifyListeners();
    _autoSaveSettings();
  }

  void updateActivityUpdates(bool value) {
    _settings = _settings.copyWith(activityUpdates: value);
    notifyListeners();
    _autoSaveSettings();
  }

  void updateVolunteerOpportunities(bool value) {
    _settings = _settings.copyWith(volunteerOpportunities: value);
    notifyListeners();
    _autoSaveSettings();
  }

  void updateVolunteerApplicationStatus(bool value) {
    _settings = _settings.copyWith(volunteerApplicationStatus: value);
    notifyListeners();
    _autoSaveSettings();
  }

  void updateHoursVerification(bool value) {
    _settings = _settings.copyWith(hoursVerification: value);
    notifyListeners();
    _autoSaveSettings();
  }

  void updateNewAchievements(bool value) {
    _settings = _settings.copyWith(newAchievements: value);
    notifyListeners();
    _autoSaveSettings();
  }

  void updatePointsEarned(bool value) {
    _settings = _settings.copyWith(pointsEarned: value);
    notifyListeners();
    _autoSaveSettings();
  }

  // Auto-save settings after a delay (debounced)
  void _autoSaveSettings() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isLoading) {
        _cacheSettings();
      }
    });
  }

  // Cache settings locally
  Future<void> _cacheSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'notification_settings',
        json.encode(_settings.toJson()),
      );
      debugPrint('✅ NOTIFICATIONS: Settings cached locally');
    } catch (e) {
      debugPrint('❌ NOTIFICATIONS: Error caching settings: $e');
    }
  }

  // Load cached settings
  Future<void> _loadCachedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('notification_settings');

      if (cachedData != null) {
        final data = json.decode(cachedData);
        _settings = NotificationSettings.fromJson(data);
        debugPrint('✅ NOTIFICATIONS: Loaded cached settings');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ NOTIFICATIONS: Error loading cached settings: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear cached data (useful for logout)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('notification_settings');
      _settings = NotificationSettings();
      _error = null;
      notifyListeners();
      debugPrint('✅ NOTIFICATIONS: Cache cleared');
    } catch (e) {
      debugPrint('❌ NOTIFICATIONS: Error clearing cache: $e');
    }
  }

  // Check if new opportunities notifications are enabled
  bool get shouldNotifyNewOpportunities =>
      _settings.newOpportunities && _settings.pushNotifications;
}
