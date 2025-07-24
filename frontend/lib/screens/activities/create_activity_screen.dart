// lib/screens/activities/create_activity_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/activity.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/activity_request.dart';

class CreateActivityScreen extends StatefulWidget {
  final Activity? activity; // If editing existing activity

  const CreateActivityScreen({super.key, this.activity});

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);

  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);

  bool _isVolunteering = false;
  String _status = 'upcoming';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // If editing existing activity, populate the form
    if (widget.activity != null) {
      _titleController.text = widget.activity!.title;
      _descriptionController.text = widget.activity!.description;
      _locationController.text = widget.activity!.location;

      _startDate = widget.activity!.startTime;
      _startTime = TimeOfDay.fromDateTime(widget.activity!.startTime);

      _endDate = widget.activity!.endTime;
      _endTime = TimeOfDay.fromDateTime(widget.activity!.endTime);

      _isVolunteering = widget.activity!.isVolunteering;
      _status = widget.activity!.status;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  DateTime _getStartDateTime() {
    return DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
  }

  DateTime _getEndDateTime() {
    return DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endTime.hour,
      _endTime.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    // Check if user has coordinator role
    if (user == null || user.role != 'coordinator') {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Activity')),
        body: const Center(
          child: Text('Only coordinators can create activities.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.activity != null ? 'Edit Activity' : 'Create Activity',
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      _buildSectionTitle('Basic Information'),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                        maxLines: 4,
                      ),

                      const SizedBox(height: 16),

                      // Location
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a location';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Start date and time
                      _buildSectionTitle('Schedule'),
                      _buildDateTimePicker(
                        title: 'Start Date & Time',
                        date: _startDate,
                        time: _startTime,
                        onDateChanged:
                            (date) => setState(() => _startDate = date),
                        onTimeChanged:
                            (time) => setState(() => _startTime = time),
                      ),

                      const SizedBox(height: 16),

                      // End date and time
                      _buildDateTimePicker(
                        title: 'End Date & Time',
                        date: _endDate,
                        time: _endTime,
                        onDateChanged:
                            (date) => setState(() => _endDate = date),
                        onTimeChanged:
                            (time) => setState(() => _endTime = time),
                      ),

                      const SizedBox(height: 16),

                      // Error message for date/time validation
                      if (_getStartDateTime().isAfter(_getEndDateTime()))
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'End time must be after start time',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Settings
                      _buildSectionTitle('Settings'),

                      // Volunteering
                      SwitchListTile(
                        title: const Text('Volunteering Activity'),
                        subtitle: const Text(
                          'Students can earn volunteering hours',
                        ),
                        value: _isVolunteering,
                        onChanged:
                            (value) => setState(() => _isVolunteering = value),
                      ),

                      const SizedBox(height: 8),

                      // Status (only for editing)
                      if (widget.activity != null)
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          value: _status,
                          items: const [
                            DropdownMenuItem(
                              value: 'upcoming',
                              child: Text('Upcoming'),
                            ),
                            DropdownMenuItem(
                              value: 'ongoing',
                              child: Text('Ongoing'),
                            ),
                            DropdownMenuItem(
                              value: 'completed',
                              child: Text('Completed'),
                            ),
                            DropdownMenuItem(
                              value: 'cancelled',
                              child: Text('Cancelled'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _status = value);
                            }
                          },
                        ),

                      const SizedBox(height: 32),

                      // Submit button
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: Text(
                            widget.activity != null
                                ? 'Update Activity'
                                : 'Create Activity',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          onPressed: _handleSubmit,
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDateTimePicker({
    required String title,
    required DateTime date,
    required TimeOfDay time,
    required Function(DateTime) onDateChanged,
    required Function(TimeOfDay) onTimeChanged,
  }) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Date picker
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text(dateFormat.format(date)),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );

            if (picked != null) {
              onDateChanged(picked);
            }
          },
        ),

        // Time picker
        ListTile(
          leading: const Icon(Icons.access_time),
          title: Text(time.format(context)),
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time,
            );

            if (picked != null) {
              onTimeChanged(picked);
            }
          },
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate date/time
    if (_getStartDateTime().isAfter(_getEndDateTime())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final activityProvider = Provider.of<ActivityProvider>(
        context,
        listen: false,
      );

      final activityRequest = ActivityCreateRequest(
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        startTime: _getStartDateTime(),
        endTime: _getEndDateTime(),
        isVolunteering: _isVolunteering,
        status: _status,
      );

      bool success;

      if (widget.activity != null) {
        // Update existing activity
        success = await activityProvider.updateActivity(
          widget.activity!.id,
          activityRequest,
        );
      } else {
        // Create new activity
        success = await activityProvider.createActivity(activityRequest);
      }

      if (!mounted) return;

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.activity != null
                  ? 'Activity updated successfully'
                  : 'Activity created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Go back to activity list
        Navigator.pop(context);
      } else {
        // Show error
        final error = activityProvider.error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to save activity'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
