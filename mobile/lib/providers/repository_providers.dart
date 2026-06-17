import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/announcement_repository.dart';
import '../data/repositories/attendance_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/child_repository.dart';
import '../data/repositories/classroom_repository.dart';
import '../data/repositories/daily_log_repository.dart';
import '../data/repositories/enrollment_repository.dart';
import '../data/repositories/invite_repository.dart';
import '../data/repositories/invoice_repository.dart';
import '../data/repositories/messaging_repository.dart';
import '../data/repositories/nursery_repository.dart';
import '../data/repositories/platform_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/services/gemini_service.dart';
import '../data/services/notification_service.dart';

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

final invoiceRepositoryProvider = Provider<InvoiceRepository>(
  (ref) => InvoiceRepository(ref.watch(firestoreProvider)),
);

final enrollmentRepositoryProvider = Provider<EnrollmentRepository>(
  (ref) => EnrollmentRepository(ref.watch(firestoreProvider)),
);

final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => AnnouncementRepository(ref.watch(firestoreProvider)),
);

final firebaseMessagingProvider = Provider<FirebaseMessaging>(
  (ref) => FirebaseMessaging.instance,
);

final localNotificationsProvider =
    Provider<FlutterLocalNotificationsPlugin>(
  (ref) => FlutterLocalNotificationsPlugin(),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(
    ref.watch(firebaseMessagingProvider),
    ref.watch(firestoreProvider),
    ref.watch(localNotificationsProvider),
  ),
);
