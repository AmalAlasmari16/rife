import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/subscription/access_control.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/subscription_providers.dart';

/// Decides whether to render [child] based on a feature predicate on
/// [AccessControl]. When access is denied the [denied] widget is shown
/// — usually an upgrade prompt.
///
/// Example:
/// ```dart
/// SubscriptionGate(
///   require: (ac) => ac.canUseAiReports,
///   denied: const UpgradePrompt(feature: 'تقارير الذكاء الاصطناعي'),
///   child: AiReportButton(),
/// )
/// ```
class SubscriptionGate extends ConsumerWidget {
  const SubscriptionGate({
    super.key,
    required this.require,
    required this.child,
    this.denied,
  });

  final bool Function(AccessControl) require;
  final Widget child;
  final Widget? denied;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = ref.watch(accessControlProvider);
    if (ac == null) return const SizedBox.shrink();
    return require(ac) ? child : (denied ?? const SizedBox.shrink());
  }
}

/// Generic "this is a paid feature" prompt used as the default `denied`
/// state for [SubscriptionGate].
class UpgradePrompt extends StatelessWidget {
  const UpgradePrompt({
    super.key,
    required this.feature,
    this.onUpgrade,
  });

  final String feature;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_outlined,
              color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$feature متاحة في الخطط الأعلى',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (onUpgrade != null)
            TextButton(onPressed: onUpgrade, child: const Text('ترقية')),
        ],
      ),
    );
  }
}
