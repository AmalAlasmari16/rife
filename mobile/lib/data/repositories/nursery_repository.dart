import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/firestore_paths.dart';
import '../../core/subscription/subscription_plan.dart';
import '../models/nursery.dart';

/// CRUD for tenant nursery documents.
class NurseryRepository {
  NurseryRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.nurseries);

  Stream<Nursery?> watch(String nurseryId) {
    return _col.doc(nurseryId).snapshots().map(
      (snap) => snap.exists ? Nursery.fromFirestore(snap) : null,
    );
  }

  Future<Nursery?> fetch(String nurseryId) async {
    final snap = await _col.doc(nurseryId).get();
    return snap.exists ? Nursery.fromFirestore(snap) : null;
  }

  /// Creates a brand-new nursery in trial state. The 30-day trial clock
  /// starts immediately. Plan defaults to [SubscriptionPlan.basic] until
  /// the admin picks one on the plan-selection screen (step 3).
  Future<Nursery> createForAdmin({
    required String name,
    required String ownerUid,
    String? city,
  }) async {
    final ref = _col.doc();
    final now = DateTime.now();
    final nursery = Nursery(
      id: ref.id,
      name: name,
      ownerUid: ownerUid,
      plan: SubscriptionPlan.basic,
      status: SubscriptionStatus.trial,
      trialStartDate: now,
      trialActive: true,
      childrenCount: 0,
      city: city,
      createdAt: now,
    );
    await ref.set(nursery.toFirestore());
    return nursery;
  }

  /// Updates the active plan and stamps [Nursery.planSelectedAt]. Trial
  /// status is left untouched — picking a plan during the trial doesn't
  /// charge the customer, it just records their selected tier.
  Future<void> selectPlan({
    required String nurseryId,
    required SubscriptionPlan plan,
  }) async {
    await _col.doc(nurseryId).update({
      'plan': plan.toFirestore(),
      'planSelectedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Activate a paid subscription (called when the trial ends and the user
  /// confirms billing, or when they upgrade from the paywall). Payment
  /// processing itself is stubbed until a real gateway is wired up.
  Future<void> activateSubscription({
    required String nurseryId,
    required SubscriptionPlan plan,
    Duration period = const Duration(days: 30),
  }) async {
    final expiry = DateTime.now().add(period);
    await _col.doc(nurseryId).update({
      'plan': plan.toFirestore(),
      'subscriptionStatus': SubscriptionStatus.active.toFirestore(),
      'trialActive': false,
      'subscriptionExpiry': Timestamp.fromDate(expiry),
      'planSelectedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Extend the free trial — used by the super-admin tools.
  Future<void> extendTrial({
    required String nurseryId,
    int extraDays = AppConstants.trialDurationDays,
  }) async {
    final snap = await _col.doc(nurseryId).get();
    final current =
        (snap.data()?['trialStartDate'] as Timestamp?)?.toDate() ??
            DateTime.now();
    final shifted = current.add(Duration(days: extraDays));
    await _col.doc(nurseryId).update({
      'trialStartDate': Timestamp.fromDate(shifted),
      'trialActive': true,
      'subscriptionStatus': SubscriptionStatus.trial.toFirestore(),
    });
  }
}
