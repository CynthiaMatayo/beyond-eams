// lib/screens/coordinator/create_activity_screen.dart - COMPLETE UPDATED VERSION
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../services/coordinator_service.dart';
import '../../models/activity.dart';
import '../../providers/coordinator_provider.dart';

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({super.key});
  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _virtualLinkController = TextEditingController();

  bool _isLoading = false;
  bool _isVolunteering = false;
  bool _isVirtual = false;
  bool _isFeatured = false;
  bool _certificateAvailable = false;

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _endTime = const TimeOfDay(hour: 14, minute: 0);
  DateTime? _registrationDeadline;

  String _selectedCategory = 'Academic';
  String _selectedDifficulty = 'Beginner';
  int _pointsReward = 10;
  File? _posterImage;

  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'Academic',
    'Sports',
    'Cultural',
    'Technology',
    'Community Service',
    'Leadership',
    'Arts & Crafts',
    'Health & Wellness',
    'Career Development',
    'Environmental',
  ];

  final List<String> _difficulties = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    final endHour = (now.hour + 2) % 24;
    _endTime = TimeOfDay(hour: endHour, minute: now.minute);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    _requirementsController.dispose();
    _virtualLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (image != null) {
        setState(() {
          _posterImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.orange),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.orange),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _selectRegistrationDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _registrationDeadline ?? _startDate.subtract(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: _startDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.orange),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _registrationDeadline = picked;
      });
    }
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _createActivity() async {
    if (!_formKey.currentState!.validate()) return;

    final startDateTime = _combineDateTime(_startDate, _startTime);
    final endDateTime = _combineDateTime(_endDate, _endTime);

    if (endDateTime.isBefore(startDateTime) ||
        endDateTime.isAtSameMomentAs(startDateTime)) {
      _showErrorSnackBar('End time must be after start time');
      return;
    }

    if (_isVirtual && _virtualLinkController.text.isEmpty) {
      _showErrorSnackBar('Virtual link is required for virtual activities');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final activity = Activity(
        id: 0,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startTime: startDateTime,
        endTime: endDateTime,
        location: _isVirtual ? 'Virtual' : _locationController.text.trim(),
        createdBy: 2,
        createdByName: 'Michael Mayaka',
        createdAt: DateTime.now(),
        isVolunteering: _isVolunteering,
        status: 'upcoming',
        enrolledCount: 0,
      );

      final coordinatorService = CoordinatorService();
      await coordinatorService.createActivity(activity, {
        'category': _selectedCategory,
        'difficulty': _selectedDifficulty,
        'maxParticipants': _maxParticipantsController.text.isNotEmpty
            ? int.parse(_maxParticipantsController.text)
            : null,
        'requirements': _requirementsController.text.trim(),
        'virtualLink': _isVirtual ? _virtualLinkController.text.trim() : null,
        'isVirtual': _isVirtual,
        'isFeatured': _isFeatured,
        'certificateAvailable': _certificateAvailable,
        'pointsReward': _pointsReward,
        'registrationDeadline': _registrationDeadline,
        'posterImage': _posterImage,
      });

      if (mounted) {
        // FIXED: Force refresh all data before navigating
        final coordinatorProvider = context.read<CoordinatorProvider>();
        await coordinatorProvider.loadMyActivities();
        
        // Navigate back to dashboard
        Navigator.popUntil(context, (route) => route.isFirst);
        
        _showSuccessSnackBar('Activity created successfully!');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to create activity: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Create Activity',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createActivity,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'CREATE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 16),
              _buildSchedulingSection(),
              const SizedBox(height: 16),
              _buildLocationSection(),
              const SizedBox(height: 16),
              _buildDetailsSection(),
              const SizedBox(height: 16),
              _buildImageSection(),
              const SizedBox(height: 16),
              _buildSettingsSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Basic Information',
      icon: Icons.info_outline,
      children: [
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Activity Title',
            labelStyle: TextStyle(fontSize: 14),
            hintText: 'Enter title',
            hintStyle: TextStyle(fontSize: 12),
            prefixIcon: Icon(Icons.title, size: 20),
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.all(12),
          ),
          style: const TextStyle(fontSize: 14),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Title is required';
            }
            if (value.trim().length < 3) {
              return 'Title must be at least 3 characters';
            }
            return null;
          },
          maxLength: 200,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            labelStyle: TextStyle(fontSize: 14),
            hintText: 'Describe your activity',
            hintStyle: TextStyle(fontSize: 12),
            prefixIcon: Icon(Icons.description, size: 20),
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.all(12),
          ),
          style: const TextStyle(fontSize: 14),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Description is required';
            }
            if (value.trim().length < 10) {
              return 'Description must be at least 10 characters';
            }
            return null;
          },
          maxLength: 1000,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(fontSize: 14),
                  prefixIcon: Icon(Icons.category, size: 20),
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                style: const TextStyle(fontSize: 14, color: Colors.black),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedDifficulty,
                decoration: const InputDecoration(
                  labelText: 'Difficulty',
                  labelStyle: TextStyle(fontSize: 14),
                  prefixIcon: Icon(Icons.bar_chart, size: 20),
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                style: const TextStyle(fontSize: 14, color: Colors.black),
                items: _difficulties.map((difficulty) {
                  return DropdownMenuItem(
                    value: difficulty,
                    child: Text(
                      difficulty,
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDifficulty = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSchedulingSection() {
    return _buildSection(
      title: 'Scheduling',
      icon: Icons.schedule,
      children: [
        Column(
          children: [
            _buildDateTimeField(
              label: 'Start Date',
              date: _startDate,
              time: _startTime,
              onDateTap: () => _selectDate(context, true),
              onTimeTap: () => _selectTime(context, true),
            ),
            const SizedBox(height: 12),
            _buildDateTimeField(
              label: 'End Date',
              date: _endDate,
              time: _endTime,
              onDateTap: () => _selectDate(context, false),
              onTimeTap: () => _selectTime(context, false),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _selectRegistrationDeadline,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_available, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registration Deadline (Optional)',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Text(
                        _registrationDeadline != null
                            ? '${_registrationDeadline!.day}/${_registrationDeadline!.month}/${_registrationDeadline!.year}'
                            : 'Set deadline',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (_registrationDeadline != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      setState(() {
                        _registrationDeadline = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return _buildSection(
      title: 'Location',
      icon: Icons.location_on,
      children: [
        SwitchListTile(
          title: const Text('Virtual Activity', style: TextStyle(fontSize: 14)),
          subtitle: const Text(
            'This activity will be conducted online',
            style: TextStyle(fontSize: 12),
          ),
          value: _isVirtual,
          onChanged: (value) {
            setState(() {
              _isVirtual = value;
            });
          },
          activeColor: Colors.orange,
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        if (_isVirtual)
          TextFormField(
            controller: _virtualLinkController,
            decoration: const InputDecoration(
              labelText: 'Virtual Meeting Link',
              labelStyle: TextStyle(fontSize: 14),
              hintText: 'https://zoom.us/j/...',
              hintStyle: TextStyle(fontSize: 12),
              prefixIcon: Icon(Icons.link, size: 20),
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.all(12),
            ),
            style: const TextStyle(fontSize: 14),
            validator: _isVirtual
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Virtual link is required';
                    }
                    return null;
                  }
                : null,
          )
        else
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Physical Location',
              labelStyle: TextStyle(fontSize: 14),
              hintText: 'Room 101, Main Building',
              hintStyle: TextStyle(fontSize: 12),
              prefixIcon: Icon(Icons.place, size: 20),
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.all(12),
            ),
            style: const TextStyle(fontSize: 14),
            validator: !_isVirtual
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Location is required';
                    }
                    return null;
                  }
                : null,
          ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return _buildSection(
      title: 'Additional Details',
      icon: Icons.details,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _maxParticipantsController,
                decoration: const InputDecoration(
                  labelText: 'Max Participants',
                  labelStyle: TextStyle(fontSize: 14),
                  hintText: '50',
                  hintStyle: TextStyle(fontSize: 12),
                  prefixIcon: Icon(Icons.people, size: 20),
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.all(12),
                ),
                style: const TextStyle(fontSize: 14),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final num = int.tryParse(value);
                    if (num == null || num <= 0) {
                      return 'Enter a valid number';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Points Reward',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Slider(
                      value: _pointsReward.toDouble(),
                      min: 5,
                      max: 50,
                      divisions: 9,
                      label: '$_pointsReward pts',
                      activeColor: Colors.orange,
                      onChanged: (value) {
                        setState(() {
                          _pointsReward = value.round();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _requirementsController,
          decoration: const InputDecoration(
            labelText: 'Requirements (Optional)',
            labelStyle: TextStyle(fontSize: 14),
            hintText: 'Prerequisites, materials needed, etc.',
            hintStyle: TextStyle(fontSize: 12),
            prefixIcon: Icon(Icons.checklist, size: 20),
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.all(12),
          ),
          style: const TextStyle(fontSize: 14),
          maxLines: 3,
          maxLength: 500,
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return _buildSection(
      title: 'Activity Poster',
      icon: Icons.image,
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: _posterImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Container(
                            width: double.infinity,
                            height: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[200],
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Image selected',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'Preview not available on web',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            height: 150,
                            child: Image.file(
                              _posterImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 150,
                            ),
                          ),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 40,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap to add poster image',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      Text(
                        'Optional but recommended',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
          ),
        ),
        if (_posterImage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _posterImage = null;
                });
              },
              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
              label: const Text(
                'Remove Image',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return _buildSection(
      title: 'Activity Settings',
      icon: Icons.settings,
      children: [
        SwitchListTile(
          title: const Text(
            'Volunteering Activity',
            style: TextStyle(fontSize: 14),
          ),
          subtitle: const Text(
            'Mark this as a volunteering opportunity',
            style: TextStyle(fontSize: 12),
          ),
          value: _isVolunteering,
          onChanged: (value) {
            setState(() {
              _isVolunteering = value;
            });
          },
          activeColor: Colors.orange,
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text(
            'Featured Activity',
            style: TextStyle(fontSize: 14),
          ),
          subtitle: const Text(
            'Highlight this activity on the main page',
            style: TextStyle(fontSize: 12),
          ),
          value: _isFeatured,
          onChanged: (value) {
            setState(() {
              _isFeatured = value;
            });
          },
          activeColor: Colors.orange,
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text(
            'Certificate Available',
            style: TextStyle(fontSize: 14),
          ),
          subtitle: const Text(
            'Participants will receive a certificate',
            style: TextStyle(fontSize: 12),
          ),
          value: _certificateAvailable,
          onChanged: (value) {
            setState(() {
              _certificateAvailable = value;
            });
          },
          activeColor: Colors.orange,
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required DateTime date,
    required TimeOfDay time,
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: onDateTap,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${date.day}/${date.month}/${date.year}',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: onTimeTap,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          time.format(context),
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
