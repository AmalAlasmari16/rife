import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/message.dart';

class MessagingRepository {
  MessagingRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _threads =>
      _db.collection(FirestorePaths.messageThreads);

  CollectionReference<Map<String, dynamic>> _messagesOf(String threadId) =>
      _threads.doc(threadId).collection('messages');

  Stream<List<MessageThread>> watchThreadsForUser(String uid) {
    return _threads
        .where('participantUids', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(MessageThread.fromFirestore).toList());
  }

  Stream<List<Message>> watchMessages(String threadId) {
    return _messagesOf(threadId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(Message.fromFirestore).toList());
  }

  /// Looks up the parent↔teacher thread for a given child and pair of
  /// participants. Creates the thread doc on demand so the parent and
  /// teacher can land on the same chat from either side.
  Future<MessageThread> openParentTeacherThread({
    required String nurseryId,
    required String childId,
    required List<String> participantUids,
  }) async {
    final existing = await _threads
        .where('childId', isEqualTo: childId)
        .where('kind', isEqualTo: ThreadKind.parentTeacher.toFirestore())
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return MessageThread.fromFirestore(existing.docs.first);
    }
    final ref = _threads.doc();
    final thread = MessageThread(
      id: ref.id,
      nurseryId: nurseryId,
      kind: ThreadKind.parentTeacher,
      participantUids: participantUids.toSet().toList(),
      childId: childId,
      lastMessageAt: DateTime.now(),
    );
    await ref.set(thread.toFirestore());
    return thread;
  }

  Future<void> send({
    required String threadId,
    required String senderUid,
    required String body,
  }) async {
    final messageRef = _messagesOf(threadId).doc();
    final threadRef = _threads.doc(threadId);
    final batch = _db.batch()
      ..set(messageRef, {
        'threadId': threadId,
        'senderUid': senderUid,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': [senderUid],
      })
      ..update(threadRef, {
        'lastMessageBody': body,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    await batch.commit();
  }
}
