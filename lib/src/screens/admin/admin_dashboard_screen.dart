import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/request_model.dart';
import '../../models/user_model.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Requests'), // Priority
            Tab(text: 'Users'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestsTab(),
          _buildUsersTab(),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    final firestoreService = ref.watch(firestoreServiceProvider);

    return FutureBuilder<List<RequestModel>>(
      future: firestoreService.getAllRequests(),
      builder: (context, snapshot) {
         if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
         }
         if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
         }
         final requests = snapshot.data ?? [];

         if (requests.isEmpty) return const Center(child: Text('No requests found'));

         return ListView.builder(
           itemCount: requests.length,
           itemBuilder: (context, index) {
             final req = requests[index];
             Color statusColor = Colors.grey;
             if (req.status == 'created') statusColor = Colors.blue;
             if (req.status == 'admin_verified') statusColor = Colors.orange;
             if (req.status == 'completed') statusColor = Colors.green;

             return Card(
               margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
               child: ListTile(
                 onTap: () => _showRequestDialog(req),
                 title: Text(req.instructions, maxLines: 1, overflow: TextOverflow.ellipsis),
                 subtitle: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text('Deadline: ${DateFormat('MMM d').format(req.deadline)}'),
                     Text('Status: ${req.status}', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                     if (req.budget > 0) Text('Budget: ₹${req.budget}'),
                   ],
                 ),
                 trailing: Text(DateFormat('h:mm a').format(req.createdAt), style: const TextStyle(fontSize: 12)),
               ),
             );
           },
         );
      },
    );
  }

  Future<void> _showRequestDialog(RequestModel req) async {
    final pageCountController = TextEditingController(text: req.pageCount.toString());
    final budgetController = TextEditingController(text: req.budget.toString());
    String status = req.status;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Manage Request'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Instructions: ${req.instructions}'),
                const SizedBox(height: 10),
                TextField(
                  controller: pageCountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Verify Page Count'),
                ),
                TextField(
                  controller: budgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Set Final Budget (₹)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'created', child: Text('Created')),
                    DropdownMenuItem(value: 'admin_verified', child: Text('Admin Verified')),
                    DropdownMenuItem(value: 'writer_assigned', child: Text('Writer Assigned')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  ],
                  onChanged: (val) => status = val!,
                ),
                const SizedBox(height: 10),
                const Text('Attachments:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...req.attachmentUrls.map((url) => InkWell(
                  onTap: () {
                     // In real app, launch URL
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open: $url')));
                  },
                  child: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.blue)),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                 final newPageCount = int.tryParse(pageCountController.text) ?? req.pageCount;
                 final newBudget = double.tryParse(budgetController.text) ?? req.budget;

                 await ref.read(firestoreServiceProvider).updateRequestStatus(
                   req.id,
                   status,
                   additionalData: {
                     'pageCount': newPageCount,
                     'budget': newBudget,
                     'isPageCountVerified': true, // Auto verify if admin sets it
                   }
                 );
                 if (context.mounted) {
                    Navigator.pop(context);
                    setState(() {}); // Refresh
                 }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUsersTab() {
    final firestorePoints = ref.watch(firestoreServiceProvider);
    return FutureBuilder<List<AppUser>>(
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
      );
  }
}
