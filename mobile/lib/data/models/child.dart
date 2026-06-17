import 'package:cloud_firestore/cloud_firestore.dart';

class Child {
  const Child({
    required this.id,
    required this.name,
    required this.classroomId,
    this.dateOfBirth,
    this.photoUrl,
    this.allergies = const [],
    this.notes,
    this.parentIds = const [],
    this.authorizedPickups = const [],
    this.createdAt,
  });

  final String id;
  final String name;
  final String classroomId;
  final DateTime? dateOfBirth;
  final String? photoUrl;
  final List<String> allergies;
  final String? notes;

  /// User ids of guardians linked to this child.
  final List<String> parentIds;

  /// Authorized pickup persons — free-text names since they're not app users.
  final List<String> authorizedPickups;

  final DateTime? createdAt;

  int? get ageInMonths {
    final dob = dateOfBirth;
    if (dob == null) return null;
    final now = DateTime.now();
    return (now.year - dob.year) * 12 + (now.month - dob.month);
  }

  String? get ageLabel {
    final m = ageInMonths;
    if (m == null) return null;
    final years = m ~/ 12;
    final months = m % 12;
    if (years == 0) return '$months شهراً';
    if (months == 0) return '$years سنوات';
    return '$years سنوات و$months شهراً';
  }

  factory Child.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Child(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      classroomId: (data['classroomId'] as String?) ?? '',
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate(),
      photoUrl: data['photoUrl'] as String?,
      allergies: ((data['allergies'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      notes: data['notes'] as String?,
      parentIds: ((data['parentIds'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      authorizedPickups: ((data['authorizedPickups'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'classroomId': classroomId,
        'dateOfBirth': dateOfBirth == null
            ? null
            : Timestamp.fromDate(dateOfBirth!),
        'photoUrl': photoUrl,
        'allergies': allergies,
        'notes': notes,
        'parentIds': parentIds,
        'authorizedPickups': authorizedPickups,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };

  Child copyWith({
    String? name,
    String? classroomId,
    DateTime? dateOfBirth,
    String? photoUrl,
    List<String>? allergies,
    String? notes,
    List<String>? parentIds,
    List<String>? authorizedPickups,
  }) {
    return Child(
      id: id,
      name: name ?? this.name,
      classroomId: classroomId ?? this.classroomId,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      photoUrl: photoUrl ?? this.photoUrl,
      allergies: allergies ?? this.allergies,
      notes: notes ?? this.notes,
      parentIds: parentIds ?? this.parentIds,
      authorizedPickups: authorizedPickups ?? this.authorizedPickups,
      createdAt: createdAt,
    );
  }
}
