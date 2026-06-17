import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/classroom.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/nursery_data_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../widgets/loading_view.dart';

class ClassroomsTab extends ConsumerWidget {
  const ClassroomsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classroomsAsync = ref.watch(classroomsProvider);
    final children = ref.watch(childrenProvider).valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: classroomsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (classrooms) {
          if (classrooms.isEmpty) {
            return _Empty(onAdd: () => _openForm(context, ref));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: classrooms.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final c = classrooms[i];
              final used =
                  children.where((ch) => ch.classroomId == c.id).length;
              return _ClassroomTile(
                classroom: c,
                used: used,
                onTap: () => _openForm(context, ref, existing: c),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('إضافة فصل'),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    Classroom? existing,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ClassroomForm(existing: existing),
    );
  }
}

class _ClassroomTile extends StatelessWidget {
  const _ClassroomTile({
    required this.classroom,
    required this.used,
    required this.onTap,
  });

  final Classroom classroom;
  final int used;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final full = used >= classroom.capacity && classroom.capacity > 0;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryLight,
                child: const Icon(Icons.meeting_room_outlined,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classroom.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (classroom.ageRange != null) classroom.ageRange,
                        '$used / ${classroom.capacity} طفلاً',
                      ].whereType<String>().join(' · '),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (full)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'مكتمل',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
            const Icon(Icons.meeting_room_outlined,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'لا توجد فصول بعد',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'ابدأ بإضافة أول فصل لحضانتك',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('إضافة فصل'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassroomForm extends ConsumerStatefulWidget {
  const _ClassroomForm({this.existing});
  final Classroom? existing;

  @override
  ConsumerState<_ClassroomForm> createState() => _ClassroomFormState();
}

class _ClassroomFormState extends ConsumerState<_ClassroomForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _capacity;
  late final TextEditingController _ageRange;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _capacity = TextEditingController(
      text: widget.existing?.capacity.toString() ?? '15',
    );
    _ageRange = TextEditingController(text: widget.existing?.ageRange ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _capacity.dispose();
    _ageRange.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final nurseryId =
        ref.read(currentUserProvider).valueOrNull?.nurseryId;
    if (nurseryId == null) return;

    setState(() => _busy = true);
    final repo = ref.read(classroomRepositoryProvider);
    try {
      if (widget.existing == null) {
        await repo.create(
          nurseryId: nurseryId,
          name: _name.text.trim(),
          capacity: int.parse(_capacity.text.trim()),
          ageRange:
              _ageRange.text.trim().isEmpty ? null : _ageRange.text.trim(),
        );
      } else {
        await repo.update(
          nurseryId: nurseryId,
          classroom: widget.existing!.copyWith(
            name: _name.text.trim(),
            capacity: int.parse(_capacity.text.trim()),
            ageRange:
                _ageRange.text.trim().isEmpty ? null : _ageRange.text.trim(),
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
        title: const Text('حذف الفصل'),
        content: Text('هل أنت متأكد من حذف "${widget.existing!.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busy = true);
    await ref.read(classroomRepositoryProvider).delete(
          nurseryId: nurseryId,
          classroomId: widget.existing!.id,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
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
                isEdit ? 'تعديل الفصل' : 'فصل جديد',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'اسم الفصل',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'أدخل اسماً'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _capacity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'السعة',
                  prefixIcon: Icon(Icons.groups_outlined),
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'أدخل عدداً صحيحاً';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageRange,
                decoration: const InputDecoration(
                  labelText: 'الفئة العمرية (اختياري)',
                  prefixIcon: Icon(Icons.cake_outlined),
                  hintText: 'مثل: 2-3 سنوات',
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
                    : Text(isEdit ? 'حفظ' : 'إنشاء الفصل'),
              ),
              if (isEdit) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _busy ? null : _delete,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('حذف الفصل'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
