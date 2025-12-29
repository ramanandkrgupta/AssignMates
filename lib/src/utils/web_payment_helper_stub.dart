import 'package:razorpay_flutter/razorpay_flutter.dart';

/// A stub handler for managing Razorpay payments on non-Web platforms.
/// This implementation does nothing but satisfies the interface requirements.
class WebPaymentHandler {
  // Callback functions
  final Function(PaymentSuccessResponse)? onSuccess;
  final Function(PaymentFailureResponse)? onFailure;
  final Function(ExternalWalletResponse)? onExternalWallet;

  WebPaymentHandler({
    this.onSuccess,
    this.onFailure,
    this.onExternalWallet,
  });

  /// Opens the Razorpay checkout with the given [options].
  void openCheckout(Map<String, dynamic> options) {
    // No-op on non-web platforms
  }

  /// Clears the Razorpay listeners.
  void clear() {
    // No-op on non-web platforms
  }
}
