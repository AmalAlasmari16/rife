import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';

/// Renders the QR a parent shows at drop-off / pickup. Encodes a stable
/// payload `rifq://{nurseryId}/{childId}` that the teacher's scanner
/// resolves into an attendance write.
class ChildQrCard extends StatelessWidget {
  const ChildQrCard({
    super.key,
    required this.nurseryId,
    required this.childId,
    required this.childName,
  });

  final String nurseryId;
  final String childId;
  final String childName;

  String get _payload => 'rifq://$nurseryId/$childId';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_2, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'رمز $childName',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          QrImageView(
            data: _payload,
            size: 200,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
          ),
          const SizedBox(height: 10),
          const Text(
            'اعرضي هذا الرمز عند الدخول أو الخروج',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
