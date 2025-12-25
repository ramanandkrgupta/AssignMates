import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../home/home_screen.dart';
import 'onboarding_state.dart';

final profileSetupStateProvider = StateProvider.autoDispose<OnboardingState>((ref) {
  return OnboardingState();
});

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  late final TextEditingController _collegeController;
  late final TextEditingController _cityController;
  int _currentPage = 0;

  static const Color primaryOrange = Color(0xFFFFAF00);

  @override
  void initState() {
    super.initState();
    final state = ref.read(profileSetupStateProvider);
    _collegeController = TextEditingController(text: state.collegeId);
    _cityController = TextEditingController(text: state.city);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _collegeController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileSetupStateProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Setup Profile (${_currentPage + 1}/4)',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildCollegeStep(state),
                  _buildLocationStep(state),
                  _buildPermissionsStep(state),
                  _buildFinalStep(state),
                ],
              ),
            ),
             // Progress Indicator
            LinearProgressIndicator(
              value: (_currentPage + 1) / 4,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(primaryOrange),
              minHeight: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollegeStep(OnboardingState state) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.school_outlined, size: 64, color: primaryOrange),
          const SizedBox(height: 24),
          const Text(
            'Select your College',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _collegeController,
            decoration: InputDecoration(
              labelText: 'College Name',
              hintText: 'Enter college name',
              labelStyle: TextStyle(color: Colors.grey[600]),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: primaryOrange, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
            ),
            onChanged: (value) {
                ref.read(profileSetupStateProvider.notifier).state = state.copyWith(collegeId: value);
            },
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {},
            child: const Text("My college isn't listed", style: TextStyle(color: Colors.grey)),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: state.collegeId?.isNotEmpty == true
                ? () => _nextPage()
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep(OnboardingState state) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.location_on_outlined, size: 64, color: primaryOrange),
          const SizedBox(height: 24),
          const Text(
            'Where are you based?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _cityController,
            decoration: InputDecoration(
              labelText: 'City',
              hintText: 'Enter your city',
              labelStyle: TextStyle(color: Colors.grey[600]),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: primaryOrange, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.location_city, color: Colors.grey),
            ),
             onChanged: (value) {
                ref.read(profileSetupStateProvider.notifier).state = state.copyWith(city: value);
            },
          ),
          const Spacer(),
          ElevatedButton(
             onPressed: state.city?.isNotEmpty == true
                ? () => _nextPage()
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsStep(OnboardingState state) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.security, size: 64, color: primaryOrange),
          const SizedBox(height: 24),
          const Text(
            'Permissions',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildPermissionTile(
            'Enable Notifications',
            'Get updates on your requests',
            state.notificationsEnabled,
            (val) => ref.read(profileSetupStateProvider.notifier).state = state.copyWith(notificationsEnabled: val),
          ),
          const SizedBox(height: 16),
           _buildPermissionTile(
            'Enable Camera',
            'To take photos of assignments',
            state.cameraPermissionGranted,
            (val) => ref.read(profileSetupStateProvider.notifier).state = state.copyWith(cameraPermissionGranted: val),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => _nextPage(),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        value: value,
        activeColor: primaryOrange,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildFinalStep(OnboardingState state) {
     return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
           const Icon(Icons.check_circle, size: 80, color: Colors.green),
           const SizedBox(height: 24),
          const Text(
            'You are all set!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Ready to find assignment help?',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
           const Spacer(),
          ElevatedButton(
            onPressed: _completeOnboarding,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Get Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    final user = ref.read(authStateProvider).value;
    final onboardingData = ref.read(profileSetupStateProvider);

    if (user != null) {
      try {
        final firestore = ref.read(firestoreServiceProvider);

        final updateData = {
          if (onboardingData.collegeId != null) 'collegeId': onboardingData.collegeId,
          if (onboardingData.city != null) 'city': onboardingData.city,
        };

        await firestore.updateUser(user.uid, updateData);

      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
        }
        return;
      }
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }
}
