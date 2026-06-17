import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/enrollment_application.dart';

/// Each nursery exposes a short public code so the link they share with
/// families can be a simple `rifq://enroll/{code}` deep link (or just spoken
/// over the phone). The code is the document id in `/enrollmentCodes`,
/// pointing at the nursery id — same pattern as invites in step 2.
class EnrollmentRepository {
  EnrollmentRepository(this._db);

  final FirebaseFirestore _db;

  static const _codeCollection = 'enrollmentCodes';

  Future<String?> resolveCodeToNurseryId(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    final snap = await _db.collection(_codeCollection).doc(normalized).get();
    return snap.data()?['nurseryId'] as String?;
  }

  Stream<List<EnrollmentApplication>> watchAll(String nurseryId) {
    return _db
        .collection(FirestorePaths.enrollments(nurseryId))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(EnrollmentApplication.fromFirestore).toList());
  }

  Future<EnrollmentApplication> submit({
    required String nurseryId,
    required String childName,
    required String parentName,
    required String parentPhone,
    String? parentEmail,
    DateTime? childDateOfBirth,
    String? preferredClassroomId,
    String? notes,
    List<String> documents = const [],
  }) async {
    final ref =
        _db.collection(FirestorePaths.enrollments(nurseryId)).doc();
    final app = EnrollmentApplication(
      id: ref.id,
      nurseryId: nurseryId,
      childName: childName,
      parentName: parentName,
      parentPhone: parentPhone,
      parentEmail: parentEmail,
      childDateOfBirth: childDateOfBirth,
      preferredClassroomId: preferredClassroomId,
      notes: notes,
      documents: documents,
      createdAt: DateTime.now(),
    );
    await ref.set(app.toFirestore());
    return app;
  }

  Future<void> setStatus({
    required String nurseryId,
    required String applicationId,
    required EnrollmentStatus status,
    required String decidedBy,
    String? convertedChildId,
  }) {
    return _db
        .collection(FirestorePaths.enrollments(nurseryId))
        .doc(applicationId)
        .update({
      'status': status.toFirestore(),
      'decidedAt': FieldValue.serverTimestamp(),
      'decidedBy': decidedBy,
      if (convertedChildId != null) 'convertedChildId': convertedChildId,
    });
  }
}
