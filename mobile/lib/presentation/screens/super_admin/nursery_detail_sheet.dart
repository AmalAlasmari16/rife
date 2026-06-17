import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/subscription/subscription_plan.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/nursery.dart';
import '../../../providers/repository_providers.dart';

/// Bottom sheet shown when the super-admin taps a nursery in the list.
/// Supports manually changing the plan and extending the trial.
class NurseryDetailSheet extends ConsumerStatefulWidget {
  const NurseryDetailSheet({super.key, required this.nursery});

  final Nursery nursery;

  static Future<void> show(BuildContext context, Nursery nursery) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => NurseryDetailSheet(nursery: nursery),
    );
  }

  @override
  ConsumerState<NurseryDetailSheet> createState() =>
      _NurseryDetailSheetState();
}

class _NurseryDetailSheetState extends ConsumerState<NurseryDetailSheet> {
  bool _busy = false;

  Future<void> _setPlan(SubscriptionPlan plan) async {
    setState(() => _busy = true);
    try {
      await ref.read(nurseryRepositoryProvider).selectPlan(
            nurseryId: widget.nursery.id,
            plan: plan,
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _extendTrial() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(nurseryRepositoryProvider)
          .extendTrial(nurseryId: widget.nursery.id);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.nursery;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
              n.name,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (n.city != null) n.city!,
                if (n.createdAt != null)
                  'سُجّلت ${RifqDateUtils.shortDate(n.createdAt!)}',
              ].join(' · '),
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            _row('الخطة الحالية', n.plan.arabicName),
            _row('الحالة', _statusLabel(n.status)),
            _row(
              'الأطفال',
              n.plan.maxChildren == null
                  ? '${n.childrenCount} (بدون حد)'
                  : '${n.childrenCount} / ${n.plan.maxChildren}',
            ),
            _row('عدد الفروع', '${n.branchCount}'),
            if (n.subscriptionExpiry != null)
              _row(
                'تاريخ التجديد',
                RifqDateUtils.shortDate(n.subscriptionExpiry!),
              ),
            const Divider(height: 32),
            Text(
              'تغيير الخطة يدوياً',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final p in SubscriptionPlan.values)
                  ChoiceChip(
                    label: Text(p.arabicName),
                    selected: p == n.plan,
                    onSelected:
                        _busy ? null : (_) => _setPlan(p),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.timer_outlined),
              label: const Text('تمديد التجربة 30 يوماً'),
              onPressed: _busy ? null : _extendTrial,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  String _statusLabel(SubscriptionStatus s) {
    switch (s) {
      case SubscriptionStatus.active:
        return 'مشترك';
      case SubscriptionStatus.trial:
        return 'تجربة';
      case SubscriptionStatus.expired:
        return 'منتهٍ';
    }
  }
}
