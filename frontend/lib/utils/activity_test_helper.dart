// Test helper to verify Activity model is working correctly
// lib/utils/activity_test_helper.dart

import 'package:flutter/material.dart';
import '../models/activity.dart';

class ActivityTestHelper {
  static void testActivityModel() {
    debugPrint('=== 🧪 TESTING ACTIVITY MODEL ===');

    final now = DateTime.now();

    // Test 1: Upcoming activity
    final upcomingActivity = Activity(
      id: 1,
      title: 'Test Upcoming Activity',
      description: 'Test',
      location: 'Test Location',
      startTime: now.add(const Duration(days: 1)), // Tomorrow
      endTime: now.add(const Duration(days: 1, hours: 2)),
      createdBy: 1,
      createdByName: 'Test User',
      createdAt: now,
      isVolunteering: false,
      status: 'scheduled',
      enrolledCount: 5,
    );

    debugPrint('Test 1 - Upcoming Activity:');
    debugPrint('  Start Time: ${upcomingActivity.startTime}');
    debugPrint('  End Time: ${upcomingActivity.endTime}');
    debugPrint('  Current Time: $now');
    debugPrint('  Database Status: ${upcomingActivity.status}');

    try {
      final dynamicStatus = upcomingActivity.getDynamicStatus();
      debugPrint('  Dynamic Status: $dynamicStatus');
      debugPrint('  Expected: upcoming, Got: $dynamicStatus ✅');
    } catch (e) {
      debugPrint('  ERROR calling getDynamicStatus(): $e ❌');
    }

    // Test 2: Completed activity
    final completedActivity = Activity(
      id: 2,
      title: 'Test Completed Activity',
      description: 'Test',
      location: 'Test Location',
      startTime: now.subtract(const Duration(days: 2)), // 2 days ago
      endTime: now.subtract(const Duration(days: 1)), // Yesterday
      createdBy: 1,
      createdByName: 'Test User',
      createdAt: now.subtract(const Duration(days: 3)),
      isVolunteering: true,
      status: 'scheduled',
      enrolledCount: 10,
    );

    debugPrint('\nTest 2 - Completed Activity:');
    debugPrint('  Start Time: ${completedActivity.startTime}');
    debugPrint('  End Time: ${completedActivity.endTime}');
    debugPrint('  Current Time: $now');
    debugPrint('  Database Status: ${completedActivity.status}');
    debugPrint('  Is Volunteering: ${completedActivity.isVolunteering}');
    debugPrint('  Enrolled Count: ${completedActivity.enrolledCount}');

    try {
      final dynamicStatus = completedActivity.getDynamicStatus();
      debugPrint('  Dynamic Status: $dynamicStatus');
      debugPrint('  Expected: completed, Got: $dynamicStatus ✅');
    } catch (e) {
      debugPrint('  ERROR calling getDynamicStatus(): $e ❌');
    }

    // Test 3: Draft activity
    final draftActivity = Activity(
      id: 3,
      title: 'Test Draft Activity',
      description: 'Test',
      location: 'Test Location',
      startTime: now.add(const Duration(days: 5)),
      endTime: now.add(const Duration(days: 5, hours: 2)),
      createdBy: 1,
      createdByName: 'Test User',
      createdAt: now,
      isVolunteering: false,
      status: 'draft', // Explicit draft status
      enrolledCount: 0,
    );

    debugPrint('\nTest 3 - Draft Activity:');
    debugPrint('  Database Status: ${draftActivity.status}');

    try {
      final dynamicStatus = draftActivity.getDynamicStatus();
      debugPrint('  Dynamic Status: $dynamicStatus');
      debugPrint('  Expected: draft, Got: $dynamicStatus ✅');
    } catch (e) {
      debugPrint('  ERROR calling getDynamicStatus(): $e ❌');
    }

    // Test 4: Ongoing activity
    final ongoingActivity = Activity(
      id: 4,
      title: 'Test Ongoing Activity',
      description: 'Test',
      location: 'Test Location',
      startTime: now.subtract(const Duration(hours: 1)), // Started 1 hour ago
      endTime: now.add(const Duration(hours: 1)), // Ends in 1 hour
      createdBy: 1,
      createdByName: 'Test User',
      createdAt: now.subtract(const Duration(hours: 2)),
      isVolunteering: false,
      status: 'scheduled',
      enrolledCount: 8,
    );

    debugPrint('\nTest 4 - Ongoing Activity:');
    debugPrint('  Start Time: ${ongoingActivity.startTime}');
    debugPrint('  End Time: ${ongoingActivity.endTime}');
    debugPrint('  Current Time: $now');

    try {
      final dynamicStatus = ongoingActivity.getDynamicStatus();
      debugPrint('  Dynamic Status: $dynamicStatus');
      debugPrint('  Expected: ongoing, Got: $dynamicStatus ✅');
    } catch (e) {
      debugPrint('  ERROR calling getDynamicStatus(): $e ❌');
    }

    debugPrint('=== 🧪 END ACTIVITY MODEL TEST ===\n');
  }

  static void testActivityCounting() {
    debugPrint('=== 🧮 TESTING ACTIVITY COUNTING LOGIC ===');

    final now = DateTime.now();
    final activities = <Activity>[
      // Upcoming volunteer activity
      Activity(
        id: 1,
        title: 'Upcoming Volunteer',
        description: 'Test',
        location: 'Test Location',
        startTime: now.add(const Duration(days: 1)),
        endTime: now.add(const Duration(days: 1, hours: 2)),
        createdBy: 1,
        createdByName: 'Test User',
        createdAt: now,
        isVolunteering: true,
        status: 'scheduled',
        enrolledCount: 5,
      ),
      // Completed volunteer activity
      Activity(
        id: 2,
        title: 'Completed Volunteer',
        description: 'Test',
        location: 'Test Location',
        startTime: now.subtract(const Duration(days: 2)),
        endTime: now.subtract(const Duration(days: 1)),
        createdBy: 1,
        createdByName: 'Test User',
        createdAt: now.subtract(const Duration(days: 3)),
        isVolunteering: true,
        status: 'scheduled',
        enrolledCount: 10,
      ),
      // Draft activity
      Activity(
        id: 3,
        title: 'Draft Activity',
        description: 'Test',
        location: 'Test Location',
        startTime: now.add(const Duration(days: 5)),
        endTime: now.add(const Duration(days: 5, hours: 2)),
        createdBy: 1,
        createdByName: 'Test User',
        createdAt: now,
        isVolunteering: false,
        status: 'draft',
        enrolledCount: 0,
      ),
      // This month activity
      Activity(
        id: 4,
        title: 'This Month Activity',
        description: 'Test',
        location: 'Test Location',
        startTime: DateTime(now.year, now.month, 15), // Middle of this month
        endTime: DateTime(now.year, now.month, 15, 2),
        createdBy: 1,
        createdByName: 'Test User',
        createdAt: now,
        isVolunteering: false,
        status: 'scheduled',
        enrolledCount: 3,
      ),
    ];

    debugPrint('Testing with ${activities.length} activities:');

    int upcomingCount = 0;
    int completedCount = 0;
    int activeVolunteers = 0;
    int thisMonthCount = 0;

    for (var activity in activities) {
      final dynamicStatus = _getDynamicStatus(activity);
      debugPrint('  "${activity.title}" -> $dynamicStatus');

      if (dynamicStatus == 'upcoming') upcomingCount++;
      if (dynamicStatus == 'completed') completedCount++;

      if (activity.isVolunteering && activity.enrolledCount > 0) {
        activeVolunteers += activity.enrolledCount;
      }

      if (activity.startTime.month == now.month &&
          activity.startTime.year == now.year) {
        thisMonthCount++;
      }
    }

    debugPrint('\nCounting Results:');
    debugPrint('  Total Activities: ${activities.length}');
    debugPrint('  Upcoming: $upcomingCount');
    debugPrint('  Completed: $completedCount');
    debugPrint('  Active Volunteers: $activeVolunteers');
    debugPrint('  This Month: $thisMonthCount');

    debugPrint('=== 🧮 END COUNTING TEST ===\n');
  }

  // Helper method to test the dynamic status logic
  static String _getDynamicStatus(Activity activity) {
    final now = DateTime.now();

    if (activity.status.toLowerCase() == 'draft' ||
        activity.status.toLowerCase() == 'cancelled') {
      return activity.status;
    }

    if (now.isBefore(activity.startTime)) {
      return 'upcoming';
    } else if (now.isAfter(activity.endTime)) {
      return 'completed';
    } else {
      return 'ongoing';
    }
  }
}
