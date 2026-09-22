import 'package:flutter/material.dart';
import 'package:flutterwave_standard/flutterwave.dart';

class PaymentService {
  final String publicKey;
  final String redirectUrl;
  final bool isTestMode;

  PaymentService({
    required this.publicKey,
    required this.redirectUrl,
    required this.isTestMode,
  }) {
    if (publicKey.trim().isEmpty) {
      throw StateError(
        'FLUTTERWAVE_PUBLIC_KEY is not configured. '
        'Provide it with --dart-define=FLUTTERWAVE_PUBLIC_KEY=...',
      );
    }
    if (redirectUrl.trim().isEmpty) {
      throw StateError(
        'FLUTTERWAVE_REDIRECT_URL is not configured. '
        'Provide it with --dart-define=FLUTTERWAVE_REDIRECT_URL=...',
      );
    }
  }

  Future<void> makePayment({
    required BuildContext context,
    required String email,
    required String fullName,
    required String phoneNumber,
    required String amount,
    required String txRef,
    required Function(String) onResult,
  }) async {
    final Customer customer = Customer(
      name: fullName,
      phoneNumber: phoneNumber,
      email: email,
    );

    final Flutterwave flutterwave = Flutterwave(
      publicKey: publicKey,
      currency: "NGN",
      redirectUrl: redirectUrl,
      txRef: txRef,
      amount: amount,
      customer: customer,
      paymentOptions: "card, payattitude, barter, bank transfer, ussd",
      customization: Customization(title: "KowoPay Deposit"),
      isTestMode: isTestMode,
    );

    try {
      final ChargeResponse response = await flutterwave.charge(context);
      // Inspecting the package, charge returns dynamic or Future<ChargeResponse>
      // If the error persists, it might be that charge() doesn't need await or returns something else.
      // However, usually it is await flutterwave.charge().

      if (response.success == true) {
        onResult("Transaction Successful! Ref: ${response.txRef}");
      } else {
        onResult("Transaction Failed!");
      }
    } catch (error) {
      onResult("Error: $error");
    }
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
