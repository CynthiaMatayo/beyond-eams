// lib/widgets/activity_card_skeleton.dart
import 'package:flutter/material.dart';

class ActivityCardSkeleton extends StatefulWidget {
  const ActivityCardSkeleton({super.key});

  @override
  State<ActivityCardSkeleton> createState() => _ActivityCardSkeletonState();
}

class _ActivityCardSkeletonState extends State<ActivityCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with skeleton elements
              Row(
                children: [
                  _buildShimmerBox(
                    60,
                    60,
                    circular: true,
                  ), // Avatar placeholder
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShimmerBox(120, 16), // Title placeholder
                        const SizedBox(height: 8),
                        _buildShimmerBox(80, 14), // Subtitle placeholder
                      ],
                    ),
                  ),
                  _buildShimmerBox(60, 24), // Badge placeholder
                ],
              ),
              const SizedBox(height: 16),

              // Description skeleton
              _buildShimmerBox(double.infinity, 14),
              const SizedBox(height: 8),
              _buildShimmerBox(200, 14),
              const SizedBox(height: 16),

              // Info row skeleton
              Row(
                children: [
                  _buildShimmerBox(16, 16, circular: true),
                  const SizedBox(width: 8),
                  _buildShimmerBox(100, 14),
                  const SizedBox(width: 24),
                  _buildShimmerBox(16, 16, circular: true),
                  const SizedBox(width: 8),
                  _buildShimmerBox(80, 14),
                ],
              ),
              const SizedBox(height: 16),

              // Action buttons skeleton
              Row(
                children: [
                  Expanded(child: _buildShimmerBox(double.infinity, 40)),
                  const SizedBox(width: 12),
                  _buildShimmerBox(100, 40),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerBox(
    double width,
    double height, {
    bool circular = false,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius:
                circular
                    ? BorderRadius.circular(height / 2)
                    : BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: [0.0, _animation.value, 1.0],
            ),
          ),
        );
      },
    );
  }
}
