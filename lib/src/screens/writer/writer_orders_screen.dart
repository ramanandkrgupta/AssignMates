import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../models/request_model.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/audio_player_widget.dart';
import '../../widgets/animated_notification_icon.dart';
import '../common/media_viewer_screen.dart';
import '../common/notification_screen.dart';
import '../../models/timeline_step.dart';

class WriterOrdersScreen extends ConsumerStatefulWidget {
  const WriterOrdersScreen({super.key});

  @override
  ConsumerState<WriterOrdersScreen> createState() => _WriterOrdersScreenState();
}

class _WriterOrdersScreenState extends ConsumerState<WriterOrdersScreen> {
  String? _uploadingOrderId;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('My Active Assignments', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: Color(0xFFFFAF00)),
            onPressed: () => _callAdmin(),
            tooltip: 'Call Admin',
          ),
        ],
      ),
      body: StreamBuilder<List<RequestModel>>(
        stream: ref.read(firestoreServiceProvider).getWriterRequestsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFFAF00)));
          }
          final orders = (snapshot.data ?? []).where((r) => r.status != 'completed' && r.status != 'cancelled').toList();

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_outlined, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text('No active orders.', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Added bottom padding for navigation
            itemCount: orders.length,
            itemBuilder: (context, index) => _buildOrderCard(orders[index]),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(RequestModel request) {
    // Show upload button for all active assigned states as requested
    final bool canUpload = ['assigned', 'payment_pending', 'in_progress', 'payment_remaining_pending'].contains(request.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${request.id.substring(0, 8)}', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
                    Text('${request.pageCount} Pages | ${request.pageType}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                _buildStatusBadge(request.status),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('INSTRUCTIONS'),
                const SizedBox(height: 8),
                Text(request.instructions, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 20),

                _buildSectionTitle('ATTACHMENTS'),
                const SizedBox(height: 8),
                _buildMediaSection(request),

                const SizedBox(height: 24),
                if (request.status == 'assigned')
                   SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                         await ref.read(firestoreServiceProvider).updateRequestStatusWithStep(
                           request.id,
                           'in_progress',
                             TimelineStep(
                             status: 'in_progress',
                             title: 'Writer Started',
                             description: 'Writer has started working',
                             timestamp: DateTime.now(),
                             notificationsSent: {'student': false},
                           )
                         );
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: Text('START WORK', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                else if (canUpload)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _uploadingOrderId != null ? null : () => _uploadVerificationPhotos(request),
                      icon: _uploadingOrderId == request.id
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.file_upload_outlined),
                      label: Text(_uploadingOrderId == request.id ? 'UPLOADING...' : 'UPLOAD PROOF & COMPLETE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFAF00),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                else if (request.status == 'review_pending')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text('Proof Submitted', style: GoogleFonts.outfit(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.outfit(color: const Color(0xFFFFAF00), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1));
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.blue;
    if (status == 'review_pending') color = Colors.orange;
    if (status == 'delivering') color = Colors.purple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(status.toUpperCase().replaceAll('_', ' '), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMediaSection(RequestModel request) {
    final docs = request.attachmentUrls.where((url) => url.toLowerCase().contains('.pdf')).toList();
    final images = request.attachmentUrls.where((url) => ['.jpg', '.jpeg', '.png', '.webp'].any((ext) => url.toLowerCase().contains(ext))).toList();
    final voiceNote = request.voiceNoteUrl;

    return Column(
      children: [
        if (voiceNote != null) AudioPlayerWidget(url: voiceNote, label: 'Voice Note'),
        if (docs.isNotEmpty)
          _buildMediaItem('Documents (${docs.length})', Icons.description_outlined, Colors.orange, () => _viewFiles(docs, 'Documents'), downloadUrl: docs.length == 1 ? docs.first : null),
        if (images.isNotEmpty)
          _buildMediaItem('Images (${images.length})', Icons.image_outlined, Colors.blue, () => _viewFiles(images, 'Images'), downloadUrl: images.length == 1 ? images.first : null),
        if (request.attachmentUrls.isEmpty && voiceNote == null)
          Text('No attachments provided.', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 12)),
      ],
    );
  }

  Widget _buildMediaItem(String label, IconData icon, Color color, VoidCallback onTap, {String? downloadUrl}) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (downloadUrl != null)
            IconButton(
              icon: const Icon(Icons.download, size: 18, color: Color(0xFFFFAF00)),
              onPressed: () => _downloadFile(downloadUrl),
              tooltip: 'Download',
            ),
          const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white24),
        ],
      ),
    );
  }

  Future<void> _downloadFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download started...')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not start download'), backgroundColor: Colors.red));
      }
    }
  }

  void _viewFiles(List<String> urls, String title) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => MediaViewerScreen(urls: urls, title: title)));
  }

  Future<void> _callAdmin() async {
    const adminPhone = '7742880154'; // Replace with actual admin phone if dynamic
    final uri = Uri.parse('tel:$adminPhone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _uploadVerificationPhotos(RequestModel request) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true);
    if (result == null || result.files.isEmpty) return;

    if (result.files.length > 4) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Max 4 photos allowed')));
      return;
    }

    setState(() => _uploadingOrderId = request.id);
    try {
      final cloudinary = cloudinaryServiceProvider;
      List<String> uploadedUrls = [];

      for (var file in result.files) {
        final url = await cloudinary.uploadFile(file: file, folder: 'verification_proofs/${request.id}');
        if (url != null) uploadedUrls.add(url);
      }

      await ref.read(firestoreServiceProvider).updateRequestStatusWithStep(
        request.id,
        'review_pending',
        TimelineStep(
          status: 'review_pending',
          title: 'Proof Submitted',
          description: request.isHalfPayment
              ? 'Writer uploaded verification photos. Make remaining payment now for final steps.'
              : 'Writer uploaded verification photos',
          timestamp: DateTime.now(),
          notificationsSent: {'admin': false, 'student': false},
        ),
        additionalData: {'verificationPhotos': uploadedUrls}
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Work submitted for review!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _uploadingOrderId = null);
    }
  }
}
