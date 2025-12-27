import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/request_model.dart';

class AdminRequestDetailsScreen extends StatelessWidget {
  final RequestModel request;
  const AdminRequestDetailsScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFAF00),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Instructions', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(request.instructions, style: GoogleFonts.outfit(fontSize: 16)),
            // Add more details here as needed
          ],
        ),
      ),
    );
  }
}
