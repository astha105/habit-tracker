import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService {
  final Razorpay _razorpay = Razorpay();

  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;

  void init() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleWallet);
  }

  void _handleSuccess(PaymentSuccessResponse res) => onSuccess?.call(res);
  void _handleFailure(PaymentFailureResponse res) => onFailure?.call(res);
  void _handleWallet(ExternalWalletResponse res) {}

  void openCheckout({
    required String userPhone,
    required String userEmail,
    required String userName,
  }) {
    final options = {
      'key': 'rzp_test_YOUR_KEY_ID', // 🔑 paste your key here
      'amount': 19900,               // ₹199 in paise
      'name': 'HabitFlow',
      'description': 'Track Progress — Pro Unlock',
      'prefill': {
        'contact': userPhone,
        'email': userEmail,
        'name': userName,
      },
      'theme': {'color': '#7C6FD8'},
    };
    _razorpay.open(options);
  }

  void dispose() => _razorpay.clear();
}