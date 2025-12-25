import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

import '../student/create_request_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(appUserProvider);
    final user = userAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AssignMates Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user != null) ...[
              if (user.photoURL != null)
                CircleAvatar(
                  backgroundImage: NetworkImage(user.photoURL!),
                  radius: 40,
                ),
              const SizedBox(height: 16),
              Text(
                'Welcome, ${user.displayName ?? 'Student'}!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text('Role: ${user.role}'),
            ] else
              const CircularProgressIndicator(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateRequestScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
    );
  }
}
