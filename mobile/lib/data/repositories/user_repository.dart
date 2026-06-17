import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';

/// CRUD over `/users/{uid}`. The document mirrors the Firebase Auth account
/// and stores role + tenant binding.
class UserRepository {
  UserRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection(FirestorePaths.users).doc(uid);

  /// Streams the user document. Emits `null` until the document exists
  /// (e.g. just after sign-up, before [createIfMissing] has run).
  Stream<AppUser?> watch(String uid) {
    return _doc(uid).snapshots().map(
      (snap) => snap.exists ? AppUser.fromFirestore(snap) : null,
    );
  }

  Future<AppUser?> fetch(String uid) async {
    final snap = await _doc(uid).get();
    return snap.exists ? AppUser.fromFirestore(snap) : null;
  }

  /// Idempotent creation — safe to call after sign-up regardless of whether
  /// a previous attempt partially completed.
  Future<void> createIfMissing(AppUser user) async {
    final ref = _doc(user.id);
    final existing = await ref.get();
    if (existing.exists) return;
    await ref.set(user.toFirestore());
  }

  Future<void> update(AppUser user) => _doc(user.id).update(user.toFirestore());

  Future<void> linkChildToParent({
    required String parentUid,
    required String childId,
  }) async {
    await _doc(parentUid).set({
      'childIds': FieldValue.arrayUnion([childId]),
      'role': UserRole.parent.toFirestore(),
    }, SetOptions(merge: true));
  }
}
