import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'admin_orders_screen.dart';
import 'admin_enquiries_screen.dart';
import 'admin_writers_screen.dart';
import 'admin_users_screen.dart';
import 'admin_pricing_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  static const Color primaryOrange = Color(0xFFFFAF00);

  @override
  Widget build(BuildContext context) {
    // Admin Screens
    final List<Widget> screens = [
      const AdminOrdersScreen(),
      const AdminEnquiriesScreen(),
      const AdminWritersScreen(),
      const AdminUsersScreen(),
      const AdminPricingScreen(),
    ];

    return Scaffold(
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
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Enquiries',
            ),
             NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Writers',
            ),
            NavigationDestination(
              icon: Icon(Icons.manage_accounts_outlined),
              selectedIcon: Icon(Icons.manage_accounts),
              label: 'Users',
            ),
             NavigationDestination(
              icon: Icon(Icons.currency_rupee_outlined),
              selectedIcon: Icon(Icons.currency_rupee),
              label: 'Pricing',
            ),
          ],
        ),
      ),
    );
  }
}
