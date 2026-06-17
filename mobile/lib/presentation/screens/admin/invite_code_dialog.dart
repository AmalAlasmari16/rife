import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_role.dart';

/// Dialog shown after an invite is created — the admin shares this code with
/// the teacher / parent so they can redeem it on the invite-code screen.
class InviteCodeDialog extends StatelessWidget {
  const InviteCodeDialog({super.key, required this.code, required this.role});

  final String code;
  final UserRole role;

  static Future<void> show(BuildContext context, String code,
      {required UserRole role}) {
    return showDialog<void>(
      context: context,
      builder: (_) => InviteCodeDialog(code: code, role: role),
    );
  }

  String get _audience {
    switch (role) {
      case UserRole.teacher:
        return 'المعلمة';
      case UserRole.parent:
        return 'ولي الأمر';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text('رمز دعوة $_audience'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'شارك هذا الرمز فقط مع الشخص المعني. الرمز يُستخدم مرة واحدة.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              code,
              textAlign: TextAlign.center,
              style: textTheme.displaySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 6,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم النسخ')),
                    );
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('نسخ'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('تم'),
        ),
      ],
    );
  }
}
