import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/notification_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Fire and forget early permission request
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1. Notification Permission
      ref.read(notificationServiceProvider).startEarlyPermissionRequest();
      
      // 2. Location Permission (Silent check/request)
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          // Request permission
          await Geolocator.requestPermission();
        }
      } catch (e) {
        debugPrint("Error requesting early location permission: $e");
      }
    });
  }

  final List<Map<String, String>> _onboardingData = [
    {
      "animation": "assets/animations/thinking.json",
      "title": "Bored writing assignments?",
      "subtitle": "The Assignment Help is here as AssignMates",
    },
    {
      "animation": "assets/animations/collaboration.json",
      "title": "Collaboration with Notes Mates",
      "subtitle": "Assignment Help launched this application in cooperation with Notes Mates",
    },
    {
      "animation": "assets/animations/wellbeing.json",
      "title": "Stressed about assignments?",
      "subtitle": "We are here for your mental wellbeing. Seek help.",
    },
    {
      "animation": "assets/animations/community.json",
      "title": "Join our Community",
      "subtitle": "Be part of the AssignMates family",
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() async {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', true);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryOrange = Color(0xFFFFAF00);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) {
                  setState(() {
                    _currentPage = value;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  final data = _onboardingData[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Branding on First Screen (Optional, but looks nice)
                        if (index == 0) ...[
                          RichText(
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
                          const SizedBox(height: 40),
                        ],

                        SizedBox(
                          height: 300,
                          child: Lottie.asset(
                            data["animation"]!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error, color: Colors.red, size: 50);
                            },
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          data["title"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          data["subtitle"]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(
                      _onboardingData.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? primaryOrange : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Next/Get Started Button
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                      elevation: 0,
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
