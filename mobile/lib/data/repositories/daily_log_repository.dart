import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/daily_log.dart';

class DailyLogRepository {
  DailyLogRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc({
    required String nurseryId,
    required String childId,
    required DateTime date,
  }) {
    return _db
        .collection(FirestorePaths.dailyLogs(nurseryId, childId))
        .doc(DailyLog.docId(date));
  }

  Stream<DailyLog> watch({
    required String nurseryId,
    required String childId,
    required DateTime date,
  }) {
    return _doc(nurseryId: nurseryId, childId: childId, date: date)
        .snapshots()
        .map(
          (snap) => snap.exists
              ? DailyLog.fromFirestore(snap,
                  childId: childId, fallbackDate: date)
              : DailyLog.empty(childId: childId, date: date),
        );
  }

  Stream<List<DailyLog>> watchHistory({
    required String nurseryId,
    required String childId,
    int limit = 30,
  }) {
    return _db
        .collection(FirestorePaths.dailyLogs(nurseryId, childId))
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs
            .map((d) => DailyLog.fromFirestore(d,
                childId: childId, fallbackDate: DateTime.now()))
            .toList());
  }

  Future<void> save({
    required String nurseryId,
    required DailyLog log,
  }) {
    return _doc(
      nurseryId: nurseryId,
      childId: log.childId,
      date: log.date,
    ).set(log.toFirestore(), SetOptions(merge: true));
  }
}
