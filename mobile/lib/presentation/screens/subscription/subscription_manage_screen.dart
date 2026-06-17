import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/subscription/subscription_plan.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/subscription_providers.dart';
import '../../router/routes.dart';
import '../../widgets/loading_view.dart';

/// In-app subscription management for nursery admins. Shows the current
/// plan, trial / renewal countdown, and a button to open the paywall when
/// they want to upgrade or downgrade.
class SubscriptionManageScreen extends ConsumerWidget {
  const SubscriptionManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nurseryAsync = ref.watch(currentNurseryProvider);
    final ac = ref.watch(accessControlProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('اشتراكي')),
      body: nurseryAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (nursery) {
          if (nursery == null) return const LoadingView();
          final inTrial = ac?.snapshot.isInTrial ?? false;
          final daysLeft = ac?.snapshot.daysLeftInTrial ?? 0;
          final expiry = nursery.subscriptionExpiry;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
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
                      'خطتك الحالية',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      nursery.plan.arabicName,
                      style: textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${nursery.plan.monthlyPrice} ريال / شهرياً',
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _StatusTile(
                icon: inTrial
                    ? Icons.celebration_outlined
                    : Icons.workspace_premium_outlined,
                title: inTrial
                    ? 'تجربتك المجانية فعّالة'
                    : 'اشتراكك ${nursery.status.toFirestore() == "active" ? "فعّال" : "منتهي"}',
                subtitle: inTrial
                    ? (daysLeft > 0
                        ? 'متبقي $daysLeft يوماً'
                        : 'تنتهي اليوم')
                    : (expiry == null
                        ? '—'
                        : 'يتجدد في ${RifqDateUtils.shortDate(expiry)}'),
              ),
              const SizedBox(height: 12),
              _StatusTile(
                icon: Icons.child_care_outlined,
                title: 'الأطفال المسجّلون',
                subtitle: nursery.plan.maxChildren == null
                    ? '${nursery.childrenCount} طفلاً (بدون حد)'
                    : '${nursery.childrenCount} / ${nursery.plan.maxChildren} طفلاً',
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.upgrade),
                label: const Text('تغيير الخطة'),
                onPressed: () => context.push(Routes.paywall),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.support_agent_outlined),
                label: Text(
                  nursery.plan == SubscriptionPlan.premium
                      ? 'الدعم المخصص'
                      : 'الدعم',
                ),
                onPressed: () {},
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryLight,
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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
