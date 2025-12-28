import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../models/notification_model.dart';

import 'package:google_fonts/google_fonts.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  int _limit = 20;
  final Set<String> _sessionNewIds = {};
  bool _initialized = false;

  IconData _getNotificationIcon(NotificationModel notification) {
    // ... (rest of the helper stays same)
    final title = notification.title.toLowerCase();
    final body = notification.body.toLowerCase();

    if (title.contains('created') || title.contains('received') || title.contains('placed')) {
      return Icons.receipt_long_rounded;
    }
    if (title.contains('verified')) {
      return Icons.verified_rounded;
    }
    if (title.contains('assigned')) {
      return Icons.person_search_rounded;
    }
    if (title.contains('payment') || body.contains('pay')) {
      return Icons.payments_rounded;
    }
    if (title.contains('started') || title.contains('progress')) {
      return Icons.edit_note_rounded;
    }
    if (title.contains('proof') || title.contains('review')) {
      return Icons.visibility_rounded;
    }
    if (title.contains('delivery') || title.contains('way') || title.contains('delivering')) {
      return Icons.local_shipping_rounded;
    }
    if (title.contains('completed')) {
      return Icons.task_alt_rounded;
    }
    if (title.contains('cancelled')) {
      return Icons.cancel_rounded;
    }

    switch (notification.type?.toLowerCase() ?? '') {
      case 'new_order': return Icons.notification_important_rounded;
      case 'delivery_update': return Icons.local_shipping_rounded;
      case 'order_created': return Icons.receipt_long_rounded;
      case 'payment': return Icons.payments_rounded;
      default:
        return notification.isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please log in to view notifications')),
      );
    }

    final appUser = ref.watch(appUserProvider).value;
    final isAdmin = appUser?.role == 'admin';
    final notificationsStream = ref.watch(firestoreServiceProvider).getNotificationsStream(
      user.uid,
      showAdminNotifications: isAdmin,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFFAF00)));
          }

          final allNotifications = snapshot.data ?? [];

          // Logic to mark as read ONCE per session open
          if (!_initialized && snapshot.hasData) {
            final unread = allNotifications.where((n) => !n.isRead).map((n) => n.id).toList();
            if (unread.isNotEmpty) {
              _sessionNewIds.addAll(unread);
              // Run in microtask to avoid build phase side effects
              Future.microtask(() {
                ref.read(firestoreServiceProvider).markAllNotificationsAsRead(user.uid);
              });
            }
            _initialized = true;
          }

          final displayedNotifications = allNotifications.take(_limit).toList();

          if (allNotifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                     child: Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
                   ),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: displayedNotifications.length + (allNotifications.length > _limit ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == displayedNotifications.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: TextButton(
                      onPressed: () => setState(() => _limit += 20),
                      child: Text('Show more', style: GoogleFonts.outfit(color: const Color(0xFFFFAF00), fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                );
              }

              final notification = displayedNotifications[index];
              // Use local session set to highlight items, even if they are marked read in DB
              final bool isNewForThisSession = _sessionNewIds.contains(notification.id);

              return Container(
                color: isNewForThisSession ? const Color(0xFFFFF9EB) : Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isNewForThisSession ? const Color(0xFFFFAF00).withOpacity(0.1) : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getNotificationIcon(notification),
                      color: isNewForThisSession ? const Color(0xFFFFAF00) : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: GoogleFonts.outfit(
                      fontWeight: isNewForThisSession ? FontWeight.bold : FontWeight.w500,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(notification.body, style: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(DateFormat('MMM d, h:mm a').format(notification.createdAt), style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                  onTap: () async {
                    if (!notification.isRead) {
                      await ref.read(firestoreServiceProvider).markNotificationAsRead(notification.id);
                      setState(() => _sessionNewIds.remove(notification.id));
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
