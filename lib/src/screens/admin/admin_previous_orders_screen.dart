import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firestore_service.dart';
import '../../models/request_model.dart';
import '../../models/user_model.dart';
import 'package:intl/intl.dart';
import '../common/media_viewer_screen.dart';

class AdminPreviousOrdersScreen extends ConsumerWidget {
  const AdminPreviousOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreService = ref.watch(firestoreServiceProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          title: Text('Order History', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            indicatorColor: const Color(0xFFFFAF00),
            labelColor: const Color(0xFFFFAF00),
            unselectedLabelColor: Colors.white70,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: StreamBuilder<List<RequestModel>>(
          stream: firestoreService.getAllRequestsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFFFAF00)));
            }
            final requests = snapshot.data ?? [];
            final completed = requests.where((r) => r.status == 'completed').toList();
            final cancelled = requests.where((r) => r.status == 'cancelled').toList();

            completed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            cancelled.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return TabBarView(
              children: [
                _HistoryList(orders: completed),
                _HistoryList(orders: cancelled),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  final List<RequestModel> orders;
  const _HistoryList({required this.orders});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.white10),
            const SizedBox(height: 16),
            Text('No historical orders found', style: GoogleFonts.outfit(color: Colors.white38)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) => _HistoryCard(request: orders[index]),
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  final RequestModel request;
  const _HistoryCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = request.status == 'completed' ? Colors.greenAccent : Colors.redAccent;

    return FutureBuilder<AppUser?>(
      future: ref.read(firestoreServiceProvider).getUser(request.studentId),
      builder: (context, snapshot) {
        final studentName = snapshot.data?.displayName ?? 'Loading Student...';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'ID: ${request.id.substring(0, 8)} • ${DateFormat('MMM d').format(request.createdAt)}',
                        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: GoogleFonts.outfit(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Instructions:', style: GoogleFonts.outfit(color: const Color(0xFFFFAF00), fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(request.instructions, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _info('Budget', '₹${request.budget.toStringAsFixed(0)}'),
                        _info('Pages', '${request.pageCount}'),
                        _info('Paid', '₹${request.paidAmount.toStringAsFixed(0)}'),
                      ],
                    ),
                    if (request.status == 'cancelled' && request.cancellationReason != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CANCELLED BY: ${request.cancelledBy?.toUpperCase() ?? "UNKNOWN"}',
                              style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              request.cancellationReason!,
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (request.attachmentUrls.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Attachments:', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: request.attachmentUrls.length,
                          itemBuilder: (context, i) => GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MediaViewerScreen(urls: request.attachmentUrls, title: 'Attachments', initialIndex: i))),
                            child: Container(
                              width: 50,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.description, color: Color(0xFFFFAF00), size: 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _info(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10)),
        Text(val, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
