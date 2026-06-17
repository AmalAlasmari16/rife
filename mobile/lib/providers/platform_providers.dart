import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/nursery.dart';
import '../data/repositories/platform_repository.dart';
import 'repository_providers.dart';

/// Live stream of every nursery in the system. Visible only to the
/// super-admin (Firestore rules enforce that in step 3+).
final allNurseriesProvider = StreamProvider<List<Nursery>>((ref) {
  return ref.watch(platformRepositoryProvider).watchAllNurseries();
});

/// Aggregated platform stats derived from [allNurseriesProvider].
final platformStatsProvider = Provider<PlatformStats?>((ref) {
  final nurseries = ref.watch(allNurseriesProvider).valueOrNull;
  if (nurseries == null) return null;
  return PlatformStats.from(nurseries);
});
