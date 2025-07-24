// lib/screens/activities/activity_qr_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';

class ActivityQRScreen extends StatefulWidget {
  const ActivityQRScreen({super.key});

  @override
  State<ActivityQRScreen> createState() => _ActivityQRScreenState();
}

class _ActivityQRScreenState extends State<ActivityQRScreen> {
  MobileScannerController? _controller;
  bool _isScanning = true;
  bool _isProcessing = false;
  String? _lastScannedCode;
  Map<String, dynamic>? _activityData;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
    // Get activity data if passed as arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        setState(() {
          _activityData = args;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning || _isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code == _lastScannedCode) return;

    setState(() {
      _isProcessing = true;
      _isScanning = false;
      _lastScannedCode = code;
    });

    await _processQRCode(code);
  }

  Future<void> _processQRCode(String code) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final activityProvider = Provider.of<ActivityProvider>(
        context,
        listen: false,
      );

      if (authProvider.user == null) {
        _showErrorDialog('Authentication Error', 'Please login first');
        return;
      }

      // Show processing dialog
      _showProcessingDialog();

      // Process the QR code for activity check-in
      final result = await activityProvider.checkInWithQR(
        code,
        authProvider.user!.id,
      );

      // Hide processing dialog
      if (mounted) Navigator.of(context).pop();

      if (result['success']) {
        _showSuccessDialog(
          'Check-in Successful!',
          result['message'] ??
              'You have successfully checked in to the activity.',
          result['activity_title'] ?? 'Activity',
        );
      } else {
        _showErrorDialog(
          'Check-in Failed',
          result['message'] ?? 'Failed to check in. Please try again.',
        );
      }
    } catch (e) {
      // Hide processing dialog if still showing
      if (mounted) Navigator.of(context).pop();
      _showErrorDialog('Error', 'An error occurred: ${e.toString()}');
    }
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF3F51B5)),
            const SizedBox(height: 16),
            const Text('Processing QR Code...'),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String title, String message, String activityTitle) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.green)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activityTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanner();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'Scan Another',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanner();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F51B5),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _isProcessing = false;
      _lastScannedCode = null;
    });
  }

  void _toggleFlash() {
    _controller?.toggleTorch();
  }

  Widget _buildCornerIndicator({
    required bool showTop,
    required bool showRight,
    required bool showBottom,
    required bool showLeft,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: showTop
              ? const BorderSide(color: Color(0xFF3F51B5), width: 6)
              : BorderSide.none,
          right: showRight
              ? const BorderSide(color: Color(0xFF3F51B5), width: 6)
              : BorderSide.none,
          bottom: showBottom
              ? const BorderSide(color: Color(0xFF3F51B5), width: 6)
              : BorderSide.none,
          left: showLeft
              ? const BorderSide(color: Color(0xFF3F51B5), width: 6)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Simple app bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(6, 16, 6, 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'QR Check-in',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_activityData != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _activityData!['title'] ?? 'Activity',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.flash_on,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: _toggleFlash,
                ),
              ],
            ),
          ),
          // Scanner section
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: Stack(
                children: [
                  // QR Scanner
                  if (_controller != null)
                    MobileScanner(
                      controller: _controller!,
                      onDetect: _onDetect,
                    ),
                  // Overlay with scan area
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: SafeArea(
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height * 0.4,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              // Scan frame
                              Container(
                                width: 250,
                                height: 250,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFF3F51B5),
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                            child: Stack(
                              children: [
                                // Corner indicators
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: _buildCornerIndicator(
                                    showTop: true,
                                    showRight: false,
                                    showBottom: false,
                                    showLeft: true,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: _buildCornerIndicator(
                                    showTop: true,
                                    showRight: true,
                                    showBottom: false,
                                    showLeft: false,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  child: _buildCornerIndicator(
                                    showTop: false,
                                    showRight: false,
                                    showBottom: true,
                                    showLeft: true,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: _buildCornerIndicator(
                                    showTop: false,
                                    showRight: true,
                                    showBottom: true,
                                    showLeft: false,
                                  ),
                                ),
                                // Scanning animation line
                                if (_isScanning && !_isProcessing)
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(17),
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        duration: const Duration(seconds: 2),
                                        builder: (context, value, child) {
                                          return Stack(
                                            children: [
                                              Positioned(
                                                top: value * 220,
                                                left: 20,
                                                right: 20,
                                                child: Container(
                                                  height: 3,
                                                  decoration: BoxDecoration(
                                                    gradient:
                                                        const LinearGradient(
                                                      colors: [
                                                        Colors.transparent,
                                                        Color(0xFF3F51B5),
                                                        Colors.transparent,
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(2),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                        onEnd: () {
                                          if (_isScanning && !_isProcessing) {
                                            setState(() {});
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Instructions
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.center_focus_strong,
                                  size: 24,
                                  color: Color(0xFF3F51B5),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Position QR code within the frame',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hold steady and ensure good lighting',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Manual entry button
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isProcessing ? null : _showManualEntryDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3F51B5),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Enter Code Manually',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                        ),
                      ),
                    ),
                  ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog() {
    final TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Enter QR Code'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            hintText: 'Enter QR code manually',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.of(context).pop();
                _processQRCode(code);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F51B5),
            ),
            child: const Text(
              'Submit',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}