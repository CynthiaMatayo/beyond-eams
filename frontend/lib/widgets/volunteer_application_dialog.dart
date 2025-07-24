// lib/widgets/volunteer_application_dialog.dart - ENHANCED VERSION WITH STRUCTURED FORM
import 'package:flutter/material.dart';

class VolunteerApplicationDialog extends StatefulWidget {
  final String activityTitle;
  final String activityDescription;
  final DateTime activityDateTime;
  final String activityLocation;
  final int activityDurationHours;
  final VoidCallback? onSubmit;

  const VolunteerApplicationDialog({
    super.key,
    required this.activityTitle,
    required this.activityDescription,
    required this.activityDateTime,
    required this.activityLocation,
    required this.activityDurationHours,
    this.onSubmit,
  });

  @override
  State<VolunteerApplicationDialog> createState() =>
      _VolunteerApplicationDialogState();
}

class _VolunteerApplicationDialogState
    extends State<VolunteerApplicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _motivationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _specificRoleController = TextEditingController();

  bool _isSubmitting = false;
  String _selectedAvailability = '';
  String _selectedCommitment = '';

  // Structured availability options
  final List<String> _availabilityOptions = [
    'Full event duration (${_formatDuration})',
    'Morning session only',
    'Afternoon session only',
    'Evening session only',
    'Setup phase only',
    'Main event only',
    'Cleanup phase only',
  ];

  // Commitment level options
  final List<String> _commitmentOptions = [
    'Full commitment - can work entire duration',
    'Partial commitment - can work 50-75% of time',
    'Limited commitment - can work 25-50% of time',
    'Minimal commitment - can work less than 25% of time',
  ];

  static String get _formatDuration => ''; // Will be filled in initState

  @override
  void initState() {
    super.initState();
    // Update the duration in the first availability option
    _availabilityOptions[0] =
        'Full event duration (${widget.activityDurationHours} hours)';
  }

  @override
  void dispose() {
    _motivationController.dispose();
    _experienceController.dispose();
    _specificRoleController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAvailability.isEmpty) {
      _showErrorMessage('Please select your availability');
      return;
    }

    if (_selectedCommitment.isEmpty) {
      _showErrorMessage('Please select your commitment level');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Enhanced application data with all form fields
      final applicationData = {
        'activity_title': widget.activityTitle,
        'activity_datetime': widget.activityDateTime.toIso8601String(),
        'activity_location': widget.activityLocation,
        'motivation': _motivationController.text.trim(),
        'experience': _experienceController.text.trim(),
        'specific_role': _specificRoleController.text.trim(),
        'availability': _selectedAvailability,
        'commitment_level': _selectedCommitment,
        'submitted_at': DateTime.now().toIso8601String(),
      };

      // TODO: Send this data to the backend via the provider
      debugPrint('📋 Volunteer Application Data: $applicationData');

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Application submitted successfully!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Role: ${_specificRoleController.text.trim().isEmpty ? "General volunteer" : _specificRoleController.text.trim()}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 4),
        ),
      );

      // Call the callback if provided
      if (widget.onSubmit != null) {
        widget.onSubmit!();
      }

      // Close dialog
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('Error submitting application: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.volunteer_activism,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Volunteer Application',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        widget.activityTitle,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Activity Information Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.event,
                        color: Colors.orange.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Activity Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.access_time,
                    'Date & Time',
                    _formatDateTime(widget.activityDateTime),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.location_on,
                    'Location',
                    widget.activityLocation,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.schedule,
                    'Duration',
                    '${widget.activityDurationHours} hours',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Description:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.activityDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Application Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Application Form',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Specific Role/Position Field
                      _buildSectionTitle('Specific Role/Position (Optional)'),
                      TextFormField(
                        controller: _specificRoleController,
                        decoration: InputDecoration(
                          hintText:
                              'e.g., Pianist, MC, Registration assistant, Setup crew...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.orange),
                          ),
                          prefixIcon: const Icon(Icons.work_outline, size: 20),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Specify if you want to volunteer for a particular role',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),

                      // Availability Selection
                      _buildSectionTitle('Your Availability *'),
                      ...(_availabilityOptions.map(
                        (option) => RadioListTile<String>(
                          title: Text(
                            option,
                            style: const TextStyle(fontSize: 14),
                          ),
                          value: option,
                          groupValue: _selectedAvailability,
                          onChanged: (value) {
                            setState(() {
                              _selectedAvailability = value!;
                            });
                          },
                          activeColor: Colors.orange,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      )),
                      const SizedBox(height: 20),

                      // Commitment Level
                      _buildSectionTitle('Commitment Level *'),
                      ...(_commitmentOptions.map(
                        (option) => RadioListTile<String>(
                          title: Text(
                            option,
                            style: const TextStyle(fontSize: 14),
                          ),
                          value: option,
                          groupValue: _selectedCommitment,
                          onChanged: (value) {
                            setState(() {
                              _selectedCommitment = value!;
                            });
                          },
                          activeColor: Colors.orange,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      )),
                      const SizedBox(height: 20),

                      // Motivation
                      _buildSectionTitle(
                        'Why do you want to volunteer for this activity? *',
                      ),
                      TextFormField(
                        controller: _motivationController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText:
                              'Share your motivation and what you hope to contribute...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.orange),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please share your motivation';
                          }
                          if (value.trim().length < 20) {
                            return 'Please provide at least 20 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Experience
                      _buildSectionTitle('Relevant Experience (Optional)'),
                      TextFormField(
                        controller: _experienceController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Any relevant skills, experience, or previous volunteer work...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.orange),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitApplication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        _isSubmitting
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text(
                              'Submit Application',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.orange.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.orange.shade700,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.orange.shade600, fontSize: 13),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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

    final dayName = days[dateTime.weekday - 1];
    final monthName = months[dateTime.month - 1];
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '$dayName, $monthName ${dateTime.day}, ${dateTime.year} at $displayHour:$minute $ampm';
  }
}
