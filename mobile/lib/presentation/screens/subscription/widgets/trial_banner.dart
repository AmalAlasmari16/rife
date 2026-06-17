import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/subscription_providers.dart';
import '../../../router/routes.dart';

/// Compact banner that shows trial days remaining at the top of role homes.
/// Tapping opens the subscription-management screen.
class TrialBanner extends ConsumerWidget {
  const TrialBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = ref.watch(accessControlProvider);
    if (ac == null) return const SizedBox.shrink();
    if (!ac.snapshot.isInTrial) return const SizedBox.shrink();

    final days = ac.snapshot.daysLeftInTrial;
    final urgent = days <= 5;
    return Material(
      color: urgent ? AppColors.accentLight : AppColors.primaryLight,
      child: InkWell(
        onTap: () => context.push(Routes.subscriptionManage),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                urgent ? Icons.timer : Icons.celebration_outlined,
                color: urgent ? AppColors.accent : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  days <= 0
                      ? 'تنتهي تجربتك اليوم — اختر خطة الآن'
                      : 'متبقي $days يوماً في تجربتك المجانية',
                  style: TextStyle(
                    color: urgent ? AppColors.accent : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_left, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
