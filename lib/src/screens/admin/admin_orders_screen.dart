import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../services/firestore_service.dart';
import '../../models/request_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../widgets/audio_player_widget.dart';
import '../common/media_viewer_screen.dart';
import '../../services/notification_service.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = ref.watch(firestoreServiceProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Manage Orders', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFFFAF00)),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFAF00),
          labelColor: const Color(0xFFFFAF00),
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Ongoing'),
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
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }
          final requests = snapshot.data ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList(requests.where((r) => r.status != 'completed' && r.status != 'cancelled').toList()),
              _buildOrderList(requests.where((r) => r.status == 'completed').toList()),
              _buildOrderList(requests.where((r) => r.status == 'cancelled').toList()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderList(List<RequestModel> orders) {
    return Column(
      children: [
        if (_tabController.index == 0) // Only on Ongoing tab
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.bug_report, color: Colors.black),
              label: Text('Simulate Student Request', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFAF00),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                 final firestore = ref.read(firestoreServiceProvider);
                 final notifier = ref.read(notificationServiceProvider);
                 final users = await firestore.getAllUsers();
                 final student = users.firstWhere((u) => u.role == 'student', orElse: () => users.first);

                 final requestId = 'sim_${DateTime.now().millisecondsSinceEpoch}';
                 final newRequest = RequestModel(
                   id: requestId,
                   studentId: student.uid,
                   instructions: 'SIMULATED REQUEST: This is a test request created from the Admin Dashboard to verify notifications. No docs attached.',
                   deadline: DateTime.now().add(const Duration(days: 3)),
                   budget: 0.0,
                   status: 'created',
                   attachmentUrls: [],
                   mediaUrls: {},
                   pageCount: 1,
                   createdAt: DateTime.now(),
                 );

                 await firestore.createRequest(newRequest);
                 await notifier.notifyAdmins(
                   title: 'New Order Received! 🚀',
                   body: 'From ${student.city ?? 'Unknown city'}, ${student.displayName ?? 'Student'} created 1 page order',
                 );

                 if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulated request created! Check for notification.')));
                 }
              },
            ),
          ),
        if (orders.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.list_alt, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No orders found.', style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                return _buildRequestCard(context, orders[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRequestCard(BuildContext context, RequestModel request) {
    return FutureBuilder<AppUser?>(
      future: ref.read(firestoreServiceProvider).getUser(request.studentId),
      builder: (context, userSnapshot) {
        final student = userSnapshot.data;

        Color statusColor;
        String statusText = request.status.toUpperCase().replaceAll('_', ' ');

        // Determine active step index
        int currentStep = 0;
        switch (request.status) {
          case 'created': currentStep = 0; break;
          case 'verified': currentStep = 1; break;
          case 'assigned': currentStep = 2; break;
          case 'payment_pending': currentStep = 3; break;
          case 'in_progress': currentStep = 4; break;
          case 'review_pending': currentStep = 5; break;
          case 'payment_remaining_pending': currentStep = 6; break;
          case 'delivering': currentStep = 7; break;
          case 'completed': currentStep = 8; break;
          case 'cancelled': currentStep = -1; break;
          default: currentStep = 0;
        }

        // Status Logic & Colors
        switch (request.status) {
          case 'completed':
            statusColor = Colors.greenAccent;
            statusText = "ORDER COMPLETED";
            break;
          case 'cancelled':
            statusColor = Colors.redAccent;
            break;
          case 'payment_pending':
          case 'payment_remaining_pending':
          case 'review_pending':
            statusColor = const Color(0xFFE440FF);
            break;
          case 'created':
          case 'verified':
            statusColor = const Color(0xFFFFAF00);
            break;
          case 'assigned':
          case 'in_progress':
          case 'delivering':
            statusColor = const Color(0xFF40C4FF);
            break;
          default: statusColor = Colors.grey;
        }

        final deadlineDiff = request.deadline.difference(DateTime.now());
        final deadlineStr = deadlineDiff.isNegative
            ? 'Overdue'
            : '${deadlineDiff.inDays} days remaining';

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Info Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color(0xFFFFAF00).withValues(alpha: 0.2),
                      backgroundImage: student?.photoURL != null ? NetworkImage(student!.photoURL!) : null,
                      child: student?.photoURL == null ? const Icon(Icons.person, color: Color(0xFFFFAF00)) : null,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(
                              student?.displayName ?? 'Loading Student...',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Order #${request.id.substring(0, 8)}',
                              style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        statusText,
                        style: GoogleFonts.outfit(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Instructions Section
                    Text('INSTRUCTIONS', style: GoogleFonts.outfit(color: const Color(0xFFFFAF00), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        request.instructions,
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location & Contact Row
                    _buildInfoTile(Icons.location_on_outlined, student?.city ?? '...', trailing: 'City'),
                    _buildInfoTile(Icons.school_outlined, student?.collegeId ?? '...', trailing: 'College'),
                    _buildInteractiveTile(
                      Icons.map_outlined,
                      student?.location ?? 'No location provided',
                      onCopy: () {
                        Clipboard.setData(ClipboardData(text: student?.location ?? ''));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location copied!')));
                      },
                      label: 'Location',
                    ),
                    if (student?.phoneNumber != null)
                      _buildContactTile(
                        student!.phoneNumber!,
                        onCopy: () {
                          Clipboard.setData(ClipboardData(text: student.phoneNumber!));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mobile copied!')));
                        },
                        onCall: () async {
                          final uri = Uri.parse('tel:${student.phoneNumber}');
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        },
                      ),

                    const SizedBox(height: 15),
                    // Budget & Deadline
                    Row(
                      children: [
                        Expanded(child: _buildStatBox('Budget', request.budget > 0 ? '₹${request.budget.toStringAsFixed(0)}' : 'TBD', const Color(0xFFFFAF00))),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatBox('Deadline', deadlineStr, Colors.orangeAccent)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatBox('Pages', '${request.pageCount}', Colors.blueAccent)),
                      ],
                    ),

                    const SizedBox(height: 15),
                    // Media Preview Section
                    Text('ATTACHED DOCUMENTS', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 10),
                    _buildMediaSection(request),

                    const SizedBox(height: 15),
                    // Progress
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text('Track Progress', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                        childrenPadding: const EdgeInsets.only(left: 8, bottom: 8),
                        tilePadding: EdgeInsets.zero,
                        children: [
                          _buildVerticalStep(context, 0, 'Order Placed', 'Request created successfully', currentStep),
                          _buildVerticalStep(context, 1, 'Admin Verification', 'Admin verified request', currentStep),
                          _buildVerticalStep(context, 2, 'Writer Assigned', 'Writer has been assigned', currentStep),
                          _buildVerticalStep(context, 3, 'Payment', 'Half or Full Payment required', currentStep),
                          _buildVerticalStep(context, 4, 'Writer Started', 'Writer is working', currentStep),
                          _buildVerticalStep(context, 5, 'Writer Completed', 'Work ready for verification', currentStep),
                          if (request.isHalfPayment)
                            _buildVerticalStep(context, 6, 'Final Payment', 'Remaining payment pending', currentStep),
                          _buildVerticalStep(context, 7, 'Delivering', 'Delivering to student', currentStep),
                          _buildVerticalStep(context, 8, 'Order Completed', 'Order delivered successfully', currentStep, isLast: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),
                    // Verification Action Bar
                    _buildVerificationBar(request),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(IconData icon, String text, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white38),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14))),
          if (trailing != null) Text(trailing, style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildInteractiveTile(IconData icon, String text, {required VoidCallback onCopy, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white38),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 14, color: Color(0xFFFFAF00)),
            onPressed: onCopy,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(String phone, {required VoidCallback onCopy, required VoidCallback onCall}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.phone_outlined, size: 20, color: Color(0xFFFFAF00)),
          const SizedBox(width: 15),
          Expanded(child: Text(phone, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
          IconButton(icon: const Icon(Icons.copy, color: Colors.white38, size: 18), onPressed: onCopy),
          IconButton(icon: const Icon(Icons.call, color: Colors.greenAccent, size: 18), onPressed: onCall),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMediaSection(RequestModel request) {
    final docs = request.attachmentUrls.where((url) {
      final uri = url.toLowerCase().split('?').first;
      return uri.contains('/pdfs/') || uri.endsWith('.pdf');
    }).toList();
    final images = request.attachmentUrls.where((url) {
      final uri = url.toLowerCase().split('?').first;
      return uri.contains('/images/') || uri.endsWith('.jpg') || uri.endsWith('.jpeg') || uri.endsWith('.png') || uri.endsWith('.webp') || uri.endsWith('.gif');
    }).toList();
    final videos = request.attachmentUrls.where((url) {
      final uri = url.toLowerCase().split('?').first;
      return uri.contains('/videos/') || uri.endsWith('.mp4') || uri.endsWith('.mov') || uri.endsWith('.avi') || uri.endsWith('.mkv');
    }).toList();
    final voiceNote = request.voiceNoteUrl;

    return Column(
      children: [
        if (voiceNote != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AudioPlayerWidget(url: voiceNote, label: 'Voice Note Attachment'),
          ),
        if (docs.isNotEmpty) _buildMediaButton('Documents', Icons.description_outlined, Colors.orange, () => _viewFiles(docs, 'Documents')),
        if (images.isNotEmpty) _buildMediaButton('Photos', Icons.image_outlined, Colors.blue, () => _viewFiles(images, 'Photos')),
        if (videos.isNotEmpty) _buildMediaButton('Videos', Icons.videocam_outlined, Colors.purple, () => _viewFiles(videos, 'Videos')),
        if (request.attachmentUrls.isEmpty && voiceNote == null)
           Text('No attachments', style: GoogleFonts.outfit(color: Colors.white12, fontSize: 12)),
      ],
    );
  }

  Widget _buildMediaButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 15),
            Text(label, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBar(RequestModel request) {
    final pageController = TextEditingController(text: request.pageCount.toString());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFFAF00).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFAF00).withValues(alpha: 0.2))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: pageController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Edit Pages',
                labelStyle: TextStyle(color: Colors.white38, fontSize: 12),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 15),
          ElevatedButton(
            onPressed: () async {
              final count = int.tryParse(pageController.text) ?? request.pageCount;
              await ref.read(firestoreServiceProvider).updateRequestStatus(
                request.id,
                'verified',
                additionalData: {'pageCount': count, 'isPageCountVerified': true}
              );
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order verified!')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFAF00),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('VERIFY', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _viewFiles(List<String> urls, String title) {
    if (urls.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MediaViewerScreen(
            urls: urls,
            title: title,
          ),
        ),
      );
    }
  }

  Widget _buildVerticalStep(BuildContext context, int index, String title, String subtitle, int currentIndex, {bool isLast = false}) {
    bool isCompleted = index < currentIndex;
    bool isActive = index == currentIndex;

    Color circleColor;
    Color borderColor;
    Widget? icon;

    if (isCompleted) {
      circleColor = Colors.green;
      borderColor = Colors.green;
      icon = const Icon(Icons.check, size: 14, color: Colors.white);
    } else if (isActive) {
      circleColor = Colors.transparent;
      borderColor = const Color(0xFFFFAF00);
      icon = Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(color: Color(0xFFFFAF00), shape: BoxShape.circle),
      );
    } else {
      circleColor = Colors.transparent;
      borderColor = Colors.grey[800]!;
      icon = null;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   color: circleColor,
                   border: Border.all(color: borderColor, width: 2),
                   boxShadow: isActive ? [
                     BoxShadow(color: const Color(0xFFFFAF00).withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 2)
                   ] : null,
                ),
                alignment: Alignment.center,
                child: icon,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? Colors.green : Colors.grey[800],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isActive ? Colors.white : (isCompleted ? Colors.white70 : Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAdminManageDialog(RequestModel req) async {
    final pageCountController = TextEditingController(text: req.pageCount.toString());
    final budgetController = TextEditingController(text: req.budget.toString());
    String status = req.status;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text('Manage Order #${req.id.substring(0, 5)}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Instructions:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white70)),
                Text(req.instructions, style: GoogleFonts.outfit(color: Colors.white)),
                const SizedBox(height: 16),
                TextField(
                  controller: pageCountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Verify Page Count',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: budgetController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Set Final Budget (₹)',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'created', child: Text('Created')),
                    DropdownMenuItem(value: 'verified', child: Text('Verified')),
                    DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
                    DropdownMenuItem(value: 'payment_pending', child: Text('Payment Pending')),
                    DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'review_pending', child: Text('Review Pending')),
                    DropdownMenuItem(value: 'payment_remaining_pending', child: Text('Final Payment Pending')),
                    DropdownMenuItem(value: 'delivering', child: Text('Delivering')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                  ],
                  onChanged: (val) => status = val!,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
            ),
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
                 }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFAF00), foregroundColor: Colors.black),
              child: Text('Update', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
