import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

// Stream of the Firebase User (Auth State)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Stream of the AppUser from Firestore, dependent on Auth State
final appUserProvider = StreamProvider<AppUser?>((ref) async* {
  final authState = ref.watch(authStateProvider);
  
  final user = authState.value;
  if (user != null) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      
      // Ensure user exists (This side-effect is handled here for reactivity 'freshness')
      // Ideally this is done in the sign-in flow, but to be safe we check.
      // Actually, let's just listen to the doc. Creation happens in controller.
      yield* firestoreService.getUserStream(user.uid);
  } else {
    yield null;
  }
});

// Controller for Auth Actions (Sign In, Sign Out)
final authControllerProvider = AsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // No initial state to load
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authService = ref.read(authServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      final credential = await authService.signInWithGoogle();
      
      if (credential != null && credential.user != null) {
        final firebaseUser = credential.user!;
        
        // Check if user exists
        final existingUser = await firestoreService.getUser(firebaseUser.uid);
        
        if (existingUser == null) {
          // Create new user
          final newUser = AppUser(
            uid: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL,
            role: 'student',
            createdAt: DateTime.now(),
          );
          await firestoreService.createUser(newUser);
        }
      }
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authServiceProvider).signOut();
    });
  }
}
