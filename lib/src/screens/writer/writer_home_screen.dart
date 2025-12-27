import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photo_view/photo_view.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../models/request_model.dart';

final activeOrdersProvider = StreamProvider.autoDispose<List<RequestModel>>((ref) {
  final user = ref.watch(currentUserStreamProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getWriterRequestsStream(user.uid);
});

class WriterHomeScreen extends ConsumerStatefulWidget {
  const WriterHomeScreen({super.key});

  @override
  ConsumerState<WriterHomeScreen> createState() => _WriterHomeScreenState();
}

class _WriterHomeScreenState extends ConsumerState<WriterHomeScreen> {
  bool _isUploading = false;

  Future<void> _uploadSampleWork(AppUser user) async {
    final int currentCount = user.sampleWorkUrls.length;
    if (currentCount >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can only upload up to 4 sample photos.')));
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      if (!mounted) return;
      setState(() => _isUploading = true);
      try {
        final cloudinary = CloudinaryPublic(
          dotenv.env['CLOUDINARY_CLOUD_NAME']!,
          dotenv.env['CLOUDINARY_UPLOAD_PRESET']!,
          cache: false,
        );

        final int availableSlots = 4 - currentCount;
        final filesToUpload = result.files.take(availableSlots).toList();

        if (result.files.length > availableSlots) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Only the first $availableSlots selected photos will be uploaded.')));
        }

        List<String> newUrls = [];
        for (var file in filesToUpload) {
          if (file.path != null) {
            CloudinaryResponse response = await cloudinary.uploadFile(
              CloudinaryFile.fromFile(file.path!, resourceType: CloudinaryResourceType.Image),
            );
            newUrls.add(response.secureUrl);
          }
        }

        final updatedList = List<String>.from(user.sampleWorkUrls)..addAll(newUrls);

        await ref.read(firestoreServiceProvider).updateUser(user.uid, {'sampleWorkUrls': updatedList});

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Samples uploaded successfully!')));

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

  void _showImagePopup(String url) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: PhotoView(
                imageProvider: NetworkImage(url),
                backgroundDecoration: const BoxDecoration(color: Colors.transparent),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showAvailabilityConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirm Action',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Do you really want to change your availability ?',
          style: GoogleFonts.outfit(),
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('No', style: GoogleFonts.outfit(color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              ),
              Container(width: 1, height: 20, color: Colors.grey[300]),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Yes', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFFFFAF00),
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 150,
        leading: Consumer(
          builder: (context, ref, child) {
            final ordersAsync = ref.watch(activeOrdersProvider);
            return ordersAsync.when(
              data: (orders) {
                final activeCount = orders.where((o) => o.status != 'completed' && o.status != 'cancelled').length;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Active Orders - $activeCount',
                        style: GoogleFonts.outfit(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            );
          },
        ),
        actions: [
          userAsync.when(
            data: (user) {
              if (user == null) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Row(
                  children: [
                    Text(
                      user.isAvailable ? 'Available' : 'Unavailable',
                      style: GoogleFonts.outfit(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: user.isAvailable,
                      onChanged: (value) async {
                        final confirmed = await _showAvailabilityConfirmation(context);
                        if (confirmed == true) {
                          await ref.read(firestoreServiceProvider).updateUser(user.uid, {'isAvailable': value});
                        }
                      },
                      activeColor: Colors.green,
                      activeTrackColor: Colors.green.withValues(alpha: 0.3),
                      inactiveThumbColor: Colors.red,
                      inactiveTrackColor: Colors.red.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User not found'));
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
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
                   Consumer(
                     builder: (context, ref, child) {
                       final ordersAsync = ref.watch(activeOrdersProvider);
                       return ordersAsync.when(
                         data: (orders) {
                           final activeCount = orders.where((o) => o.status != 'completed' && o.status != 'cancelled').length;
                           return Text(
                             'You have $activeCount active assignments.',
                             style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600]),
                           );
                         },
                         loading: () => Text('Loading assignments...', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600])),
                         error: (_, __) => Text('Error loading assignments', style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600])),
                       );
                     },
                   ),
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
                       child: Text(
                         'Admin will assign you assignments if you are available',
                         style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                         textAlign: TextAlign.center,
                       ),
                     ),
                   ),

                   const SizedBox(height: 40),

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
                             InkWell(
                               onTap: () => _showImagePopup(url),
                               child: Container(
                                 decoration: BoxDecoration(
                                   borderRadius: BorderRadius.circular(12),
                                   image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                                 ),
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
                       Column(
                         children: [
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
                           const SizedBox(height: 12),
                           Text(
                             'You can upload any 4 photoes as sample',
                             style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500]),
                           ),
                         ],
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
