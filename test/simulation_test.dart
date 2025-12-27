import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:assignmates/firebase_options.dart';
import 'package:assignmates/src/services/firestore_service.dart';
import 'package:assignmates/src/services/notification_service.dart';
import 'package:assignmates/src/models/request_model.dart';
import 'package:assignmates/src/models/user_model.dart';

void main() {
  // This test requires internet and Firebase config to be valid in the env
  test('Simulate Student Request and Notification', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    print('🚀 Initializing Simulation Test...');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final container = ProviderContainer();
    final firestore = container.read(firestoreServiceProvider);
    final notifier = container.read(notificationServiceProvider);

    print('🔍 Searching for a student user...');
    final users = await firestore.getAllUsers();

    if (users.isEmpty) {
      print('❌ No users found in Firestore. Can\'t simulate.');
      return;
    }

    final student = users.firstWhere(
      (u) => u.role == 'student',
      orElse: () => users.first, // Fallback to any user if no student
    );

    print('✅ Using student: ${student.displayName} (${student.email})');

    final requestId = 'sim_${DateTime.now().millisecondsSinceEpoch}';
    final newRequest = RequestModel(
      id: requestId,
      studentId: student.uid,
      instructions: 'SIMULATED REQUEST: This is a test request with only instructions. No docs attached.',
      deadline: DateTime.now().add(const Duration(days: 3)),
      budget: 0.0,
      status: 'created',
      attachmentUrls: [],
      mediaUrls: {},
      pageCount: 1,
      createdAt: DateTime.now(),
      statusHistory: [{'status': 'created', 'timestamp': DateTime.now().millisecondsSinceEpoch}],
    );

    print('📦 Creating Request in Firestore...');
    await firestore.createRequest(newRequest);
    print('✅ Request created: $requestId');

    print('🔔 Triggering Admin Notification...');
    await notifier.notifyAdmins(
      title: 'New Order Received! 🚀',
      body: 'From ${student.city ?? 'Unknown'}, ${student.displayName} created 1 page order',
    );

    print('🎉 Simulation Complete.');

    // Cleanup - optional
    // await firestore.deleteRequest(requestId);
  });
}
