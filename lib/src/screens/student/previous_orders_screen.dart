import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../models/request_model.dart';
import '../common/media_viewer_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';

class PreviousOrdersScreen extends ConsumerWidget {
  const PreviousOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final firestoreService = ref.watch(firestoreServiceProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          title: Text('Previous Orders', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
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
        body: user == null
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<List<RequestModel>>(
                stream: firestoreService.getStudentRequests(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFFFAF00)));
                  }
                  final requests = snapshot.data ?? [];
                  final completed = requests.where((r) => r.status == 'completed').toList();
                  final cancelled = requests.where((r) => r.status == 'cancelled').toList();

                  // Sort by newness
                  completed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  cancelled.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  return TabBarView(
                    children: [
                      _OrdersList(requests: completed, emptyMessage: 'No completed orders yet'),
                      _OrdersList(requests: cancelled, emptyMessage: 'No cancelled orders yet'),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<RequestModel> requests;
  final String emptyMessage;

  const _OrdersList({required this.requests, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/animations/empty.json', height: 150),
            const SizedBox(height: 16),
            Text(emptyMessage, style: GoogleFonts.outfit(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) => _PreviousOrderCard(request: requests[index]),
    );
  }
}

class _PreviousOrderCard extends StatelessWidget {
  final RequestModel request;
  const _PreviousOrderCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final isCompleted = request.status == 'completed';
    final statusColor = isCompleted ? Colors.greenAccent : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: ExpansionTile(
        initiallyExpanded: false, // track order progress closed by default for previous orders
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.instructions,
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    DateFormat('MMM d, yyyy • hh:mm a').format(request.createdAt),
                    style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Text('₹${request.budget.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: const Color(0xFFFFAF00), fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Text('${request.pageCount} Pages', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Colors.white12),
                const SizedBox(height: 8),
                Text('Track Order Progress', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                ...List.generate(request.timeline.length, (index) {
                  final step = request.timeline[index];
                  return _buildTimelineItem(
                    step.title,
                    step.description,
                    DateFormat('MMM d, hh:mm a').format(step.timestamp),
                    isLast: index == request.timeline.length - 1,
                  );
                }),
                if (request.attachmentUrls.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Attachments', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: request.attachmentUrls.length,
                      itemBuilder: (context, i) => GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MediaViewerScreen(urls: request.attachmentUrls, title: 'Order Attachments', initialIndex: i))),
                        child: Container(
                          width: 60,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white.withOpacity(0.05),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Icon(Icons.description, color: Color(0xFFFFAF00), size: 30),
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
  }

  Widget _buildTimelineItem(String title, String desc, String time, {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: Colors.green.withOpacity(0.3))),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(desc, style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12)),
                  Text(time, style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
