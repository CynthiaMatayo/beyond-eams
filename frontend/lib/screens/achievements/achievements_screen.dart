// lib/screens/achievements/achievements_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/achievements_provider.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAchievements();
    });
  }

  Future<void> _initializeAchievements() async {
    final achievementsProvider = Provider.of<AchievementsProvider>(
      context,
      listen: false,
    );
    await achievementsProvider.initialize();
  }

  Future<void> _refreshAchievements() async {
    final achievementsProvider = Provider.of<AchievementsProvider>(
      context,
      listen: false,
    );
    await achievementsProvider.refreshAchievements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Achievements',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.indigo,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _refreshAchievements,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<AchievementsProvider>(
        builder: (context, achievementsProvider, child) {
          if (achievementsProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.indigo),
                  SizedBox(height: 16),
                  Text('Loading achievements...'),
                ],
              ),
            );
          }

          if (achievementsProvider.error != null) {
            return RefreshIndicator(
              onRefresh: _refreshAchievements,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Failed to load achievements'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _refreshAchievements,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshAchievements,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Points and Level Card
                  _buildPointsCard(achievementsProvider),
                  const SizedBox(height: 16),

                  // Achievement Progress Cards
                  ..._buildAchievementCards(achievementsProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPointsCard(AchievementsProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Colors.indigo, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.emoji_events, size: 48, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              '${provider.totalPoints}',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              'Total Points',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      'Level ${provider.currentLevel}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Current Level',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${provider.pointsToNextLevel}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'To Next Level',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAchievementCards(AchievementsProvider provider) {
    final achievements = provider.getAchievementProgress();

    return achievements.map((achievement) {
      final progress = achievement['progress'] as int;
      final target = achievement['target'] as int;
      final unlocked = achievement['unlocked'] as bool;
      final progressPercentage = (progress / target).clamp(0.0, 1.0);

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        unlocked
                            ? achievement['color'].withOpacity(0.2)
                            : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    achievement['icon'],
                    color: unlocked ? achievement['color'] : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            achievement['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  unlocked ? Colors.black87 : Colors.grey[600],
                            ),
                          ),
                          if (unlocked) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle,
                              color: achievement['color'],
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement['description'],
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$progress / $target',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: progressPercentage,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              achievement['color'],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
