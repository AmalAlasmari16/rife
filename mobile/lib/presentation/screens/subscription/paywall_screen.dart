import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/subscription/access_control.dart';
import '../../../core/subscription/subscription_plan.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/subscription_providers.dart';
import '../../widgets/loading_view.dart';
import 'widgets/plan_card.dart';

/// Hard paywall — the only screen accessible when [AccessControl.hasAnyAccess]
/// is false, or when [AccessControl.canAddChild] blocks a tier-specific
/// operation. The payment buttons are placeholders until a real gateway is
/// wired up.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.reason});

  /// Override the reason shown at the top of the screen. When `null`, the
  /// reason is derived from [AccessControl.blockingReason].
  final AccessDenyReason? reason;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  SubscriptionPlan? _busyPlan;

  Future<void> _activate(SubscriptionPlan plan) async {
    final nursery = ref.read(currentNurseryProvider).valueOrNull;
    if (nursery == null) return;
    setState(() => _busyPlan = plan);
    try {
      // Payment processing is intentionally stubbed — calling this directly
      // simulates a successful Mada/STC charge for the chosen plan.
      await ref.read(nurseryRepositoryProvider).activateSubscription(
            nurseryId: nursery.id,
            plan: plan,
          );
    } finally {
      if (mounted) setState(() => _busyPlan = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ac = ref.watch(accessControlProvider);
    final nursery = ref.watch(currentNurseryProvider).valueOrNull;
    final reason = widget.reason ?? ac?.blockingReason;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ترقية الاشتراك'),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: nursery == null
          ? const LoadingView()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ReasonBanner(reason: reason, currentPlan: nursery.plan),
                  const SizedBox(height: 20),
                  Text(
                    'اختر خطة لمواصلة استخدام رِفق',
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  PlanCard(
                    plan: SubscriptionPlan.basic,
                    ctaLabel: 'اشترك في الأساسي',
                    onTap: () => _activate(SubscriptionPlan.basic),
                    busy: _busyPlan == SubscriptionPlan.basic,
                  ),
                  const SizedBox(height: 16),
                  PlanCard(
                    plan: SubscriptionPlan.standard,
                    isRecommended: true,
                    ctaLabel: 'اشترك في المتوسط',
                    onTap: () => _activate(SubscriptionPlan.standard),
                    busy: _busyPlan == SubscriptionPlan.standard,
                  ),
                  const SizedBox(height: 16),
                  PlanCard(
                    plan: SubscriptionPlan.premium,
                    ctaLabel: 'اشترك في البريميوم',
                    onTap: () => _activate(SubscriptionPlan.premium),
                    busy: _busyPlan == SubscriptionPlan.premium,
                  ),
                  const SizedBox(height: 24),
                  const _PaymentMethodsRow(),
                ],
              ),
            ),
    );
  }
}

class _ReasonBanner extends StatelessWidget {
  const _ReasonBanner({required this.reason, required this.currentPlan});

  final AccessDenyReason? reason;
  final SubscriptionPlan currentPlan;

  @override
  Widget build(BuildContext context) {
    final (icon, headline, body) = switch (reason) {
      AccessDenyReason.trialExpired => (
          Icons.timer_off_outlined,
          'انتهت تجربتك المجانية',
          'استمر باستخدام رِفق باختيار خطة تناسب حضانتك.',
        ),
      AccessDenyReason.subscriptionExpired => (
          Icons.lock_outline,
          'انتهى اشتراكك',
          'جدّد اشتراكك للوصول إلى بيانات حضانتك مرة أخرى.',
        ),
      AccessDenyReason.childLimitReached => (
          Icons.group_off_outlined,
          'وصلت الحد الأقصى لخطة ${currentPlan.arabicName}',
          'قم بالترقية لإضافة المزيد من الأطفال.',
        ),
      AccessDenyReason.planMissingFeature => (
          Icons.upgrade,
          'هذه الميزة غير متاحة في خطتك',
          'الترقية تفتح كامل ميزات رِفق.',
        ),
      null => (
          Icons.workspace_premium_outlined,
          'ترقية خطتك',
          '',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodsRow extends StatelessWidget {
  const _PaymentMethodsRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'طرق الدفع المقبولة',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: const [
            _PaymentChip(label: 'مدى'),
            _PaymentChip(label: 'STC Pay'),
            _PaymentChip(label: 'تحويل بنكي'),
          ],
        ),
      ],
    );
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
