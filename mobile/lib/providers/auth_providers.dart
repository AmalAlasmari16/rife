import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_user.dart';
import '../data/services/notification_service.dart';
import 'repository_providers.dart';

/// Streams the raw Firebase Auth user — null when signed out.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Streams the merged [AppUser] (Firebase Auth + `/users/{uid}` Firestore
/// doc). Resolution states:
///
/// - `AsyncLoading` while auth or the Firestore doc are settling
/// - `AsyncData(null)` when signed out **or** signed in but the Firestore
///    profile doc hasn't been created yet (e.g. mid-sign-up)
/// - `AsyncData(AppUser)` once both are ready
final currentUserProvider = StreamProvider<AppUser?>((ref) async* {
  final authState = ref.watch(authStateProvider);
  final firebaseUser = authState.valueOrNull;
  if (firebaseUser == null) {
    yield null;
    return;
  }
  yield* ref.watch(userRepositoryProvider).watch(firebaseUser.uid);
});

/// Side-effect provider that wires the [NotificationService] to the
/// current Firebase Auth user, attaching on sign-in and detaching on
/// sign-out. The app reads it once from `main`-level Consumer so it runs
/// for the lifetime of the session.
final pushBootstrapProvider = Provider<void>((ref) {
  final service = ref.watch(notificationServiceProvider);
  ref.listen<AsyncValue<User?>>(authStateProvider, (_, next) {
    final uid = next.valueOrNull?.uid;
    if (uid == null) {
      service.detach();
    } else {
      service.attach(uid);
    }
  }, fireImmediately: true);
});
