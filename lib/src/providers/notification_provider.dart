import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

final unreadNotificationsCountProvider = StreamProvider.autoDispose<int>((ref) {
  final userAsync = ref.watch(appUserProvider);
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value(0);
      return ref.watch(firestoreServiceProvider).getNotificationsStream(
        user.uid,
        showAdminNotifications: user.role == 'admin',
      ).map((notifications) {
        return notifications.where((n) => !n.isRead).length;
      });
    },
    loading: () => Stream.value(0),
    error: (_, __) => Stream.value(0),
  );
});
