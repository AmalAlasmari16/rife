import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/child.dart';

class ChildRepository {
  ChildRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String nurseryId) =>
      _db.collection(FirestorePaths.children(nurseryId));

  Stream<List<Child>> watchAll(String nurseryId) {
    return _col(nurseryId)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(Child.fromFirestore).toList());
  }

  Stream<List<Child>> watchByClassroom({
    required String nurseryId,
    required String classroomId,
  }) {
    return _col(nurseryId)
        .where('classroomId', isEqualTo: classroomId)
        .snapshots()
        .map((s) => s.docs.map(Child.fromFirestore).toList());
  }

  Future<Child?> fetch({
    required String nurseryId,
    required String childId,
  }) async {
    final snap = await _col(nurseryId).doc(childId).get();
    return snap.exists ? Child.fromFirestore(snap) : null;
  }

  /// Adds a child and bumps the denormalized [Nursery.childrenCount] in a
  /// single batch so the access-control checks stay correct after the call.
  Future<Child> create({
    required String nurseryId,
    required String name,
    required String classroomId,
    DateTime? dateOfBirth,
    List<String> allergies = const [],
    String? notes,
    List<String> authorizedPickups = const [],
  }) async {
    final childRef = _col(nurseryId).doc();
    final nurseryRef = _db.collection(FirestorePaths.nurseries).doc(nurseryId);
    final child = Child(
      id: childRef.id,
      name: name,
      classroomId: classroomId,
      dateOfBirth: dateOfBirth,
      allergies: allergies,
      notes: notes,
      authorizedPickups: authorizedPickups,
      createdAt: DateTime.now(),
    );

    final batch = _db.batch()
      ..set(childRef, child.toFirestore())
      ..update(nurseryRef, {'childrenCount': FieldValue.increment(1)});
    await batch.commit();
    return child;
  }

  Future<void> update({
    required String nurseryId,
    required Child child,
  }) {
    return _col(nurseryId).doc(child.id).update(child.toFirestore());
  }

  Future<void> delete({
    required String nurseryId,
    required String childId,
  }) async {
    final childRef = _col(nurseryId).doc(childId);
    final nurseryRef = _db.collection(FirestorePaths.nurseries).doc(nurseryId);
    final batch = _db.batch()
      ..delete(childRef)
      ..update(nurseryRef, {'childrenCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  Future<void> linkParent({
    required String nurseryId,
    required String childId,
    required String parentUid,
  }) {
    return _col(nurseryId).doc(childId).update({
      'parentIds': FieldValue.arrayUnion([parentUid]),
    });
  }
}
