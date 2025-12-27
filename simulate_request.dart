import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lib/firebase_options.dart';
import 'lib/src/services/firestore_service.dart';
import 'lib/src/services/notification_service.dart';
import 'lib/src/models/request_model.dart';
import 'lib/src/models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Initializing Simulation...');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final container = ProviderContainer();
  final firestore = container.read(firestoreServiceProvider);
  final notifier = container.read(notificationServiceProvider);

  print('🔍 Searching for a student user...');
  final users = await firestore.getAllUsers();
  final student = users.firstWhere(
    (u) => u.role == 'student',
    orElse: () => throw Exception('No student found in DB'),
  );

  print('✅ Found student: ${student.displayName} (${student.email})');

  final requestId = 'sim_${DateTime.now().millisecondsSinceEpoch}';
  final newRequest = RequestModel(
    id: requestId,
    studentId: student.uid,
    instructions: 'SIMULATED REQUEST: Please provide a 5-page assignment on Quantum Computing. This is a dummy request for testing notifications.',
    deadline: DateTime.now().add(const Duration(days: 3)),
    budget: 50.0,
    status: 'created',
    attachmentUrls: [],
    mediaUrls: [],
    pageCount: 5,
    createdAt: DateTime.now(),
    statusHistory: [{'status': 'created', 'timestamp': DateTime.now().millisecondsSinceEpoch}],
  );

  print('📦 Creating Request $requestId...');
  await firestore.createRequest(newRequest);

  print('🔔 Triggering Admin Notification...');
  await notifier.notifyAdmins(
    title: 'New Order Received! 🚀',
    body: 'From ${student.city ?? 'Unknown'}, ${student.displayName} created 5 pages order',
  );

  print('🎉 Simulation Complete. Check the admin device.');

  // Wait a bit for Firestore sync
  await Future.delayed(const Duration(seconds: 3));
  print('Exiting...');
}
