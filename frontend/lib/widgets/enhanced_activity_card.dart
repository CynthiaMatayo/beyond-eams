// lib/widgets/enhanced_activity_card.dart
import 'package:flutter/material.dart';
import '../models/activity.dart';

class EnhancedActivityCard extends StatefulWidget {
  final Activity activity;
  final VoidCallback? onTap;
  final VoidCallback? onEnroll;
  final VoidCallback? onUnenroll;
  final bool showEnrollButton;
  final String userRole;

  const EnhancedActivityCard({
    super.key,
    required this.activity,
    this.onTap,
    this.onEnroll,
    this.onUnenroll,
    this.showEnrollButton = true,
    required this.userRole,
  });

  @override
  State<EnhancedActivityCard> createState() => _EnhancedActivityCardState();
}

class _EnhancedActivityCardState extends State<EnhancedActivityCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _shadowAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  Color _getStatusColor() {
    switch (widget.activity.status.toLowerCase()) {
      case 'upcoming':
        return const Color(0xFF2196F3); // Blue
      case 'ongoing':
        return const Color(0xFF4CAF50); // Green
      case 'completed':
        return const Color(0xFF757575); // Grey
      case 'cancelled':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF2196F3); // Blue
    }
  }

  IconData _getActivityIcon() {
    if (widget.activity.isVolunteering) {
      return Icons.volunteer_activism;
    }
    return Icons.event;
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays > 1 && difference.inDays <= 7) {
      return 'In ${difference.inDays} days';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  bool _isActivityDisabled() {
    return widget.activity.status.toLowerCase() == 'completed' ||
        widget.activity.status.toLowerCase() == 'cancelled';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.onTap,
            child: MouseRegion(
              onEnter: (_) => _onHover(true),
              onExit: (_) => _onHover(false),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.1),
                      blurRadius: _shadowAnimation.value,
                      offset: const Offset(0, 2),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_buildHeader(), _buildContent(theme)],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getStatusColor().withOpacity(0.8), _getStatusColor()],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getActivityIcon(), color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.activity.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.white.withOpacity(0.9),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.activity.location,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (widget.activity.isVolunteering)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A), // Volunteering green
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'VOLUNTEER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            widget.activity.description,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
              fontSize: 14,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // Date, time and enrollment info
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 4),
              Text(
                '${_formatDate(widget.activity.startTime)} • ${_formatTime(widget.activity.startTime)}',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.people,
                size: 16,
                color: theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.activity.enrolledCount} enrolled',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Status indicator
          if (widget.activity.status.toLowerCase() != 'upcoming')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.activity.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Action buttons
          if (widget.showEnrollButton && widget.userRole == 'student')
            _buildStudentActions(),
          if (widget.userRole == 'instructor' ||
              widget.userRole == 'coordinator' ||
              widget.userRole == 'admin')
            _buildInstructorActions(),
        ],
      ),
    );
  }

  Widget _buildStudentActions() {
    final isDisabled = _isActivityDisabled();

    return Row(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: ElevatedButton.icon(
              onPressed:
                  isDisabled
                      ? null
                      : (widget.activity.isEnrolled
                          ? widget.onUnenroll
                          : widget.onEnroll),
              icon: Icon(
                widget.activity.isEnrolled
                    ? Icons.check_circle
                    : Icons.add_circle_outline,
                size: 18,
              ),
              label: Text(
                widget.activity.isEnrolled ? 'Enrolled' : 'Enroll Now',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDisabled
                        ? Colors.grey[400]
                        : (widget.activity.isEnrolled
                            ? Colors.grey[400]
                            : _getStatusColor()),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: widget.activity.isEnrolled || isDisabled ? 0 : 2,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: widget.onTap,
          icon: const Icon(Icons.arrow_forward_ios),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[100],
            foregroundColor: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructorActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onTap,
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text(
              'View Details',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _getStatusColor(),
              side: BorderSide(color: _getStatusColor()),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: widget.onTap,
            icon: Icon(Icons.people, color: _getStatusColor()),
            tooltip: 'View Attendances',
          ),
        ),
      ],
    );
  }
}
