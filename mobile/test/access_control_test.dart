import 'package:flutter_test/flutter_test.dart';
import 'package:rifq/core/subscription/access_control.dart';
import 'package:rifq/core/subscription/subscription_plan.dart';

SubscriptionSnapshot _snapshot({
  SubscriptionPlan plan = SubscriptionPlan.basic,
  SubscriptionStatus status = SubscriptionStatus.active,
  int childrenCount = 0,
  bool trialActive = false,
  DateTime? trialStart,
  DateTime? expiry,
}) {
  return SubscriptionSnapshot(
    plan: plan,
    status: status,
    trialStartDate: trialStart ?? DateTime(2000),
    trialActive: trialActive,
    subscriptionExpiry: expiry,
    childrenCount: childrenCount,
  );
}

void main() {
  group('Trial override', () {
    test('unlocks AI + billing on basic plan during trial', () {
      final ac = AccessControl(_snapshot(
        plan: SubscriptionPlan.basic,
        status: SubscriptionStatus.trial,
        trialActive: true,
        trialStart: DateTime.now(),
      ));
      expect(ac.hasAnyAccess, isTrue);
      expect(ac.canUseAiReports, isTrue);
      expect(ac.canUseBilling, isTrue);
      expect(ac.canUseMultipleBranches, isTrue);
    });

    test('expires after 30 days', () {
      final ac = AccessControl(_snapshot(
        plan: SubscriptionPlan.basic,
        status: SubscriptionStatus.expired,
        trialActive: true,
        trialStart: DateTime.now().subtract(const Duration(days: 31)),
      ));
      expect(ac.hasAnyAccess, isFalse);
      expect(ac.blockingReason, AccessDenyReason.trialExpired);
    });
  });

  group('Child limits', () {
    test('basic plan blocks 30th child', () {
      final ac = AccessControl(_snapshot(
        plan: SubscriptionPlan.basic,
        childrenCount: 30,
      ));
      expect(ac.canAddChild, isFalse);
    });

    test('standard plan blocks 80th child', () {
      final ac = AccessControl(_snapshot(
        plan: SubscriptionPlan.standard,
        childrenCount: 80,
      ));
      expect(ac.canAddChild, isFalse);
    });

    test('premium plan is unlimited', () {
      final ac = AccessControl(_snapshot(
        plan: SubscriptionPlan.premium,
        childrenCount: 9999,
      ));
      expect(ac.canAddChild, isTrue);
    });
  });

  group('Plan features', () {
    test('basic plan hides billing + AI when not in trial', () {
      final ac = AccessControl(_snapshot(plan: SubscriptionPlan.basic));
      expect(ac.canUseBilling, isFalse);
      expect(ac.canUseAiReports, isFalse);
      expect(ac.canUseMultipleBranches, isFalse);
    });

    test('standard plan unlocks billing + AI but not branches', () {
      final ac = AccessControl(_snapshot(plan: SubscriptionPlan.standard));
      expect(ac.canUseBilling, isTrue);
      expect(ac.canUseAiReports, isTrue);
      expect(ac.canUseMultipleBranches, isFalse);
    });
  });

  group('Expired subscription', () {
    test('blocks everything regardless of plan', () {
      final ac = AccessControl(_snapshot(
        plan: SubscriptionPlan.premium,
        status: SubscriptionStatus.expired,
      ));
      expect(ac.hasAnyAccess, isFalse);
      expect(ac.canAddChild, isFalse);
      expect(ac.canUseBilling, isFalse);
      expect(ac.blockingReason, AccessDenyReason.subscriptionExpired);
    });
  });
}
