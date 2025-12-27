import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  @override
  Widget build(BuildContext context) {
    final firestoreService = ref.watch(firestoreServiceProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Users', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
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
          future: firestoreService.getAllUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final users = snapshot.data ?? [];
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                      backgroundColor: const Color(0xFFFFAF00).withValues(alpha: 0.1),
                      child: user.photoURL == null ? const Icon(Icons.person, color: Color(0xFFFFAF00)) : null,
                    ),
                    title: Text(user.displayName ?? 'Unknown', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email ?? '', style: GoogleFonts.outfit(fontSize: 12)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                           decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4)),
                          child: Text(user.role.toUpperCase(), style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (String newRole) async {
                        if (newRole != user.role) {
                          await firestoreService.updateUserRole(user.uid, newRole);
                          setState(() {}); // Refresh UI
                          if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Updated to $newRole')));
                          }
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(value: 'student', child: Text('Student')),
                        const PopupMenuItem<String>(value: 'writer', child: Text('Writer')),
                        const PopupMenuItem<String>(value: 'admin', child: Text('Admin')),
                      ],
                      child: const Icon(Icons.more_vert),
                    ),
                  ),
                );
              },
            );
          },
        ),
    );
  }
}
