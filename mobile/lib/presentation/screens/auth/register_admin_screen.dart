import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/app_user.dart';
import '../../../data/models/user_role.dart';
import '../../../providers/repository_providers.dart';
import '../../widgets/brand_scaffold.dart';

/// Self-service registration for nursery directors. Creates the Firebase
/// Auth account, the `/users/{uid}` profile, and the `/nurseries/{nid}`
/// tenant document in a single flow. The plan-selection screen (step 3)
/// runs immediately after.
class RegisterAdminScreen extends ConsumerStatefulWidget {
  const RegisterAdminScreen({super.key});

  @override
  ConsumerState<RegisterAdminScreen> createState() =>
      _RegisterAdminScreenState();
}

class _RegisterAdminScreenState extends ConsumerState<RegisterAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nurseryCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nurseryCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final authRepo = ref.read(authRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);
    final nurseryRepo = ref.read(nurseryRepositoryProvider);

    try {
      final cred = await authRepo.registerWithEmail(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        displayName: _nameCtrl.text.trim(),
      );
      final uid = cred.user!.uid;

      final nursery = await nurseryRepo.createForAdmin(
        name: _nurseryCtrl.text.trim(),
        ownerUid: uid,
        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      );

      await userRepo.createIfMissing(AppUser(
        id: uid,
        name: _nameCtrl.text.trim(),
        role: UserRole.admin,
        nurseryId: nursery.id,
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty
            ? null
            : _phoneCtrl.text.trim(),
      ));

      // Router redirect takes over from here.
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mapRegisterError(e));
    } catch (e) {
      setState(() => _error = 'تعذّر إنشاء الحساب. حاول مجدداً.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return BrandScaffold(
      title: 'تسجيل حضانة جديدة',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ابدأ تجربتك المجانية لمدة 30 يوماً',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'اسمك',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'أدخل اسمك الكامل'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nurseryCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم الحضانة',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'أدخل اسم الحضانة'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cityCtrl,
              decoration: const InputDecoration(
                labelText: 'المدينة (اختياري)',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'أدخل بريداً صحيحاً'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'الجوال (اختياري)',
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: '+9665XXXXXXXX',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) => (v == null || v.length < 6)
                  ? 'كلمة المرور يجب ألا تقل عن 6 أحرف'
                  : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
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
                  : const Text('إنشاء الحساب'),
            ),
            const SizedBox(height: 16),
            Text(
              'بإنشاء الحساب توافق على شروط الاستخدام وسياسة الخصوصية.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

String _mapRegisterError(FirebaseAuthException e) {
  switch (e.code) {
    case 'email-already-in-use':
      return 'هذا البريد مسجّل مسبقاً';
    case 'invalid-email':
      return 'البريد الإلكتروني غير صحيح';
    case 'weak-password':
      return 'كلمة المرور ضعيفة';
    case 'network-request-failed':
      return 'تحقق من اتصالك بالإنترنت';
    default:
      return e.message ?? 'تعذّر إنشاء الحساب';
  }
}
