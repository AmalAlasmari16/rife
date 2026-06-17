import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_user.dart';
import '../data/models/child.dart';
import '../data/models/classroom.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

/// Streams the classrooms of the current user's nursery. Empty list when
/// the user has no nursery binding (e.g. super-admin).
final classroomsProvider = StreamProvider<List<Classroom>>((ref) async* {
  final nurseryId = ref.watch(currentUserProvider).valueOrNull?.nurseryId;
  if (nurseryId == null) {
    yield const [];
    return;
  }
  yield* ref.watch(classroomRepositoryProvider).watchAll(nurseryId);
});

/// Streams every child in the current user's nursery.
final childrenProvider = StreamProvider<List<Child>>((ref) async* {
  final nurseryId = ref.watch(currentUserProvider).valueOrNull?.nurseryId;
  if (nurseryId == null) {
    yield const [];
    return;
  }
  yield* ref.watch(childRepositoryProvider).watchAll(nurseryId);
});

/// Streams teachers belonging to the current user's nursery.
final staffProvider = StreamProvider<List<AppUser>>((ref) async* {
  final nurseryId = ref.watch(currentUserProvider).valueOrNull?.nurseryId;
  if (nurseryId == null) {
    yield const [];
    return;
  }
  yield* ref.watch(userRepositoryProvider).watchStaff(nurseryId);
});
