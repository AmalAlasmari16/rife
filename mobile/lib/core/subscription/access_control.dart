import 'subscription_plan.dart';

/// Snapshot of a nursery's billing state used by the access-control layer.
class SubscriptionSnapshot {
  const SubscriptionSnapshot({
    required this.plan,
    required this.status,
    required this.trialStartDate,
    required this.trialActive,
    required this.subscriptionExpiry,
    required this.childrenCount,
  });

  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime trialStartDate;
  final bool trialActive;
  final DateTime? subscriptionExpiry;
  final int childrenCount;

  /// Whether the nursery is currently inside its 30-day free trial.
  bool get isInTrial {
    if (!trialActive) return false;
    final endsAt = trialStartDate.add(const Duration(days: 30));
    return DateTime.now().isBefore(endsAt);
  }

  int get daysLeftInTrial {
    final endsAt = trialStartDate.add(const Duration(days: 30));
    return endsAt.difference(DateTime.now()).inDays;
  }
}

/// Reasons we may block a feature for a given nursery.
enum AccessDenyReason {
  trialExpired,
  subscriptionExpired,
  childLimitReached,
  planMissingFeature,
}

/// Pure-Dart access-control rules. The UI layer wraps this in providers; the
/// rules themselves stay testable without Firebase.
class AccessControl {
  const AccessControl(this.snapshot);

  final SubscriptionSnapshot snapshot;

  /// Trial overrides everything — full access for 30 days.
  bool get _trialOverride => snapshot.isInTrial;

  bool get hasAnyAccess {
    if (_trialOverride) return true;
    return snapshot.status == SubscriptionStatus.active;
  }

  AccessDenyReason? get blockingReason {
    if (_trialOverride) return null;
    if (snapshot.status == SubscriptionStatus.expired) {
      return snapshot.trialActive
          ? AccessDenyReason.trialExpired
          : AccessDenyReason.subscriptionExpired;
    }
    return null;
  }

  bool get canAddChild {
    if (!hasAnyAccess) return false;
    final cap = snapshot.plan.maxChildren;
    if (cap == null) return true;
    return snapshot.childrenCount < cap;
  }

  bool get canUseBilling =>
      hasAnyAccess && (_trialOverride || snapshot.plan.hasBilling);

  bool get canUseAiReports =>
      hasAnyAccess && (_trialOverride || snapshot.plan.hasAiReports);

  bool get canUseMultipleBranches =>
      hasAnyAccess && (_trialOverride || snapshot.plan.hasMultipleBranches);
}
