import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../home/home_screen.dart';
import 'onboarding_state.dart';

final onboardingStateProvider = StateProvider.autoDispose<OnboardingState>((ref) {
  return OnboardingState();
});

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Setup Profile (${_currentPage + 1}/4)'),
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              )
            : null,
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
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
    );
  }

  Widget _buildCollegeStep(OnboardingState state) {
    final TextEditingController collegeController = TextEditingController(text: state.collegeId);
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Select your College', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: collegeController, // TODO: Use Autocomplete/Dropdown with real data
            decoration: const InputDecoration(
              labelText: 'College Name',
              border: OutlineInputBorder(),
              hintText: 'Enter college name',
            ),
            onChanged: (value) {
                ref.read(onboardingStateProvider.notifier).state = state.copyWith(collegeId: value);
            },
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: () {}, child: const Text("My college isn't listed")),
          const Spacer(),
          ElevatedButton(
            onPressed: state.collegeId?.isNotEmpty == true
                ? () => _nextPage()
                : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep(OnboardingState state) {
     final TextEditingController cityController = TextEditingController(text: state.city);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Where are you based?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: cityController,
            decoration: const InputDecoration(
              labelText: 'City',
              border: OutlineInputBorder(),
            ),
             onChanged: (value) {
                ref.read(onboardingStateProvider.notifier).state = state.copyWith(city: value);
            },
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: state.city?.isNotEmpty == true
                ? () => _nextPage()
                : null,
            child: const Text('Next'),
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
        children: [
          const Text('Permissions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Get updates on your requests'),
            value: state.notificationsEnabled,
            onChanged: (bool value) {
                ref.read(onboardingStateProvider.notifier).state = state.copyWith(notificationsEnabled: value);
            },
          ),
           SwitchListTile(
            title: const Text('Enable Camera'),
            subtitle: const Text('To take photos of assignments'),
            value: state.cameraPermissionGranted,
            onChanged: (bool value) {
               ref.read(onboardingStateProvider.notifier).state = state.copyWith(cameraPermissionGranted: value);
            },
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => _nextPage(),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalStep(OnboardingState state) {
     return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           const Icon(Icons.check_circle, size: 80, color: Colors.green),
           const SizedBox(height: 20),
          const Text('You are all set!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Ready to find assignment help?'),
           const Spacer(),
          ElevatedButton(
            onPressed: _completeOnboarding,
            child: const Text('Get Started'),
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
    final onboardingData = ref.read(onboardingStateProvider);
    
    if (user != null) {
      try {
        final firestore = ref.read(firestoreServiceProvider);
        
        final updateData = {
          if (onboardingData.collegeId != null) 'collegeId': onboardingData.collegeId,
          if (onboardingData.city != null) 'city': onboardingData.city,
          // We can also store permissions if we wanted, but local state is fine for now or user prefs.
        };
        
        await firestore.updateUser(user.uid, updateData);
        
        // Refresh user provider?? 
        // The user provider listens to Firestore stream, so it should auto-update!
        
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
        }
        return; // Don't navigate if error? Or allow anyway? Better to stop.
      }
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }
}
