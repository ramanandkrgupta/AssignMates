import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firestore_service.dart';
import '../providers/auth_provider.dart';
import '../models/notification_model.dart';

final notificationServiceProvider = Provider((ref) => NotificationService(ref));

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Use a separate core initialization if needed for background persistence
  // But for just showing a notification, local_notifications suffice.
  print("Handling a background message: ${message.messageId}");

  // We don't need to manually show here if it's a 'Notification' message (Firebase handles it)
  // If it's a 'Data' message, we might need to show local notification manually.
}

class NotificationService {
  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService(this._ref);

  Future<void> init() async {
    // 1. Request Permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Init Local Notifications for Foreground
    const androidInit = AndroidInitializationSettings('@drawable/am_notif_icon');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // 3. Listen for Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
  }

  Future<void> updateToken(String uid) async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _ref.read(firestoreServiceProvider).updateFcmToken(uid, token);
        print('FCM Token Updated for $uid');
      }
    } catch (e) {
      print('Error updating token: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await showLocalNotification(title: notification.title ?? '', body: notification.body ?? '');
  }

  Future<void> showLocalNotification({required String title, required String body}) async {
    final androidDetails = AndroidNotificationDetails(
      'order_updates_channel',
      'Order Updates',
      channelDescription: 'Get real-time updates for your assignment orders',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/am_notif_icon',
      largeIcon: const DrawableResourceAndroidBitmap('@drawable/notification_icon'),
      color: const Color(0xFFFFAF00),
      category: AndroidNotificationCategory.status,
      styleInformation: const BigTextStyleInformation(''),
      ticker: 'Order Update',
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      enableLights: true,
      ledColor: const Color(0xFFFFAF00),
      ledOnMs: 1000,
      ledOffMs: 500,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// Sends a notification to a specific list of tokens
  /// This typically requires a backend or FCM Server Key.
  Future<void> sendNotification({
    required String targetUserId,
    required String title,
    required String body,
  }) async {
    final currentUser = _ref.read(authStateProvider).value;

    // 1. Persist to Firestore as a bridge for real-time sync across devices
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      targetUserId: targetUserId,
      senderId: currentUser?.uid,
      title: title,
      body: body,
      createdAt: DateTime.now(),
    );

    await _ref.read(firestoreServiceProvider).createNotification(notification);

    // 2. Original Logging
    print('Notification Persisted to Firestore: $title - $body for $targetUserId');
  }

  Future<void> notifyAdmins({required String title, required String body}) async {
    // Target 'admin' bridge
    await sendNotification(targetUserId: 'admin', title: title, body: body);
  }

  Future<void> notifyUser({required String userId, required String title, required String body}) async {
    await sendNotification(targetUserId: userId, title: title, body: body);
  }
}
