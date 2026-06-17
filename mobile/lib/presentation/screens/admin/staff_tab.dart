import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/classroom.dart';
import '../../../data/models/user_role.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/nursery_data_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../widgets/loading_view.dart';
import 'invite_code_dialog.dart';

class StaffTab extends ConsumerWidget {
  const StaffTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffProvider);
    final classrooms = ref.watch(classroomsProvider).valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: staffAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (staff) {
          if (staff.isEmpty) {
            return _Empty(onAdd: () => _openInvite(context, ref, classrooms));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: staff.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final t = staff[i];
              final classroom = classrooms.firstWhere(
                (c) => c.id == t.classroomId,
                orElse: () =>
                    const Classroom(id: '', name: '—', capacity: 0),
              );
              return _StaffTile(staff: t, classroomName: classroom.name);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openInvite(context, ref, classrooms),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('دعوة معلمة'),
      ),
    );
  }

  Future<void> _openInvite(
    BuildContext context,
    WidgetRef ref,
    List<Classroom> classrooms,
  ) async {
    final result = await showModalBottomSheet<_InviteResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _InviteTeacherForm(classrooms: classrooms),
    );
    if (result == null) return;

    final nurseryId =
        ref.read(currentUserProvider).valueOrNull?.nurseryId;
    if (nurseryId == null) return;

    final invite = await ref.read(inviteRepositoryProvider).create(
          nurseryId: nurseryId,
          role: UserRole.teacher,
          classroomId: result.classroomId,
          phone: result.phone,
        );
    if (!context.mounted) return;
    await InviteCodeDialog.show(
      context,
      invite.code,
      role: UserRole.teacher,
    );
  }
}

class _StaffTile extends StatelessWidget {
  const _StaffTile({required this.staff, required this.classroomName});

  final AppUser staff;
  final String classroomName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.info.withOpacity(0.15),
            child: const Icon(Icons.school_outlined, color: AppColors.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    'معلمة',
                    if (staff.classroomId != null) 'فصل $classroomName',
                  ].join(' · '),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
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
            const Icon(Icons.badge_outlined,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'لا يوجد موظفون بعد',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'ادعُ معلماتك للانضمام عبر رمز الدعوة',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_alt),
              label: const Text('دعوة معلمة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteResult {
  const _InviteResult({this.classroomId, this.phone});
  final String? classroomId;
  final String? phone;
}

class _InviteTeacherForm extends StatefulWidget {
  const _InviteTeacherForm({required this.classrooms});
  final List<Classroom> classrooms;

  @override
  State<_InviteTeacherForm> createState() => _InviteTeacherFormState();
}

class _InviteTeacherFormState extends State<_InviteTeacherForm> {
  String? _classroomId;
  final _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
            'دعوة معلمة جديدة',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            'سننشئ رمز دعوة لمرة واحدة تستخدمه المعلمة عند تسجيل الدخول.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _classroomId,
            decoration: const InputDecoration(
              labelText: 'الفصل (اختياري)',
              prefixIcon: Icon(Icons.meeting_room_outlined),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('بدون تخصيص'),
              ),
              for (final c in widget.classrooms)
                DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) => setState(() => _classroomId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'رقم الجوال (اختياري)',
              prefixIcon: Icon(Icons.phone_outlined),
              hintText: '+9665XXXXXXXX',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(
              _InviteResult(
                classroomId: _classroomId,
                phone: _phone.text.trim().isEmpty
                    ? null
                    : _phone.text.trim(),
              ),
            ),
            child: const Text('إنشاء رمز الدعوة'),
          ),
        ],
      ),
    );
  }
}
