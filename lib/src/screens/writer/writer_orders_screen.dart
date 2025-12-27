import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WriterOrdersScreen extends StatelessWidget {
  const WriterOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFAF00),
        elevation: 0,
         automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             const Icon(Icons.assignment, size: 64, color: Colors.grey),
             const SizedBox(height: 16),
             Text('No orders yet.', style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
