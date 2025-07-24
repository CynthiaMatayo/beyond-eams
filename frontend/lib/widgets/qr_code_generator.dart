// lib/widgets/qr_code_generator.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/activity.dart';
import '../services/qr_code_service.dart';

class QRCodeGenerator extends StatelessWidget {
  final Activity activity;
  final double size;

  const QRCodeGenerator({super.key, required this.activity, this.size = 300});

  @override
  Widget build(BuildContext context) {
    final qrData = QRCodeService.generateQRData(activity);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Activity Check-in',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            activity.title,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: size,
            backgroundColor: Colors.white,
            // FIXED: Use dataModuleStyle instead of deprecated foregroundColor
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF5B6DCD),
            ),
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF5B6DCD),
            ),
            errorCorrectionLevel: QrErrorCorrectLevel.M,
            embeddedImage: null, // Could add school logo here
            embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(40, 40)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF5B6DCD).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: Color(0xFF5B6DCD),
                ),
                const SizedBox(width: 8),
                Text(
                  activity.location,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5B6DCD),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Students scan this code to check-in',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
