import 'package:cloud_firestore/cloud_firestore.dart';

/// Per-child attendance status for a given day.
enum AttendanceStatus {
  present,
  absent,
  late,
  picked;

  String get arabic {
    switch (this) {
      case AttendanceStatus.present:
        return 'حاضر';
      case AttendanceStatus.absent:
        return 'غائب';
      case AttendanceStatus.late:
        return 'متأخر';
      case AttendanceStatus.picked:
        return 'تم استلامه';
    }
  }

  String toFirestore() => name;

  static AttendanceStatus fromFirestore(String? raw) {
    return AttendanceStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => AttendanceStatus.absent,
    );
  }
}

/// One Firestore document per day at
/// `/nurseries/{nurseryId}/attendance/{YYYY-MM-DD}` storing every child's
/// status for that day. Single-doc-per-day keeps offline writes simple.
class DailyAttendance {
  const DailyAttendance({
    required this.date,
    required this.statuses,
    this.checkInTimes = const {},
    this.checkOutTimes = const {},
  });

  /// Date the records apply to (date-only).
  final DateTime date;

  /// childId → status
  final Map<String, AttendanceStatus> statuses;

  /// childId → check-in timestamp (set by the QR/PIN flow in step 8).
  final Map<String, DateTime> checkInTimes;

  /// childId → check-out timestamp.
  final Map<String, DateTime> checkOutTimes;

  static String docId(DateTime date) {
    return '${date.year.toString().padLeft(4, "0")}-'
        '${date.month.toString().padLeft(2, "0")}-'
        '${date.day.toString().padLeft(2, "0")}';
  }

  factory DailyAttendance.empty(DateTime date) => DailyAttendance(
        date: DateTime(date.year, date.month, date.day),
        statuses: const {},
      );

  factory DailyAttendance.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    DateTime fallbackDate,
  ) {
    final data = doc.data() ?? const {};
    final raw = (data['statuses'] as Map?) ?? const {};
    final statuses = <String, AttendanceStatus>{};
    raw.forEach((key, value) {
      statuses[key as String] =
          AttendanceStatus.fromFirestore(value as String?);
    });

    final checkIns = <String, DateTime>{};
    ((data['checkInTimes'] as Map?) ?? const {}).forEach((k, v) {
      if (v is Timestamp) checkIns[k as String] = v.toDate();
    });
    final checkOuts = <String, DateTime>{};
    ((data['checkOutTimes'] as Map?) ?? const {}).forEach((k, v) {
      if (v is Timestamp) checkOuts[k as String] = v.toDate();
    });

    return DailyAttendance(
      date:
          (data['date'] as Timestamp?)?.toDate() ?? fallbackDate,
      statuses: statuses,
      checkInTimes: checkIns,
      checkOutTimes: checkOuts,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'date': Timestamp.fromDate(date),
        'statuses': {
          for (final e in statuses.entries) e.key: e.value.toFirestore(),
        },
        'checkInTimes': {
          for (final e in checkInTimes.entries)
            e.key: Timestamp.fromDate(e.value),
        },
        'checkOutTimes': {
          for (final e in checkOutTimes.entries)
            e.key: Timestamp.fromDate(e.value),
        },
      };
}
