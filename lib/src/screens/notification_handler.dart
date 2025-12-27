import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../services/firestore_service.dart';
import '../models/notification_model.dart';
import '../providers/auth_provider.dart';

class NotificationHandler extends ConsumerStatefulWidget {
  final Widget child;
  const NotificationHandler({super.key, required this.child});

  @override
  ConsumerState<NotificationHandler> createState() => _NotificationHandlerState();
}

class _NotificationHandlerState extends ConsumerState<NotificationHandler> {
  StreamSubscription? _notifSubscription;
  DateTime _lastTriggerTime = DateTime.now().subtract(const Duration(seconds: 10));

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initNotifications() async {
    final service = ref.read(notificationServiceProvider);
    await service.init();

    // Also update token if user is already here
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      await service.updateToken(user.uid);
      _setupRealtimeBridge(user.uid);
    }
  }

  void _setupRealtimeBridge(String uid) {
    _notifSubscription?.cancel();
    final firestore = ref.read(firestoreServiceProvider);
    final service = ref.read(notificationServiceProvider);

    _notifSubscription = firestore.getNotificationsStream(uid).listen((notifs) async {
       print('🔔 Notification Stream Received: ${notifs.length} items');
       if (notifs.isEmpty) return;

       // Filter for very recent notifications
       final newNotifs = notifs.where((n) {
         final isRecent = n.createdAt.isAfter(_lastTriggerTime);
         // Allow self-notifications if targeted at the user specifically (confirmations) or admin alerts
         final isTargeted = n.targetUserId == uid || n.targetUserId == 'admin';
         print('  - Notif ${n.id}: recent=$isRecent, targeted=$isTargeted, created=${n.createdAt}');
         return isRecent && isTargeted;
       }).toList();

       if (newNotifs.isEmpty) {
         print('  - No new/valid notifications to show.');
         return;
       }

       for (var n in newNotifs) {
         if (n.createdAt.isAfter(_lastTriggerTime)) {
           _lastTriggerTime = n.createdAt;
           await service.init(); // ensure init

           // Show local popup ONLY to avoid infinite bridge recursion
           await service.showLocalNotification(title: n.title, body: n.body);
         }
       }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes to update token and restart bridge
    ref.listen(authStateProvider, (previous, next) {
      if (next.value != null) {
        ref.read(notificationServiceProvider).updateToken(next.value!.uid);
        _setupRealtimeBridge(next.value!.uid);
      } else {
        _notifSubscription?.cancel();
      }
    });

    return widget.child;
  }
}
