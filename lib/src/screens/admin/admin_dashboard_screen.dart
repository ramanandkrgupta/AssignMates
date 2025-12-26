import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  static const Color primaryOrange = Color(0xFFFFAF00);

  @override
  Widget build(BuildContext context) {
    // Admin Screens
    final List<Widget> screens = [
      const _AdminOrdersScreen(),
      const _AdminEnquiriesScreen(),
      const _AdminWritersScreen(),
      const _AdminUsersScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: primaryOrange,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
             if (states.contains(WidgetState.selected)) {
               return const IconThemeData(size: 28, color: Colors.black);
             }
             return const IconThemeData(size: 28, color: Colors.white);
          }),
        ),
        child: NavigationBar(
          height: 80,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.black,
          indicatorColor: primaryOrange,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Enquiries',
            ),
             NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Writers',
            ),
            NavigationDestination(
              icon: Icon(Icons.manage_accounts_outlined),
              selectedIcon: Icon(Icons.manage_accounts),
              label: 'Users',
            ),
          ],
        ),
      ),
    );
  }
}

// 1. Orders Screen (Formerly Requests)
class _AdminOrdersScreen extends ConsumerStatefulWidget {
  const _AdminOrdersScreen();

  @override
  ConsumerState<_AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<_AdminOrdersScreen> {
  @override
  Widget build(BuildContext context) {
    final firestoreService = ref.watch(firestoreServiceProvider);

    return StreamBuilder<List<RequestModel>>(
      stream: firestoreService.getAllRequestsStream(),
      builder: (context, snapshot) {
         if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
         if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
         final requests = snapshot.data ?? [];
         if (requests.isEmpty) return const Center(child: Text('No orders found'));

         return ListView.builder(
           padding: const EdgeInsets.all(16),
           itemCount: requests.length,
           itemBuilder: (context, index) {
             final req = requests[index];
             Color statusColor = Colors.grey;
             if (req.status == 'created') {
               statusColor = Colors.blue;
             } else if (req.status == 'admin_verified') {
               statusColor = Colors.orange;
             } else if (req.status == 'completed') {
               statusColor = Colors.green;
             }

             return Card(
               margin: const EdgeInsets.only(bottom: 12),
               elevation: 2,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               child: ListTile(
                 onTap: () => _showRequestDialog(req),
                 contentPadding: const EdgeInsets.all(16),
                 title: Text(req.instructions, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                 subtitle: Padding(
                   padding: const EdgeInsets.only(top: 8.0),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         children: [
                           const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                           const SizedBox(width: 4),
                           Text('Deadline: ${DateFormat('MMM d').format(req.deadline)}', style: GoogleFonts.outfit()),
                         ],
                       ),
                       const SizedBox(height: 4),
                        Row(
                         children: [
                           const Icon(Icons.attach_money, size: 14, color: Colors.grey),
                           const SizedBox(width: 4),
                           Text('Budget: ₹${req.budget}', style: GoogleFonts.outfit()),
                         ],
                       ),
                       const SizedBox(height: 8),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                         child: Text(req.status.toUpperCase(), style: GoogleFonts.outfit(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                       ),
                     ],
                   ),
                 ),
                 trailing: Text(DateFormat('h:mm a').format(req.createdAt), style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12)),
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
          title: Text('Manage Order #${req.id.substring(0, 5)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Instructions:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                Text(req.instructions, style: GoogleFonts.outfit()),
                const SizedBox(height: 16),
                TextField(
                  controller: pageCountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Verify Page Count', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: budgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Set Final Budget (₹)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'created', child: Text('Created')),
                    DropdownMenuItem(value: 'admin_verified', child: Text('Admin Verified')),
                    DropdownMenuItem(value: 'writer_assigned', child: Text('Writer Assigned')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  ],
                  onChanged: (val) => status = val!,
                ),
                const SizedBox(height: 16),
                if (req.attachmentUrls.isNotEmpty) ...[
                   Text('Attachments:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                   ...req.attachmentUrls.map((url) => InkWell(
                     onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open: $url'))),
                     child: Padding(
                       padding: const EdgeInsets.symmetric(vertical: 4),
                       child: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                     ),
                   )),
                ]
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
                     'isPageCountVerified': true,
                   }
                 );
                 if (context.mounted) {
                    Navigator.pop(context);
                    setState(() {}); // Refresh the list by triggering rebuild
                 }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFAF00), foregroundColor: Colors.white),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}

// 2. Enquiries Screen (Placeholder)
class _AdminEnquiriesScreen extends StatelessWidget {
  const _AdminEnquiriesScreen();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
           const SizedBox(height: 16),
           Text('No Enquiries yet.', style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }
}

// 3. Writers Screen (Filtered Users)
class _AdminWritersScreen extends ConsumerWidget {
  const _AdminWritersScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreService = ref.watch(firestoreServiceProvider);
    return FutureBuilder<List<AppUser>>(
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
                 title: Text(user.displayName ?? 'Writer'),
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
    );
  }
}

// 4. Users Screen
class _AdminUsersScreen extends ConsumerStatefulWidget {
  const _AdminUsersScreen();

  @override
  ConsumerState<_AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<_AdminUsersScreen> {
  @override
  Widget build(BuildContext context) {
    final firestoreService = ref.watch(firestoreServiceProvider);
    return FutureBuilder<List<AppUser>>(
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
      );
  }
}
