import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../home/home_screen.dart';
import 'loading_screen.dart';
import 'profile_setup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  void _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
      // Fake delay to show the nice animation as requested
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        final authUser = ref.read(authStateProvider).value;
        if (authUser != null) {
          final firestore = ref.read(firestoreServiceProvider);
          final appUser = await firestore.getUser(authUser.uid);

          if (mounted) {
             // Explicit navigation based on profile completion
            if (appUser != null && (appUser.collegeId == null || appUser.collegeId!.isEmpty)) {
               Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
              );
            } else {
               Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingScreen();
    }

    const Color primaryOrange = Color(0xFFFFAF00);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               SizedBox(
                height: 300,
                child: Lottie.asset(
                  'assets/animations/welcome.json',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 48),

              // Branding
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                  children: [
                    TextSpan(text: 'Assign', style: TextStyle(color: primaryOrange)),
                    TextSpan(text: 'Mates', style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                  children: [
                    TextSpan(text: 'Assignment', style: TextStyle(color: primaryOrange)),
                    TextSpan(text: ' ', style: TextStyle(color: Colors.black)),
                    TextSpan(text: 'Help', style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // Google Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 1,
                    side: const BorderSide(color: Colors.grey, width: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/google.png',
                        height: 24,
                        width: 24,
                        errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.g_mobiledata, size: 24, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Indicator (Bars) as requested in "bg white and use color orange kind of color okay - ffaf00 this for buttons and bars in left side bottom"
              // Adding a decorative element
              const Spacer(),
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  width: 100,
                  height: 8,
                  decoration: BoxDecoration(
                    color: primaryOrange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
