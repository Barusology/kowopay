import 'package:flutter/material.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:kowopay/config/app_config.dart';

class PaymentResult {
  const PaymentResult({
    required this.success,
    required this.cancelled,
    required this.message,
  });

  final bool success;
  final bool cancelled;
  final String message;
}

class PaymentService {
  PaymentService({String? publicKey})
      : publicKey = publicKey ?? AppConfig.flutterwavePublicKey;

  /// Flutterwave publishes this key; it is still injected at build time so it
  /// is not baked into a single shared binary.
  final String publicKey;

  bool get isConfigured => publicKey.isNotEmpty;

  Future<PaymentResult> makePayment({
    required BuildContext context,
    required String email,
    required String fullName,
    required String phoneNumber,
    required String amount,
    required String txRef,
  }) async {
    if (!isConfigured) {
      return const PaymentResult(
        success: false,
        cancelled: false,
        message: 'Payments are not configured for this build.',
      );
    }

    final Customer customer = Customer(
      name: fullName,
      phoneNumber: phoneNumber,
      email: email,
    );

    final Flutterwave flutterwave = Flutterwave(
      publicKey: publicKey,
      currency: 'NGN',
      redirectUrl: AppConfig.flutterwaveRedirectUrl,
      txRef: txRef,
      amount: amount,
      customer: customer,
      paymentOptions: 'card, payattitude, barter, bank transfer, ussd',
      customization: Customization(title: 'KowoPay Deposit'),
      isTestMode: AppConfig.flutterwaveTestMode,
    );

    try {
      final ChargeResponse response = await flutterwave.charge(context);
      if (response.success == true) {
        return PaymentResult(
          success: true,
          cancelled: false,
          message: 'Payment submitted. Your wallet is credited after the '
              'payment provider confirms the transaction.',
        );
      }
      return const PaymentResult(
        success: false,
        cancelled: true,
        message: 'Payment was not completed.',
      );
    } catch (_) {
      return const PaymentResult(
        success: false,
        cancelled: false,
        message: 'Payment failed. Please try again.',
      );
    }
  }
}
