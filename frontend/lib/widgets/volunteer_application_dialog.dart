// lib/widgets/volunteer_application_dialog.dart - COMPLETE FIXED VERSION
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/volunteer_provider.dart';

class VolunteerApplicationDialog extends StatefulWidget {
  // FIXED: Updated parameter names to match your usage
  final String title;
  final String description;
  final DateTime dateTime;
  final String location;
  final int durationHours;
  final int activityId;
  final VoidCallback? onSubmit;

  const VolunteerApplicationDialog({
    super.key,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.durationHours,
    required this.activityId,
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
  final _specificRoleController = TextEditingController();
  bool _isSubmitting = false;
  String _selectedAvailability = '';

  // Realistic and focused availability options
  final List<String> _availabilityOptions = [
    'Full event duration',
    'Morning session only',
    'Afternoon session only',
    'Setup phase only',
    'Main event only',
    'Cleanup phase only',
  ];

  @override
  void initState() {
    super.initState();
    // Set realistic default values for better UX
    _motivationController.text =
        'I am interested in volunteering because I enjoy helping others and contributing to community activities. This opportunity aligns with my values and I believe I can make a positive impact.';
  }

  @override
  void dispose() {
    _motivationController.dispose();
    _specificRoleController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAvailability.isEmpty) {
      _showErrorMessage('Please select your availability');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create application data with all necessary fields
      final applicationData = {
        'activity_id': widget.activityId,
        'activity_title': widget.title,
        'activity_datetime': widget.dateTime.toIso8601String(),
        'activity_location': widget.location,
        'motivation': _motivationController.text.trim(),
        'specific_role':
            _specificRoleController.text.trim().isEmpty
                ? 'General volunteer'
                : _specificRoleController.text.trim(),
        'availability': _selectedAvailability,
        'status': 'pending',
        'submitted_at': DateTime.now().toIso8601String(),
      };

      // Submit via the volunteer provider
      final volunteerProvider = Provider.of<VolunteerProvider>(
        context,
        listen: false,
      );
      final success = await volunteerProvider.submitVolunteerApplication(
        applicationData,
      );

      if (!mounted) return;

      if (success) {
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
                        'Role: ${applicationData['specific_role']}',
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
      } else {
        _showErrorMessage('Failed to submit application. Please try again.');
      }
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
        height:
            MediaQuery.of(context).size.height *
            0.75, // Reduced height for better scrolling
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
                        widget.title,
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
            const SizedBox(height: 16),

            // Activity Information Card (Condensed)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activity Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '📅 ${_formatDateTime(widget.dateTime)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade600,
                    ),
                  ),
                  Text(
                    '📍 ${widget.location}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade600,
                    ),
                  ),
                  Text(
                    '⏱️ ${widget.durationHours} hours',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Application Form (More scrollable space)
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preferred Role Field (Simplified)
                      _buildSectionTitle('Preferred Role (Optional)'),
                      TextFormField(
                        controller: _specificRoleController,
                        decoration: InputDecoration(
                          hintText: 'e.g., Event setup, Registration, Cleanup',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.orange),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Availability Selection (Compact)
                      _buildSectionTitle('Your Availability *'),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children:
                              _availabilityOptions
                                  .map(
                                    (option) => RadioListTile<String>(
                                      title: Text(
                                        option,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      value: option,
                                      groupValue: _selectedAvailability,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedAvailability = value!;
                                        });
                                      },
                                      activeColor: Colors.orange,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 0,
                                          ),
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Motivation (Pre-filled with realistic example)
                      _buildSectionTitle('Why do you want to volunteer? *'),
                      TextFormField(
                        controller: _motivationController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.orange),
                          ),
                          contentPadding: const EdgeInsets.all(12),
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
                      const SizedBox(height: 8),
                      Text(
                        'Feel free to edit the text above to personalize your application',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            const SizedBox(height: 16),
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
