import '../models/money.dart';

class PaymentReceipt {
  const PaymentReceipt({required this.providerReference, required this.amount});

  final String providerReference;
  final Money amount;
}

class PaymentService {
  PaymentService();

  Future<PaymentReceipt> purchaseAirtime({
    required String phoneNumber,
    required Money amount,
    required String carrier,
  }) async {
    throw UnsupportedError(
      'Airtime purchases require the authenticated server-side payment flow.',
    );
  }

  Future<PaymentReceipt> makePayment({
    required String email,
    required String fullName,
    required String phoneNumber,
    required Money amount,
    required String txRef,
  }) async {
    throw UnsupportedError(
      'Payments require the authenticated server-side Flutterwave flow.',
    );
  }

  Future<PaymentReceipt> withdrawToBank({
    required String bankCode,
    required String accountNumber,
    required Money amount,
    required String narration,
    required String userId,
  }) async {
    throw UnimplementedError(
      'Bank withdrawals require a trusted server-side Flutterwave integration.',
    );
  }
}
