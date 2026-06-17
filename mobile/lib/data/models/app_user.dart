import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

/// Firestore representation of a user account, stored at `/users/{uid}`.
///
/// The Firebase Auth user is the source of truth for identity; this document
/// adds role, tenant binding, and profile fields.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.nurseryId,
    this.email,
    this.phone,
    this.classroomId,
    this.childIds = const [],
    this.createdAt,
  });

  final String id;
  final String name;
  final UserRole role;

  /// `null` only for the [UserRole.superAdmin] account.
  final String? nurseryId;

  final String? email;
  final String? phone;

  /// Teachers only — the classroom they are assigned to.
  final String? classroomId;

  /// Parents only — the children linked to this guardian.
  final List<String> childIds;

  final DateTime? createdAt;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return AppUser(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      role: UserRole.fromFirestore(data['role'] as String?),
      nurseryId: data['nurseryId'] as String?,
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      classroomId: data['classroomId'] as String?,
      childIds: ((data['childIds'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'role': role.toFirestore(),
        'nurseryId': nurseryId,
        'email': email,
        'phone': phone,
        'classroomId': classroomId,
        'childIds': childIds,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };

  AppUser copyWith({
    String? name,
    UserRole? role,
    String? nurseryId,
    String? email,
    String? phone,
    String? classroomId,
    List<String>? childIds,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      nurseryId: nurseryId ?? this.nurseryId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      classroomId: classroomId ?? this.classroomId,
      childIds: childIds ?? this.childIds,
      createdAt: createdAt,
    );
  }
}
