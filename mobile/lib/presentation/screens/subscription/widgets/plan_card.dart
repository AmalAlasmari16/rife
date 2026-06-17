import 'package:flutter/material.dart';

import '../../../../core/subscription/subscription_plan.dart';
import '../../../../core/theme/app_colors.dart';

/// Rounded plan card used on the plan-selection screen and the paywall.
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.onTap,
    this.isRecommended = false,
    this.isCurrent = false,
    this.busy = false,
    this.ctaLabel,
  });

  final SubscriptionPlan plan;
  final VoidCallback onTap;
  final bool isRecommended;
  final bool isCurrent;
  final bool busy;
  final String? ctaLabel;

  Color get _tint {
    switch (plan) {
      case SubscriptionPlan.basic:
        return AppColors.planBasic;
      case SubscriptionPlan.standard:
        return AppColors.planStandard;
      case SubscriptionPlan.premium:
        return AppColors.planPremium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cap = plan.maxChildren;
    final highlight = isRecommended;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlight ? AppColors.primary : AppColors.border,
          width: highlight ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (highlight)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(21),
                  topRight: Radius.circular(21),
                ),
              ),
              child: const Text(
                'الأكثر اختياراً',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _tint,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        plan.arabicName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isCurrent)
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 22),
                  ],
                ),
                const SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    style: textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                    children: [
                      TextSpan(text: '${plan.monthlyPrice}'),
                      TextSpan(
                        text: ' ريال',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: ' / شهرياً',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Feature(label: 'حتى ${cap == null ? "∞" : "$cap"} طفلاً'),
                const _Feature(label: 'الحضور والتقرير اليومي'),
                const _Feature(label: 'مشاركة الصور مع الأهالي'),
                _Feature(
                  label: 'الفوترة والإيصالات',
                  enabled: plan.hasBilling,
                ),
                _Feature(
                  label: 'تقارير الذكاء الاصطناعي',
                  enabled: plan.hasAiReports,
                ),
                _Feature(
                  label: 'عدة فروع',
                  enabled: plan.hasMultipleBranches,
                ),
                _Feature(
                  label: 'دعم مخصص',
                  enabled: plan.hasDedicatedSupport,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: busy ? null : onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        highlight ? AppColors.primary : AppColors.primaryLight,
                    foregroundColor:
                        highlight ? Colors.white : AppColors.primary,
                  ),
                  child: busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(ctaLabel ?? 'ابدأ تجربتك المجانية 30 يوم'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.label, this.enabled = true});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            color: enabled ? AppColors.success : AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: enabled
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
                decoration:
                    enabled ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
