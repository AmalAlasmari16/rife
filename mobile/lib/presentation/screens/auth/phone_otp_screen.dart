import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/app_user.dart';
import '../../../data/models/invite.dart';
import '../../../data/models/user_role.dart';
import '../../../providers/repository_providers.dart';
import '../../widgets/brand_scaffold.dart';

/// Args passed via go_router's `extra`. When [invite] is set, successful
/// OTP verification redeems the invite and creates the corresponding
/// teacher/parent profile.
class PhoneOtpArgs {
  const PhoneOtpArgs({this.invite});
  final Invite? invite;
}

class PhoneOtpScreen extends ConsumerStatefulWidget {
  const PhoneOtpScreen({super.key, required this.args});

  final PhoneOtpArgs args;

  @override
  ConsumerState<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

enum _Stage { enterPhone, enterCode }

class _PhoneOtpScreenState extends ConsumerState<PhoneOtpScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  _Stage _stage = _Stage.enterPhone;
  String? _verificationId;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.args.invite?.phone != null) {
      _phoneCtrl.text = widget.args.invite!.phone!;
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  String _normalizePhone(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('+')) return trimmed;
    if (trimmed.startsWith('05')) return '+966${trimmed.substring(1)}';
    if (trimmed.startsWith('5')) return '+966$trimmed';
    return '+966$trimmed';
  }

  Future<void> _sendCode() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      setState(() => _error = 'أدخل رقم الجوال');
      return;
    }
    final phone = _normalizePhone(_phoneCtrl.text);
    if (widget.args.invite?.phone != null &&
        widget.args.invite!.phone != phone) {
      setState(() => _error = 'الرقم لا يطابق رقم الدعوة');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.sendPhoneOtp(
      phoneE164: phone,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _stage = _Stage.enterCode;
          _busy = false;
        });
      },
      onFailed: (e) {
        if (!mounted) return;
        setState(() {
          _error = _mapPhoneError(e);
          _busy = false;
        });
      },
      onAutoSignIn: (_) => _afterSignIn(),
    );
  }

  Future<void> _confirmCode() async {
    if (_verificationId == null || _otpCtrl.text.trim().length < 4) {
      setState(() => _error = 'أدخل رمز التحقق');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).confirmPhoneOtp(
            verificationId: _verificationId!,
            smsCode: _otpCtrl.text,
          );
      await _afterSignIn();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = _mapPhoneError(e);
        _busy = false;
      });
    }
  }

  Future<void> _afterSignIn() async {
    final invite = widget.args.invite;
    final firebaseUser = ref.read(authRepositoryProvider).currentUser;
    if (firebaseUser == null) return;

    if (invite != null) {
      final name = _nameCtrl.text.trim().isEmpty
          ? (invite.role == UserRole.teacher ? 'معلمة' : 'ولي أمر')
          : _nameCtrl.text.trim();

      await ref.read(userRepositoryProvider).createIfMissing(AppUser(
            id: firebaseUser.uid,
            name: name,
            role: invite.role,
            nurseryId: invite.nurseryId,
            phone: firebaseUser.phoneNumber,
            classroomId: invite.classroomId,
            childIds: invite.childId == null ? const [] : [invite.childId!],
          ));

      await ref.read(inviteRepositoryProvider).markRedeemed(
            invite: invite,
            redeemedByUid: firebaseUser.uid,
          );
    }
    // Router redirect picks up from here.
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isCodeStage = _stage == _Stage.enterCode;

    return BrandScaffold(
      title: 'التحقق برقم الجوال',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            isCodeStage ? 'أدخل رمز التحقق' : 'أدخل رقم جوالك',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isCodeStage
                ? 'أرسلنا رمزاً مكوّناً من 6 أرقام إلى ${_phoneCtrl.text}'
                : 'سنرسل لك رمز تحقق عبر رسالة نصية',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (!isCodeStage) ...[
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الجوال',
                hintText: '05XXXXXXXX',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            if (widget.args.invite != null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسمك',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
            ],
          ] else ...[
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: textTheme.headlineSmall?.copyWith(letterSpacing: 8),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                hintText: '------',
                counterText: '',
              ),
            ),
          ],
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
            onPressed: _busy ? null : (isCodeStage ? _confirmCode : _sendCode),
            child: _busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(isCodeStage ? 'تأكيد' : 'إرسال الرمز'),
          ),
          if (isCodeStage) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _stage = _Stage.enterPhone;
                        _otpCtrl.clear();
                        _verificationId = null;
                      }),
              child: const Text('تغيير الرقم'),
            ),
          ],
        ],
      ),
    );
  }
}

String _mapPhoneError(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-phone-number':
      return 'رقم الجوال غير صحيح';
    case 'invalid-verification-code':
      return 'رمز التحقق غير صحيح';
    case 'session-expired':
      return 'انتهت صلاحية الرمز. اطلب رمزاً جديداً';
    case 'too-many-requests':
      return 'محاولات كثيرة. حاول لاحقاً';
    case 'network-request-failed':
      return 'تحقق من اتصالك بالإنترنت';
    default:
      return e.message ?? 'تعذّر التحقق';
  }
}
