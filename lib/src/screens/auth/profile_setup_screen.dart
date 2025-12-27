import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../home/home_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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
  late final TextEditingController _phoneController;
  int _currentPage = 0;
  bool _isLocating = false;

  static const Color primaryOrange = Color(0xFFFFAF00);

  @override
  void initState() {
    super.initState();
    final state = ref.read(profileSetupStateProvider);
    _collegeController = TextEditingController(text: state.collegeId);
    _cityController = TextEditingController(text: state.city);
    _phoneController = TextEditingController(text: state.phoneNumber);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _collegeController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileSetupStateProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Setup Profile (${_currentPage + 1}/5)',
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
                  // Step 2 is Location (Index 1)
                  if (page == 1) {
                     final state = ref.read(profileSetupStateProvider);
                     // Auto-detect if not already set or locating
                     if ((state.city == null || state.city!.isEmpty) && !_isLocating) {
                       _detectLocation();
                     }
                  }
                },
                children: [
                  _buildCollegeStep(state),
                  _buildLocationStep(state),
                  _buildPhoneStep(state),
                  _buildPermissionsStep(state),
                  _buildFinalStep(state),
                ],
              ),
            ),
             // Progress Indicator
            LinearProgressIndicator(
              value: (_currentPage + 1) / 5,
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
            style: const TextStyle(color: Colors.black), // Make input text black
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
            child: const Text("My college isn't listed", style: TextStyle(color: Colors.black)),
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
            style: const TextStyle(color: Colors.black), // Make input text black
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
              suffixIcon: IconButton(
                icon: _isLocating 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: primaryOrange)
                    )
                  : const Icon(Icons.my_location, color: primaryOrange),
                onPressed: _isLocating ? null : _detectLocation,
              ),
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

  Widget _buildPhoneStep(OnboardingState state) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.phone_android, size: 64, color: primaryOrange),
          const SizedBox(height: 24),
          const Text(
            'Mobile Number',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _phoneController,
            style: const TextStyle(color: Colors.black),
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: 'Enter your mobile number',
              labelStyle: TextStyle(color: Colors.grey[600]),
               focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: primaryOrange, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.phone, color: Colors.grey),
            ),
             onChanged: (value) {
                ref.read(profileSetupStateProvider.notifier).state = state.copyWith(phoneNumber: value);
            },
          ),
          const Spacer(),
          ElevatedButton(
             onPressed: state.phoneNumber?.isNotEmpty == true && state.phoneNumber!.length >= 10
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
            (val) async {
              if (val) {
                // Request permission when enabled
                ref.read(profileSetupStateProvider.notifier).state = state.copyWith(notificationsEnabled: true);
                // We use the same 'startEarlyPermissionRequest' or similar logic, 
                // but since we want to ensure token sync, we can just call requestPermission on FCM directly or via service
                 // Actually, we should just update the state and let the service handle the actual permission request if not granted?
                 // Let's explicitly ask for permission here using our service.
                 // But wait, the user asked to "fix this" meaning ensure token is saved.
                 // So we should try to sync token here.
                 
                 final notifService = ref.read(notificationServiceProvider);
                 // We can re-use the startEarlyPermissionRequest but maybe rename it or just use it.
                 // It prints to console but also syncs token if authorized.
                 await notifService.startEarlyPermissionRequest();
              } else {
                 ref.read(profileSetupStateProvider.notifier).state = state.copyWith(notificationsEnabled: false);
              }
            },
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
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.black, fontSize: 13)),
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

  Future<void> _detectLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Show dialog to ask user to enable location
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Location Services Disabled'),
              content: const Text('Please enable location services to auto-detect your city.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                     Navigator.pop(context);
                     Geolocator.openLocationSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }
        // Check again after dialog closed (simulating user return)
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
             throw 'Location services are disabled.';
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permission denied.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permission permanently denied.';
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea;
        
        if (city != null) {
          setState(() {
            _cityController.text = city;
          });
          setState(() {
            _cityController.text = city;
          });
          
          
          // Construct formatted address
          // Example: 9W72+W2C, Keolari, 480994
          // We don't get PlusCode from placemark directly usually, but we can try to construct a good address
          // street, subLocality, locality, postalCode
          
           final formattedAddress = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}';

          final state = ref.read(profileSetupStateProvider);
          ref.read(profileSetupStateProvider.notifier).state = state.copyWith(
            city: city,
            formattedAddress: formattedAddress,
            latitude: position.latitude,
            longitude: position.longitude,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  void _nextPage() {
    FocusScope.of(context).unfocus(); // Hide keyboard
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
          if (onboardingData.phoneNumber != null) 'phoneNumber': onboardingData.phoneNumber,
          if (onboardingData.formattedAddress != null)
             'location': onboardingData.formattedAddress
          else if (onboardingData.latitude != null && onboardingData.longitude != null) 
            'location': "${onboardingData.latitude},${onboardingData.longitude}",
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
