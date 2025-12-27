import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WriterHistoryScreen extends StatelessWidget {
  const WriterHistoryScreen({super.key});

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
