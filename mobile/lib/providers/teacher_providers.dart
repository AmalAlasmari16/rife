import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/attendance.dart';
import '../data/models/child.dart';
import '../data/models/daily_log.dart';
import 'auth_providers.dart';
import 'nursery_data_providers.dart';
import 'repository_providers.dart';

/// Today's date stripped to date-only, exposed so the UI can override it
/// in dev tools without rewriting providers.
final todayProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Children assigned to the signed-in teacher's classroom.
final teacherClassroomChildrenProvider =
    Provider<List<Child>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user?.classroomId == null) return const [];
  final all = ref.watch(childrenProvider).valueOrNull ?? const [];
  return all.where((c) => c.classroomId == user!.classroomId).toList();
});

/// Live attendance doc for today, for the teacher's nursery.
final todayAttendanceProvider =
    StreamProvider<DailyAttendance>((ref) async* {
  final nurseryId =
      ref.watch(currentUserProvider).valueOrNull?.nurseryId;
  if (nurseryId == null) {
    yield DailyAttendance.empty(ref.watch(todayProvider));
    return;
  }
  yield* ref.watch(attendanceRepositoryProvider).watch(
        nurseryId: nurseryId,
        date: ref.watch(todayProvider),
      );
});

/// Live today's log for a specific child.
final childDailyLogProvider = StreamProvider.family
    .autoDispose<DailyLog, String>((ref, childId) async* {
  final nurseryId =
      ref.watch(currentUserProvider).valueOrNull?.nurseryId;
  if (nurseryId == null) {
    yield DailyLog.empty(childId: childId, date: ref.watch(todayProvider));
    return;
  }
  yield* ref.watch(dailyLogRepositoryProvider).watch(
        nurseryId: nurseryId,
        childId: childId,
        date: ref.watch(todayProvider),
      );
});
