// lib/screens/activities/activities_list_screen.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/activity_provider.dart';

class ActivitiesListScreen extends StatefulWidget {
  const ActivitiesListScreen({super.key});

  @override
  State<ActivitiesListScreen> createState() => _ActivitiesListScreenState();
}

class _ActivitiesListScreenState extends State<ActivitiesListScreen> {
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Academic',
    'Sports',
    'Cultural',
    'Technology',
    'Community Service',
    'Leadership',
    'Arts',
    'Other',
  ];

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
    setState(() {
      _isLoading = true;
    });

    try {
      final activityProvider = Provider.of<ActivityProvider>(
        context,
        listen: false,
      );

      if (!activityProvider.isInitialized) {
        await activityProvider.initialize();
      }
    } catch (e) {
      debugPrint('Error loading activities: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Browse Activities',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF8B5CF6),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search activities...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF8B5CF6),
                    ),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                              icon: const Icon(Icons.clear_rounded),
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF8B5CF6),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Category Filter
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;

                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            category,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : const Color(0xFF8B5CF6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFF8B5CF6),
                          checkmarkColor: Colors.white,
                          side: BorderSide(
                            color:
                                isSelected
                                    ? const Color(0xFF8B5CF6)
                                    : Colors.grey[300]!,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Activities List
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF8B5CF6),
                        ),
                      ),
                    )
                    : Consumer<ActivityProvider>(
                      builder: (context, activityProvider, child) {
                        final filteredActivities = _getFilteredActivities(
                          activityProvider.activities,
                        );

                        if (filteredActivities.isEmpty) {
                          return _buildEmptyState();
                        }

                        return RefreshIndicator(
                          onRefresh: _loadActivities,
                          color: const Color(0xFF8B5CF6),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredActivities.length,
                            itemBuilder: (context, index) {
                              final activity = filteredActivities[index];
                              return _buildActivityCard(activity);
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _getFilteredActivities(List<dynamic> activities) {
    return activities.where((activity) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          (activity.title?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false) ||
          (activity.description?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);

      final matchesCategory =
          _selectedCategory == 'All' ||
          (activity.category ?? 'Other') == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty || _selectedCategory != 'All'
                ? 'No Activities Found'
                : 'No Activities Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _searchQuery.isNotEmpty || _selectedCategory != 'All'
                  ? 'Try adjusting your search or filter criteria'
                  : 'Check back later for new opportunities',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: Activity card with VOLUNTEER/REGULAR badges instead of category badges
  Widget _buildActivityCard(dynamic activity) {
    final bool isEnrolled = activity.isEnrolled ?? false;
    final bool isFull =
        (activity.enrolledCount ?? 0) >= (activity.maxParticipants ?? 100);
    final bool isUpcoming = activity.status == 'upcoming';
    final bool isVolunteering =
        activity.isVolunteering ?? false; // ✅ ADDED: Check volunteer status

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with VOLUNTEER/REGULAR badge (FIXED)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isVolunteering ? Colors.orange : Colors.indigo)
                  .withValues(
                    alpha: 0.1,
                  ), // ✅ FIXED: Color based on volunteer status
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // ✅ FIXED: VOLUNTEER/REGULAR badge instead of category
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isVolunteering
                            ? Colors.orange
                            : Colors.indigo, // ✅ FIXED: Proper colors
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isVolunteering
                        ? 'VOLUNTEER'
                        : 'REGULAR', // ✅ FIXED: Proper labels
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (isEnrolled) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Enrolled',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ] else if (isFull) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Full',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title ?? 'Activity Title',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                if (activity.description != null) ...[
                  Text(
                    activity.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ],
                // Activity details
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      Icons.calendar_today_rounded,
                      _formatDate(activity.startTime),
                      const Color(0xFF3B82F6),
                    ),
                    _buildInfoChip(
                      Icons.access_time_rounded,
                      _formatTime(activity.startTime),
                      const Color(0xFFF59E0B),
                    ),
                    _buildInfoChip(
                      Icons.location_on_rounded,
                      activity.location ?? 'TBD',
                      const Color(0xFF10B981),
                    ),
                    _buildInfoChip(
                      Icons.group_rounded,
                      '${activity.enrolledCount ?? 0} enrolled',
                      const Color(0xFF8B5CF6),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showActivityDetails(activity),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF8B5CF6),
                          side: const BorderSide(color: Color(0xFF8B5CF6)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            isEnrolled || isFull || !isUpcoming
                                ? null
                                : () => _enrollInActivity(activity),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isVolunteering
                                  ? Colors.orange
                                  : const Color(
                                    0xFF8B5CF6,
                                  ), // ✅ FIXED: Button color based on type
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          isEnrolled
                              ? 'Enrolled'
                              : isFull
                              ? 'Full'
                              : !isUpcoming
                              ? 'Past Event'
                              : isVolunteering
                              ? 'Apply'
                              : 'Enroll', // ✅ FIXED: Button text based on type
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'TBD';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'TBD';
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'academic':
        return const Color(0xFF3B82F6);
      case 'sports':
        return const Color(0xFF10B981);
      case 'cultural':
        return const Color(0xFFEC4899);
      case 'technology':
        return const Color(0xFF8B5CF6);
      case 'community service':
        return const Color(0xFF059669);
      case 'leadership':
        return const Color(0xFFF59E0B);
      case 'arts':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  void _showActivityDetails(dynamic activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                activity.title ?? 'Activity Details',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (activity.description != null) ...[
                                  const Text(
                                    'Description',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    activity.description!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                const Text(
                                  'Event Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // ✅ FIXED: Show VOLUNTEER/REGULAR instead of category
                                _buildDetailRow(
                                  activity.isVolunteering ?? false
                                      ? Icons.volunteer_activism
                                      : Icons.event,
                                  'Type',
                                  (activity.isVolunteering ?? false)
                                      ? 'Volunteer Activity'
                                      : 'Regular Activity',
                                ),
                                _buildDetailRow(
                                  Icons.calendar_today_rounded,
                                  'Date',
                                  _formatDate(activity.startTime),
                                ),
                                _buildDetailRow(
                                  Icons.access_time_rounded,
                                  'Time',
                                  _formatTime(activity.startTime),
                                ),
                                _buildDetailRow(
                                  Icons.location_on_rounded,
                                  'Location',
                                  activity.location ?? 'TBD',
                                ),
                                _buildDetailRow(
                                  Icons.person_rounded,
                                  'Coordinator',
                                  activity.createdByName ?? 'TBD',
                                ),
                                _buildDetailRow(
                                  Icons.group_rounded,
                                  'Enrolled',
                                  '${activity.enrolledCount ?? 0} participants',
                                ),
                                const SizedBox(height: 32),
                                if (!(activity.isEnrolled ?? false) &&
                                    !((activity.enrolledCount ?? 0) >=
                                        (activity.maxParticipants ?? 100)) &&
                                    activity.status == 'upcoming') ...[
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _enrollInActivity(activity);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            (activity.isVolunteering ?? false)
                                                ? Colors.orange
                                                : const Color(
                                                  0xFF8B5CF6,
                                                ), // ✅ FIXED: Button color
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        (activity.isVolunteering ?? false)
                                            ? 'Apply for Volunteer Position'
                                            : 'Enroll in Activity', // ✅ FIXED: Button text
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF8B5CF6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _enrollInActivity(dynamic activity) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  (activity.isVolunteering ?? false)
                      ? Icons.volunteer_activism
                      : Icons.event_rounded,
                  color:
                      (activity.isVolunteering ?? false)
                          ? Colors.orange
                          : const Color(0xFF8B5CF6),
                ), // ✅ FIXED: Icon based on type
                const SizedBox(width: 8),
                Text(
                  (activity.isVolunteering ?? false)
                      ? 'Confirm Application'
                      : 'Confirm Enrollment', // ✅ FIXED: Title based on type
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (activity.isVolunteering ?? false)
                      ? 'Are you sure you want to apply for "${activity.title ?? 'this volunteer position'}"?'
                      : 'Are you sure you want to enroll in "${activity.title ?? 'this activity'}"?', // ✅ FIXED: Message based on type
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Date:', _formatDate(activity.startTime)),
                      _buildInfoRow('Time:', _formatTime(activity.startTime)),
                      _buildInfoRow('Location:', activity.location ?? 'TBD'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  (activity.isVolunteering ?? false)
                      ? 'You will receive a confirmation notification once your application is reviewed.'
                      : 'You will receive a confirmation notification once enrolled.', // ✅ FIXED: Message based on type
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _processEnrollment(activity);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      (activity.isVolunteering ?? false)
                          ? Colors.orange
                          : const Color(0xFF8B5CF6), // ✅ FIXED: Button color
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  (activity.isVolunteering ?? false) ? 'Apply' : 'Enroll',
                ), // ✅ FIXED: Button text
              ),
            ],
          ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processEnrollment(dynamic activity) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
            ),
          ),
    );

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      Navigator.pop(context); // Remove loading dialog

      // Show success message
      _showSnackBar(
        (activity.isVolunteering ?? false)
            ? 'Successfully applied for "${activity.title ?? 'volunteer position'}"!'
            : 'Successfully enrolled in "${activity.title ?? 'activity'}"!', // ✅ FIXED: Message based on type
        isSuccess: true,
      );

      // Update the activity provider
      final activityProvider = Provider.of<ActivityProvider>(
        context,
        listen: false,
      );
      activityProvider.enrollInActivity(activity.id);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Remove loading dialog
      _showSnackBar('Enrollment failed: $e', isSuccess: false);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.info_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isSuccess ? const Color(0xFF10B981) : const Color(0xFF8B5CF6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isSuccess ? 3 : 2),
      ),
    );
  }
}
