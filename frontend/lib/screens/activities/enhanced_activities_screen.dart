// lib/screens/activities/enhanced_activities_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/feedback_widgets.dart';
import '../../widgets/enhanced_activity_card.dart';
import '../../widgets/slide_in_animation.dart';
import '../../widgets/activity_card_skeleton.dart';

class EnhancedActivitiesScreen extends StatefulWidget {
  const EnhancedActivitiesScreen({super.key});

  @override
  State<EnhancedActivitiesScreen> createState() =>
      _EnhancedActivitiesScreenState();
}

class _EnhancedActivitiesScreenState extends State<EnhancedActivitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    try {
      await Provider.of<ActivityProvider>(
        context,
        listen: false,
      ).loadActivities();
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'Failed to load activities. Please try again.',
          type: SnackBarType.error,
          action: _loadActivities,
          actionLabel: 'Retry',
        );
      }
    }
  }

  Future<void> _refreshActivities() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadActivities();
    setState(() {
      _isRefreshing = false;
    });
    if (mounted) {
      CustomSnackBar.show(
        context,
        message: 'Activities refreshed successfully!',
        type: SnackBarType.success,
      );
    }
  }

  Future<void> _handleEnroll(int activityId) async {
    try {
      final success = await Provider.of<ActivityProvider>(
        context,
        listen: false,
      ).enrollActivity(activityId);
      if (mounted) {
        if (success) {
          CustomSnackBar.show(
            context,
            message: 'Successfully enrolled in activity!',
            type: SnackBarType.success,
          );
        } else {
          final error =
              Provider.of<ActivityProvider>(context, listen: false).error;
          CustomSnackBar.show(
            context,
            message: error ?? 'Failed to enroll in activity',
            type: SnackBarType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context,
          message: 'An error occurred. Please try again.',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _handleUnenroll(int activityId) async {
    if (!mounted) return;

    ConfirmationDialog.show(
      context,
      title: 'Unenroll from Activity',
      message: 'Are you sure you want to unenroll from this activity?',
      confirmLabel: 'Unenroll',
      confirmColor: Colors.orange,
      onConfirm: () async {
        try {
          final success = await Provider.of<ActivityProvider>(
            context,
            listen: false,
          ).unenrollActivity(activityId);
          if (mounted && success) {
            CustomSnackBar.show(
              context,
              message: 'Successfully unenrolled from activity',
              type: SnackBarType.info,
            );
          }
        } catch (e) {
          if (mounted) {
            CustomSnackBar.show(
              context,
              message: 'Failed to unenroll. Please try again.',
              type: SnackBarType.error,
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Consumer<ActivityProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.activities.isEmpty) {
            return _buildLoadingState();
          }

          if (provider.error != null && provider.activities.isEmpty) {
            return ErrorStateWidget(
              title: 'Oops! Something went wrong',
              message: provider.error!,
              onRetry: _loadActivities,
              retryLabel: 'Reload Activities',
            );
          }

          if (provider.activities.isEmpty) {
            return EmptyStateWidget(
              title: 'No Activities Available',
              message:
                  'There are no activities scheduled at the moment. Check back later for new opportunities!',
              icon: Icons.event_busy,
            );
          }

          return _buildActivitiesList(provider);
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Activities',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _isRefreshing ? null : _refreshActivities,
          tooltip: 'Refresh',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: Colors.indigo,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search activities...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                      : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: 5,
            itemBuilder:
                (context, index) => SlideInAnimation(
                  delay: Duration(milliseconds: index * 100),
                  child: const ActivityCardSkeleton(),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivitiesList(ActivityProvider provider) {
    final user = Provider.of<AuthProvider>(context).user;
    final filteredActivities =
        provider.activities.where((activity) {
          return activity.title.toLowerCase().contains(_searchQuery) ||
              activity.description.toLowerCase().contains(_searchQuery) ||
              activity.location.toLowerCase().contains(_searchQuery);
        }).toList();

    if (filteredActivities.isEmpty && _searchQuery.isNotEmpty) {
      return EmptyStateWidget(
        title: 'No Results Found',
        message:
            'No activities match your search criteria. Try different keywords.',
        icon: Icons.search_off,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshActivities,
      color: Colors.indigo,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: filteredActivities.length,
        itemBuilder: (context, index) {
          final activity = filteredActivities[index];
          return SlideInAnimation(
            delay: Duration(milliseconds: index * 100),
            child: EnhancedActivityCard(
              activity: activity,
              userRole: user?.role ?? 'student',
              onTap: () => _navigateToActivityDetail(activity.id),
              onEnroll: () => _handleEnroll(activity.id),
              onUnenroll: () => _handleUnenroll(activity.id),
            ),
          );
        },
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    final user = Provider.of<AuthProvider>(context).user;
    if (user?.role == 'coordinator' || user?.role == 'admin') {
      return FloatingActionButton.extended(
        onPressed: () => _navigateToCreateActivity(),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Activity'),
      );
    }
    return null;
  }

  void _navigateToActivityDetail(int activityId) {
    // Replace with your actual navigation logic
    Navigator.pushNamed(context, '/activity-detail', arguments: activityId);
  }

  void _navigateToCreateActivity() {
    // Replace with your actual navigation logic
    Navigator.pushNamed(context, '/create-activity');
  }
}
