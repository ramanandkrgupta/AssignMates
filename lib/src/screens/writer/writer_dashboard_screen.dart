import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart'; // Ensure UserModel is imported
import '../student/profile_screen.dart'; // Reusing Profile Screen

import 'writer_home_screen.dart';
import 'writer_orders_screen.dart';
import 'writer_messages_screen.dart';

class WriterDashboardScreen extends ConsumerStatefulWidget {
  const WriterDashboardScreen({super.key});

  @override
  ConsumerState<WriterDashboardScreen> createState() => _WriterDashboardScreenState();
}

class _WriterDashboardScreenState extends ConsumerState<WriterDashboardScreen> {
  int _selectedIndex = 0;
  static const Color primaryOrange = Color(0xFFFFAF00);

  @override
  Widget build(BuildContext context) {
    // Writer Screens
    final List<Widget> screens = [
      const WriterHomeScreen(),
      const WriterOrdersScreen(),
      const WriterMessagesScreen(),
       const ProfileScreen(), // Reuse generic profile screen
    ];

    return Scaffold(
      extendBody: true,
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
             if (states.contains(WidgetState.selected)) {
               return const IconThemeData(size: 28, color: Colors.black);
             }
             return const IconThemeData(size: 28, color: Colors.white);
          }),
        ),
        child: NavigationBar(
          height: 80,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.black,
          indicatorColor: primaryOrange,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'Orders',
            ),
             NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum),
              label: 'Messages',
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
