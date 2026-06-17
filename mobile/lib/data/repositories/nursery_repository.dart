import 'package:cloud_firestore/cloud_firestore.dart';

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
}
