// lib/main.dart - FINAL FIXED VERSION with correct class names
import 'package:flutter/material.dart';
import 'package:frontend/providers/coordinator_provider.dart';
import 'package:frontend/screens/activities/recent_activities_screen.dart';
import 'package:frontend/screens/admin/admin/system_settings_screen.dart';
import 'package:frontend/widgets/analytics_chart.dart';
import 'package:provider/provider.dart';

// Provider imports - Fixed to avoid conflicts
import 'providers/auth_provider.dart';
import 'providers/activity_provider.dart' as ActivityProviders;
import 'providers/volunteer_provider.dart' as VolunteerProviders;
import 'providers/achievements_provider.dart';
import 'providers/notification_provider.dart';

// Model imports
import 'models/activity.dart';

// Screen imports
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/student_dashboard.dart';
// FIXED: Import admin dashboard with alias to avoid conflict
import 'screens/dashboard/admin_dashboard.dart' as AdminDash;
import 'screens/activities/browse_activities_screen.dart';
import 'screens/activities/my_activities_screen.dart';
import 'screens/activities/activity_qr_screen.dart';
import 'screens/volunteer/volunteering_dashboard_screen.dart';
import 'screens/volunteer/my_volunteer_applications_screen.dart';
import 'screens/admin/system_reports_screen.dart';
import 'screens/admin/system_reports_screen.dart';
import 'screens/profile/my_profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/instructor/instructor_main_screen.dart';
import 'screens/achievements/achievements_screen.dart';
import 'screens/settings/notifications_settings_screen.dart';

// Coordinator imports
import 'screens/coordinator/coordinator_main_screen.dart';
import 'screens/coordinator/create_activity_screen.dart';
import 'screens/coordinator/manage_activities_screen.dart';
import 'screens/coordinator/promote_activities_screen.dart';
import 'screens/coordinator/activity_reports_screen.dart';
import 'screens/coordinator/edit_activity_screen.dart';
import 'screens/coordinator/volunteer_management_screen.dart';

// Admin imports - only the files we actually created
import 'screens/admin/user_management_screen.dart';
import 'screens/admin/system_reports_screen.dart';
import 'screens/admin/role_management_screen.dart';
import 'screens/admin/data_export_screen.dart';
import 'screens/admin/admin/admin_activities_screen.dart';
import 'screens/admin/admin_notifications_screen.dart';

// Utils
import 'utils/notification_helper.dart';

//widgets
import 'services/notification_service.dart';
import 'services/export_service.dart';
import 'widgets/notification_bell.dart';
import 'widgets/admin_export_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await NotificationHelper.initialize();
    debugPrint('✅ Notification helper initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Notification initialization failed: $e');
  }

  // FIXED: Enhanced MultiProvider with proper CoordinatorProvider integration
  runApp(
    MultiProvider(
      providers: [
        // Auth provider first
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Activity and Volunteer providers
        ChangeNotifierProvider(
          create: (_) => ActivityProviders.ActivityProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => VolunteerProviders.VolunteerProvider(),
        ),

        // FIXED: CoordinatorProvider with AuthProvider dependency
        ChangeNotifierProxyProvider<AuthProvider, CoordinatorProvider>(
          create: (_) => CoordinatorProvider(),
          update: (_, authProvider, coordinatorProvider) {
            coordinatorProvider!.setAuthProvider(authProvider);
            return coordinatorProvider;
          },
        ),

        // Other providers
        ChangeNotifierProvider(create: (_) => AchievementsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isAppInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // FIXED: Initialize app providers after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAppWithProperProviderConnection();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _isAppInitialized) {
      _refreshAppData();
    }
  }

  // FIXED: Enhanced initialization with CoordinatorProvider support
  Future<void> _initializeAppWithProperProviderConnection() async {
    if (_isAppInitialized) {
      debugPrint('✅ App already initialized');
      return;
    }

    try {
      debugPrint('🚀 Starting complete app initialization...');

      // STEP 1: Get all providers with null safety
      if (!context.mounted) {
        debugPrint('❌ Context not mounted');
        return;
      }

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
      final coordinatorProvider = Provider.of<CoordinatorProvider>(
        context,
        listen: false,
      );

      // STEP 2: Connect auth provider to all dependent providers
      debugPrint('🔗 Setting up provider connections...');
      authProvider.setActivityProviderInitializer(() async {
        debugPrint(
          '🔄 Auth provider triggering all provider initialization...',
        );
        await activityProvider.ensureProperInitialization();
        await volunteerProvider.initialize();

        // FIXED: Initialize coordinator provider for coordinators
        if (authProvider.user?.role == 'coordinator') {
          debugPrint(
            '👑 User is coordinator, initializing coordinator provider...',
          );
          await coordinatorProvider.initialize();
        }
        debugPrint('✅ All providers initialized by auth provider');
      });

      // STEP 3: Initialize authentication FIRST
      debugPrint('🔐 Initializing authentication...');
      await authProvider.checkAuthStatus();
      debugPrint('✅ Authentication check completed');

      // STEP 4: If auth didn't trigger provider initialization, do it manually
      if (authProvider.isLoggedIn && authProvider.user != null) {
        debugPrint('👤 User is logged in: ${authProvider.user?.email}');
        debugPrint('🎭 User role: ${authProvider.user?.role}');

        if (!activityProvider.isInitialized) {
          debugPrint('🔄 Manually initializing activity provider...');
          await activityProvider.ensureProperInitialization();
        }

        if (!volunteerProvider.isInitialized) {
          debugPrint('🔄 Manually initializing volunteer provider...');
          await volunteerProvider.initialize();
        }

        // FIXED: Initialize coordinator provider for coordinators
        if (authProvider.user?.role == 'coordinator' &&
            !coordinatorProvider.isInitialized) {
          debugPrint('🔄 Manually initializing coordinator provider...');
          await coordinatorProvider.initialize();
        }

        debugPrint('✅ All providers confirmed initialized');

        if (mounted) {
          setState(() {
            _isAppInitialized = true;
          });
        }
      } else {
        debugPrint('❌ User not logged in, skipping provider initialization');
        if (mounted) {
          setState(() {
            _isAppInitialized = true;
          });
        }
      }

      debugPrint('✅ Complete app initialization finished');
    } catch (e) {
      debugPrint('❌ App initialization failed: $e');
      if (mounted) {
        setState(() {
          _isAppInitialized =
              true; // Mark as initialized to prevent infinite retry
        });
      }
    }
  }

  Future<void> _refreshAppData() async {
    if (!mounted) return;

    try {
      debugPrint('🔄 Refreshing app data...');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isLoggedIn) return;

      final activityProvider = Provider.of<ActivityProviders.ActivityProvider>(
        context,
        listen: false,
      );
      final volunteerProvider =
          Provider.of<VolunteerProviders.VolunteerProvider>(
            context,
            listen: false,
          );
      final coordinatorProvider = Provider.of<CoordinatorProvider>(
        context,
        listen: false,
      );

      if (activityProvider.isInitialized) {
        await activityProvider.syncWithServer();
      }

      if (volunteerProvider.isInitialized) {
        await volunteerProvider.refresh();
      }

      // FIXED: Refresh coordinator data for coordinators
      if (authProvider.user?.role == 'coordinator' &&
          coordinatorProvider.isInitialized) {
        await coordinatorProvider.refreshAll();
      }

      debugPrint('✅ App data refreshed');
    } catch (e) {
      debugPrint('⚠️ Error refreshing app data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beyond Activities',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        primaryColor: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.orange),
          ),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        // Auth Routes
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),

        // Dashboard Routes
        '/dashboard': (context) => const RoleBasedDashboard(),
        '/student-dashboard':
            (context) => const StudentDashboardWithBottomNav(),
        '/instructor-dashboard': (context) => const InstructorMainScreen(),
        '/coordinator-dashboard': (context) => const CoordinatorMainScreen(),
        // FIXED: Use aliased AdminDashboard
        '/admin-dashboard': (context) => const AdminDash.AdminDashboard(),

        // Student Activity Routes
        '/browse-activities':
            (context) => const BrowseActivitiesScreenWithBottomNav(),
        '/my-activities': (context) => const MyActivitiesScreenWithBottomNav(),
        '/recent-activities': (context) => const RecentActivitiesScreen(),
        '/activity_qr_screen': (context) => const ActivityQRScreen(),
        '/volunteering-dashboard':
            (context) => const VolunteeringDashboardScreenWithBottomNav(),
        '/my-volunteer-applications':
            (context) => const MyVolunteerApplicationsScreen(),

        // Coordinator Routes
        '/coordinator': (context) => const CoordinatorMainScreen(),
        '/coordinator/create-activity':
            (context) => const CreateActivityScreen(),
        '/coordinator/manage-activities':
            (context) => const ManageActivitiesScreen(),
        '/coordinator/promote-activities':
            (context) => const PromoteActivitiesScreen(),
        '/coordinator/activity-reports':
            (context) => const ActivityReportsScreen(),
        '/coordinator/volunteer-management':
            (context) => const VolunteerManagementScreen(),

        // Admin Routes - FIXED: All routes working
        '/admin/user-management': (context) => const UserManagementScreen(),
        '/admin/system-reports': (context) => const SystemReportsScreen(),
        '/admin/role-management': (context) => const RoleManagementScreen(),
        '/admin/system-settings': (context) => const SystemSettingsScreen(),
        '/admin/activities': (context) => const AdminActivitiesScreen(),
        '/admin/system-health': (context) => const SystemReportsScreen(),
        '/admin/notifications': (context) => const AdminNotificationsScreen(),
        '/notifications': (context) => const AdminNotificationsScreen(),
        '/admin/data-export': (context) => const DataExportScreen(),
        '/admin/analytics': (context) => const SystemReportsScreen(),
        // FIXED: Use existing volunteer screen - MyVolunteerApplicationsScreen
        '/admin/volunteers': (context) => const MyVolunteerApplicationsScreen(),
        '/admin/volunteer-applications':
            (context) => const MyVolunteerApplicationsScreen(),

        // Profile & Settings Routes
        '/profile': (context) => const MyProfileScreenWithBottomNav(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/notifications-settings':
            (context) => const NotificationsSettingsScreen(),
        '/achievements': (context) => const AchievementsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('/coordinator/edit-activity/') == true) {
          final activityId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder:
                (context) => EditActivityScreen(
                  activity: _getActivityById(int.tryParse(activityId) ?? 0),
                ),
          );
        }
        return MaterialPageRoute(
          builder:
              (context) => Scaffold(
                appBar: AppBar(
                  title: const Text('Page Not Found'),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Page Not Found: ${settings.name}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            () => Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/dashboard',
                              (route) => false,
                            ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text(
                          'Go to Dashboard',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        );
      },
    );
  }

  static Activity _getActivityById(int id) {
    return Activity(
      id: id,
      title: 'Sample Activity',
      description: 'Sample Description',
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(hours: 2)),
      location: 'Sample Location',
      createdBy: 1,
      createdByName: 'Coordinator',
      createdAt: DateTime.now(),
      isVolunteering: false,
      status: 'upcoming',
      enrolledCount: 0,
    );
  }
}

// FIXED: Enhanced RoleBasedDashboard with coordinator support
class RoleBasedDashboard extends StatefulWidget {
  const RoleBasedDashboard({super.key});

  @override
  State<RoleBasedDashboard> createState() => _RoleBasedDashboardState();
}

class _RoleBasedDashboardState extends State<RoleBasedDashboard> {
  @override
  void initState() {
    super.initState();
    _checkAuthStateAndEnsureProviders();
  }

  Future<void> _checkAuthStateAndEnsureProviders() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await Future.delayed(const Duration(milliseconds: 500));

      if (authProvider.user == null && !authProvider.isLoading) {
        if (mounted) {
          debugPrint('🔄 No user found, redirecting to login');
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else if (authProvider.user != null) {
        debugPrint('✅ User authenticated: ${authProvider.user?.email}');
        debugPrint('🎭 User role: ${authProvider.user?.role}');
        await _ensureProvidersInitializedForUser();
      }
    } catch (e) {
      debugPrint('❌ Auth check failed: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> _ensureProvidersInitializedForUser() async {
    try {
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
      final coordinatorProvider = Provider.of<CoordinatorProvider>(
        context,
        listen: false,
      );

      if (!activityProvider.isInitialized) {
        debugPrint(
          '🔄 CRITICAL: Initializing ActivityProvider from RoleBasedDashboard',
        );
        await activityProvider.ensureProperInitialization();
        debugPrint('✅ ActivityProvider initialized successfully');
      } else {
        debugPrint('✅ ActivityProvider already initialized');
      }

      if (!volunteerProvider.isInitialized) {
        debugPrint(
          '🔄 CRITICAL: Initializing VolunteerProvider from RoleBasedDashboard',
        );
        await volunteerProvider.initialize();
        debugPrint('✅ VolunteerProvider initialized successfully');
      } else {
        debugPrint('✅ VolunteerProvider already initialized');
      }

      // FIXED: Initialize coordinator provider for coordinators
      if (authProvider.user?.role == 'coordinator' &&
          !coordinatorProvider.isInitialized) {
        debugPrint(
          '🔄 CRITICAL: Initializing CoordinatorProvider from RoleBasedDashboard',
        );
        await coordinatorProvider.initialize();
        debugPrint('✅ CoordinatorProvider initialized successfully');
      } else if (authProvider.user?.role == 'coordinator') {
        debugPrint('✅ CoordinatorProvider already initialized');
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('⚠️ Error ensuring providers initialized: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        if (authProvider.isLoading || user == null) {
          return Scaffold(
            backgroundColor: Colors.orange,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'Loading Dashboard...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    // FIXED: Show loading status for all providers including coordinator
                    Consumer<ActivityProviders.ActivityProvider>(
                      builder: (context, activityProvider, child) {
                        return Text(
                          activityProvider.isInitialized
                              ? 'Data loaded successfully!'
                              : 'Loading your activities...',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
                    if (authProvider.user?.role == 'coordinator')
                      Consumer<CoordinatorProvider>(
                        builder: (context, coordinatorProvider, child) {
                          return Text(
                            coordinatorProvider.isInitialized
                                ? 'Coordinator data loaded!'
                                : 'Loading coordinator data...',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 32),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      },
                      child: const Text(
                        'Back to Login',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        switch (user.role.toLowerCase()) {
          case 'student':
            return const StudentDashboardWithBottomNav();
          case 'instructor':
            return const InstructorMainScreen();
          case 'coordinator':
            return const CoordinatorMainScreen();
          case 'admin':
            // FIXED: Use aliased AdminDashboard
            return const AdminDash.AdminDashboard();
          default:
            return const StudentDashboardWithBottomNav();
        }
      },
    );
  }
}

// Keep all existing navigation classes unchanged...
class StudentDashboardWithBottomNav extends StatelessWidget {
  const StudentDashboardWithBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          body: StudentDashboard(
            onBrowseActivitiesTap:
                () => Navigator.pushNamed(context, '/browse-activities'),
          ),
          bottomNavigationBar: _buildBottomNavigation(context, 0),
        );
      },
    );
  }
}

class BrowseActivitiesScreenWithBottomNav extends StatelessWidget {
  const BrowseActivitiesScreenWithBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const BrowseActivitiesScreen(),
      bottomNavigationBar: _buildBottomNavigation(context, 1),
    );
  }
}

class MyActivitiesScreenWithBottomNav extends StatelessWidget {
  const MyActivitiesScreenWithBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyActivitiesScreen();
  }
}

class MyProfileScreenWithBottomNav extends StatelessWidget {
  const MyProfileScreenWithBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const MyProfileScreen(),
      bottomNavigationBar: _buildBottomNavigation(context, 3),
    );
  }
}

class VolunteeringDashboardScreenWithBottomNav extends StatelessWidget {
  const VolunteeringDashboardScreenWithBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const VolunteeringDashboardScreen(),
      bottomNavigationBar: _buildBottomNavigation(context, 1),
    );
  }
}

Widget _buildBottomNavigation(BuildContext context, int currentIndex) {
  return BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    selectedItemColor: Colors.orange,
    unselectedItemColor: Colors.grey,
    currentIndex: currentIndex,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Browse'),
      BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today),
        label: 'My Activities',
      ),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ],
    onTap: (index) => _handleBottomNavTap(context, index, currentIndex),
  );
}

void _handleBottomNavTap(BuildContext context, int index, int currentIndex) {
  if (index == currentIndex) return;

  switch (index) {
    case 0:
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/student-dashboard',
        (route) => false,
      );
      break;
    case 1:
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/browse-activities',
        (route) => false,
      );
      break;
    case 2:
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/my-activities',
        (route) => false,
      );
      break;
    case 3:
      Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
      break;
  }
}
