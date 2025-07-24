// lib/screens/attendance/qr_code_display_screen.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';

class QRCodeDisplayScreen extends StatefulWidget {
  final int activityId;
  final String activityTitle;

  const QRCodeDisplayScreen({
    super.key,
    required this.activityId,
    required this.activityTitle,
  });

  @override
  State<QRCodeDisplayScreen> createState() => _QRCodeDisplayScreenState();
}

class _QRCodeDisplayScreenState extends State<QRCodeDisplayScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _qrCodeData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQRCode();
  }

  Future<void> _loadQRCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(
        context,
        listen: false,
      );

      // Use the correct method name from AttendanceProvider
      final result = await attendanceProvider.generateAttendanceQR(
        widget.activityId,
      );

      if (result != null) {
        setState(() {
          _qrCodeData = result;
        });
      } else {
        setState(() {
          _error = attendanceProvider.error ?? 'Failed to load QR code';
        });
      }
    } catch (e) {
      debugPrint(
        'Error loading QR code: $e',
      ); // Fixed: Use debugPrint instead of print
      setState(() {
        _error = 'Error loading QR code: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _generateNewQRCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final attendanceProvider = Provider.of<AttendanceProvider>(
        context,
        listen: false,
      );

      // Use the correct method name from AttendanceProvider
      final result = await attendanceProvider.generateAttendanceQR(
        widget.activityId,
      );

      if (result != null) {
        setState(() {
          _qrCodeData = result;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New QR code generated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final error = attendanceProvider.error ?? 'Failed to generate QR code';
        setState(() {
          _error = error;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    // Check if user has instructor or coordinator role
    if (user == null ||
        (user.role != 'instructor' &&
            user.role != 'coordinator' &&
            user.role != 'admin')) {
      return Scaffold(
        appBar: AppBar(title: const Text('QR Code')),
        body: const Center(
          child: Text('Only instructors and coordinators can view QR codes.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance QR Code'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Generate New QR Code',
            onPressed: _isLoading ? null : _generateNewQRCode,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _qrCodeData == null
              ? _buildErrorState(_error)
              : _buildQRCodeView(_qrCodeData!),
    );
  }

  Widget _buildErrorState(String? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              error ?? 'Failed to load QR code.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.red[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadQRCode,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _generateNewQRCode,
              icon: const Icon(Icons.qr_code),
              label: const Text('Generate QR Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeView(Map<String, dynamic> qrCodeData) {
    // Extract QR code information from the response
    final qrCode = qrCodeData['qr_code'] ?? '';
    final qrImage = qrCodeData['qr_image'];
    final expiresAt = qrCodeData['expires_at'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Activity info
          Text(
            widget.activityTitle,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Students scan this QR code to mark attendance',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child:
                qrCode.isNotEmpty
                    ? QrImageView(
                      data: qrCode,
                      version: QrVersions.auto,
                      size: 250,
                      backgroundColor: Colors.white,
                      errorStateBuilder: (context, error) {
                        return Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: Colors.red, size: 48),
                                SizedBox(height: 8),
                                Text(
                                  'Failed to generate QR code',
                                  style: TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                    : Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Text('No QR code available')),
                    ),
          ),
          const SizedBox(height: 24),

          // QR Code details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QR Code Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Activity ID:', widget.activityId.toString()),
                const SizedBox(height: 8),
                _buildInfoRow('Generated:', _formatDateTime(DateTime.now())),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Expires:',
                  expiresAt != null
                      ? _formatDateTime(DateTime.parse(expiresAt))
                      : 'Never',
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Status:', 'Active', color: Colors.green),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Code:',
                  qrCode.isNotEmpty ? qrCode : 'No code available',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Show this QR code to students\n'
                  '2. Students scan using their mobile app\n'
                  '3. Attendance is automatically recorded\n'
                  '4. Generate new code if needed for security',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Generate new QR code button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _generateNewQRCode,
              icon:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.refresh),
              label: Text(
                _isLoading ? 'Generating...' : 'Generate New QR Code',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: color),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
