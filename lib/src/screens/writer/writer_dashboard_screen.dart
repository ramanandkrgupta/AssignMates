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
      const _WriterHomeScreen(),
      const _WriterHistoryScreen(),
      const _WriterMessagesScreen(),
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
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'History',
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

// 1. Writer Home Screen
class _WriterHomeScreen extends ConsumerStatefulWidget {
  const _WriterHomeScreen();

  @override
  ConsumerState<_WriterHomeScreen> createState() => _WriterHomeScreenState();
}

class _WriterHomeScreenState extends ConsumerState<_WriterHomeScreen> {
  bool _isUploading = false;

  Future<void> _uploadSampleWork(AppUser user) async {
    if (user.sampleWorkUrls.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can only upload up to 4 sample photos.')));
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _isUploading = true);
      try {
        final cloudinary = CloudinaryPublic(
          dotenv.env['CLOUDINARY_CLOUD_NAME']!,
          dotenv.env['CLOUDINARY_UPLOAD_PRESET']!,
          cache: false,
        );

        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(result.files.single.path!, resourceType: CloudinaryResourceType.Image),
        );

        final newUrl = response.secureUrl;
        final updatedList = List<String>.from(user.sampleWorkUrls)..add(newUrl);

        await ref.read(firestoreServiceProvider).updateUser(user.uid, {'sampleWorkUrls': updatedList});

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sample uploaded successfully!')));

      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _deleteSampleWork(AppUser user, String url) async {
    try {
      final updatedList = List<String>.from(user.sampleWorkUrls)..remove(url);
      await ref.read(firestoreServiceProvider).updateUser(user.uid, {'sampleWorkUrls': updatedList});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Stream user to get real-time updates on images
    final userAsync = ref.watch(currentUserStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Writer Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFAF00),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User not found'));
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                   // Stats / Welcome Section
                   Container(
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(
                       color: Colors.orange.withValues(alpha: 0.1),
                       shape: BoxShape.circle,
                     ),
                     child: const Icon(Icons.assignment, size: 64, color: Colors.orange),
                   ),
                   const SizedBox(height: 24),
                   Text(
                     'Welcome, ${user.displayName?.split(' ')[0] ?? 'Writer'}!',
                     style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 8),
                   Text('You have 0 active assignments.', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600])),
                   const SizedBox(height: 32),

                   SizedBox(
                     width: double.infinity,
                     child: ElevatedButton(
                       onPressed: () {},
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.black,
                         foregroundColor: Colors.white,
                         padding: const EdgeInsets.symmetric(vertical: 16),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       ),
                       child: Text('Find Assignments', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                     ),
                   ),

                   const SizedBox(height: 40),

                   // Sample Work Section
                   Align(
                     alignment: Alignment.centerLeft,
                     child: Text('My Sample Work', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                   ),
                   const SizedBox(height: 16),
                   if (user.sampleWorkUrls.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!)
                        ),
                        child: Center(child: Text('Add sample photos of your work to attract students.', textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.grey))),
                      ),

                   if (user.sampleWorkUrls.isNotEmpty)
                     GridView.builder(
                       shrinkWrap: true,
                       physics: const NeverScrollableScrollPhysics(),
                       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                         crossAxisCount: 2,
                         crossAxisSpacing: 10,
                         mainAxisSpacing: 10,
                         childAspectRatio: 1,
                       ),
                       itemCount: user.sampleWorkUrls.length,
                       itemBuilder: (context, index) {
                         final url = user.sampleWorkUrls[index];
                         return Stack(
                           children: [
                             Container(
                               decoration: BoxDecoration(
                                 borderRadius: BorderRadius.circular(12),
                                 image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                               ),
                             ),
                             Positioned(
                               top: 5,
                               right: 5,
                               child: InkWell(
                                 onTap: () => _deleteSampleWork(user, url),
                                 child: Container(
                                   padding: const EdgeInsets.all(4),
                                   decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                   child: const Icon(Icons.close, size: 16, color: Colors.white),
                                 ),
                               ),
                             ),
                           ],
                         );
                       },
                     ),

                   const SizedBox(height: 16),

                   if (user.sampleWorkUrls.length < 4)
                      ElevatedButton.icon(
                        onPressed: _isUploading ? null : () => _uploadSampleWork(user),
                        icon: _isUploading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.add_a_photo, size: 20),
                        label: Text(_isUploading ? 'Uploading...' : 'Add Sample Photo'),
                        style: ElevatedButton.styleFrom(
                           backgroundColor: const Color(0xFFFFAF00),
                           foregroundColor: Colors.white,
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// 2. Writer History Screen (Placeholder)
class _WriterHistoryScreen extends StatelessWidget {
  const _WriterHistoryScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task History', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFAF00),
        elevation: 0,
         automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             const Icon(Icons.history_edu, size: 64, color: Colors.grey),
             const SizedBox(height: 16),
             Text('No completed tasks yet.', style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// 3. Writer Messages Screen (Placeholder)
class _WriterMessagesScreen extends StatelessWidget {
  const _WriterMessagesScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFAF00),
        elevation: 0,
         automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             const Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
             const SizedBox(height: 16),
             Text('No active conversations.', style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
