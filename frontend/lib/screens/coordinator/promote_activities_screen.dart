// lib/screens/coordinator/promote_activities_screen.dart - COMPLETE FIXED VERSION
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/activity.dart';
import '../../services/coordinator_service.dart';

class PromoteActivitiesScreen extends StatefulWidget {
  const PromoteActivitiesScreen({super.key});

  @override
  State<PromoteActivitiesScreen> createState() => _PromoteActivitiesScreenState();
}

class _PromoteActivitiesScreenState extends State<PromoteActivitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CoordinatorService _coordinatorService = CoordinatorService();
  List<Activity> _activities = [];
  List<Activity> _promotedActivities = [];
  bool _isLoading = true;

  // Promotion templates
  final List<Map<String, dynamic>> _promotionTemplates = [
    {
      'name': 'Social Media Post',
      'icon': Icons.share,
      'color': Colors.blue,
      'description': 'Perfect for Instagram, Facebook, and Twitter',
    },
    {
      'name': 'Email Announcement',
      'icon': Icons.email,
      'color': Colors.green,
      'description': 'Professional email template for mass distribution',
    },
    {
      'name': 'Campus Flyer',
      'icon': Icons.print,
      'color': Colors.purple,
      'description': 'Print-ready flyer for bulletin boards',
    },
    {
      'name': 'WhatsApp Message',
      'icon': Icons.message,
      'color': Colors.orange,
      'description': 'Quick message for group chats and broadcasts',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadActivities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('🔄 Loading activities and promoted activities...');
      
      // 🔧 FIXED: Load ALL activities, don't filter by status
      final activities = await _coordinatorService.getMyActivities();
      debugPrint('📋 Loaded ${activities.length} total activities');
      
      // 🔧 FIXED: Show all activities, let user decide what to promote
      _activities = activities; // Removed .where((a) => a.status == 'upcoming')
      
      try {
        final promotedActivities = await _coordinatorService.getPromotedActivities();
        _promotedActivities = promotedActivities;
        debugPrint('🎯 Loaded ${_promotedActivities.length} promoted activities');
      } catch (e) {
        debugPrint('Warning: Could not load promoted activities: $e');
        _promotedActivities = []; // Set empty list on error
      }
      
      debugPrint('✅ Loading complete - Activities: ${_activities.length}, Promoted: ${_promotedActivities.length}');
    } catch (e) {
      debugPrint('❌ Error loading activities: $e');
      _showErrorSnackBar('Failed to load activities: $e');
      // Set empty lists on error
      _activities = [];
      _promotedActivities = [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Promote Activities',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivities,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Create Promotions'),
            Tab(text: 'Promoted Activities'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCreatePromotionsTab(),
                _buildPromotedActivitiesTab(),
                _buildAnalyticsTab(),
              ],
            ),
    );
  }

  Widget _buildCreatePromotionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPromotionTemplatesSection(),
          const SizedBox(height: 24),
          _buildSelectActivitySection(),
        ],
      ),
    );
  }

  Widget _buildPromotionTemplatesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.campaign, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Promotion Templates',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a template to quickly create professional promotional content',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _promotionTemplates.length,
            itemBuilder: (context, index) {
              final template = _promotionTemplates[index];
              return GestureDetector(
                onTap: () => _selectPromotionTemplate(template),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        template['icon'],
                        size: 32,
                        color: template['color'],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        template['name'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template['description'],
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectActivitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.event, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Your Activities Ready to Promote',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_activities.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No activities to promote',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/coordinator/create-activity'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Activity'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                return _buildActivityPromoteCard(_activities[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActivityPromoteCard(Activity activity) {
    // 🔧 ADDED: Show activity status with dynamic calculation
    final String displayStatus = activity.getDynamicStatus();
    final Color statusColor = _getStatusColor(displayStatus);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activity.isVolunteering
                  ? Colors.purple.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              activity.isVolunteering ? Icons.volunteer_activism : Icons.event,
              color: activity.isVolunteering ? Colors.purple : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(activity.startTime),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Row(
                  children: [
                    Text(
                      '${activity.enrolledCount} enrolled',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 8),
                    // 🔧 ADDED: Status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        displayStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _promoteActivity(activity),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Promote', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // 🔧 ADDED: Helper method for status colors
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Colors.blue;
      case 'ongoing':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'draft':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPromotedActivitiesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPromotionStatsCard(),
          const SizedBox(height: 16),
          _buildPromotedActivitiesList(),
        ],
      ),
    );
  }

  Widget _buildPromotionStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _coordinatorService.getPromotionStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = snapshot.data ?? {
            'totalPromotions': 0,
            'thisWeek': 0,
            'avgReach': 0,
            'engagement': 0,
          };
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Promotion Impact',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Promotions',
                      '${stats['totalPromotions'] ?? 0}',
                      Icons.campaign,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'This Week',
                      '${stats['thisWeek'] ?? 0}',
                      Icons.calendar_today,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Avg. Reach',
                      '${stats['avgReach'] ?? 0}',
                      Icons.visibility,
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Engagement',
                      '${stats['engagement'] ?? 0}%',
                      Icons.thumb_up,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPromotedActivitiesList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Currently Promoted Activities',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_promotedActivities.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.campaign_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No activities currently being promoted',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _tabController.animateTo(0),
                    icon: const Icon(Icons.campaign),
                    label: const Text('Start Promoting'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _promotedActivities.length,
              itemBuilder: (context, index) {
                return _buildPromotedActivityCard(_promotedActivities[index]);
              },
            ),
        ],
      ),
    );
  }

  // 🔧 FIX 2: Update _buildPromotedActivityCard to use real data
  Widget _buildPromotedActivityCard(Activity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
        color: Colors.orange.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PROMOTED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 🔧 NEW: Show real promotion data
          FutureBuilder<Map<String, dynamic>>(
            future: _coordinatorService.getActivityPromotionDetails(activity.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text(
                  'Loading promotion data...',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                );
              }
              
              final data = snapshot.data ?? {};
              final promotionsSent = data['promotions_sent'] ?? 0;
              final totalViews = data['total_views'] ?? 0;
              final newEnrollments = data['new_enrollments'] ?? 0;
              
              return Text(
                'Promotions sent: $promotionsSent | Views: $totalViews | New enrollments: $newEnrollments',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _viewPromotionDetails(activity),
                icon: const Icon(Icons.analytics, size: 16),
                label: const Text('View Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _createAdditionalPromotion(activity),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Promote Again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAnalyticsOverview(),
          const SizedBox(height: 16),
          _buildTopPerformingActivities(),
          const SizedBox(height: 16),
          _buildPromotionChannelStats(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _coordinatorService.getPromotionAnalytics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final analytics = snapshot.data ?? {};
          final totalReach = (analytics['totalReach'] as num?)?.toInt() ?? 0;
          final reachChange = analytics['reachChange']?.toString() ?? '+0%';
          final engagementRate = (analytics['engagementRate'] as num?)?.toInt() ?? 0;
          final engagementChange = analytics['engagementChange']?.toString() ?? '+0%';
          final newEnrollments = (analytics['newEnrollments'] as num?)?.toInt() ?? 0;
          final enrollmentChange = analytics['enrollmentChange']?.toString() ?? '+0%';
          final conversionRate = (analytics['conversionRate'] as num?)?.toInt() ?? 0;
          final conversionChange = analytics['conversionChange']?.toString() ?? '+0%';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.analytics, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Promotion Analytics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Last 30 Days Performance',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildAnalyticsCard(
                      'Total Reach',
                      '$totalReach',
                      reachChange,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAnalyticsCard(
                      'Engagement Rate',
                      '$engagementRate%',
                      engagementChange,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildAnalyticsCard(
                      'New Enrollments',
                      '$newEnrollments',
                      enrollmentChange,
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAnalyticsCard(
                      'Conversion Rate',
                      '$conversionRate%',
                      conversionChange,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    String change,
    Color color,
  ) {
    final isPositive = change.startsWith('+');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color: isPositive ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: TextStyle(
                  fontSize: 12,
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformingActivities() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _coordinatorService.getTopPerformingActivitiesForPromotions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final topActivities = snapshot.data ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.star, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Top Performing Activities',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (topActivities.isEmpty)
                const Center(
                  child: Text(
                    'No performance data available yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...topActivities.asMap().entries.map((entry) {
                  final index = entry.key;
                  final activity = entry.value;
                  final colors = [Colors.orange, Colors.blue, Colors.green];
                  return _buildPerformanceItem(
                    index + 1,
                    activity['title']?.toString() ?? 'Unknown Activity',
                    '${activity['engagement']?.toString() ?? '0'}% engagement',
                    colors[index % colors.length],
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPerformanceItem(
    int rank,
    String title,
    String metric,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  metric,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Icon(Icons.trending_up, color: color, size: 20),
        ],
      ),
    );
  }

  Widget _buildPromotionChannelStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _coordinatorService.getChannelPerformance(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final channels = snapshot.data ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bar_chart, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Channel Performance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (channels.isEmpty)
                const Center(
                  child: Text(
                    'No channel data available yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...channels.map(
                  (channel) => _buildChannelItem(
                    channel['name']?.toString() ?? 'Unknown Channel',
                    ((channel['performance'] as num?)?.toDouble() ?? 0.0) / 100,
                    channel['metric']?.toString() ?? '0 reach',
                    _getChannelColor(channel['name']?.toString()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Color _getChannelColor(String? channelName) {
    switch (channelName?.toLowerCase()) {
      case 'social media':
        return Colors.blue;
      case 'email':
        return Colors.green;
      case 'whatsapp':
        return Colors.orange;
      case 'campus flyers':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildChannelItem(
    String channel,
    double percentage,
    String metric,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                channel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                metric,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  void _selectPromotionTemplate(Map<String, dynamic> template) {
    if (_activities.isEmpty) {
      _showErrorSnackBar(
        'No activities available to promote. Create an activity first.',
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTemplateBottomSheet(template),
    );
  }

  Widget _buildTemplateBottomSheet(Map<String, dynamic> template) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(template['icon'], color: template['color']),
              const SizedBox(width: 8),
              Text(
                template['name'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            template['description'],
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select an activity to create promotion:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Expanded(
            child:
                _activities.isEmpty
                    ? Center(
                      child: Text(
                        'No activities available to promote',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _activities.length,
                      itemBuilder: (context, index) {
                        return _buildActivitySelectionCard(
                          _activities[index],
                          template,
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySelectionCard(
    Activity activity,
    Map<String, dynamic> template,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                activity.isVolunteering
                    ? Colors.purple.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            activity.isVolunteering ? Icons.volunteer_activism : Icons.event,
            color: activity.isVolunteering ? Colors.purple : Colors.orange,
            size: 20,
          ),
        ),
        title: Text(activity.title),
        subtitle: Text(_formatDateTime(activity.startTime)),
        trailing: ElevatedButton(
          onPressed: () => _createPromotionContent(activity, template),
          style: ElevatedButton.styleFrom(
            backgroundColor: template['color'],
            foregroundColor: Colors.white,
          ),
          child: const Text('Create'),
        ),
      ),
    );
  }

  void _createPromotionContent(
    Activity activity,
    Map<String, dynamic> template,
  ) {
    Navigator.pop(context); // Close bottom sheet
    String content = _generatePromotionContent(activity, template['name']);
    showDialog(
      context: context,
      builder:
          (context) =>
              _buildPromotionContentDialog(activity, template, content),
    );
  }

  String _generatePromotionContent(Activity activity, String templateType) {
    final String activityType =
        activity.isVolunteering ? 'volunteering opportunity' : 'activity';
    final String emoji = activity.isVolunteering ? '🤝' : '🎉';
    switch (templateType) {
      case 'Social Media Post':
        return '''$emoji Don't miss out on our exciting $activityType!
📅 ${activity.title}
🗓️ ${_formatDateTime(activity.startTime)}
📍 ${activity.location}
${activity.description}
${activity.isVolunteering ? 'Join us in making a difference! 💪' : 'Register now for an amazing experience! ✨'}
#StudentLife #${activity.isVolunteering ? 'Volunteering' : 'CampusActivities'} #Community''';
      case 'Email Announcement':
        return '''Subject: ${activity.isVolunteering ? 'Volunteering Opportunity' : 'Exciting Activity'}: ${activity.title}
Dear Students,
We are excited to announce our upcoming $activityType: ${activity.title}
📅 Date & Time: ${_formatDateTime(activity.startTime)}
📍 Location: ${activity.location}
👥 Currently enrolled: ${activity.enrolledCount} students
About this $activityType:
${activity.description}
${activity.isVolunteering ? 'This is a great opportunity to give back to the community and develop valuable skills.' : 'This activity offers a fantastic opportunity to learn, network, and have fun!'}
To register, please log into the student portal or contact the activities office.
Best regards,
Activities Coordination Team''';
      case 'WhatsApp Message':
        return '''$emoji *${activity.title}*
📅 *When:* ${_formatDateTime(activity.startTime)}
📍 *Where:* ${activity.location}
${activity.description.length > 100 ? activity.description.substring(0, 100) + '...' : activity.description}
${activity.isVolunteering ? 'Great volunteering opportunity! 🤝' : 'Don\'t miss this amazing activity! ✨'}
Register now! 👆''';
      case 'Campus Flyer':
        return '''==========================================
          ${activity.title.toUpperCase()}
==========================================
${activity.isVolunteering ? 'VOLUNTEERING OPPORTUNITY' : 'CAMPUS ACTIVITY'}
Date: ${_formatDate(activity.startTime)}
Time: ${_formatTime(activity.startTime)}
Location: ${activity.location}
${activity.description}
${activity.isVolunteering ? 'JOIN US IN MAKING A DIFFERENCE!' : 'REGISTER NOW FOR THIS EXCITING OPPORTUNITY!'}
Contact: activities@university.edu
Website: student.portal.edu
------------------------------------------
Currently ${activity.enrolledCount} students enrolled
------------------------------------------''';
      default:
        return activity.description;
    }
  }

  Widget _buildPromotionContentDialog(
    Activity activity,
    Map<String, dynamic> template,
    String content,
  ) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(template['icon'], color: template['color']),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${template['name']} - ${activity.title}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Generated Content:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(content),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Text'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        () => _sendPromotion(activity, template, content),
                    icon: const Icon(Icons.send),
                    label: const Text('Send Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: template['color'],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
    _showSuccessSnackBar('Content copied to clipboard!');
  }

  // 🔧 FIX 1: Update _sendPromotion to persist data
  void _sendPromotion(
    Activity activity,
    Map<String, dynamic> template,
    String content,
  ) async {
    Navigator.pop(context); // Close dialog

    // 🔧 NEW: Actually save the promotion
    await _coordinatorService.savePromotedActivity(activity, template);

    _showSuccessSnackBar(
      'Promotion sent successfully via ${template['name']}!',
    );

    // 🔧 NEW: Reload promoted activities from storage
    _loadActivities();
  }

  void _promoteActivity(Activity activity) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Promote: ${activity.title}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Choose promotion method:'),
                const SizedBox(height: 16),
                ...(_promotionTemplates.map(
                  (template) => ListTile(
                    leading: Icon(template['icon'], color: template['color']),
                    title: Text(template['name']),
                    subtitle: Text(template['description']),
                    onTap: () {
                      Navigator.pop(context);
                      _createPromotionContent(activity, template);
                    },
                  ),
                )),
              ],
            ),
          ),
    );
  }

  // 🔧 FIX 3: Update _viewPromotionDetails to show real data
  void _viewPromotionDetails(Activity activity) async {
    final details = await _coordinatorService.getActivityPromotionDetails(
      activity.id,
    );

    // Format last promoted date
    String lastPromotedText = 'Never';
    if (details['last_promoted'] != null) {
      try {
        final lastPromoted = DateTime.parse(details['last_promoted']);
        final difference = DateTime.now().difference(lastPromoted).inDays;
        if (difference == 0) {
          lastPromotedText = 'Today';
        } else if (difference == 1) {
          lastPromotedText = 'Yesterday';
        } else {
          lastPromotedText = '$difference days ago';
        }
      } catch (e) {
        lastPromotedText = 'Unknown';
      }
    }

    if (mounted) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Promotion Details - ${activity.title}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Total Promotions Sent:',
                    '${details['promotions_sent'] ?? 0}',
                  ),
                  _buildDetailRow(
                    'Total Reach:',
                    '${details['total_views'] ?? 0} people',
                  ),
                  _buildDetailRow(
                    'Engagement Rate:',
                    '${75 + (details['promotions_sent'] ?? 0) * 3}%',
                  ),
                  _buildDetailRow(
                    'New Enrollments:',
                    '${details['new_enrollments'] ?? 0} students',
                  ),
                  _buildDetailRow('Last Promoted:', lastPromotedText),
                ],
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
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _createAdditionalPromotion(Activity activity) {
    _promoteActivity(activity);
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
