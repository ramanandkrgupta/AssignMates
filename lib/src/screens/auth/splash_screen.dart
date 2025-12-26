import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'profile_setup_screen.dart';
import '../home/home_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../writer/writer_dashboard_screen.dart';

final onboardingSeenProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('hasSeenOnboarding') ?? false;
});

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(appUserProvider);
    final onboardingSeenAsync = ref.watch(onboardingSeenProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          if (user.role == 'admin') {
            return const AdminDashboardScreen();
          }
          if (user.role == 'writer') {
            return const WriterDashboardScreen();
          }
          if (user.collegeId == null || user.collegeId!.isEmpty) {
            return const ProfileSetupScreen();
          }
          return const HomeScreen();
        } else {
          return onboardingSeenAsync.when(
            data: (seen) {
              if (seen) {
                return const LoginScreen();
              } else {
                return const OnboardingScreen();
              }
            },
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const LoginScreen(), // Fallback to login on error
          );
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
