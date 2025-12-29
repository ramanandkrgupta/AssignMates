
import 'package:flutter/foundation.dart';
import 'package:js/js.dart';
import 'package:razorpay_web/razorpay_web.dart';

/// A handler for managing Razorpay payments on the Web.
class WebPaymentHandler {
  final Razorpay _razorpay;

  // Callback functions
  final Function(PaymentSuccessResponse)? onSuccess;
  final Function(PaymentFailureResponse)? onFailure;
  final Function(ExternalWalletResponse)? onExternalWallet;

  WebPaymentHandler({
    this.onSuccess,
    this.onFailure,
    this.onExternalWallet,
  }) : _razorpay = Razorpay() {
    if (kIsWeb) {
      if (onSuccess != null) {
        _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess!);
      }
      if (onFailure != null) {
        _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure!);
      }
      if (onExternalWallet != null) {
        _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet!);
      }
    }
  }

  /// Opens the Razorpay checkout with the given [options].
  void openCheckout(Map<String, dynamic> options) {
    if (!kIsWeb) {
      debugPrint('WebPaymentHandler: Not on web, ignoring call.');
      return;
    }
    
    // Ensure key is present
    if (options['key'] == null || options['key'].toString().isEmpty) {
        throw Exception('Razorpay API Key is missing');
    }

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('WebPaymentHandler Error: $e');
      rethrow; 
    }
  }

  /// Clears the Razorpay listeners.
  void clear() {
    _razorpay.clear();
  }
}
