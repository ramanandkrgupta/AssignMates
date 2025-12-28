import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firestore_service.dart';

class CommunityLinksScreen extends ConsumerStatefulWidget {
  const CommunityLinksScreen({super.key});

  @override
  ConsumerState<CommunityLinksScreen> createState() => _CommunityLinksScreenState();
}

class _CommunityLinksScreenState extends ConsumerState<CommunityLinksScreen> {
  final Map<String, TextEditingController> _controllers = {
    'whatsapp': TextEditingController(),
    'telegram': TextEditingController(),
    'instagram': TextEditingController(),
    'twitter': TextEditingController(),
    'linkedin': TextEditingController(),
    'website': TextEditingController(),
  };

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    final stream = ref.read(firestoreServiceProvider).getCommunityLinksStream();
    final subscription = stream.listen((links) {
      if (links.isNotEmpty) {
        setState(() {
          links.forEach((key, value) {
            if (_controllers.containsKey(key)) {
              _controllers[key]!.text = value;
            }
          });
        });
      }
    });
    // We don't need to keep the subscription forever for this screen
    // but typically we'd cancel it in dispose.
    // For simplicity, we just use use the stream one-off or watch it.
  }

  @override
  void dispose() {
    _controllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  Future<void> _saveLinks() async {
    setState(() => _isLoading = true);
    final links = _controllers.map((key, controller) => MapEntry(key, controller.text.trim()));
    try {
      await ref.read(firestoreServiceProvider).updateCommunityLinks(links);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Links updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Community Links', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage social media and community links displayed to students.',
              style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 32),
            _buildLinkField('WhatsApp Group', 'whatsapp', Icons.chat_bubble_outline),
            _buildLinkField('Telegram', 'telegram', Icons.telegram),
            _buildLinkField('Instagram', 'instagram', Icons.camera_alt_outlined),
            _buildLinkField('Twitter (X)', 'twitter', Icons.close),
            _buildLinkField('LinkedIn', 'linkedin', Icons.business_outlined),
            _buildLinkField('Official Website', 'website', Icons.language_outlined),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveLinks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFAF00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Save Changes', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkField(String label, String key, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          TextField(
            controller: _controllers[key],
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFFFFAF00), size: 20),
              hintText: 'https://...',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFFAF00)),
              ),
            ),
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
