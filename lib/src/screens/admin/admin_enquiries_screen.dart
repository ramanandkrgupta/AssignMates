import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/enquiry_model.dart';
import 'community_links_screen.dart';

class AdminEnquiriesScreen extends ConsumerWidget {
  const AdminEnquiriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Enquiries', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.link, color: Color(0xFFFFAF00)),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityLinksScreen())),
        ),
      ),
      body: StreamBuilder<List<EnquiryModel>>(
        stream: ref.watch(firestoreServiceProvider).getEnquiriesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFFAF00)));
          }

          final enquiries = snapshot.data ?? [];
          if (enquiries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mark_email_unread_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No enquiries found.', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: enquiries.length,
            itemBuilder: (context, index) {
              final enquiry = enquiries[index];
              return _buildEnquiryStrip(context, ref, enquiry);
            },
          );
        },
      ),
    );
  }

  Widget _buildEnquiryStrip(BuildContext context, WidgetRef ref, EnquiryModel enquiry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: enquiry.isResolved ? Colors.grey[50] : const Color(0xFFFFF9EB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: enquiry.isResolved ? Colors.grey[200]! : const Color(0xFFFFAF00).withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: () => _showEnquiryDetails(context, ref, enquiry),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[200],
          backgroundImage: enquiry.userPhotoUrl != null ? NetworkImage(enquiry.userPhotoUrl!) : null,
          child: enquiry.userPhotoUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                enquiry.userName,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
              ),
            ),
            _buildTypeTag(enquiry.type),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              enquiry.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM d, h:mm a').format(enquiry.createdAt),
              style: GoogleFonts.outfit(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
        trailing: enquiry.isResolved
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.pending_actions, color: Color(0xFFFFAF00)),
      ),
    );
  }

  Widget _buildTypeTag(String type) {
    Color color;
    IconData icon;
    switch (type) {
      case 'whatsapp': color = const Color(0xFF25D366); icon = Icons.chat; break;
      case 'call': color = Colors.blue; icon = Icons.phone; break;
      case 'preset': color = Colors.purple; icon = Icons.list; break;
      default: color = Colors.orange; icon = Icons.text_snippet;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(type.toUpperCase(), style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  void _showEnquiryDetails(BuildContext context, WidgetRef ref, EnquiryModel enquiry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Enquiry Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            Text('MESSAGE:', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(enquiry.message, style: GoogleFonts.outfit(fontSize: 16, color: Colors.black)),
            const Spacer(),
            if (!enquiry.isResolved)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref.read(firestoreServiceProvider).resolveEnquiry(enquiry.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Mark as Resolved', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
