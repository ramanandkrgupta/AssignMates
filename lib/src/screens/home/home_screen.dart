import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';
import '../../themes/dark.dart';

// Screens
import '../student/create_request_screen.dart';
import '../student/request_history_screen.dart';
import '../student/profile_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(appUserProvider);
    final user = userAsync.value;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'AssignMates',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          // Subtle gradient background
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.eerieBlack,
              Color(0xFF232323),
              AppColors.voidBlack,
            ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: SizedBox(height: 100), // Spacing for AppBar
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (user != null)
                      Text(
                        'Hello, ${user.displayName?.split(' ')[0] ?? 'Student'}!',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
                    const SizedBox(height: 8),
                    Text(
                      'Ready to crush your assignments?',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white54,
                          ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Hero(
                  tag: 'main-action-card',
                  child: GlassCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateRequestScreen()),
                      );
                    },
                    color: AppColors.electricViolet.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(24),
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Need Help?',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.electricViolet,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Post a new assignment\nrequest now.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppColors.electricViolet,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.black, size: 32),
                        ),
                      ],
                    ),
                  ).animate().scale(delay: 300.ms, curve: Curves.easeOutBack),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                   _buildDashboardItem(
                    context,
                    title: 'History',
                    icon: Icons.history,
                    color: AppColors.cyberBlue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RequestHistoryScreen()),
                    ),
                    delay: 400,
                  ),
                   _buildDashboardItem(
                    context,
                    title: 'Profile',
                    icon: Icons.person_outline,
                    color: Colors.orangeAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    ),
                    delay: 500,
                  ),
                  _buildDashboardItem(
                    context,
                    title: 'Messages',
                    icon: Icons.chat_bubble_outline,
                    color: Colors.pinkAccent,
                    onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming Soon!')),
                      );
                    },
                    delay: 600,
                  ),
                   _buildDashboardItem(
                    context,
                    title: 'Support',
                    icon: Icons.headset_mic_outlined,
                    color: Colors.greenAccent,
                    onTap: () {},
                    delay: 700,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
    return GlassCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2);
  }
}
