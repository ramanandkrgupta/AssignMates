import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class WriterDashboardScreen extends ConsumerWidget {
  const WriterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Writer Dashboard'),
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
            const Icon(Icons.assignment, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            Text(
              'Welcome, ${user?.displayName?.split(' ')[0] ?? 'Writer'}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text('You have 0 active assignments.'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Find Assignments'),
            ),
          ],
        ),
      ),
    );
  }
}
