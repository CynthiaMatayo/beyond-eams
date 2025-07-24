// lib/screens/splash_screen.dart - UPDATED WITH NEW COLOR SCHEME
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/activity_provider.dart' as ActivityProviders;
import '../providers/volunteer_provider.dart' as VolunteerProviders;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loadingController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  // Color constants
  static const Color _primaryColor = Color(0xFF3F51B5);
  static const Color _secondaryColor = Color(0xFF333F89);
  static const Color _backgroundColor = Color(0xFFFAFCFD);
  static const Color _accentColor = Color(0xFF404FB8);
  static const Color _lightColor = Color(0xFF8B95CA);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Initialize animation controllers
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Logo animations
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    // Text animations
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  void _startAnimations() async {
    debugPrint('🟦 SPLASH: Starting animations...');

    // Start logo animation
    await _logoController.forward();
    debugPrint('🟦 SPLASH: Logo animation completed');

    // Start text animation
    await _textController.forward();
    debugPrint('🟦 SPLASH: Text animation completed');

    // Start loading animation
    _loadingController.repeat();
    debugPrint('🟦 SPLASH: Loading animation started');

    // CRITICAL FIX: Initialize app with proper timing
    final stopwatch = Stopwatch()..start();

    // Perform complete app initialization
    final isAuthenticated = await _performCompleteInitialization();

    // Ensure minimum splash duration (3 seconds)
    const minSplashDuration = Duration(seconds: 3);
    final elapsed = stopwatch.elapsed;
    if (elapsed < minSplashDuration) {
      debugPrint(
        '🟦 SPLASH: Waiting additional ${minSplashDuration - elapsed} for minimum display time',
      );
      await Future.delayed(minSplashDuration - elapsed);
    }

    debugPrint('🟦 SPLASH: Total splash time: ${stopwatch.elapsed}');

    // Navigate based on auth result
    if (mounted) {
      _navigateBasedOnAuth(isAuthenticated);
    }
  }

  // UPDATED: Complete initialization including providers
  Future<bool> _performCompleteInitialization() async {
    try {
      debugPrint('🟦 SPLASH: Starting complete app initialization...');

      // Get providers
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final activityProvider = Provider.of<ActivityProviders.ActivityProvider>(
        context,
        listen: false,
      );
      final volunteerProvider =
          Provider.of<VolunteerProviders.VolunteerProvider>(
            context,
            listen: false,
          );

      // Step 1: Initialize authentication FIRST
      debugPrint('🔐 SPLASH: Initializing authentication...');
      await authProvider.checkAuthStatus();
      final isLoggedIn = authProvider.isLoggedIn && authProvider.user != null;
      debugPrint('🔐 SPLASH: Auth result - Logged in: $isLoggedIn');

      if (authProvider.user != null) {
        debugPrint(
          '👤 SPLASH: User found - ${authProvider.user!.email} (${authProvider.user!.role})',
        );
      }

      // Step 2: Initialize other providers if user is logged in
      if (isLoggedIn) {
        debugPrint(
          '🔄 SPLASH: User authenticated, initializing data providers...',
        );
        try {
          // Initialize activity provider
          debugPrint('📱 SPLASH: Initializing activity provider...');
          await activityProvider.initialize();
          debugPrint('✅ SPLASH: Activity provider initialized');

          // Initialize volunteer provider
          debugPrint('🤝 SPLASH: Initializing volunteer provider...');
          await volunteerProvider.initialize();
          debugPrint('✅ SPLASH: Volunteer provider initialized');
        } catch (providerError) {
          debugPrint(
            '⚠️ SPLASH: Provider initialization error: $providerError',
          );
          // Continue even if providers fail to initialize
        }
      } else {
        debugPrint(
          '❌ SPLASH: User not authenticated, skipping provider initialization',
        );
      }

      debugPrint('✅ SPLASH: Complete initialization finished');
      return isLoggedIn;
    } catch (e) {
      debugPrint('❌ SPLASH: Complete initialization failed: $e');
      return false;
    }
  }

  void _navigateBasedOnAuth(bool isAuthenticated) {
    if (!mounted) return;

    debugPrint('🟦 SPLASH: Navigating based on auth: $isAuthenticated');

    if (isAuthenticated) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user != null) {
        debugPrint(
          '🟦 SPLASH: User found, navigating to role-based dashboard: ${user.role}',
        );
        // Navigate to appropriate dashboard based on role
        switch (user.role.toLowerCase()) {
          case 'student':
            debugPrint('🟦 SPLASH: Navigating to student dashboard');
            Navigator.pushReplacementNamed(context, '/student-dashboard');
            break;
          case 'instructor':
            debugPrint('🟦 SPLASH: Navigating to instructor dashboard');
            Navigator.pushReplacementNamed(context, '/instructor-dashboard');
            break;
          case 'coordinator':
            debugPrint('🟦 SPLASH: Navigating to coordinator dashboard');
            Navigator.pushReplacementNamed(context, '/coordinator-dashboard');
            break;
          case 'admin':
            debugPrint('🟦 SPLASH: Navigating to admin dashboard');
            Navigator.pushReplacementNamed(context, '/admin-dashboard');
            break;
          default:
            debugPrint(
              '🟦 SPLASH: Unknown role, defaulting to student dashboard',
            );
            Navigator.pushReplacementNamed(context, '/student-dashboard');
        }
      } else {
        // Fallback to login if user data is missing
        debugPrint(
          '🟦 SPLASH: Auth says logged in but no user data, going to login',
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      // User not authenticated, go to login
      debugPrint('🟦 SPLASH: Not authenticated, navigating to login');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _primaryColor, // #3f51b5
              _secondaryColor, // #333f89
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo Section
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScale.value,
                    child: Opacity(
                      opacity: _logoOpacity.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: _backgroundColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 60,
                          color: _accentColor,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Text Section
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: Column(
                        children: [
                          const Text(
                            'Beyond Activities',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Discover, Engage, Excel',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const Spacer(flex: 2),

              // Loading Indicator with Status Text
              Column(
                children: [
                  AnimatedBuilder(
                    animation: _loadingController,
                    builder: (context, child) {
                      return RotationTransition(
                        turns: _loadingController,
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            backgroundColor: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Initializing your data...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
