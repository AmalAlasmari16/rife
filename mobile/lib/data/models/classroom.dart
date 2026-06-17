import 'package:cloud_firestore/cloud_firestore.dart';

class Classroom {
  const Classroom({
    required this.id,
    required this.name,
    required this.capacity,
    this.teacherIds = const [],
    this.ageRange,
    this.colorHex,
    this.createdAt,
  });

  final String id;
  final String name;
  final int capacity;
  final List<String> teacherIds;

  /// Free-text age range like "2-3 سنوات".
  final String? ageRange;

  /// Optional accent color for the classroom card, stored as a `#RRGGBB`
  /// string.
  final String? colorHex;

  final DateTime? createdAt;

  factory Classroom.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Classroom(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      teacherIds: ((data['teacherIds'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      ageRange: data['ageRange'] as String?,
      colorHex: data['colorHex'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'capacity': capacity,
        'teacherIds': teacherIds,
        'ageRange': ageRange,
        'colorHex': colorHex,
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };

  Classroom copyWith({
    String? name,
    int? capacity,
    List<String>? teacherIds,
    String? ageRange,
    String? colorHex,
  }) {
    return Classroom(
      id: id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      teacherIds: teacherIds ?? this.teacherIds,
      ageRange: ageRange ?? this.ageRange,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt,
    );
  }
}
