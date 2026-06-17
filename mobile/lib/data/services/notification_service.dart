import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/constants/firestore_paths.dart';

/// Background isolate handler. Must be a top-level / static function for
/// FCM to call it after the app has been killed.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Intentionally empty for now — backend sends data-only notifications,
  // OS shows the system notification automatically. We keep the hook to
  // make the wire-up explicit so future logic (analytics, deep-link
  // routing) has somewhere obvious to land.
}

/// Owns the FCM lifecycle: permission, token registration into Firestore,
/// and foreground display via flutter_local_notifications. Wire-up happens
/// once after sign-in via [NotificationService.attach].
class NotificationService {
  NotificationService(this._messaging, this._db, this._local);

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _db;
  final FlutterLocalNotificationsPlugin _local;

  String? _attachedUid;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  bool _localReady = false;

  static const _androidChannel = AndroidNotificationChannel(
    'rifq_default',
    'إشعارات رِفق',
    description: 'تقارير الأطفال والتنبيهات الفورية',
    importance: Importance.high,
  );

  /// Bootstraps notifications for the signed-in user. Safe to call multiple
  /// times for the same uid (does nothing on the second call).
  Future<void> attach(String uid) async {
    if (_attachedUid == uid) return;
    await detach();

    await _ensureLocalReady();
    final granted = await _requestPermission();
    if (!granted) {
      _attachedUid = uid;
      return;
    }

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(uid: uid, token: token);
    }

    _tokenRefreshSub = _messaging.onTokenRefresh.listen((t) {
      _saveToken(uid: uid, token: t);
    });

    _foregroundSub = FirebaseMessaging.onMessage.listen(_showForeground);

    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    _attachedUid = uid;
  }

  Future<void> detach() async {
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    _tokenRefreshSub = null;
    _foregroundSub = null;
    _attachedUid = null;
  }

  Future<void> _ensureLocalReady() async {
    if (_localReady) return;
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
    _localReady = true;
  }

  Future<bool> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> _saveToken({
    required String uid,
    required String token,
  }) async {
    try {
      await _db.collection(FirestorePaths.users).doc(uid).set(
        {
          'fcmTokens': FieldValue.arrayUnion([token]),
          'fcmPlatform': defaultTargetPlatform.name,
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Non-fatal — user can still receive in-app updates from Firestore.
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;
    await _local.show(
      notif.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
