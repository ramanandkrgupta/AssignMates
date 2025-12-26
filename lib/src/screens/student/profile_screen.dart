import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    if (user == null) {
      return const Scaffold(backgroundColor: Colors.transparent, body: Center(child: Text('Please login')));
    }

    // Mock stats for now
    final stats = [
      {'label': 'Requests', 'value': '12'},
      {'label': 'Completed', 'value': '8'},
      {'label': 'Pending', 'value': '4'},
    ];

    const primaryOrange = Color(0xFFFFAF00);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.settings, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                    backgroundColor: Colors.grey[200],
                    child: user.photoURL == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: primaryOrange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, size: 16, color: Colors.white),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.displayName ?? 'Student',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
            ).animate().fadeIn().slideY(begin: 0.5),
            Text(
              user.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5),
            const SizedBox(height: 32),

            // Stats Row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: stats.map((stat) {
                  return Column(
                    children: [
                      Text(
                        stat['value']!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryOrange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stat['label']!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

            const SizedBox(height: 32),
            _buildSettingsItem(context, Icons.history, 'Order History'),
            _buildSettingsItem(context, Icons.help_outline, 'Help & Support'),
            _buildSettingsItem(context, Icons.privacy_tip_outlined, 'Privacy Policy'),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).signOut();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.withOpacity(0.2)),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(12),
         boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2)),
         ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black87),
        title: Text(title, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          // TODO: Implement settings
        },
      ),
    );
  }
}
