import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/attendance_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/child_repository.dart';
import '../data/repositories/classroom_repository.dart';
import '../data/repositories/daily_log_repository.dart';
import '../data/repositories/invite_repository.dart';
import '../data/repositories/messaging_repository.dart';
import '../data/repositories/nursery_repository.dart';
import '../data/repositories/platform_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/services/gemini_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(firebaseAuthProvider)),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(firestoreProvider)),
);

final nurseryRepositoryProvider = Provider<NurseryRepository>(
  (ref) => NurseryRepository(ref.watch(firestoreProvider)),
);

final inviteRepositoryProvider = Provider<InviteRepository>(
  (ref) => InviteRepository(ref.watch(firestoreProvider)),
);

final platformRepositoryProvider = Provider<PlatformRepository>(
  (ref) => PlatformRepository(ref.watch(firestoreProvider)),
);

final classroomRepositoryProvider = Provider<ClassroomRepository>(
  (ref) => ClassroomRepository(ref.watch(firestoreProvider)),
);

final childRepositoryProvider = Provider<ChildRepository>(
  (ref) => ChildRepository(ref.watch(firestoreProvider)),
);

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepository(ref.watch(firestoreProvider)),
);

final dailyLogRepositoryProvider = Provider<DailyLogRepository>(
  (ref) => DailyLogRepository(ref.watch(firestoreProvider)),
);

final geminiServiceProvider = Provider<GeminiService>(
  (ref) => GeminiService(),
);

final messagingRepositoryProvider = Provider<MessagingRepository>(
  (ref) => MessagingRepository(ref.watch(firestoreProvider)),
);
