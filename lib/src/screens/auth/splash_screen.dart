import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(appUserProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          if (user.collegeId == null || user.collegeId!.isEmpty) {
            return const OnboardingScreen();
          }
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}
