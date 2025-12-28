import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/request_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../models/pricing_model.dart';
import '../../services/notification_service.dart';
import '../../models/timeline_step.dart';

class AssignWriterScreen extends ConsumerWidget {
  final RequestModel request;

  const AssignWriterScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text('Assign Writer', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFAF00),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: ref.read(firestoreServiceProvider).getWritersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFFFFAF00)));

          final writers = snapshot.data?.where((w) => w.isAvailable).toList() ?? [];

          if (writers.isEmpty) {
            return Center(
              child: Text(
                'No available writers at the moment.',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: writers.length,
            itemBuilder: (context, index) {
              final writer = writers[index];

              return StreamBuilder<List<RequestModel>>(
                stream: ref.read(firestoreServiceProvider).getWriterRequestsStream(writer.uid),
                builder: (context, reqSnapshot) {
                  final activeCount = reqSnapshot.data?.where((r) => r.status != 'completed' && r.status != 'cancelled').length ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xFFFFAF00).withValues(alpha: 0.1),
                          backgroundImage: writer.photoURL != null ? NetworkImage(writer.photoURL!) : null,
                          child: writer.photoURL == null ? const Icon(Icons.person, color: Color(0xFFFFAF00), size: 30) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                writer.displayName ?? 'Anonymous Writer',
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFAF00).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Active: $activeCount',
                                      style: GoogleFonts.outfit(color: const Color(0xFFFFAF00), fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.call, color: Colors.greenAccent),
                              onPressed: () async {
                                if (writer.phoneNumber != null) {
                                  final uri = Uri.parse('tel:${writer.phoneNumber}');
                                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                                }
                              },
                            ),
                            const SizedBox(width: 4),
                              ElevatedButton(
                              onPressed: () async {
                                // Show loading? For now just await
                                try {
                                  final firestore = ref.read(firestoreServiceProvider);

                                  // 1. Fetch Student for City
                                  final student = await firestore.getUser(request.studentId);
                                  final city = student?.city ?? 'Default';

                                  // 2. Fetch Pricing
                                  final pricing = await firestore.getPricing(city);

                                  // 3. Calculate Estimate
                                  final budgetController = TextEditingController();
                                  double estPrice = 0.0;
                                  final deadline = request.deadline;
                                  final days = deadline.difference(DateTime.now()).inDays + 1;

                                  if (request.pageType == 'EdSheet') {
                                    estPrice = pricing.edSheetPrice * request.pageCount;
                                  } else {
                                    // Assignment
                                    double pricePerPage = pricing.a4BasePrice;
                                    if (days < 4) {
                                      if (days == 3) pricePerPage += pricing.surcharge3Days;
                                      if (days == 2) pricePerPage += pricing.surcharge2Days;
                                      if (days <= 1) pricePerPage += pricing.surcharge1Day;
                                    }
                                    estPrice = pricePerPage * request.pageCount;
                                  }
                                  budgetController.text = estPrice.toStringAsFixed(0);

                                final result = await showDialog<Map<String, dynamic>>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: const Color(0xFF1E1E1E),
                                    title: Text('Set Final Budget', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Pages: ${request.pageCount} | Type: ${request.pageType}', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                                        Text('Estimated Price: ₹${estPrice.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                                        const SizedBox(height: 20),
                                        Text('Final Budget (incl. delivery):', style: GoogleFonts.outfit(color: const Color(0xFFFFAF00), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: budgetController,
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white.withOpacity(0.05),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                                            prefixText: '₹ ',
                                            prefixStyle: const TextStyle(color: Color(0xFFFFAF00), fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.grey))),
                                      ElevatedButton(
                                        onPressed: () {
                                          final budget = double.tryParse(budgetController.text) ?? estPrice;
                                          Navigator.pop(context, {'budget': budget});
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFFFAF00),
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        child: const Text('ASSIGN & SET BUDGET'),
                                      ),
                                    ],
                                  ),
                                );

                                  if (result != null) {
                                    final double finalBudget = result['budget'];
                                    await ref.read(firestoreServiceProvider).updateRequestStatusWithStep(
                                      request.id,
                                      'assigned',
                                      TimelineStep(
                                        status: 'assigned',
                                        title: 'Writer Assigned',
                                        description: 'A writer has been assigned to your order. Final Budget: ₹${finalBudget.toStringAsFixed(0)}. Please pay the amount now.',
                                        timestamp: DateTime.now(),
                                        // Trigger backend notifications
                                        notificationsSent: {'student': false, 'writer': false},
                                      ),
                                      additionalData: {
                                        'assignedWriterId': writer.uid,
                                        'budget': finalBudget,
                                        'finalAmount': finalBudget,
                                      }
                                    );

                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Order assigned with budget ₹${finalBudget.toStringAsFixed(0)}'))
                                      );
                                    }
                                  }
                                } catch (e) {
                                  debugPrint('Error preparing assignment: $e');
                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFAF00),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: Text('ASSIGN', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
