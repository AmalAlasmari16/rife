import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

/// Code-based invite issued by a nursery admin to onboard a teacher or
/// parent. Stored at `/nurseries/{nurseryId}/invites/{code}`.
///
/// Invite creation is wired up in step 5 (nursery admin features). Step 2
/// only handles redemption from the teacher/parent side.
class Invite {
  const Invite({
    required this.code,
    required this.nurseryId,
    required this.role,
    required this.createdAt,
    this.classroomId,
    this.childId,
    this.phone,
    this.used = false,
    this.usedAt,
  });

  final String code;
  final String nurseryId;
  final UserRole role;
  final DateTime createdAt;

  /// Teachers: pre-assigned classroom. Optional — admin may leave blank.
  final String? classroomId;

  /// Parents: child the parent will be linked to on redemption.
  final String? childId;

  /// Optional pre-filled phone number. If set, the redeeming OTP phone must
  /// match for the invite to be valid.
  final String? phone;

  final bool used;
  final DateTime? usedAt;

  factory Invite.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Invite(
      code: doc.id,
      nurseryId: (data['nurseryId'] as String?) ?? '',
      role: UserRole.fromFirestore(data['role'] as String?),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      classroomId: data['classroomId'] as String?,
      childId: data['childId'] as String?,
      phone: data['phone'] as String?,
      used: (data['used'] as bool?) ?? false,
      usedAt: (data['usedAt'] as Timestamp?)?.toDate(),
    );
  }
}
