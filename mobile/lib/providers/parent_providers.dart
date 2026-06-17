import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/announcement.dart';
import '../data/models/child.dart';
import '../data/models/daily_log.dart';
import '../data/models/message.dart';
import 'auth_providers.dart';
import 'nursery_data_providers.dart';
import 'repository_providers.dart';
import 'teacher_providers.dart';

/// Children linked to the signed-in parent.
final parentChildrenProvider = Provider<List<Child>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return const [];
  final all = ref.watch(childrenProvider).valueOrNull ?? const [];
  return all.where((c) => user.childIds.contains(c.id)).toList();
});

/// The parent's "currently viewed" child. Defaults to the first linked
/// child; the parent home screen lets them switch.
final selectedChildIdProvider = StateProvider<String?>((ref) {
  final list = ref.watch(parentChildrenProvider);
  return list.isEmpty ? null : list.first.id;
});

final selectedChildProvider = Provider<Child?>((ref) {
  final id = ref.watch(selectedChildIdProvider);
  if (id == null) return null;
  final list = ref.watch(parentChildrenProvider);
  for (final c in list) {
    if (c.id == id) return c;
  }
  return null;
});

/// Today's daily log for the selected child.
final selectedChildTodayLogProvider =
    StreamProvider<DailyLog?>((ref) async* {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final childId = ref.watch(selectedChildIdProvider);
  if (user?.nurseryId == null || childId == null) {
    yield null;
    return;
  }
  yield* ref.watch(dailyLogRepositoryProvider).watch(
        nurseryId: user!.nurseryId!,
        childId: childId,
        date: ref.watch(todayProvider),
      );
});

/// Recent logs for the selected child.
final selectedChildHistoryProvider =
    StreamProvider<List<DailyLog>>((ref) async* {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final childId = ref.watch(selectedChildIdProvider);
  if (user?.nurseryId == null || childId == null) {
    yield const [];
    return;
  }
  yield* ref.watch(dailyLogRepositoryProvider).watchHistory(
        nurseryId: user!.nurseryId!,
        childId: childId,
      );
});

/// All message threads visible to the current user.
final userThreadsProvider =
    StreamProvider<List<MessageThread>>((ref) async* {
  final uid = ref.watch(currentUserProvider).valueOrNull?.id;
  if (uid == null) {
    yield const [];
    return;
  }
  yield* ref.watch(messagingRepositoryProvider).watchThreadsForUser(uid);
});

/// Announcements relevant to the selected child's classroom + any
/// nursery-wide ones, newest first.
final parentAnnouncementsProvider =
    StreamProvider<List<Announcement>>((ref) async* {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final selected = ref.watch(selectedChildProvider);
  if (user?.nurseryId == null) {
    yield const [];
    return;
  }
  yield* ref.watch(announcementRepositoryProvider).watchForParent(
        nurseryId: user!.nurseryId!,
        classroomId: selected?.classroomId,
      );
});
