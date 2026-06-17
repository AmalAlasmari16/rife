import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/repository_providers.dart';
import '../../widgets/brand_scaffold.dart';
import '../../widgets/loading_view.dart';

/// Two-step public enrollment flow: enter the nursery's enrollment code,
/// then fill the family details form. Submits to
/// /nurseries/{nurseryId}/enrollments without requiring the family to
/// authenticate — the admin reviews from the waitlist screen.
class PublicEnrollmentScreen extends ConsumerStatefulWidget {
  const PublicEnrollmentScreen({super.key});

  @override
  ConsumerState<PublicEnrollmentScreen> createState() =>
      _PublicEnrollmentScreenState();
}

class _PublicEnrollmentScreenState
    extends ConsumerState<PublicEnrollmentScreen> {
  final _codeCtrl = TextEditingController();
  final _childName = TextEditingController();
  final _parentName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _dob;
  final _docs = <String>{};
  String? _nurseryId;
  bool _busy = false;
  String? _error;
  bool _submitted = false;

  static const _docOptions = <String>[
    'شهادة ميلاد',
    'سجل التطعيمات',
    'تقرير طبي',
    'صورة هوية ولي الأمر',
  ];

  @override
  void dispose() {
    _codeCtrl.dispose();
    _childName.dispose();
    _parentName.dispose();
    _phone.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _resolveCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final id = await ref
        .read(enrollmentRepositoryProvider)
        .resolveCodeToNurseryId(_codeCtrl.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (id == null) {
        _error = 'رمز غير صحيح';
      } else {
        _nurseryId = id;
      }
    });
  }

  Future<void> _submit() async {
    if (_nurseryId == null) return;
    if (_childName.text.trim().isEmpty ||
        _parentName.text.trim().isEmpty ||
        _phone.text.trim().isEmpty) {
      setState(() => _error = 'الرجاء تعبئة الحقول الإلزامية');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(enrollmentRepositoryProvider).submit(
            nurseryId: _nurseryId!,
            childName: _childName.text.trim(),
            parentName: _parentName.text.trim(),
            parentPhone: _phone.text.trim(),
            parentEmail:
                _email.text.trim().isEmpty ? null : _email.text.trim(),
            childDateOfBirth: _dob,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            documents: _docs.toList(),
          );
      if (!mounted) return;
      setState(() => _submitted = true);
    } catch (_) {
      setState(() => _error = 'تعذّر إرسال الطلب. حاول مجدداً.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 8)),
      lastDate: DateTime.now(),
      initialDate: _dob ?? DateTime.now().subtract(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return const _SubmittedView();
    return BrandScaffold(
      title: 'طلب التحاق',
      child: _busy
          ? const LoadingView()
          : _nurseryId == null
              ? _CodeStep(
                  controller: _codeCtrl,
                  error: _error,
                  onSubmit: _resolveCode,
                )
              : _FormStep(
                  childName: _childName,
                  parentName: _parentName,
                  phone: _phone,
                  email: _email,
                  notes: _notes,
                  dob: _dob,
                  docs: _docs,
                  docOptions: _docOptions,
                  error: _error,
                  onPickDob: _pickDob,
                  onDocToggle: (d, sel) {
                    setState(() {
                      if (sel) {
                        _docs.add(d);
                      } else {
                        _docs.remove(d);
                      }
                    });
                  },
                  onSubmit: _submit,
                ),
    );
  }
}

class _CodeStep extends StatelessWidget {
  const _CodeStep({
    required this.controller,
    required this.error,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text(
          'أدخل رمز الحضانة',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'يمكنك الحصول على الرمز من إدارة الحضانة',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: controller,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'XXXXXX',
            counterText: '',
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.danger),
          ),
        ],
        const SizedBox(height: 20),
        ElevatedButton(onPressed: onSubmit, child: const Text('متابعة')),
      ],
    );
  }
}

class _FormStep extends StatelessWidget {
  const _FormStep({
    required this.childName,
    required this.parentName,
    required this.phone,
    required this.email,
    required this.notes,
    required this.dob,
    required this.docs,
    required this.docOptions,
    required this.error,
    required this.onPickDob,
    required this.onDocToggle,
    required this.onSubmit,
  });

  final TextEditingController childName;
  final TextEditingController parentName;
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController notes;
  final DateTime? dob;
  final Set<String> docs;
  final List<String> docOptions;
  final String? error;
  final VoidCallback onPickDob;
  final void Function(String, bool) onDocToggle;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          'بيانات الطلب',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: childName,
          decoration: const InputDecoration(
            labelText: 'اسم الطفل *',
            prefixIcon: Icon(Icons.child_care_outlined),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: onPickDob,
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'تاريخ الميلاد',
              prefixIcon: Icon(Icons.cake_outlined),
            ),
            child: Text(
              dob == null
                  ? 'اختر التاريخ'
                  : RifqDateUtils.shortDate(dob!),
              style: TextStyle(
                color: dob == null
                    ? AppColors.textMuted
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: parentName,
          decoration: const InputDecoration(
            labelText: 'اسم ولي الأمر *',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'رقم الجوال *',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'البريد الإلكتروني (اختياري)',
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: notes,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'ملاحظات (اختياري)',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'المستندات المرفقة',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final d in docOptions)
              FilterChip(
                label: Text(d),
                selected: docs.contains(d),
                onSelected: (sel) => onDocToggle(d, sel),
              ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'حدّد المستندات المتوفرة لديك؛ ستحضرها معك يوم المقابلة.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.danger),
          ),
        ],
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: onSubmit,
          icon: const Icon(Icons.send),
          label: const Text('إرسال الطلب'),
        ),
      ],
    );
  }
}

class _SubmittedView extends StatelessWidget {
  const _SubmittedView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.check_circle,
                      color: AppColors.primary, size: 56),
                ),
                const SizedBox(height: 16),
                Text(
                  'تم استلام طلبك',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ستتواصل معك إدارة الحضانة قريباً.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go('/welcome'),
                  child: const Text('العودة للرئيسية'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
