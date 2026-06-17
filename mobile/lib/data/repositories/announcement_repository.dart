import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/announcement.dart';

class AnnouncementRepository {
  AnnouncementRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String nurseryId) =>
      _db.collection(FirestorePaths.announcements(nurseryId));

  /// Streams all announcements for a nursery, newest first.
  Stream<List<Announcement>> watchAll(String nurseryId) {
    return _col(nurseryId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Announcement.fromFirestore).toList());
  }

  /// Streams announcements relevant to a specific parent — both
  /// nursery-wide announcements and ones targeting their child's classroom.
  Stream<List<Announcement>> watchForParent({
    required String nurseryId,
    required String? classroomId,
  }) {
    // Firestore can't OR two equality filters easily, so we read the lot
    // and filter client-side. Volume per nursery is small enough that this
    // is cheaper than maintaining a denormalised feed.
    return watchAll(nurseryId).map((list) {
      return list.where((a) =>
          a.isNurseryWide ||
          (classroomId != null && a.classroomId == classroomId)).toList();
    });
  }

  Future<void> post({
    required String nurseryId,
    required String title,
    required String body,
    required String authorUid,
    String? classroomId,
  }) async {
    final ref = _col(nurseryId).doc();
    await ref.set(Announcement(
      id: ref.id,
      nurseryId: nurseryId,
      title: title,
      body: body,
      authorUid: authorUid,
      classroomId: classroomId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    ).toFirestore());
  }

  Future<void> delete({
    required String nurseryId,
    required String announcementId,
  }) {
    return _col(nurseryId).doc(announcementId).delete();
  }
}
