import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_role.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../widgets/brand_scaffold.dart';
import '../../widgets/loading_view.dart';

/// Generic self-service profile screen. Visible to every role from the
/// shell app bar. Parents also see the emergency-contact + Hijri toggle
/// rows.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  bool _preferHijri = false;
  bool _busy = false;
  bool _seeded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      final updated = user.copyWith(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        emergencyContactName: _emergencyNameCtrl.text.trim().isEmpty
            ? null
            : _emergencyNameCtrl.text.trim(),
        emergencyContactPhone: _emergencyPhoneCtrl.text.trim().isEmpty
            ? null
            : _emergencyPhoneCtrl.text.trim(),
        preferHijri: _preferHijri,
      );
      await ref.read(userRepositoryProvider).update(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ التغييرات')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر الحفظ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    return BrandScaffold(
      title: 'حسابي',
      child: userAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => Text('خطأ: $e'),
        data: (user) {
          if (user == null) return const LoadingView();
          if (!_seeded) {
            _nameCtrl.text = user.name;
            _phoneCtrl.text = user.phone ?? '';
            _emergencyNameCtrl.text = user.emergencyContactName ?? '';
            _emergencyPhoneCtrl.text = user.emergencyContactPhone ?? '';
            _preferHijri = user.preferHijri;
            _seeded = true;
          }

          final isParent = user.role == UserRole.parent;
          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      user.name.isEmpty ? '؟' : user.name.characters.first,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    user.role.arabicName,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الاسم',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'أدخل اسمك'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم الجوال',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                if (user.email != null) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: user.email,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                ],
                if (isParent) ...[
                  const Divider(height: 32),
                  Text(
                    'جهة اتصال للطوارئ',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'يتم الاتصال بها عند تعذّر الوصول إليك أثناء الاستلام أو الطوارئ.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emergencyNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
                      prefixIcon: Icon(Icons.contact_emergency_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emergencyPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الجوال',
                      prefixIcon: Icon(Icons.phone_in_talk_outlined),
                    ),
                  ),
                  const Divider(height: 32),
                  SwitchListTile(
                    value: _preferHijri,
                    onChanged: (v) => setState(() => _preferHijri = v),
                    title: const Text('استخدام التقويم الهجري'),
                    subtitle: const Text(
                      'يُعرض التاريخ بالهجري في شاشات الأرشيف والإيصالات.',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('حفظ'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل الخروج'),
                  onPressed: () =>
                      ref.read(authRepositoryProvider).signOut(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
