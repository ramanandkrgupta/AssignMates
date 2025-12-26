import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';

class NotificationHandler extends ConsumerStatefulWidget {
  final Widget child;
  const NotificationHandler({super.key, required this.child});

  @override
  ConsumerState<NotificationHandler> createState() => _NotificationHandlerState();
}

class _NotificationHandlerState extends ConsumerState<NotificationHandler> {
  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    final service = ref.read(notificationServiceProvider);
    await service.init();

    // Also update token if user is already here
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      await service.updateToken(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes to update token
    ref.listen(authStateProvider, (previous, next) {
      if (next.value != null) {
        ref.read(notificationServiceProvider).updateToken(next.value!.uid);
      }
    });

    return widget.child;
  }
}
