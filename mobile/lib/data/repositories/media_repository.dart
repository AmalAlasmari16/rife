import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/media_item.dart';

class MediaRepository {
  MediaRepository(this._db, this._storage);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  static const _uuid = Uuid();

  CollectionReference<Map<String, dynamic>> _col(String nurseryId) =>
      _db.collection(FirestorePaths.media(nurseryId));

  /// Streams everything posted in a classroom, newest first.
  Stream<List<MediaItem>> watchByClassroom({
    required String nurseryId,
    required String classroomId,
  }) {
    return _col(nurseryId)
        .where('classroomId', isEqualTo: classroomId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(MediaItem.fromFirestore).toList());
  }

  /// Streams media tagged with [childId] or general classroom posts the
  /// child belongs to. Used by the parent gallery.
  Stream<List<MediaItem>> watchForChild({
    required String nurseryId,
    required String classroomId,
    required String childId,
  }) {
    return watchByClassroom(
      nurseryId: nurseryId,
      classroomId: classroomId,
    ).map((list) => list
        .where((m) => m.childIds.isEmpty || m.childIds.contains(childId))
        .toList());
  }

  /// Uploads a file from disk and writes its metadata. Returns the
  /// completed [MediaItem]. Caller is responsible for picking the file —
  /// keeps this layer free of UI dependencies.
  Future<MediaItem> upload({
    required File file,
    required String nurseryId,
    required String classroomId,
    required String uploadedByUid,
    required MediaType type,
    String? caption,
    List<String> childIds = const [],
  }) async {
    final id = _uuid.v4();
    final ext = type == MediaType.video ? 'mp4' : 'jpg';
    final ref = _storage.ref(
      'nurseries/$nurseryId/classrooms/$classroomId/$id.$ext',
    );

    final task = await ref.putFile(
      file,
      SettableMetadata(
        contentType: type == MediaType.video ? 'video/mp4' : 'image/jpeg',
      ),
    );
    final url = await task.ref.getDownloadURL();

    final docRef = _col(nurseryId).doc(id);
    final item = MediaItem(
      id: id,
      nurseryId: nurseryId,
      classroomId: classroomId,
      url: url,
      type: type,
      uploadedByUid: uploadedByUid,
      childIds: childIds,
      caption: caption,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
    await docRef.set(item.toFirestore());
    return item;
  }

  Future<void> delete({
    required String nurseryId,
    required MediaItem item,
  }) async {
    try {
      await _storage.refFromURL(item.url).delete();
    } catch (_) {
      // Already gone or no access — proceed with metadata removal.
    }
    await _col(nurseryId).doc(item.id).delete();
  }
}
