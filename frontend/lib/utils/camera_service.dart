// lib/utils/camera_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static final ImagePicker _picker = ImagePicker();

  // Request camera permissions
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }

  // Take a photo using camera
  static Future<File?> takePhoto() async {
    try {
      final hasPermission = await requestCameraPermission();
      if (!hasPermission) {
        debugPrint('❌ CAMERA: Permission denied');
        return null;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        debugPrint('✅ CAMERA: Photo taken successfully');
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('❌ CAMERA: Error taking photo: $e');
      return null;
    }
  }

  // Pick image from gallery
  static Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        debugPrint('✅ GALLERY: Image selected successfully');
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('❌ GALLERY: Error picking image: $e');
      return null;
    }
  }

  // Show image picker options
  static Future<File?> showImagePickerDialog(BuildContext context) async {
    return showModalBottomSheet<File?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Wrap(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Image',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: const Icon(
                          Icons.camera_alt,
                          color: Colors.indigo,
                        ),
                        title: const Text('Take Photo'),
                        onTap: () async {
                          Navigator.pop(context);
                          final file = await takePhoto();
                          if (context.mounted) {
                            Navigator.pop(context, file);
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.photo_library,
                          color: Colors.indigo,
                        ),
                        title: const Text('Choose from Gallery'),
                        onTap: () async {
                          Navigator.pop(context);
                          final file = await pickFromGallery();
                          if (context.mounted) {
                            Navigator.pop(context, file);
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.cancel, color: Colors.red),
                        title: const Text('Cancel'),
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Example usage in profile screen:
class ProfilePhotoWidget extends StatefulWidget {
  final String? currentPhotoUrl;
  final Function(File) onPhotoSelected;

  const ProfilePhotoWidget({
    super.key,
    this.currentPhotoUrl,
    required this.onPhotoSelected,
  });

  @override
  State<ProfilePhotoWidget> createState() => _ProfilePhotoWidgetState();
}

class _ProfilePhotoWidgetState extends State<ProfilePhotoWidget> {
  File? _selectedImage;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final imageFile = await CameraService.showImagePickerDialog(context);
        if (imageFile != null) {
          setState(() {
            _selectedImage = imageFile;
          });
          widget.onPhotoSelected(imageFile);
        }
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.indigo, width: 3),
          image: _getImageProvider(),
        ),
        child:
            _selectedImage == null && widget.currentPhotoUrl == null
                ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                : null,
      ),
    );
  }

  DecorationImage? _getImageProvider() {
    if (_selectedImage != null) {
      return DecorationImage(
        image: FileImage(_selectedImage!),
        fit: BoxFit.cover,
      );
    } else if (widget.currentPhotoUrl != null) {
      return DecorationImage(
        image: NetworkImage(widget.currentPhotoUrl!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }
}
