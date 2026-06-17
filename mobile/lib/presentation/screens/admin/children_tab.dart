import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/subscription/subscription_plan.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/child.dart';
import '../../../data/models/classroom.dart';
import '../../../data/models/user_role.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/nursery_data_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/subscription_providers.dart';
import '../../widgets/loading_view.dart';
import 'invite_code_dialog.dart';

class ChildrenTab extends ConsumerWidget {
  const ChildrenTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenProvider);
    final classrooms = ref.watch(classroomsProvider).valueOrNull ?? const [];
    final nursery = ref.watch(currentNurseryProvider).valueOrNull;
    final ac = ref.watch(accessControlProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: childrenAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (children) {
          if (children.isEmpty) {
            return _Empty(
              onAdd: () =>
                  _openForm(context, ref, classrooms: classrooms),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: children.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final c = children[i];
              final classroom = classrooms.firstWhere(
                (cl) => cl.id == c.classroomId,
                orElse: () =>
                    const Classroom(id: '', name: '—', capacity: 0),
              );
              return _ChildTile(
                child: c,
                classroomName: classroom.name,
                onTap: () => _openForm(
                  context,
                  ref,
                  classrooms: classrooms,
                  existing: c,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (ac == null || !ac.canAddChild) {
            _showLimitDialog(context, nursery?.plan);
            return;
          }
          if (classrooms.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('أضف فصلاً أولاً قبل تسجيل الأطفال'),
              ),
            );
            return;
          }
          _openForm(context, ref, classrooms: classrooms);
        },
        icon: const Icon(Icons.add),
        label: const Text('تسجيل طفل'),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    required List<Classroom> classrooms,
    Child? existing,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ChildForm(
        classrooms: classrooms,
        existing: existing,
      ),
    );
  }

  void _showLimitDialog(BuildContext context, SubscriptionPlan? plan) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('وصلت الحد الأقصى'),
        content: Text(
          plan == null
              ? 'لا يمكن إضافة المزيد من الأطفال على الخطة الحالية. قم بالترقية.'
              : 'خطة ${plan.arabicName} تسمح بـ${plan.maxChildren} طفلاً فقط. قم بالترقية للمتابعة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}

class _ChildTile extends StatelessWidget {
  const _ChildTile({
    required this.child,
    required this.classroomName,
    required this.onTap,
  });

  final Child child;
  final String classroomName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.accentLight,
                child: const Icon(Icons.child_care, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        classroomName,
                        if (child.ageLabel != null) child.ageLabel,
                      ].whereType<String>().join(' · '),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (child.parentIds.isEmpty)
                const Tooltip(
                  message: 'لا يوجد ولي أمر مرتبط',
                  child: Icon(Icons.person_off_outlined,
                      color: AppColors.warning, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.child_care_outlined,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'لا يوجد أطفال بعد',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'سجّل أول طفل لبدء استخدام رِفق',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('تسجيل طفل'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildForm extends ConsumerStatefulWidget {
  const _ChildForm({required this.classrooms, this.existing});

  final List<Classroom> classrooms;
  final Child? existing;

  @override
  ConsumerState<_ChildForm> createState() => _ChildFormState();
}

class _ChildFormState extends ConsumerState<_ChildForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _notes;
  late final TextEditingController _allergies;
  DateTime? _dob;
  String? _classroomId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _notes = TextEditingController(text: widget.existing?.notes ?? '');
    _allergies = TextEditingController(
      text: widget.existing?.allergies.join('، ') ?? '',
    );
    _dob = widget.existing?.dateOfBirth;
    _classroomId = widget.existing?.classroomId ??
        (widget.classrooms.isNotEmpty ? widget.classrooms.first.id : null);
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _allergies.dispose();
    super.dispose();
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

  List<String> _parseAllergies() {
    return _allergies.text
        .split(RegExp('[،,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _classroomId == null) return;
    final nurseryId =
        ref.read(currentUserProvider).valueOrNull?.nurseryId;
    if (nurseryId == null) return;

    setState(() => _busy = true);
    final repo = ref.read(childRepositoryProvider);
    try {
      if (widget.existing == null) {
        await repo.create(
          nurseryId: nurseryId,
          name: _name.text.trim(),
          classroomId: _classroomId!,
          dateOfBirth: _dob,
          allergies: _parseAllergies(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
      } else {
        await repo.update(
          nurseryId: nurseryId,
          child: widget.existing!.copyWith(
            name: _name.text.trim(),
            classroomId: _classroomId,
            dateOfBirth: _dob,
            allergies: _parseAllergies(),
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          ),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (widget.existing == null) return;
    final nurseryId =
        ref.read(currentUserProvider).valueOrNull?.nurseryId;
    if (nurseryId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الطفل'),
        content: Text(
          'سيتم حذف ${widget.existing!.name} وكل بياناته من النظام. '
          'هل أنت متأكد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busy = true);
    await ref.read(childRepositoryProvider).delete(
          nurseryId: nurseryId,
          childId: widget.existing!.id,
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _inviteParent() async {
    final nurseryId =
        ref.read(currentUserProvider).valueOrNull?.nurseryId;
    final childId = widget.existing?.id;
    if (nurseryId == null || childId == null) return;

    final invite = await ref.read(inviteRepositoryProvider).create(
          nurseryId: nurseryId,
          role: UserRole.parent,
          childId: childId,
        );
    if (!mounted) return;
    await InviteCodeDialog.show(context, invite.code, role: UserRole.parent);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                isEdit ? 'تعديل بيانات الطفل' : 'تسجيل طفل جديد',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'اسم الطفل',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'أدخل اسماً صحيحاً'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _classroomId,
                decoration: const InputDecoration(
                  labelText: 'الفصل',
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                ),
                items: [
                  for (final c in widget.classrooms)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _classroomId = v),
                validator: (v) => v == null ? 'اختر الفصل' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDob,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'تاريخ الميلاد',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  child: Text(
                    _dob == null
                        ? 'اختر التاريخ'
                        : RifqDateUtils.shortDate(_dob!),
                    style: TextStyle(
                      color: _dob == null
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _allergies,
                decoration: const InputDecoration(
                  labelText: 'الحساسية (اختياري)',
                  prefixIcon: Icon(Icons.medical_information_outlined),
                  hintText: 'افصل بفاصلة، مثل: حليب، فول',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
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
                    : Text(isEdit ? 'حفظ' : 'تسجيل الطفل'),
              ),
              if (isEdit) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _inviteParent,
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('دعوة ولي الأمر'),
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: _busy ? null : _delete,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('حذف الطفل'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
