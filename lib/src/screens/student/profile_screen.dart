import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/stats_provider.dart';
import 'support_screen.dart';
import '../common/privacy_policy_screen.dart';
import '../common/terms_service_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final statsAsync = ref.watch(studentOrderStatsProvider);
    final user = userAsync.value;

    if (user == null) {
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator(color: Color(0xFFFFAF00))));
    }

    const primaryOrange = Color(0xFFFFAF00);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Account', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black54),
            onPressed: () {}, // For future settings
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 120), // Extra bottom padding for navigation
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Section
            _buildProfileHeader(user, primaryOrange),
            const SizedBox(height: 40),

            // Order Quick Stats
            statsAsync.when(
              data: (stats) => _buildQuickStats(stats, primaryOrange),
              loading: () => _buildQuickStats(OrderStats(), primaryOrange),
              error: (_, __) => _buildQuickStats(OrderStats(), primaryOrange),
            ),
            const SizedBox(height: 40),

            // Account Information Section
            _buildSectionTitle('ACCOUNT INFORMATION'),
            const SizedBox(height: 16),
            _buildInfoCard(context, ref, user, primaryOrange),

            const SizedBox(height: 32),

            // Support & Policy Section
            _buildSectionTitle('SUPPORT & LEGAL'),
            const SizedBox(height: 12),
            _buildMenuTile(context, Icons.headset_mic_outlined, 'Help & Support', onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportScreen()));
            }),
            _buildMenuTile(context, Icons.privacy_tip_outlined, 'Privacy Policy', onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
            }),
            _buildMenuTile(context, Icons.description_outlined, 'Terms of Service', onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()));
            }),

            const SizedBox(height: 40),

            // Logout Button
            _buildLogoutButton(context, ref, primaryOrange),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AppUser user, Color primaryOrange) {
    // Calculate profile completion %
    int filled = 0;
    if (user.city != null) filled++;
    if (user.phoneNumber != null) filled++;
    if (user.location != null) filled++;
    final double completion = filled / 3.0;

    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: CircularProgressIndicator(
                value: completion,
                backgroundColor: primaryOrange.withOpacity(0.1),
                color: primaryOrange,
                strokeWidth: 3,
              ),
            ),
            CircleAvatar(
              radius: 38,
              backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              backgroundColor: Colors.grey[100],
              child: user.photoURL == null ? const Icon(Icons.person, size: 38, color: Colors.grey) : null,
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName ?? 'Student',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 4),
              Text(
                user.email ?? '',
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  completion == 1.0 ? 'Profile Complete' : 'Finish your profile',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: primaryOrange),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(OrderStats stats, Color primaryOrange) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
       decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark premium card
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Active', stats.active.toString(), primaryOrange),
          Container(width: 1, height: 30, color: Colors.white12),
          _buildStatItem('Completed', stats.completed.toString(), Colors.white),
          Container(width: 1, height: 30, color: Colors.white12),
          _buildStatItem('Cancelled', stats.cancelled.toString(), Colors.white38),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: valueColor)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFFFAF00),
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, WidgetRef ref, AppUser user, Color primaryOrange) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildInfoTile(context, ref, user, 'Phone', user.phoneNumber ?? 'Add Number', Icons.phone_outlined, 'phoneNumber'),
          _buildDivider(),
          _buildInfoTile(context, ref, user, 'City', user.city ?? 'Add City', Icons.location_city_outlined, 'city'),
          _buildDivider(),
          _buildInfoTile(context, ref, user, 'Full Address', user.location ?? 'Add Address', Icons.map_outlined, 'location', isLocation: true),
        ],
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, WidgetRef ref, AppUser user, String label, String value, IconData icon, String key, {bool isLocation = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey[200]!)),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
      title: Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
      trailing: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFFFAF00)),
      onTap: () => _showEditDialog(context, ref, user, label, value, key, isLocation: isLocation),
    );
  }

  Widget _buildDivider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Divider(height: 1, color: Colors.grey[200]),
  );

  Widget _buildMenuTile(BuildContext context, IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      leading: Container(
         padding: const EdgeInsets.all(8),
         decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
         child: Icon(icon, size: 20, color: Colors.black54),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref, Color primaryOrange) {
    return InkWell(
      onTap: () => _showLogoutDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
            const SizedBox(width: 10),
            Text('Sign Out', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref, AppUser user, String title, String currentValue, String fieldKey, {bool isLocation = false}) async {
    final controller = TextEditingController(text: currentValue.contains('Add') ? '' : currentValue);
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text('Update $title', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLocation) ...[
                    ElevatedButton.icon(
                      onPressed: () async {
                         setDialogState(() => isLoading = true);
                         try {
                            bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                            if (!serviceEnabled) {
                               serviceEnabled = await Geolocator.openLocationSettings();
                               if (!serviceEnabled) throw Exception('Please enable Location Services (GPS) on your device.');
                            }

                            var permission = await Geolocator.checkPermission();
                            if (permission == LocationPermission.denied) {
                               permission = await Geolocator.requestPermission();
                               if (permission == LocationPermission.denied) throw Exception('Location permissions are denied.');
                            }
                            if (permission == LocationPermission.deniedForever) {
                               throw Exception('Location permissions are permanently denied. Please enable them in App Settings.');
                            }

                            final position = await Geolocator.getCurrentPosition();
                            final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
                            if (placemarks.isNotEmpty) {
                               final place = placemarks.first;
                               controller.text = '${place.street}, ${place.subLocality}, ${place.locality}';
                            }
                         } catch (e) {
                             debugPrint('GPS Error: $e');
                             if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('GPS Error: $e'), backgroundColor: Colors.red));
                             }
                         } finally {
                            if (context.mounted) setDialogState(() => isLoading = false);
                         }
                      },
                      icon: isLoading ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.my_location),
                      label: Text(isLoading ? 'Detecting...' : 'Use My GPS'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                    ),
                    const SizedBox(height: 10),
                ],
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Enter $title',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  style: GoogleFonts.outfit(),
                  maxLines: isLocation ? 3 : 1,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey))),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                     await ref.read(firestoreServiceProvider).updateUser(user.uid, {fieldKey: controller.text});
                     if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFAF00), foregroundColor: Colors.white),
                child: const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Sign Out', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to log out?', style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Stay')),
          ElevatedButton(
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
