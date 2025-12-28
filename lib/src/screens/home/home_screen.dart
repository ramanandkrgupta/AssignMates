import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/geometric_background.dart';
import '../../widgets/animated_notification_icon.dart';
import '../student/create_request_screen.dart';
import '../student/request_history_screen.dart';
import '../student/profile_screen.dart';

import '../student/support_screen.dart';
import '../common/notification_screen.dart';

final homeTabIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const Color primaryOrange = Color(0xFFFFAF00);
  static const Color darkBlack = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(homeTabIndexProvider);

    // List of screens for the bottom navigation
    final List<Widget> screens = [
      const _HomeContent(),       // Home Dashboard
      const RequestHistoryScreen(),
      const SupportScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: GeometricBackground(
        child: screens[selectedIndex],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
             if (states.contains(WidgetState.selected)) {
               return const IconThemeData(size: 28, color: Colors.black); // Selected icon color (on orange pill)
             }
             return const IconThemeData(size: 28, color: Colors.white); // Unselected icon color
          }),
        ),
        child: NavigationBar(
          height: 80, // Taller navigation bar
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            ref.read(homeTabIndexProvider.notifier).state = index;
          },
          backgroundColor: Colors.black, // Dark background
          indicatorColor: primaryOrange, // Orange pill
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'History',
            ),
             NavigationDestination(
              icon: Icon(Icons.headset_mic_outlined),
              selectedIcon: Icon(Icons.headset_mic),
              label: 'Support',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(appUserProvider);
    final user = userAsync.value;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                      'Hello,',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      user?.displayName?.split(' ')[0] ?? 'Student',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                 ),
                 Row(
                   children: [
                     Consumer(
                       builder: (context, ref, child) {
                         final unreadCount = ref.watch(unreadNotificationsCountProvider).value ?? 0;
                         return AnimatedNotificationIcon(
                           unreadCount: unreadCount,
                           onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
                           },
                         );
                       },
                     ),
                     const SizedBox(width: 16),
                     CircleAvatar(
                       radius: 24,
                       backgroundColor: Colors.grey[200],
                       backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                       child: user?.photoURL == null ? const Icon(Icons.person, color: Colors.grey) : null,
                     ),
                   ],
                 ),
              ],
            ),
            const SizedBox(height: 48),

            // Hero Text from Image
            Text(
              'Secure.',
              style: GoogleFonts.outfit(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                height: 1.1,
              ),
            ),
            Text(
              'Anonymous.',
              style: GoogleFonts.outfit(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                height: 1.1,
              ),
            ),
            Text(
              'Private.',
              style: GoogleFonts.outfit(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.black, // Keeping black per request "make them black" in general, or matching image
                height: 1.1,
              ),
            ),

            const Spacer(),

            // Main Action Card (simplified to just a button or small card)
             Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Need Assignment Help?',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Post a request and get matched with a writer instantly.',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CreateRequestScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFAF00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Get Started 🚀',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
