import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/nursery_data_providers.dart';
import '../../../providers/subscription_providers.dart';
import '../../router/routes.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/subscription_gate.dart';
import '../super_admin/widgets/stat_tile.dart';

class AdminHomeTab extends ConsumerWidget {
  const AdminHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nursery = ref.watch(currentNurseryProvider).valueOrNull;
    final children = ref.watch(childrenProvider).valueOrNull;
    final classrooms = ref.watch(classroomsProvider).valueOrNull;
    final staff = ref.watch(staffProvider).valueOrNull;
    final textTheme = Theme.of(context).textTheme;

    if (nursery == null) return const LoadingView();
    final cap = nursery.plan.maxChildren;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                'مرحباً بك في',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                nursery.name,
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'الخطة: ${nursery.plan.arabicName}',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.4,
          children: [
            StatTile(
              label: 'الأطفال',
              value: '${children?.length ?? 0}'
                  '${cap == null ? "" : " / $cap"}',
              icon: Icons.child_care_outlined,
            ),
            StatTile(
              label: 'الفصول',
              value: '${classrooms?.length ?? 0}',
              icon: Icons.meeting_room_outlined,
              tint: AppColors.accent,
            ),
            StatTile(
              label: 'المعلمات',
              value: '${staff?.length ?? 0}',
              icon: Icons.badge_outlined,
              tint: AppColors.success,
            ),
            StatTile(
              label: 'أيام التجربة المتبقية',
              value: '${(ref.watch(accessControlProvider)?.snapshot.daysLeftInTrial ?? 0).clamp(0, 30)}',
              icon: Icons.timer_outlined,
              tint: AppColors.info,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SubscriptionGate(
          require: (ac) => ac.canUseBilling,
          denied: const UpgradePrompt(feature: 'الفوترة'),
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push(Routes.billing),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.receipt_long_outlined,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الفوترة',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'إصدار الفواتير الشهرية ومتابعة المدفوعات',
                            style:
                                TextStyle(color: AppColors.textSecondary),
                          ),
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
        ),
      ],
    );
  }
}
