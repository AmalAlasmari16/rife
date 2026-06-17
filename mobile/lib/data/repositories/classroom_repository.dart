import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/classroom.dart';

class ClassroomRepository {
  ClassroomRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String nurseryId) =>
      _db.collection(FirestorePaths.classrooms(nurseryId));

  Stream<List<Classroom>> watchAll(String nurseryId) {
    return _col(nurseryId)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(Classroom.fromFirestore).toList());
  }

  Future<Classroom> create({
    required String nurseryId,
    required String name,
    required int capacity,
    String? ageRange,
    String? colorHex,
  }) async {
    final ref = _col(nurseryId).doc();
    final classroom = Classroom(
      id: ref.id,
      name: name,
      capacity: capacity,
      ageRange: ageRange,
      colorHex: colorHex,
      createdAt: DateTime.now(),
    );
    await ref.set(classroom.toFirestore());
    return classroom;
  }

  Future<void> update({
    required String nurseryId,
    required Classroom classroom,
  }) {
    return _col(nurseryId).doc(classroom.id).update(classroom.toFirestore());
  }

  Future<void> delete({
    required String nurseryId,
    required String classroomId,
  }) {
    return _col(nurseryId).doc(classroomId).delete();
  }

  Future<void> assignTeacher({
    required String nurseryId,
    required String classroomId,
    required String teacherUid,
  }) {
    return _col(nurseryId).doc(classroomId).update({
      'teacherIds': FieldValue.arrayUnion([teacherUid]),
    });
  }

  Future<void> removeTeacher({
    required String nurseryId,
    required String classroomId,
    required String teacherUid,
  }) {
    return _col(nurseryId).doc(classroomId).update({
      'teacherIds': FieldValue.arrayRemove([teacherUid]),
    });
  }
}
