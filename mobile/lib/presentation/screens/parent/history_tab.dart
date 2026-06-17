import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/daily_log.dart';
import '../../../providers/parent_providers.dart';
import '../../widgets/loading_view.dart';

class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(selectedChildHistoryProvider);
    final selected = ref.watch(selectedChildProvider);

    if (selected == null) {
      return const Center(
        child: Text('لا يوجد طفل مرتبط بحسابك',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return historyAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (logs) {
        final withReport = logs
            .where((l) => (l.reportForParent ?? '').isNotEmpty)
            .toList();
        if (withReport.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month_outlined,
                      size: 56, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'لا توجد تقارير سابقة بعد',
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ستظهر تقارير الأيام السابقة هنا بمجرد إرسالها.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: withReport.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _HistoryTile(log: withReport[i]),
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.log});
  final DailyLog log;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              if (log.mood != null)
                Text(log.mood!.emoji,
                    style: const TextStyle(fontSize: 22)),
              if (log.mood != null) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  RifqDateUtils.formatGregorianArabic(log.date),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            log.reportForParent ?? '',
            style: const TextStyle(height: 1.6),
          ),
        ],
      ),
    );
  }
}
