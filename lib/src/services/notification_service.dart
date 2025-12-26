import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firestore_service.dart';
import '../providers/auth_provider.dart';

final notificationServiceProvider = Provider((ref) => NotificationService(ref));

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
    await _showLocalDirect(title: notification.title ?? '', body: notification.body ?? '');
  }

  Future<void> _showLocalDirect({required String title, required String body}) async {
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
    required List<String> receiverTokens,
    required String title,
    required String body,
  }) async {
    if (receiverTokens.isEmpty) return;

    // For a real app, you should use Firebase Cloud Functions to send notifications securely.
    // If you have a Legacy Server Key, you could use:
    /*
    final serverKey = 'YOUR_SERVER_KEY';
    for (var token in receiverTokens) {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'notification': {'title': title, 'body': body},
          'priority': 'high',
          'to': token,
        }),
      );
    }
    */

    // For now, we will log it. In a production environment, this should trigger a Cloud Function.
    print('Sending Notification: $title - $body to ${receiverTokens.length} devices');
  }

  Future<void> notifyAdmins({required String title, required String body}) async {
    final admins = await _ref.read(firestoreServiceProvider).getAdmins();
    final tokens = admins.map((a) => a.fcmToken).whereType<String>().toList();

    // Also show locally if current user is admin
    final currentUser = _ref.read(authStateProvider).value;
    if (currentUser != null && admins.any((a) => a.uid == currentUser.uid)) {
      await _showLocalDirect(title: title, body: body);
    }

    await sendNotification(receiverTokens: tokens, title: title, body: body);
  }

  Future<void> notifyUser({required String userId, required String title, required String body}) async {
    // 1. If for current user, show locally immediately
    final currentUser = _ref.read(authStateProvider).value;
    if (currentUser != null && currentUser.uid == userId) {
      await _showLocalDirect(title: title, body: body);
    }

    final user = await _ref.read(firestoreServiceProvider).getUser(userId);
    if (user?.fcmToken != null) {
      await sendNotification(receiverTokens: [user!.fcmToken!], title: title, body: body);
    }
  }
}
