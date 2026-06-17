import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/repository_providers.dart';
import '../../widgets/brand_scaffold.dart';
import '../../widgets/rifq_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithEmail(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
          );
      // Router redirect handles the rest.
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mapAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return BrandScaffold(
      title: 'تسجيل الدخول',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            const Center(child: RifqLogo()),
            const SizedBox(height: 24),
            Text(
              'أهلاً بعودتك',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
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
                  : const Text('دخول'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy
                  ? null
                  : () async {
                      final email = _emailCtrl.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        setState(() => _error =
                            'أدخل بريدك الإلكتروني لإرسال رابط إعادة التعيين');
                        return;
                      }
                      await ref
                          .read(authRepositoryProvider)
                          .sendPasswordReset(email);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم إرسال رابط إعادة التعيين'),
                        ),
                      );
                    },
              child: const Text('نسيت كلمة المرور؟'),
            ),
          ],
        ),
      ),
    );
  }
}

String _mapAuthError(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'البريد الإلكتروني غير صحيح';
    case 'user-disabled':
      return 'تم تعطيل هذا الحساب';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'البريد أو كلمة المرور غير صحيحة';
    case 'too-many-requests':
      return 'محاولات كثيرة. حاول لاحقاً';
    case 'network-request-failed':
      return 'تحقق من اتصالك بالإنترنت';
    default:
      return e.message ?? 'تعذّر تسجيل الدخول';
  }
}
