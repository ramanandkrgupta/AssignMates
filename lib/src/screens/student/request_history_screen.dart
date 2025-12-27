import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/request_model.dart';
import 'package:lottie/lottie.dart';
import 'create_request_screen.dart';

class RequestHistoryScreen extends ConsumerStatefulWidget {
  const RequestHistoryScreen({super.key});

  @override
  ConsumerState<RequestHistoryScreen> createState() => _RequestHistoryScreenState();
}

class _RequestHistoryScreenState extends ConsumerState<RequestHistoryScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Success: ${response.paymentId}')));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Failed: ${response.message}')));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('External Wallet: ${response.walletName}')));
  }

  void _openCheckout(RequestModel request, {bool isHalf = false, bool isFull = false, bool isFinal = false}) {
    int amountInPaise = 0;
    if (isFinal) {
      amountInPaise = ((request.budget - request.paidAmount) * 100).toInt();
    } else if (isHalf) {
      amountInPaise = ((request.budget / 2) * 100).toInt();
    } else {
      amountInPaise = (request.budget * 100).toInt();
    }

    var options = {
      'key': dotenv.env['RAZORPAY_KEY_ID']!,
      'amount': amountInPaise,
      'name': 'AssignMates',
      'description': 'Payment for Request #${request.id}',
      'prefill': {
        'contact': '',
        'email': ''
      },
      'notes': {
        'requestId': request.id,
        'paymentType': isHalf ? 'half' : (isFinal ? 'final' : 'full'),
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final firestoreService = ref.watch(firestoreServiceProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('My Orders',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateRequestScreen()));
              },
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFFAF00), size: 20),
              label: const Text('New Order',
                style: TextStyle(color: Color(0xFFFFAF00), fontWeight: FontWeight.bold, fontSize: 14)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Please login to view history', style: TextStyle(color: Colors.white)))
          : StreamBuilder<List<RequestModel>>(
              stream: firestoreService.getStudentRequests(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFFAF00)));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                }

                final requests = snapshot.data ?? [];

                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset('assets/animations/empty.json', height: 200),
                        const SizedBox(height: 16),
                        const Text(
                          'No bookings done yet',
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                             Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateRequestScreen()));
                          },
                          icon: const Icon(Icons.add, color: Colors.black),
                          label: const Text('Create your first Booking', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFAF00),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms);
                }

                // Grouping: Ongoing vs Previous
                final ongoingRequests = requests.where((r) => r.status != 'completed' && r.status != 'cancelled').toList();
                final previousRequests = requests.where((r) => r.status == 'completed' || r.status == 'cancelled').toList();

                // Sort by date
                ongoingRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                previousRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (ongoingRequests.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16, left: 4),
                        child: Text(
                          'Ongoing orders',
                          style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...ongoingRequests.asMap().entries.map((entry) {
                        return _buildRequestCard(context, entry.value);
                      }),
                      const SizedBox(height: 16),
                    ],

                    if (previousRequests.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16, top: 8, left: 4),
                        child: Text(
                          'Previous orders',
                          style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...previousRequests.asMap().entries.map((entry) {
                        return _buildRequestCard(context, entry.value);
                      }),
                    ],

                    // Extra padding at the bottom for navigation menu
                    const SizedBox(height: 80),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildRequestCard(BuildContext context, RequestModel request) {
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
        statusColor = const Color(0xFFE440FF); // Purple for Action Required
        break;
      case 'created':
      case 'verified':
        statusColor = const Color(0xFFFFAF00); // Orange for Pending
        break;
      case 'assigned':
      case 'in_progress':
      case 'delivering':
        statusColor = const Color(0xFF40C4FF); // Blue for Ongoing
        break;
      default: statusColor = Colors.grey;
    }

    // Allow cancellation before payment is made (until step 3 inclusive)
    bool canCancel = currentStep >= 0 && currentStep <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark Card Background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    request.instructions,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Info Row: Attachments & Price
            Row(
              children: [
                const Icon(Icons.attachment, size: 18, color: Color(0xFFFFAF00)),
                const SizedBox(width: 6),
                Text('${request.attachmentUrls.length} Views', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(width: 20),
                const Icon(Icons.account_balance_wallet_outlined, size: 18, color: Color(0xFFFFAF00)),
                const SizedBox(width: 6),
                Text(
                  request.budget > 0 ? '₹${request.budget.toStringAsFixed(0)}' : 'Budget TBD',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)
                ),
                if (request.paidAmount > 0)
                  Text(' (Paid: ₹${request.paidAmount.toStringAsFixed(0)})', style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
              ],
            ),
             const SizedBox(height: 16),

            // Stepper Visualization
            Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                expansionTileTheme: const ExpansionTileThemeData(
                  iconColor: Color(0xFFFFAF00),
                  collapsedIconColor: Colors.white70,
                  textColor: Color(0xFFFFAF00),
                  collapsedTextColor: Colors.white
                ),
              ),
              child: ExpansionTile(
                title: const Text('Track Order Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                childrenPadding: const EdgeInsets.only(left: 8, bottom: 8),
                tilePadding: EdgeInsets.zero,
                children: [
                  _buildVerticalStep(context, 0, 'Order Placed', 'Request created successfully', currentStep),
                  _buildVerticalStep(context, 1, 'Admin Verification', 'Admin verified your request', currentStep),
                  _buildVerticalStep(context, 2, 'Writer Assigned', 'Writer has been assigned', currentStep),
                  _buildVerticalStep(context, 3, 'Payment', 'Half or Full Payment required', currentStep),
                  _buildVerticalStep(context, 4, 'Writer Started', 'Writer is working on your assignment', currentStep),
                  _buildVerticalStep(context, 5, 'Writer Completed', 'View photos for verification', currentStep),
                  if (request.isHalfPayment)
                    _buildVerticalStep(context, 6, 'Final Payment', 'Remaining payment pending', currentStep),
                  _buildVerticalStep(context, 7, 'Delivering', 'Delivering to your location', currentStep),
                  _buildVerticalStep(context, 8, 'Order Completed', 'Order delivered successfully', currentStep, isLast: true),
                ],
              ),
            ),

            const SizedBox(height: 12),

            if (request.status == 'cancelled')
               Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(15),
                 margin: const EdgeInsets.only(bottom: 15),
                 decoration: BoxDecoration(
                   color: Colors.red.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: Colors.red.withOpacity(0.3))
                 ),
                 child: const Text('This order has been cancelled.',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
               ),

            // CANCEL BUTTON
            if (canCancel && request.status != 'cancelled')
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => _cancelOrder(request),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ),

             // Payment Step
             if (request.status == 'payment_pending')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _showPaymentOptions(request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Make Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),

              // Assigned - Mock Profile
              if (request.status == 'assigned')
               Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Writer Assigned! Check their samples:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        children: [1,2].map((e) => Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.image, size: 24, color: Colors.white54)
                        )).toList(),
                      ),
                    ],
                  ),
                ),

             // Review Step
             if (request.status == 'review_pending')
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text('Writer completed work. Please verify:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                   const SizedBox(height: 12),
                   if (request.verificationPhotos.isNotEmpty)
                      SizedBox(
                        height: 80,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: request.verificationPhotos.map((url) => Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(url, width: 80, height: 80, fit: BoxFit.cover),
                            ),
                          )).toList(),
                        ),
                      ),
                   const SizedBox(height: 16),
                   SizedBox(
                     width: double.infinity,
                     height: 50,
                     child: ElevatedButton.icon(
                       onPressed: () => _verifyWork(request),
                       icon: const Icon(Icons.check_circle),
                       label: const Text('Verify & Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                       style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       ),
                     ),
                   ),
                 ],
               ),

              // Final Payment
              if (request.status == 'payment_remaining_pending')
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _openCheckout(request, isFinal: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Pay Remaining ₹${(request.budget - request.paidAmount).toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
          ],
        ),
      ),
    );
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
                    BoxShadow(color: const Color(0xFFFFAF00).withOpacity(0.3), blurRadius: 8, spreadRadius: 2)
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isActive ? Colors.white : (isCompleted ? Colors.white70 : Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentOptions(RequestModel request) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment Options', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.pie_chart_outline, color: Colors.orange),
              title: const Text('Pay 50% Now', style: TextStyle(color: Colors.white)),
              subtitle: Text('₹${(request.budget / 2).toStringAsFixed(0)} now, rest check photos', style: const TextStyle(color: Colors.grey)),
              onTap: () {
                Navigator.pop(context);
                _openCheckout(request, isHalf: true);
              },
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Colors.green),
              title: const Text('Pay Full Amount', style: TextStyle(color: Colors.white)),
              subtitle: Text('₹${request.budget.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey)),
              onTap: () {
                Navigator.pop(context);
                _openCheckout(request, isFull: true);
              },
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyWork(RequestModel request) async {
      await ref.read(firestoreServiceProvider).updateRequest(request.id, {
        'status': request.isHalfPayment ? 'payment_remaining_pending' : 'delivering',
      });
  }

  Future<void> _cancelOrder(RequestModel request) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Cancel Order?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Yes, Cancel')),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(firestoreServiceProvider).updateRequest(request.id, {'status': 'cancelled'});
    }
  }
}
