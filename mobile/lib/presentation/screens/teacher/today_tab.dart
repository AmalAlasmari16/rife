import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:collection/collection.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/attendance.dart';
import '../../../data/models/child.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/nursery_data_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/teacher_providers.dart';
import '../../widgets/loading_view.dart';
import 'daily_log_screen.dart';

class TodayTab extends ConsumerWidget {
  const TodayTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final children = ref.watch(teacherClassroomChildrenProvider);
    final attendanceAsync = ref.watch(todayAttendanceProvider);
    final today = ref.watch(todayProvider);
    final classrooms = ref.watch(classroomsProvider).valueOrNull ?? const [];
    final textTheme = Theme.of(context).textTheme;

    final classroomName =
        classrooms.firstWhereOrNull((c) => c.id == user?.classroomId)?.name ??
            'فصلك';

    return attendanceAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (attendance) {
        final present = attendance.statuses.values
            .where((s) =>
                s == AttendanceStatus.present || s == AttendanceStatus.late)
            .length;
        final absent = attendance.statuses.values
            .where((s) => s == AttendanceStatus.absent)
            .length;
        final picked = attendance.statuses.values
            .where((s) => s == AttendanceStatus.picked)
            .length;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todayAttendanceProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classroomName,
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      RifqDateUtils.formatGregorianArabic(today),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _MiniCount(
                            label: 'حاضر', value: present, color: Colors.white),
                        const SizedBox(width: 14),
                        _MiniCount(
                            label: 'غائب',
                            value: absent,
                            color: Colors.white.withOpacity(0.9)),
                        const SizedBox(width: 14),
                        _MiniCount(
                            label: 'تم الاستلام',
                            value: picked,
                            color: Colors.white.withOpacity(0.9)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (children.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'لم يتم تعيينك إلى فصل بعد',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                for (final c in children) ...[
                  _ChildAttendanceTile(
                    child: c,
                    status: attendance.statuses[c.id],
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _MiniCount extends StatelessWidget {
  const _MiniCount(
      {required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: color.withOpacity(0.85), fontSize: 12),
        ),
      ],
    );
  }
}

class _ChildAttendanceTile extends ConsumerWidget {
  const _ChildAttendanceTile({required this.child, this.status});

  final Child child;
  final AttendanceStatus? status;

  Future<void> _setStatus(WidgetRef ref, AttendanceStatus s) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user?.nurseryId == null) return;
    await ref.read(attendanceRepositoryProvider).setStatus(
          nurseryId: user!.nurseryId!,
          date: ref.read(todayProvider),
          childId: child.id,
          status: s,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = switch (status) {
      AttendanceStatus.present => AppColors.success,
      AttendanceStatus.absent => AppColors.danger,
      AttendanceStatus.late => AppColors.warning,
      AttendanceStatus.picked => AppColors.info,
      null => AppColors.textMuted,
    };

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DailyLogScreen(child: child),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(Icons.child_care, color: color),
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
                      status?.arabic ?? 'لم يُسجّل',
                      style: TextStyle(color: color, fontSize: 13),
                    ),
                  ],
                ),
              ),
              _PillButton(
                label: 'حاضر',
                color: AppColors.success,
                selected: status == AttendanceStatus.present,
                onTap: () => _setStatus(ref, AttendanceStatus.present),
              ),
              const SizedBox(width: 6),
              _PillButton(
                label: 'غائب',
                color: AppColors.danger,
                selected: status == AttendanceStatus.absent,
                onTap: () => _setStatus(ref, AttendanceStatus.absent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
