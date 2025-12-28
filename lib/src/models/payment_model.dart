class PaymentTransaction {
  final String transactionId; // Razorpay Payment ID
  final String orderId;       // Razorpay Order ID
  final String? signature;
  final double amount;
  final String status;        // 'success', 'failed'
  final String method;        // 'upi', 'card', 'netbanking'
  final DateTime timestamp;
  final Map<String, dynamic> metadata; // email, contact, wallet, vpa, etc.

  PaymentTransaction({
    required this.transactionId,
    required this.orderId,
    this.signature,
    required this.amount,
    required this.status,
    required this.method,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'orderId': orderId,
      'signature': signature,
      'amount': amount,
      'status': status,
      'method': method,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  factory PaymentTransaction.fromMap(Map<String, dynamic> map) {
    return PaymentTransaction(
      transactionId: map['transactionId'] ?? '',
      orderId: map['orderId'] ?? '',
      signature: map['signature'],
      amount: (map['amount'] ?? 0).toDouble(),
      status: map['status'] ?? 'unknown',
      method: map['method'] ?? 'unknown',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}
