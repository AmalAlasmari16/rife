import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/invite.dart';
import '../../../providers/repository_providers.dart';
import '../../router/routes.dart';
import '../../widgets/brand_scaffold.dart';
import 'phone_otp_screen.dart';

/// First half of the teacher/parent onboarding: enter the 6-character invite
/// code the admin shared with them. On success we hand off to the phone-OTP
/// screen carrying the resolved [Invite] so it can finish the redemption.
class InviteCodeScreen extends ConsumerStatefulWidget {
  const InviteCodeScreen({super.key});

  @override
  ConsumerState<InviteCodeScreen> createState() => _InviteCodeScreenState();
}

class _InviteCodeScreenState extends ConsumerState<InviteCodeScreen> {
  final _codeCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final invite =
          await ref.read(inviteRepositoryProvider).lookup(_codeCtrl.text);
      if (invite == null) {
        setState(() => _error = 'رمز الدعوة غير صحيح أو تم استخدامه');
        return;
      }
      if (!mounted) return;
      context.push(
        Routes.phoneOtp,
        extra: PhoneOtpArgs(invite: invite),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return BrandScaffold(
      title: 'رمز الدعوة',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            'أدخل رمز الدعوة',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'استلمتِ الرمز من إدارة الحضانة',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _codeCtrl,
            textAlign: TextAlign.center,
            maxLength: 8,
            textCapitalization: TextCapitalization.characters,
            style: textTheme.headlineSmall?.copyWith(
              letterSpacing: 6,
              fontWeight: FontWeight.w700,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[A-Z0-9a-z]')),
              UpperCaseFormatter(),
            ],
            decoration: const InputDecoration(
              hintText: 'XXXXXX',
              counterText: '',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: textTheme.bodyMedium?.copyWith(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text('متابعة'),
          ),
        ],
      ),
    );
  }
}

class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
