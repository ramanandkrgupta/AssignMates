import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Terms of Service', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('1. Acceptance of Terms',
              'By accessing or using AssignMates, you agree to be bound by these Terms of Service and all applicable laws and regulations.'),
            _buildSection('2. Services Description',
              'AssignMates provides a platform connecting students with academic writers for assistance with assignments, projects, and research.'),
            _buildSection('3. User Conduct',
              'Users are responsible for their accounts and must use the platform for legitimate academic assistance. Plagiarism is strongly discouraged.'),
            _buildSection('4. Payment Terms',
              'Payments are processed securely. Half-payment options are available for verified orders. Delivery is initiated after final payment confirmation.'),
            _buildSection('5. Termination',
              'We reserve the right to terminate or suspend access to our service immediately, without prior notice or liability, for any reason whatsoever.'),
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
