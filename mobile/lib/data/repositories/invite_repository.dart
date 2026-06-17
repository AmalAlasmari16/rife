import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/invite.dart';
import '../models/user_role.dart';

/// Invite codes live under `/nurseries/{nurseryId}/invites/{code}`. To
/// support entering the code without first knowing the nursery, we mirror
/// each code in a top-level lookup collection `/inviteCodes/{code}` whose
/// document only stores `{ nurseryId }`.
///
/// Mirror documents are written by the admin-side invite creator (step 5)
/// and read by the teacher/parent redemption flow (step 2).
class InviteRepository {
  InviteRepository(this._db);

  final FirebaseFirestore _db;

  static const String _lookupCollection = 'inviteCodes';

  /// Resolves an invite code into the actual invite document, or `null`
  /// when the code is unknown or already used.
  Future<Invite?> lookup(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;

    final lookup = await _db.collection(_lookupCollection).doc(normalized).get();
    final nurseryId = lookup.data()?['nurseryId'] as String?;
    if (nurseryId == null) return null;

    final inviteRef = _db
        .collection(FirestorePaths.invites(nurseryId))
        .doc(normalized);
    final inviteSnap = await inviteRef.get();
    if (!inviteSnap.exists) return null;

    final invite = Invite.fromFirestore(inviteSnap);
    if (invite.used) return null;
    return invite;
  }

  /// Atomically marks the invite as redeemed.
  Future<void> markRedeemed({
    required Invite invite,
    required String redeemedByUid,
  }) async {
    final ref = _db
        .collection(FirestorePaths.invites(invite.nurseryId))
        .doc(invite.code);
    await ref.update({
      'used': true,
      'usedAt': FieldValue.serverTimestamp(),
      'redeemedBy': redeemedByUid,
    });
  }

  /// Issues a new invite. Writes the nested invite doc *and* a mirror in the
  /// top-level [_lookupCollection] in a single batch so lookups stay
  /// consistent. Returns the generated 6-character code.
  Future<Invite> create({
    required String nurseryId,
    required UserRole role,
    String? classroomId,
    String? childId,
    String? phone,
  }) async {
    final code = _generateCode();
    final inviteRef =
        _db.collection(FirestorePaths.invites(nurseryId)).doc(code);
    final lookupRef = _db.collection(_lookupCollection).doc(code);

    final invite = Invite(
      code: code,
      nurseryId: nurseryId,
      role: role,
      createdAt: DateTime.now(),
      classroomId: classroomId,
      childId: childId,
      phone: phone,
    );

    final batch = _db.batch()
      ..set(inviteRef, {
        'nurseryId': nurseryId,
        'role': role.toFirestore(),
        'classroomId': classroomId,
        'childId': childId,
        'phone': phone,
        'used': false,
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..set(lookupRef, {'nurseryId': nurseryId});
    await batch.commit();

    return invite;
  }

  /// 6-character alphanumeric, ambiguous chars (O, 0, I, 1) stripped.
  String _generateCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(
      6,
      (_) => alphabet[rng.nextInt(alphabet.length)],
    ).join();
  }
}
