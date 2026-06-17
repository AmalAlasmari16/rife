import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/attendance.dart';

class AttendanceRepository {
  AttendanceRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(
    String nurseryId,
    DateTime date,
  ) {
    return _db
        .collection(FirestorePaths.attendance(nurseryId))
        .doc(DailyAttendance.docId(date));
  }

  Stream<DailyAttendance> watch({
    required String nurseryId,
    required DateTime date,
  }) {
    final fallback = DateTime(date.year, date.month, date.day);
    return _doc(nurseryId, date).snapshots().map(
          (snap) => snap.exists
              ? DailyAttendance.fromFirestore(snap, fallback)
              : DailyAttendance.empty(fallback),
        );
  }

  Future<void> setStatus({
    required String nurseryId,
    required DateTime date,
    required String childId,
    required AttendanceStatus status,
  }) {
    return _doc(nurseryId, date).set(
      {
        'date': Timestamp.fromDate(
            DateTime(date.year, date.month, date.day)),
        'statuses': {childId: status.toFirestore()},
      },
      SetOptions(merge: true),
    );
  }

  Future<void> recordCheckIn({
    required String nurseryId,
    required DateTime date,
    required String childId,
  }) {
    return _doc(nurseryId, date).set(
      {
        'date': Timestamp.fromDate(
            DateTime(date.year, date.month, date.day)),
        'statuses': {childId: AttendanceStatus.present.toFirestore()},
        'checkInTimes': {childId: FieldValue.serverTimestamp()},
      },
      SetOptions(merge: true),
    );
  }

  Future<void> recordCheckOut({
    required String nurseryId,
    required DateTime date,
    required String childId,
  }) {
    return _doc(nurseryId, date).set(
      {
        'date': Timestamp.fromDate(
            DateTime(date.year, date.month, date.day)),
        'statuses': {childId: AttendanceStatus.picked.toFirestore()},
        'checkOutTimes': {childId: FieldValue.serverTimestamp()},
      },
      SetOptions(merge: true),
    );
  }
}
