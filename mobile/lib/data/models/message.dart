import 'package:cloud_firestore/cloud_firestore.dart';

/// One message inside a chat thread.
class Message {
  const Message({
    required this.id,
    required this.threadId,
    required this.senderUid,
    required this.body,
    required this.createdAt,
    this.readBy = const [],
  });

  final String id;
  final String threadId;
  final String senderUid;
  final String body;
  final DateTime createdAt;
  final List<String> readBy;

  factory Message.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Message(
      id: doc.id,
      threadId: (data['threadId'] as String?) ?? '',
      senderUid: (data['senderUid'] as String?) ?? '',
      body: (data['body'] as String?) ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readBy: ((data['readBy'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'threadId': threadId,
        'senderUid': senderUid,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': readBy,
      };
}

enum ThreadKind {
  parentTeacher,
  classroom,
  staffInternal;

  String toFirestore() => name;

  static ThreadKind fromFirestore(String? raw) {
    return ThreadKind.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => ThreadKind.parentTeacher,
    );
  }
}

class MessageThread {
  const MessageThread({
    required this.id,
    required this.nurseryId,
    required this.kind,
    required this.participantUids,
    this.childId,
    this.classroomId,
    this.lastMessageBody,
    this.lastMessageAt,
  });

  final String id;
  final String nurseryId;
  final ThreadKind kind;
  final List<String> participantUids;
  final String? childId;
  final String? classroomId;
  final String? lastMessageBody;
  final DateTime? lastMessageAt;

  factory MessageThread.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return MessageThread(
      id: doc.id,
      nurseryId: (data['nurseryId'] as String?) ?? '',
      kind: ThreadKind.fromFirestore(data['kind'] as String?),
      participantUids: ((data['participantUids'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      childId: data['childId'] as String?,
      classroomId: data['classroomId'] as String?,
      lastMessageBody: data['lastMessageBody'] as String?,
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nurseryId': nurseryId,
        'kind': kind.toFirestore(),
        'participantUids': participantUids,
        'childId': childId,
        'classroomId': classroomId,
        'lastMessageBody': lastMessageBody,
        'lastMessageAt': lastMessageAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(lastMessageAt!),
      };
}
