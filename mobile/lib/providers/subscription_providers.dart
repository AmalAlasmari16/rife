import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/subscription/access_control.dart';
import '../data/models/nursery.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

/// Live tenant document for the currently signed-in user's nursery.
final currentNurseryProvider = StreamProvider<Nursery?>((ref) async* {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final nurseryId = user?.nurseryId;
  if (nurseryId == null) {
    yield null;
    return;
  }
  yield* ref.watch(nurseryRepositoryProvider).watch(nurseryId);
});

/// Pure-Dart access-control snapshot derived from the live nursery doc.
final accessControlProvider = Provider<AccessControl?>((ref) {
  final nursery = ref.watch(currentNurseryProvider).valueOrNull;
  if (nursery == null) return null;
  return AccessControl(nursery.toSubscriptionSnapshot());
});
