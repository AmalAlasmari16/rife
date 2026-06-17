import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/attendance.dart';
import '../../../data/models/daily_log.dart';
import '../../../data/models/invoice.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/invoice_providers.dart';
import '../../../providers/parent_providers.dart';
import '../../../providers/teacher_providers.dart';
import '../../router/routes.dart';
import '../../widgets/child_qr_card.dart';
import '../../widgets/loading_view.dart';

class ParentHomeTab extends ConsumerWidget {
  const ParentHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(parentChildrenProvider);
    final selected = ref.watch(selectedChildProvider);
    final selectedId = ref.watch(selectedChildIdProvider);
    final logAsync = ref.watch(selectedChildTodayLogProvider);
    final attendanceAsync = ref.watch(todayAttendanceProvider);
    final today = ref.watch(todayProvider);
    final textTheme = Theme.of(context).textTheme;

    if (children.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.child_care_outlined,
                  size: 56, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                'لا يوجد طفل مرتبط بحسابك بعد',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'تواصل مع إدارة الحضانة للحصول على رابط الربط.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(selectedChildTodayLogProvider);
        ref.invalidate(todayAttendanceProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (children.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final c in children)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(c.name),
                          selected: selectedId == c.id,
                          onSelected: (_) =>
                              ref.read(selectedChildIdProvider.notifier).state =
                                  c.id,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (selected != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    RifqDateUtils.formatGregorianArabic(today),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    RifqDateUtils.formatHijri(today),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    selected.name,
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (selected.ageLabel != null)
                    Text(
                      selected.ageLabel!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            attendanceAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (att) {
                final status =
                    att.statuses[selected.id] ?? AttendanceStatus.absent;
                return _AttendanceCard(
                  status: status,
                  checkIn: att.checkInTimes[selected.id],
                  checkOut: att.checkOutTimes[selected.id],
                );
              },
            ),
            const SizedBox(height: 16),
            logAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: LoadingView(),
              ),
              error: (e, _) => Text('خطأ: $e'),
              data: (log) {
                if (log == null) return const SizedBox.shrink();
                return _TodaysReport(log: log);
              },
            ),
            const SizedBox(height: 16),
            Builder(builder: (context) {
              final invoices =
                  ref.watch(selectedChildInvoicesProvider).valueOrNull ??
                      const <Invoice>[];
              final unpaid = invoices
                  .where((i) =>
                      i.status == InvoiceStatus.unpaid ||
                      i.status == InvoiceStatus.overdue)
                  .toList();
              if (unpaid.isEmpty) return const SizedBox.shrink();
              final total =
                  unpaid.fold<int>(0, (a, b) => a + b.amount);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.push(Routes.parentInvoices),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.danger.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFFFE3E3),
                            child: Icon(Icons.receipt_long_outlined,
                                color: AppColors.danger),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'فواتير مستحقة',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.danger,
                                  ),
                                ),
                                Text('$total ريال · ${unpaid.length} فاتورة'),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_left,
                              color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            Builder(builder: (context) {
              final user = ref.watch(currentUserProvider).valueOrNull;
              if (user?.nurseryId == null) return const SizedBox.shrink();
              return ChildQrCard(
                nurseryId: user!.nurseryId!,
                childId: selected.id,
                childName: selected.name,
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({
    required this.status,
    this.checkIn,
    this.checkOut,
  });

  final AttendanceStatus status;
  final DateTime? checkIn;
  final DateTime? checkOut;

  Color _color() {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.late:
        return AppColors.warning;
      case AttendanceStatus.picked:
        return AppColors.info;
      case AttendanceStatus.absent:
        return AppColors.danger;
    }
  }

  IconData _icon() {
    switch (status) {
      case AttendanceStatus.present:
      case AttendanceStatus.late:
        return Icons.check_circle_outline;
      case AttendanceStatus.picked:
        return Icons.directions_walk_outlined;
      case AttendanceStatus.absent:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(_icon(), color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.arabic,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (checkIn != null || checkOut != null)
                  Text(
                    [
                      if (checkIn != null)
                        'الدخول ${RifqDateUtils.time(checkIn!)}',
                      if (checkOut != null)
                        'الخروج ${RifqDateUtils.time(checkOut!)}',
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

class _TodaysReport extends StatelessWidget {
  const _TodaysReport({required this.log});
  final DailyLog log;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasReport = (log.reportForParent ?? '').isNotEmpty;
    final highlights = <Widget>[];

    if (log.mood != null) {
      highlights.add(_HighlightChip(
        icon: log.mood!.emoji,
        label: 'المزاج: ${log.mood!.arabic}',
      ));
    }
    if (log.meals.isNotEmpty) {
      highlights.add(_HighlightChip(
        icon: '🍎',
        label: '${log.meals.length} وجبات',
      ));
    }
    if (log.naps.isNotEmpty) {
      final total = log.naps
          .map((n) => n.duration?.inMinutes ?? 0)
          .fold<int>(0, (a, b) => a + b);
      highlights.add(_HighlightChip(
        icon: '💤',
        label: total > 0 ? 'نوم $total دقيقة' : '${log.naps.length} فترات نوم',
      ));
    }
    if (log.activities.isNotEmpty) {
      highlights.add(_HighlightChip(
        icon: '🎨',
        label: '${log.activities.length} أنشطة',
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (highlights.isNotEmpty) ...[
          Wrap(spacing: 8, runSpacing: 8, children: highlights),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.description_outlined,
                      color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'تقرير اليوم',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (log.sentAt != null)
                    Text(
                      RifqDateUtils.time(log.sentAt!),
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                hasReport
                    ? log.reportForParent!
                    : 'لم تكتب المعلمة تقرير اليوم بعد. سيظهر هنا بمجرد إرساله.',
                style: textTheme.bodyLarge?.copyWith(
                  color: hasReport
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
        if (log.incidents.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: AppColors.danger),
                    SizedBox(width: 8),
                    Text(
                      'تنبيه',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                for (final inc in log.incidents)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('• $inc'),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _HighlightChip extends StatelessWidget {
  const _HighlightChip({required this.icon, required this.label});
  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
