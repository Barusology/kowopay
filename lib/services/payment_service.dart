class PaymentService {
  PaymentService();

  Future<void> purchaseAirtime({
    required String phoneNumber,
    required double amount,
    required String carrier,
  }) async {
    throw UnsupportedError(
      'Airtime purchases require the authenticated server-side payment flow.',
    );
  }

  Future<void> makePayment({
    required Object context,
    required String email,
    required String fullName,
    required String phoneNumber,
    required String amount,
    required String txRef,
    required Function(String) onResult,
  }) async {
    throw UnsupportedError(
      'Payments require the authenticated server-side Flutterwave flow.',
    );
  }

  Future<bool> withdrawToBank({
    required String bankCode,
    required String accountNumber,
    required double amount,
    required String narration,
    required String userId,
  }) async {
    throw UnimplementedError(
      'Bank withdrawals require a trusted server-side Flutterwave integration.',
    );
  }
}
