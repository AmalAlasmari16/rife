import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin-broadcast message shown in the parent feed.
///
/// `classroomId == null` means it's sent to the whole nursery; otherwise
/// only parents whose child belongs to that classroom see it.
class Announcement {
  const Announcement({
    required this.id,
    required this.nurseryId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.authorUid,
    this.classroomId,
  });

  final String id;
  final String nurseryId;
  final String title;
  final String body;
  final DateTime createdAt;
  final String authorUid;
  final String? classroomId;

  bool get isNurseryWide => classroomId == null;

  factory Announcement.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Announcement(
      id: doc.id,
      nurseryId: (data['nurseryId'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      body: (data['body'] as String?) ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      authorUid: (data['authorUid'] as String?) ?? '',
      classroomId: data['classroomId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nurseryId': nurseryId,
        'title': title,
        'body': body,
        'authorUid': authorUid,
        'classroomId': classroomId,
        'createdAt': createdAt.millisecondsSinceEpoch == 0
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt),
      };
}
