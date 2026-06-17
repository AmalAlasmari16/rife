import 'package:flutter/material.dart';

import '../../../../core/subscription/subscription_plan.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../data/models/nursery.dart';

class NurseryListTile extends StatelessWidget {
  const NurseryListTile({
    super.key,
    required this.nursery,
    required this.onTap,
  });

  final Nursery nursery;
  final VoidCallback onTap;

  Color _statusColor() {
    switch (nursery.status) {
      case SubscriptionStatus.active:
        return AppColors.success;
      case SubscriptionStatus.trial:
        return AppColors.accent;
      case SubscriptionStatus.expired:
        return AppColors.danger;
    }
  }

  String _statusLabel() {
    switch (nursery.status) {
      case SubscriptionStatus.active:
        return 'مشترك';
      case SubscriptionStatus.trial:
        return 'تجربة';
      case SubscriptionStatus.expired:
        return 'منتهٍ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
                radius: 22,
                backgroundColor: AppColors.primaryLight,
                child: const Icon(Icons.business_outlined,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nursery.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${nursery.plan.arabicName} · ${nursery.childrenCount} طفلاً'
                      '${nursery.createdAt == null ? "" : " · سُجّلت ${RifqDateUtils.shortDate(nursery.createdAt!)}"}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor().withOpacity(0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _statusLabel(),
                  style: TextStyle(
                    color: _statusColor(),
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
