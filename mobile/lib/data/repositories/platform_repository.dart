import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/subscription/subscription_plan.dart';
import '../models/nursery.dart';

/// Platform-wide aggregates over the [Nursery] collection, computed
/// client-side from the list stream. This stays simple for early-stage
/// usage (hundreds of nurseries). Once volume justifies it, the same
/// numbers can be precomputed by a Cloud Function into /platform/stats.
class PlatformStats {
  const PlatformStats({
    required this.totalNurseries,
    required this.trialCount,
    required this.activeCount,
    required this.expiredCount,
    required this.monthlyRecurringRevenue,
    required this.signupsByMonth,
  });

  final int totalNurseries;
  final int trialCount;
  final int activeCount;
  final int expiredCount;

  /// Sum of monthly plan prices for nurseries with [SubscriptionStatus.active].
  /// In SAR.
  final int monthlyRecurringRevenue;

  /// Map of `YYYY-MM` → number of nurseries that registered that month.
  /// Sorted oldest → newest by the caller as needed.
  final Map<String, int> signupsByMonth;

  factory PlatformStats.from(List<Nursery> nurseries) {
    var trial = 0, active = 0, expired = 0, mrr = 0;
    final signups = <String, int>{};

    for (final n in nurseries) {
      switch (n.status) {
        case SubscriptionStatus.trial:
          trial++;
          break;
        case SubscriptionStatus.active:
          active++;
          mrr += n.plan.monthlyPrice;
          break;
        case SubscriptionStatus.expired:
          expired++;
          break;
      }

      final ts = n.createdAt;
      if (ts != null) {
        final key =
            '${ts.year.toString().padLeft(4, "0")}-${ts.month.toString().padLeft(2, "0")}';
        signups[key] = (signups[key] ?? 0) + 1;
      }
    }

    return PlatformStats(
      totalNurseries: nurseries.length,
      trialCount: trial,
      activeCount: active,
      expiredCount: expired,
      monthlyRecurringRevenue: mrr,
      signupsByMonth: signups,
    );
  }
}

class PlatformRepository {
  PlatformRepository(this._db);

  final FirebaseFirestore _db;

  Stream<List<Nursery>> watchAllNurseries() {
    return _db
        .collection(FirestorePaths.nurseries)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Nursery.fromFirestore).toList());
  }
}
