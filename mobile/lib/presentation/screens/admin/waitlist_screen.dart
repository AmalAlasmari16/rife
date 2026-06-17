import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/enrollment_application.dart';
import '../../../data/models/user_role.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/nursery_data_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../widgets/loading_view.dart';

final _waitlistProvider =
    StreamProvider.autoDispose<List<EnrollmentApplication>>((ref) async* {
  final nurseryId =
      ref.watch(currentUserProvider).valueOrNull?.nurseryId;
  if (nurseryId == null) {
    yield const [];
    return;
  }
  yield* ref.watch(enrollmentRepositoryProvider).watchAll(nurseryId);
});

class WaitlistScreen extends ConsumerStatefulWidget {
  const WaitlistScreen({super.key});

  @override
  ConsumerState<WaitlistScreen> createState() => _WaitlistScreenState();
}

class _WaitlistScreenState extends ConsumerState<WaitlistScreen> {
  EnrollmentStatus? _filter = EnrollmentStatus.pending;

  @override
  Widget build(BuildContext context) {
    final apps = ref.watch(_waitlistProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('قائمة الانتظار')),
      body: apps.when(
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (list) {
          final filtered = list.where((a) {
            if (_filter == null) return true;
            return a.status == _filter;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    _Chip(
                      label: 'الكل',
                      selected: _filter == null,
                      onSelected: () => setState(() => _filter = null),
                    ),
                    for (final s in EnrollmentStatus.values)
                      _Chip(
                        label: s.arabic,
                        selected: _filter == s,
                        onSelected: () => setState(() => _filter = s),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const _Empty()
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) => _AppTile(
                          application: filtered[i],
                          onApprove: () => _approve(filtered[i]),
                          onReject: () => _reject(filtered[i]),
                          onWaitlist: () => _waitlist(filtered[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _approve(EnrollmentApplication app) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user?.nurseryId == null) return;

    final classrooms = ref.read(classroomsProvider).valueOrNull ?? const [];
    if (classrooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('أضف فصلاً أولاً قبل قبول الطلب')),
      );
      return;
    }
    final classroomId = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'اختر الفصل لربط الطفل به',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            for (final c in classrooms)
              ListTile(
                title: Text(c.name),
                subtitle: Text('السعة ${c.capacity}'),
                onTap: () => Navigator.of(context).pop(c.id),
              ),
          ],
        ),
      ),
    );
    if (classroomId == null) return;

    final child = await ref.read(childRepositoryProvider).create(
          nurseryId: user!.nurseryId!,
          name: app.childName,
          classroomId: classroomId,
          dateOfBirth: app.childDateOfBirth,
        );

    await ref.read(enrollmentRepositoryProvider).setStatus(
          nurseryId: user.nurseryId!,
          applicationId: app.id,
          status: EnrollmentStatus.approved,
          decidedBy: user.id,
          convertedChildId: child.id,
        );

    // Auto-create a parent invite tied to the new child so the family can
    // sign in immediately.
    await ref.read(inviteRepositoryProvider).create(
          nurseryId: user.nurseryId!,
          role: UserRole.parent,
          childId: child.id,
          phone: app.parentPhone.isEmpty ? null : app.parentPhone,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم قبول ${app.childName} وإصدار دعوة لولي الأمر')),
    );
  }

  Future<void> _reject(EnrollmentApplication app) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user?.nurseryId == null) return;
    await ref.read(enrollmentRepositoryProvider).setStatus(
          nurseryId: user!.nurseryId!,
          applicationId: app.id,
          status: EnrollmentStatus.rejected,
          decidedBy: user.id,
        );
  }

  Future<void> _waitlist(EnrollmentApplication app) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user?.nurseryId == null) return;
    await ref.read(enrollmentRepositoryProvider).setStatus(
          nurseryId: user!.nurseryId!,
          applicationId: app.id,
          status: EnrollmentStatus.waitlisted,
          decidedBy: user.id,
        );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'لا توجد طلبات',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  const _AppTile({
    required this.application,
    required this.onApprove,
    required this.onReject,
    required this.onWaitlist,
  });

  final EnrollmentApplication application;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onWaitlist;

  Color _statusColor() {
    switch (application.status) {
      case EnrollmentStatus.pending:
        return AppColors.warning;
      case EnrollmentStatus.waitlisted:
        return AppColors.info;
      case EnrollmentStatus.approved:
        return AppColors.success;
      case EnrollmentStatus.rejected:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.childName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ولي الأمر: ${application.parentName} · '
                      '${application.parentPhone}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    if (application.childDateOfBirth != null)
                      Text(
                        'مواليد ${RifqDateUtils.shortDate(application.childDateOfBirth!)}',
                        style: const TextStyle(
                            color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  application.status.arabic,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (application.documents.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final d in application.documents)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(d,
                        style: const TextStyle(
                            color: AppColors.primary, fontSize: 12)),
                  ),
              ],
            ),
          ],
          if (application.notes != null) ...[
            const SizedBox(height: 8),
            Text(
              application.notes!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
          if (application.status == EnrollmentStatus.pending ||
              application.status == EnrollmentStatus.waitlisted) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text('قبول'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onWaitlist,
                    icon: const Icon(Icons.schedule),
                    label: const Text('انتظار'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onReject,
                  icon: const Icon(Icons.cancel_outlined,
                      color: AppColors.danger),
                  tooltip: 'رفض',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
