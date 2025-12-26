import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final firestorePoints = ref.watch(firestoreServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<AppUser>>(
        future: firestorePoints.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final users = snapshot.data ?? [];
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                    child: user.photoURL == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(user.displayName ?? 'Unknown'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.email ?? ''),
                      Text('Current Role: ${user.role}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (String newRole) async {
                      if (newRole != user.role) {
                        await firestorePoints.updateUserRole(user.uid, newRole);
                        setState(() {}); // Refresh list
                        if (mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Updated ${user.displayName} to $newRole')));
                        }
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                         value: 'student',
                        child: Text('Make Student'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'writer',
                        child: Text('Make Writer'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'admin',
                        child: Text('Make Admin'),
                      ),
                    ],
                    child: const Icon(Icons.edit),
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
