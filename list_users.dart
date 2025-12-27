import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lib/firebase_options.dart';
import 'lib/src/services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final container = ProviderContainer();
  final firestore = container.read(firestoreServiceProvider);

  print('FETCHING_USERS_START');
  final users = await firestore.getAllUsers();
  for (var user in users) {
    print('USER: ${user.uid} | ${user.role} | ${user.email} | ${user.displayName}');
  }
  print('FETCHING_USERS_END');

  // Exit script
  print('Done.');
}
