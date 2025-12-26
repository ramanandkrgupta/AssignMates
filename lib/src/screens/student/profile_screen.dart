import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/glass_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;

    if (user == null) {
      return const Scaffold(backgroundColor: Colors.transparent, body: Center(child: CircularProgressIndicator()));
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
        backgroundColor: const Color(0xFFFFAF00),
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
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

             // Personal Details Section
            Text(
              'Personal Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 16),

            _buildEditableTile(
              context,
              ref,
              user,
              'Mobile Number',
              user.phoneNumber ?? 'Add Mobile Number',
              Icons.phone,
              'phoneNumber'
            ),
             _buildEditableTile(
              context,
              ref,
              user,
              'Location',
              user.location ?? 'Add Location',
              Icons.location_on,
              'location',
              isLocation: true
            ),

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

  Widget _buildEditableTile(BuildContext context, WidgetRef ref, AppUser user, String title, String value, IconData icon, String fieldKey, {bool isLocation = false}) {
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
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFFFAF00).withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFFFFAF00), size: 20),
        ),
        title: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        subtitle: Text(value, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.edit, color: Colors.grey, size: 20),
        onTap: () => _showEditDialog(context, ref, user, title, value, fieldKey, isLocation: isLocation),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref, AppUser user, String title, String currentValue, String fieldKey, {bool isLocation = false}) async {
    final controller = TextEditingController(text: currentValue == 'Add $title' ? '' : currentValue);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update $title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLocation) ...[
                ElevatedButton.icon(
                  onPressed: () async {
                     // Reuse location logic or simple placeholder for now as full logic is in CreateRequest
                     // ideally we move location logic to a service.
                     // For now, let user type or we can copy-paste the geolocator logic if needed.
                     // But strictly user asked for "update from there too", implying manual or auto.
                     Navigator.pop(context);
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please use the Create Request page to auto-detect GPS location for accuracy.')));
                  },
                  icon: const Icon(Icons.my_location),
                  label: const Text('Detect GPS Location'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                ),
                const SizedBox(height: 10),
                const Text('OR', style: TextStyle(fontSize: 10, color: Colors.grey)),
                 const SizedBox(height: 10),
            ],
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Enter $title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: isLocation ? 3 : 1,
              keyboardType: isLocation ? TextInputType.multiline : TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
