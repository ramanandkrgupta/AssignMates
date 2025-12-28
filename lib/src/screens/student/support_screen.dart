import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/enquiry_model.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;

  final String whatsappNumber = "7489439579";
  final String callNumber = "7489439579";

  final List<String> presetMessages = [
    "Writer is not responding",
    "Incorrect page count",
    "Need urgent revision",
    "Payment verification help",
    "General inquiry"
  ];

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _submitEnquiry(String message, String type) async {
    final user = ref.read(appUserProvider).value;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    final firestoreService = ref.read(firestoreServiceProvider);
    final enquiryId = firestoreService.enquiriesCollection.doc().id;

    final enquiry = EnquiryModel(
      id: enquiryId,
      userId: user.uid,
      userName: user.displayName ?? 'Student',
      userPhotoUrl: user.photoURL,
      message: message,
      type: type,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(firestoreServiceProvider).submitEnquiry(enquiry);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support request sent successfully!'), backgroundColor: Colors.green),
        );
        if (type == 'text') _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: const Color(0xFF1E1E1E),
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Support Hub', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                   Image.asset(
                    'assets/images/support_header.png',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('HELP CHANNELS'),
                  const SizedBox(height: 16),
                  _buildSupportActions(),
                  const SizedBox(height: 32),

                  _buildSectionTitle('COMMON ISSUES'),
                  const SizedBox(height: 12),
                  _buildPresetChips(),
                  const SizedBox(height: 32),

                  _buildSectionTitle('WRITE TO US'),
                  const SizedBox(height: 12),
                  _buildCustomMessageBox(),
                  const SizedBox(height: 32),

                  _buildSectionTitle('COMMUNITY'),
                  const SizedBox(height: 16),
                  _buildCommunityLinks(),
                ],
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: const Color(0xFFFFAF00),
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSupportActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.chat_bubble_outline,
            label: 'WhatsApp',
            color: const Color(0xFF25D366),
            onTap: () {
              final url = "https://wa.me/91$whatsappNumber?text=Hi Team, I need help with my Order.";
              _launchURL(url);
              _submitEnquiry("Clicked WhatsApp Support", "whatsapp");
            },
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildActionButton(
            icon: Icons.phone_in_talk_outlined,
            label: 'Call Now',
            color: const Color(0xFFFFAF00),
            onTap: () {
              _launchURL("tel:$callNumber");
              _submitEnquiry("Initiated Phone Support Call", "call");
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    final bool isWhatsApp = label.toLowerCase().contains('whatsapp');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                duration: 1000.ms,
                begin: const Offset(1, 1),
                end: Offset(isWhatsApp ? 1.2 : 1.1, isWhatsApp ? 1.2 : 1.1),
                curve: Curves.easeInOut,
              )
              .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.5)),
            const SizedBox(height: 10),
            Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presetMessages.map((msg) => ActionChip(
        label: Text(msg, style: GoogleFonts.outfit(fontSize: 13, color: Colors.black87)),
        backgroundColor: Colors.grey[100],
        onPressed: () => _submitEnquiry(msg, "preset"),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      )).toList(),
    );
  }

  Widget _buildCustomMessageBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Describe your issue in detail...',
              border: InputBorder.none,
            ),
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.black),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: _isSubmitting ? null : () {
                  if (_messageController.text.trim().isNotEmpty) {
                    _submitEnquiry(_messageController.text, "text");
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFAF00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send Message'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityLinks() {
    return StreamBuilder<Map<String, String>>(
      stream: ref.watch(firestoreServiceProvider).getCommunityLinksStream(),
      builder: (context, snapshot) {
        final links = snapshot.data ?? {};

        // Configuration for small icons
        final smallIcons = [
          {'key': 'telegram', 'icon': Icons.telegram_outlined},
          {'key': 'website', 'icon': Icons.language_outlined},
          {'key': 'twitter', 'icon': Icons.close},
          {'key': 'linkedin', 'icon': Icons.business_outlined},
          {'key': 'instagram', 'icon': Icons.camera_alt_outlined},
        ];

        // Filter active links
        final activeIcons = smallIcons.where((item) {
          final link = links[item['key'] as String];
          return link != null && link.trim().isNotEmpty;
        }).toList();

        final whatsappLink = links['whatsapp'];
        final hasWhatsapp = (whatsappLink != null && whatsappLink.trim().isNotEmpty) ||
                             snapshot.connectionState == ConnectionState.waiting;

        return Column(
          children: [
            if (hasWhatsapp)
              _buildSocialTile(
                Icons.groups_outlined,
                'Join WhatsApp Group',
                'Get latest updates directly',
                () => _launchURL(whatsappLink ?? "https://chat.whatsapp.com/E8E0N0pOd70AX4fP8RXdjH")
              ),

            if (activeIcons.isNotEmpty) ...[
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: activeIcons.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: _buildSmallIcon(
                        item['icon'] as IconData,
                        () => _launchURL(links[item['key'] as String]!)
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        );
      }
    );
  }

  Widget _buildSocialTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: const Color(0xFFFFAF00).withValues(alpha: 0.05),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFFFAF00).withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: const Color(0xFFFFAF00)),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
      subtitle: Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
    );
  }

  Widget _buildSmallIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black54, size: 20),
      ),
    );
  }
}
