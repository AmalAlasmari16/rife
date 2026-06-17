import 'package:cloud_firestore/cloud_firestore.dart';

enum EnrollmentStatus {
  pending,
  waitlisted,
  approved,
  rejected;

  String get arabic {
    switch (this) {
      case EnrollmentStatus.pending:
        return 'قيد المراجعة';
      case EnrollmentStatus.waitlisted:
        return 'قائمة الانتظار';
      case EnrollmentStatus.approved:
        return 'مقبول';
      case EnrollmentStatus.rejected:
        return 'مرفوض';
    }
  }

  String toFirestore() => name;
  static EnrollmentStatus fromFirestore(String? raw) {
    return EnrollmentStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => EnrollmentStatus.pending,
    );
  }
}

class EnrollmentApplication {
  const EnrollmentApplication({
    required this.id,
    required this.nurseryId,
    required this.childName,
    required this.parentName,
    required this.parentPhone,
    this.parentEmail,
    this.childDateOfBirth,
    this.preferredClassroomId,
    this.notes,
    this.documents = const [],
    this.status = EnrollmentStatus.pending,
    this.createdAt,
    this.decidedAt,
    this.decidedBy,
    this.convertedChildId,
  });

  final String id;
  final String nurseryId;
  final String childName;
  final String parentName;
  final String parentPhone;
  final String? parentEmail;
  final DateTime? childDateOfBirth;
  final String? preferredClassroomId;
  final String? notes;

  /// Free-form list of document descriptions (e.g. "شهادة ميلاد",
  /// "سجل التطعيمات"). Real file URLs are added in a later iteration once
  /// Firebase Storage is wired in.
  final List<String> documents;

  final EnrollmentStatus status;
  final DateTime? createdAt;
  final DateTime? decidedAt;
  final String? decidedBy;
  final String? convertedChildId;

  factory EnrollmentApplication.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return EnrollmentApplication(
      id: doc.id,
      nurseryId: (data['nurseryId'] as String?) ?? '',
      childName: (data['childName'] as String?) ?? '',
      parentName: (data['parentName'] as String?) ?? '',
      parentPhone: (data['parentPhone'] as String?) ?? '',
      parentEmail: data['parentEmail'] as String?,
      childDateOfBirth:
          (data['childDateOfBirth'] as Timestamp?)?.toDate(),
      preferredClassroomId: data['preferredClassroomId'] as String?,
      notes: data['notes'] as String?,
      documents: ((data['documents'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      status: EnrollmentStatus.fromFirestore(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      decidedAt: (data['decidedAt'] as Timestamp?)?.toDate(),
      decidedBy: data['decidedBy'] as String?,
      convertedChildId: data['convertedChildId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nurseryId': nurseryId,
        'childName': childName,
        'parentName': parentName,
        'parentPhone': parentPhone,
        'parentEmail': parentEmail,
        'childDateOfBirth': childDateOfBirth == null
            ? null
            : Timestamp.fromDate(childDateOfBirth!),
        'preferredClassroomId': preferredClassroomId,
        'notes': notes,
        'documents': documents,
        'status': status.toFirestore(),
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
        'decidedAt': decidedAt == null
            ? null
            : Timestamp.fromDate(decidedAt!),
        'decidedBy': decidedBy,
        'convertedChildId': convertedChildId,
      };
}
