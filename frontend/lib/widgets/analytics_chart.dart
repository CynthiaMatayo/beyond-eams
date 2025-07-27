// lib/widgets/analytics_chart.dart - COMPLETE WORKING VERSION
import 'package:flutter/material.dart';

class AnalyticsChart extends StatefulWidget {
  final String chartType;
  final Map<String, dynamic>? data;
  
  const AnalyticsChart({
    super.key,
    required this.chartType,
    this.data,
  });

  @override
  State<AnalyticsChart> createState() => _AnalyticsChartState();
}

class _AnalyticsChartState extends State<AnalyticsChart> {
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    setState(() => _isLoading = true);
    
    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
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
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading chart data...'),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
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
          Text(
            _getChartTitle(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildChart(),
          ),
        ],
      ),
    );
  }

  String _getChartTitle() {
    switch (widget.chartType) {
      case 'users':
        return 'User Activity (Last 7 Days)';
      case 'activities':
        return 'Activity Participation';
      case 'volunteering':
        return 'Volunteering Hours';
      default:
        return 'System Analytics';
    }
  }

  Widget _buildChart() {
    switch (widget.chartType) {
      case 'users':
        return _buildUserActivityChart();
      case 'activities':
        return _buildActivityChart();
      case 'volunteering':
        return _buildVolunteeringChart();
      default:
        return _buildDefaultChart();
    }
  }

  // FIXED: Simple bar chart for user activity
  Widget _buildUserActivityChart() {
    final data = [
      {'day': 'Mon', 'users': 45},
      {'day': 'Tue', 'users': 38},
      {'day': 'Wed', 'users': 52},
      {'day': 'Thu', 'users': 61},
      {'day': 'Fri', 'users': 49},
      {'day': 'Sat', 'users': 28},
      {'day': 'Sun', 'users': 35},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((item) {
        final users = item['users'] as int;
        final maxUsers = 70;
        final height = (users / maxUsers) * 120;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              users.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 24,
              height: height,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item['day'] as String,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  // FIXED: Pie chart representation for activities
  Widget _buildActivityChart() {
    final data = [
      {'type': 'Sports', 'count': 12, 'color': Colors.blue},
      {'type': 'Academic', 'count': 8, 'color': Colors.green},
      {'type': 'Social', 'count': 6, 'color': Colors.orange},
      {'type': 'Cultural', 'count': 4, 'color': Colors.purple},
    ];

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: CustomPaint(
            painter: PieChartPainter(data),
            child: const SizedBox(
              width: 120,
              height: 120,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: data.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: item['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item['type']} (${item['count']})',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // FIXED: Volunteering hours chart
  Widget _buildVolunteeringChart() {
    final data = [
      {'month': 'Jan', 'hours': 120},
      {'month': 'Feb', 'hours': 95},
      {'month': 'Mar', 'hours': 140},
      {'month': 'Apr', 'hours': 165},
      {'month': 'May', 'hours': 180},
      {'month': 'Jun', 'hours': 155},
    ];

    return Column(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((item) {
              final hours = item['hours'] as int;
              final maxHours = 200;
              final height = (hours / maxHours) * 100;
              
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${hours}h',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 20,
                    height: height,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['month'] as String,
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Total: 855 hours | Average: 142.5h/month',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Analytics Dashboard',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chart data visualization appears here',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for pie chart
class PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    final total = data.fold<int>(0, (sum, item) => sum + (item['count'] as int));
    
    double startAngle = -90 * (3.14159 / 180); // Start from top
    
    for (final item in data) {
      final count = item['count'] as int;
      final color = item['color'] as Color;
      final sweepAngle = (count / total) * 2 * 3.14159;
      
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Usage in dashboard
class DashboardAnalytics extends StatelessWidget {
  const DashboardAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System Analytics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // User Activity Chart
        const AnalyticsChart(chartType: 'users'),
        const SizedBox(height: 16),
        
        // Activity Distribution Chart
        const AnalyticsChart(chartType: 'activities'),
        const SizedBox(height: 16),
        
        // Volunteering Chart
        const AnalyticsChart(chartType: 'volunteering'),
      ],
    );
  }
}

// Quick stats widget to complement charts
class QuickStatsGrid extends StatelessWidget {
  const QuickStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard('Active Users', '127', Icons.people, Colors.blue),
        _buildStatCard('Total Activities', '30', Icons.event, Colors.green),
        _buildStatCard('Volunteer Hours', '855', Icons.volunteer_activism, Colors.orange),
        _buildStatCard('Participation Rate', '87%', Icons.trending_up, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.trending_up, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}