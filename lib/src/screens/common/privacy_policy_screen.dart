import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Privacy Policy', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('1. Data Collection',
              'We collect information you provide directly to us, such as when you create an account, submit an assignment request, or communicate with our support team.'),
            _buildSection('2. How We Use Information',
              'We use the information we collect to provide, maintain, and improve our services, including matching students with writers and processing payments.'),
            _buildSection('3. Information Sharing',
              'We do not share your private assignment details with third parties except as necessary to provide our services or as required by law.'),
            _buildSection('4. Security',
              'We take reasonable measures to help protect information about you from loss, theft, misuse, and unauthorized access.'),
            _buildSection('5. Contact Us',
              'If you have any questions about this Privacy Policy, please contact us via the Support Hub.'),
            const SizedBox(height: 40),
            Center(
              child: Text('Last Updated: December 2025',
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFFFAF00))),
          const SizedBox(height: 10),
          Text(content, style: GoogleFonts.outfit(fontSize: 14, color: Colors.black87, height: 1.5)),
        ],
      ),
    );
  }
}
