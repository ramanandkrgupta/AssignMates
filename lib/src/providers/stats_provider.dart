import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../models/request_model.dart';

class OrderStats {
  final int active;
  final int completed;
  final int cancelled;

  OrderStats({this.active = 0, this.completed = 0, this.cancelled = 0});
}

final studentOrderStatsProvider = StreamProvider.autoDispose<OrderStats>((ref) {
  final userAsync = ref.watch(appUserProvider);

  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value(OrderStats());

      return ref.watch(firestoreServiceProvider).getStudentRequests(user.uid).map((requests) {
        int active = 0;
        int completed = 0;
        int cancelled = 0;

        for (var request in requests) {
          if (request.status == 'completed' || request.status == 'delivered') {
            completed++;
          } else if (request.status == 'cancelled') {
            cancelled++;
          } else {
            active++;
          }
        }

        return OrderStats(
          active: active,
          completed: completed,
          cancelled: cancelled,
        );
      });
    },
    loading: () => Stream.value(OrderStats()),
    error: (_, __) => Stream.value(OrderStats()),
  );
});
