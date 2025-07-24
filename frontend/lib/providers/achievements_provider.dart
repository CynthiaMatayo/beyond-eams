// lib/providers/achievements_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AchievementsProvider with ChangeNotifier {
  final String baseUrl =
      'http://127.0.0.1:8000/'; 

  Map<String, dynamic>? _userAchievements;
  List<dynamic> _availableAchievements = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get userAchievements => _userAchievements;
  List<dynamic> get availableAchievements => _availableAchievements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalPoints => _userAchievements?['total_points'] ?? 0;
  int get currentLevel => _calculateLevel(totalPoints);
  int get pointsToNextLevel => _getPointsToNextLevel(currentLevel);

  // Calculate level based on points
  int _calculateLevel(int points) {
    if (points < 100) return 1;
    if (points < 300) return 2;
    if (points < 600) return 3;
    if (points < 1000) return 4;
    if (points < 1500) return 5;
    return 6; // Max level
  }

  // Get points needed for next level
  int _getPointsToNextLevel(int currentLevel) {
    final Map<int, int> levelThresholds = {
      1: 100,
      2: 300,
      3: 600,
      4: 1000,
      5: 1500,
      6: 2000, // Max level
    };

    if (currentLevel >= 6) return 0; // Max level reached
    return levelThresholds[currentLevel + 1]! - totalPoints;
  }

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      debugPrint('❌ ACHIEVEMENTS: Error getting token: $e');
      return null;
    }
  }

  // Fetch user achievements and points
  Future<void> fetchUserAchievements() async {
    _setLoading(true);
    _error = null;

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      debugPrint('🔄 ACHIEVEMENTS: Fetching user achievements...');

      final response = await http.get(
        Uri.parse('$baseUrl/api/achievements/points/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('🔄 ACHIEVEMENTS: Response status: ${response.statusCode}');
      debugPrint('🔄 ACHIEVEMENTS: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _userAchievements = data;

        // Cache the data locally
        await _cacheUserAchievements(data);

        debugPrint('✅ ACHIEVEMENTS: User achievements loaded successfully');
        debugPrint('📊 ACHIEVEMENTS: Total points: $totalPoints');
        debugPrint('📊 ACHIEVEMENTS: Current level: $currentLevel');
      } else {
        throw Exception('Failed to load achievements: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ ACHIEVEMENTS: Error fetching user achievements: $e');
      _error = e.toString();

      // Try to load from cache
      await _loadCachedAchievements();
    } finally {
      _setLoading(false);
    }
  }

  // Fetch available achievements
  Future<void> fetchAvailableAchievements() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      debugPrint('🔄 ACHIEVEMENTS: Fetching available achievements...');

      final response = await http.get(
        Uri.parse('$baseUrl/api/achievements/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _availableAchievements = data is List ? data : [];
        debugPrint(
          '✅ ACHIEVEMENTS: Available achievements loaded: ${_availableAchievements.length}',
        );
      } else {
        debugPrint(
          '❌ ACHIEVEMENTS: Failed to load available achievements: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ ACHIEVEMENTS: Error fetching available achievements: $e');
    }
  }

  // Initialize - fetch both user and available achievements
  Future<void> initialize() async {
    await Future.wait([fetchUserAchievements(), fetchAvailableAchievements()]);
  }

  // Refresh achievements (pull-to-refresh)
  Future<void> refreshAchievements() async {
    debugPrint('🔄 ACHIEVEMENTS: Refreshing achievements...');
    await initialize();
  }

  // Award points manually (for testing or admin use)
  Future<bool> awardPoints(int points, String reason) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/achievements/award/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'points': points, 'reason': reason}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ ACHIEVEMENTS: Points awarded successfully');
        await fetchUserAchievements(); // Refresh to get updated points
        return true;
      } else {
        debugPrint(
          '❌ ACHIEVEMENTS: Failed to award points: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ ACHIEVEMENTS: Error awarding points: $e');
      return false;
    }
  }

  // Cache user achievements locally
  Future<void> _cacheUserAchievements(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_achievements', json.encode(data));
      debugPrint('✅ ACHIEVEMENTS: User achievements cached');
    } catch (e) {
      debugPrint('❌ ACHIEVEMENTS: Error caching achievements: $e');
    }
  }

  // Load cached achievements
  Future<void> _loadCachedAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_achievements');

      if (cachedData != null) {
        _userAchievements = json.decode(cachedData);
        debugPrint('✅ ACHIEVEMENTS: Loaded cached achievements');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ ACHIEVEMENTS: Error loading cached achievements: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Get achievement progress for display
  List<Map<String, dynamic>> getAchievementProgress() {
    final List<Map<String, dynamic>> achievements = [];

    // Activity participation achievements
    final activitiesCount = _userAchievements?['activities_completed'] ?? 0;
    achievements.add({
      'title': 'Activity Participant',
      'description': 'Complete your first activity',
      'progress': activitiesCount,
      'target': 1,
      'icon': Icons.event,
      'color': Colors.blue,
      'unlocked': activitiesCount >= 1,
    });

    achievements.add({
      'title': 'Activity Enthusiast',
      'description': 'Complete 5 activities',
      'progress': activitiesCount,
      'target': 5,
      'icon': Icons.emoji_events,
      'color': Colors.orange,
      'unlocked': activitiesCount >= 5,
    });

    achievements.add({
      'title': 'Activity Champion',
      'description': 'Complete 20 activities',
      'progress': activitiesCount,
      'target': 20,
      'icon': Icons.star,
      'color': Colors.purple,
      'unlocked': activitiesCount >= 20,
    });

    // Volunteering achievements
    final volunteerHours = _userAchievements?['volunteer_hours'] ?? 0;
    achievements.add({
      'title': 'Helper',
      'description': 'Complete 5 volunteer hours',
      'progress': volunteerHours,
      'target': 5,
      'icon': Icons.volunteer_activism,
      'color': Colors.green,
      'unlocked': volunteerHours >= 5,
    });

    achievements.add({
      'title': 'Volunteer Hero',
      'description': 'Complete 25 volunteer hours',
      'progress': volunteerHours,
      'target': 25,
      'icon': Icons.favorite,
      'color': Colors.red,
      'unlocked': volunteerHours >= 25,
    });

    // Points-based achievements
    achievements.add({
      'title': 'Point Collector',
      'description': 'Earn 100 points',
      'progress': totalPoints,
      'target': 100,
      'icon': Icons.monetization_on,
      'color': Colors.amber,
      'unlocked': totalPoints >= 100,
    });

    achievements.add({
      'title': 'Point Master',
      'description': 'Earn 500 points',
      'progress': totalPoints,
      'target': 500,
      'icon': Icons.diamond,
      'color': Colors.indigo,
      'unlocked': totalPoints >= 500,
    });

    return achievements;
  }

  // Clear cached data (useful for logout)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_achievements');
      _userAchievements = null;
      _availableAchievements = [];
      _error = null;
      notifyListeners();
      debugPrint('✅ ACHIEVEMENTS: Cache cleared');
    } catch (e) {
      debugPrint('❌ ACHIEVEMENTS: Error clearing cache: $e');
    }
  }
}
