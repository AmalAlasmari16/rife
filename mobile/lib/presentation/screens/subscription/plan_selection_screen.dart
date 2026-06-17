import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/subscription/subscription_plan.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/subscription_providers.dart';
import '../../widgets/loading_view.dart';
import 'widgets/plan_card.dart';

/// Shown once, right after a nursery is created. Picking a plan stamps
/// `planSelectedAt` on the nursery doc; the router then lets the admin into
/// their home. Trial access is identical for all plans for the first 30
/// days, so the choice is mostly a commitment signal.
class PlanSelectionScreen extends ConsumerStatefulWidget {
  const PlanSelectionScreen({super.key});

  @override
  ConsumerState<PlanSelectionScreen> createState() =>
      _PlanSelectionScreenState();
}

class _PlanSelectionScreenState
    extends ConsumerState<PlanSelectionScreen> {
  SubscriptionPlan? _busyPlan;

  Future<void> _pick(SubscriptionPlan plan) async {
    final nursery = ref.read(currentNurseryProvider).valueOrNull;
    if (nursery == null) return;
    setState(() => _busyPlan = plan);
    try {
      await ref.read(nurseryRepositoryProvider).selectPlan(
            nurseryId: nursery.id,
            plan: plan,
          );
      // Router redirect picks it up via the live currentNurseryProvider.
    } finally {
      if (mounted) setState(() => _busyPlan = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final nurseryAsync = ref.watch(currentNurseryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: nurseryAsync.when(
          loading: () => const LoadingView(message: 'جارٍ التحميل…'),
          error: (e, _) => Center(child: Text('خطأ: $e')),
          data: (nursery) {
            if (nursery == null) {
              return const LoadingView(message: 'جارٍ تجهيز حضانتك…');
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'اختر الخطة المناسبة لحضانتك',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'جميع الخطط تتضمن تجربة مجانية لمدة 30 يوماً '
                    'بكامل الميزات',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PlanCard(
                    plan: SubscriptionPlan.basic,
                    onTap: () => _pick(SubscriptionPlan.basic),
                    busy: _busyPlan == SubscriptionPlan.basic,
                  ),
                  const SizedBox(height: 16),
                  PlanCard(
                    plan: SubscriptionPlan.standard,
                    isRecommended: true,
                    onTap: () => _pick(SubscriptionPlan.standard),
                    busy: _busyPlan == SubscriptionPlan.standard,
                  ),
                  const SizedBox(height: 16),
                  PlanCard(
                    plan: SubscriptionPlan.premium,
                    onTap: () => _pick(SubscriptionPlan.premium),
                    busy: _busyPlan == SubscriptionPlan.premium,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'يمكنك تغيير الخطة في أي وقت من إعدادات الاشتراك.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
