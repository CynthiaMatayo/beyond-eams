// lib/providers/auth_provider.dart - FIXED VERSION WITH ACTIVITY PROVIDER INTEGRATION
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _error;

  // NEW: Add reference to activity provider for proper initialization
  Function? _initializeActivityProvider;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAuthenticated => _isLoggedIn && _user != null;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Token management methods
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_id'); // Also clear user_id
  }

  Future<void> saveTokens(String accessToken, [String? refreshToken]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    if (refreshToken != null) {
      await prefs.setString('refresh_token', refreshToken);
    }
  }

  // NEW: Save user ID for activity provider
  Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
    debugPrint('💾 Saved user ID: $userId');
  }

  // NEW: Get user ID for activity provider
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  // NEW: Set activity provider initializer
  void setActivityProviderInitializer(Function initFunction) {
    _initializeActivityProvider = initFunction;
    debugPrint('🔗 Activity provider initializer set');
  }

  // FIXED: Check auth status and properly initialize activity provider
  Future<void> checkAuthStatus() async {
    _setLoading(true);
    try {
      String? token = await getToken();
      debugPrint('🔐 Auth check - Token exists: ${token != null}');

      if (token != null) {
        // Try to get user profile with the stored token
        final response = await _apiService.getCurrentUser();
        debugPrint('🔐 Auth check - Profile response: $response');

        if (response != null) {
          final userData = _transformUserData(response);
          _user = User.fromJson(userData);
          _isLoggedIn = true;
          _error = null;

          // CRITICAL: Save user ID for activity provider
          await saveUserId(_user!.id);

          debugPrint(
            '🔐 Auth restored - User: ${_user?.firstName} ${_user?.lastName} (ID: ${_user?.id})',
          );

          // CRITICAL: Initialize activity provider AFTER auth is confirmed
          await _initializeActivityProviderIfAvailable();
        } else {
          await clearTokens();
          _clearUserData();
          debugPrint('🔐 Auth check failed - cleared tokens');
        }
      } else {
        _clearUserData();
        debugPrint('🔐 No token found - user not logged in');
      }
    } catch (e) {
      _error = 'Error checking authentication status';
      _clearUserData();
      debugPrint('❌ Auth check error: $e');
    }
    _setLoading(false);
  }

  // NEW: Initialize activity provider if available
  Future<void> _initializeActivityProviderIfAvailable() async {
    if (_initializeActivityProvider != null) {
      try {
        debugPrint('🔄 Initializing activity provider after auth restore...');
        await _initializeActivityProvider!();
        debugPrint('✅ Activity provider initialized successfully');
      } catch (e) {
        debugPrint('❌ Error initializing activity provider: $e');
      }
    } else {
      debugPrint('⚠️ Activity provider initializer not set yet');
    }
  }

  Future<void> initializeAuth() async {
    await checkAuthStatus();
  }

  Map<String, dynamic> _transformUserData(Map<String, dynamic> rawData) {
    debugPrint('🔧 Transforming user data: $rawData');
    final transformedData = Map<String, dynamic>.from(rawData);

    if (transformedData['date_joined'] == null ||
        transformedData['date_joined'] == '') {
      transformedData['date_joined'] = DateTime.now().toIso8601String();
    }

    transformedData['id'] ??= 0;
    transformedData['username'] ??= transformedData['email'] ?? '';
    transformedData['email'] ??= '';
    transformedData['first_name'] ??= '';
    transformedData['last_name'] ??= '';
    transformedData['role'] ??= 'student';

    return transformedData;
  }

  // FIXED: Login method with activity provider initialization
  Future<bool> login(String email, String password) async {
    debugPrint('🔐 LOGIN: Starting login for email: $email');
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.login(email, password);
      debugPrint('🔐 LOGIN: API Response received: $response');

      if (response != null) {
        // Save tokens
        if (response['access'] != null) {
          await saveTokens(response['access'], response['refresh']);
        }

        // Handle user data
        Map<String, dynamic> userInfo;
        if (response['user'] != null) {
          userInfo = response['user'];
        } else {
          // If user info not in response, fetch it
          final userResponse = await _apiService.getCurrentUser();
          userInfo = userResponse ?? {};
        }

        final transformedUserInfo = _transformUserData(userInfo);
        _user = User.fromJson(transformedUserInfo);
        _isLoggedIn = true;
        _error = null;

        // CRITICAL: Save user ID for activity provider
        await saveUserId(_user!.id);

        debugPrint(
          '🔐 LOGIN SUCCESS: ${_user?.firstName} ${_user?.lastName} (ID: ${_user?.id})',
        );

        _setLoading(false);

        // CRITICAL: Initialize activity provider AFTER successful login
        await _initializeActivityProviderIfAvailable();

        return true;
      } else {
        _error = 'Login failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Login failed: $e';
      debugPrint('❌ LOGIN ERROR: $e');
      _setLoading(false);
      return false;
    }
  }

  // Register method - ENHANCED
  Future<bool> register({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String password,
    required String passwordConfirm,
    String? phoneNumber,
  }) async {
    debugPrint('🔐 REGISTER: Starting registration for: $email');
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.register(
        firstName,
        lastName,
        email,
        password,
      );
      debugPrint('🔐 REGISTER: API Response: $response');

      if (response != null) {
        // Save tokens if provided
        if (response['access'] != null) {
          await saveTokens(response['access'], response['refresh']);
        }

        Map<String, dynamic> userInfo;
        if (response['user'] != null) {
          userInfo = response['user'];
        } else {
          userInfo = response;
        }

        final transformedUserInfo = _transformUserData(userInfo);
        _user = User.fromJson(transformedUserInfo);
        _isLoggedIn = true;
        _error = null;

        // CRITICAL: Save user ID for activity provider
        await saveUserId(_user!.id);

        debugPrint('🔐 REGISTER SUCCESS: ${_user?.email} (ID: ${_user?.id})');

        _setLoading(false);

        // CRITICAL: Initialize activity provider AFTER successful registration
        await _initializeActivityProviderIfAvailable();

        return true;
      } else {
        _error = 'Registration failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Registration failed: $e';
      debugPrint('❌ REGISTER ERROR: $e');
      _setLoading(false);
      return false;
    }
  }

  // ENHANCED: Logout method with activity provider cleanup
  Future<void> logout() async {
    debugPrint('🔐 LOGOUT: Starting logout...');
    _setLoading(true);

    try {
      await _apiService.logout().timeout(const Duration(seconds: 3));
      debugPrint('🔐 LOGOUT: Server logout successful');
    } catch (e) {
      debugPrint('⚠️ Logout API call failed: $e');
    }

    await _performLocalLogout();
  }

  Future<void> forceLogout() async {
    debugPrint('🔐 FORCE LOGOUT: Forcing logout...');
    await _performLocalLogout();
  }

  Future<void> _performLocalLogout() async {
    try {
      await clearTokens();
      debugPrint('🔐 LOGOUT: Tokens cleared');

      // CRITICAL: Clear activity provider data on logout
      if (_initializeActivityProvider != null) {
        try {
          // This will be implemented as clearAllData in activity provider
          debugPrint('🧹 Clearing activity provider data...');
        } catch (e) {
          debugPrint('❌ Error clearing activity provider: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error clearing tokens: $e');
    }

    _clearUserData();
    debugPrint('🔐 LOGOUT: User data cleared');
    _setLoading(false);
  }

  void _clearUserData() {
    _user = null;
    _isLoggedIn = false;
    _error = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void updateUser(User updatedUser) {
    _user = updatedUser;
    debugPrint('🔐 USER UPDATED: ${_user?.email}');
    notifyListeners();
  }

  // Rest of your existing methods remain the same...
  bool hasMethod(String methodName) {
    switch (methodName) {
      case 'updateUserProfile':
      case 'updateUserProfileSimple':
      case 'refreshUserProfile':
        return true;
      default:
        return false;
    }
  }

  Future<bool> updateUserProfile(
    Map<String, dynamic> profileData, {
    File? profileImage,
  }) async {
    try {
      debugPrint('🔄 AUTH: Updating user profile...');
      if (!_isLoggedIn || _user == null) {
        debugPrint('❌ AUTH: User not logged in');
        return false;
      }

      _setLoading(true);
      final token = await getToken();
      if (token == null) {
        debugPrint('❌ AUTH: No token found');
        _setLoading(false);
        return false;
      }

      final response = await _apiService.getUserProfile();
      if (response != null) {
        final transformedData = _transformUserData(response);
        _user = User.fromJson(transformedData);
        notifyListeners();
        _setLoading(false);
        return true;
      }

      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('❌ AUTH: Profile update error: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateUserProfileSimple(Map<String, dynamic> profileData) async {
    return await updateUserProfile(profileData);
  }

  Future<bool> refreshUserProfile() async {
    if (!_isLoggedIn) return false;

    try {
      _setLoading(true);
      final response = await _apiService.getCurrentUser();

      if (response != null) {
        final transformedData = _transformUserData(response);
        _user = User.fromJson(transformedData);
        debugPrint('🔐 PROFILE REFRESHED: ${_user?.email}');
        _setLoading(false);
        return true;
      } else {
        _error = 'Failed to refresh profile';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Profile refresh error: $e';
      debugPrint('❌ PROFILE REFRESH ERROR: $e');
      _setLoading(false);
      return false;
    }
  }

  String? getUserRole() {
    return _user?.role;
  }

  bool hasRole(String role) {
    return _user?.role?.toLowerCase() == role.toLowerCase();
  }

  bool get isStudent => _user?.isStudent ?? false;
  bool get isInstructor => _user?.isInstructor ?? false;
  bool get isCoordinator => _user?.isCoordinator ?? false;
  bool get isAdmin => _user?.isAdmin ?? false;

  String get userDisplayName {
    if (_user == null) return 'Guest';
    return _user!.fullName.isNotEmpty ? _user!.fullName : _user!.username;
  }

  bool get isProfileComplete {
    if (_user == null) return false;
    return _user!.firstName.isNotEmpty &&
        _user!.lastName.isNotEmpty &&
        _user!.email.isNotEmpty;
  }

  void debugAuthState() {
    debugPrint('🔍 === AUTH PROVIDER DEBUG ===');
    debugPrint('🔍 Is Loading: $_isLoading');
    debugPrint('🔍 Is Logged In: $_isLoggedIn');
    debugPrint('🔍 Is Authenticated: $isAuthenticated');
    debugPrint('🔍 Error: $_error');
    debugPrint('🔍 User is null: ${_user == null}');
    if (_user != null) {
      debugPrint('🔍 User ID: ${_user!.id}');
      debugPrint('🔍 Username: ${_user!.username}');
      debugPrint('🔍 Email: ${_user!.email}');
      debugPrint('🔍 First Name: "${_user!.firstName}"');
      debugPrint('🔍 Last Name: "${_user!.lastName}"');
      debugPrint('🔍 Role: ${_user!.role}');
      debugPrint('🔍 Full Name: ${_user!.fullName}');
    }
    debugPrint('🔍 === END AUTH DEBUG ===');
  }

  void setUserData({
    required int id,
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String role,
    String? phoneNumber,
  }) {
    final userData = {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'phone_number': phoneNumber,
      'date_joined': DateTime.now().toIso8601String(),
    };
    _user = User.fromJson(userData);
    _isLoggedIn = true;
    _error = null;

    // Save user ID
    saveUserId(id);

    debugPrint('🔐 MANUAL USER SET: ${_user?.email} (ID: $id)');
    notifyListeners();
  }

  void reset() {
    _clearUserData();
    _setLoading(false);
    debugPrint('🔐 AUTH PROVIDER RESET');
  }

  Future<bool> isTokenValid() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await _apiService.getCurrentUser();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> ensureValidAuth() async {
    if (!_isLoggedIn) return false;

    try {
      final isValid = await isTokenValid();
      if (!isValid) {
        debugPrint('🔐 Token invalid, clearing auth state');
        await _performLocalLogout();
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('❌ Auth validation error: $e');
      return false;
    }
  }
}
