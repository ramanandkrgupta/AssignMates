import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class AdminWritersScreen extends ConsumerWidget {
  const AdminWritersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreService = ref.watch(firestoreServiceProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Writers', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFAF00),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: FutureBuilder<List<AppUser>>(
        future: firestoreService.getAllUsers(), // Ideally should have logic to get only writers
        builder: (context, snapshot) {
           if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
           final users = snapshot.data?.where((u) => u.role == 'writer').toList() ?? [];

           if (users.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.person_off_outlined, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   Text('No Writers found.', style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey)),
                 ],
               )
             );
           }

           return ListView.builder(
             itemCount: users.length,
             itemBuilder: (context, index) {
               final user = users[index];
               return Card(
                 margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 child: ListTile(
                   leading: CircleAvatar(backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null, child: user.photoURL == null ? const Icon(Icons.person) : null),
                   title: Row(
                     children: [
                       Text(user.displayName ?? 'Writer'),
                       const SizedBox(width: 8),
                       Container(
                         width: 8,
                         height: 8,
                         decoration: BoxDecoration(
                           color: user.isAvailable ? Colors.green : Colors.red,
                           shape: BoxShape.circle,
                         ),
                       ),
                     ],
                   ),
                   subtitle: Text(user.email ?? ''),
                   trailing: const Icon(Icons.chevron_right),
                   onTap: () {
                     // Manage writer details
                   },
                 ),
               );
             },
           );
        }
      ),
    );
  }
}
