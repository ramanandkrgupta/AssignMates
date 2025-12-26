  void _cancelOrder(RequestModel request) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Yes, Cancel')),
        ],
      ),
    );

    if (confirm == true) {
      await _firestoreService.updateRequest(request.id, {'status': 'cancelled'});
    }
  }

  void _verifyWork(RequestModel request) async {
     // For now, auto-accept. In real app, user confirms photos.
     // Logic: If half payment was done, move to 'payment_remaining_pending', else 'delivering'
     bool isHalf = request.isHalfPayment;

     if (isHalf) {
        await _firestoreService.updateRequest(request.id, {'status': 'payment_remaining_pending'});
     } else {
        await _firestoreService.updateRequest(request.id, {'status': 'delivering'});
     }
  }
