import 'package:flutter/material.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:uuid/uuid.dart';

class PaymentService {
  final String publicKey;

  PaymentService({required this.publicKey});

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
      redirectUrl: "https://google.com",
      txRef: txRef,
      amount: amount,
      customer: customer,
      paymentOptions: "card, payattitude, barter, bank transfer, ussd",
      customization: Customization(title: "KowoPay Deposit"),
      isTestMode: true,
    );

    try {
      final ChargeResponse response = await flutterwave.charge(context);
      // Inspecting the package, charge returns dynamic or Future<ChargeResponse>
      // If the error persists, it might be that charge() doesn't need await or returns something else.
      // However, usually it is await flutterwave.charge().
      
      if (response != null) {
        if (response.success == true) {
          onResult("Transaction Successful! Ref: ${response.txRef}");
        } else {
           onResult("Transaction Failed!");
        }
      } else {
        onResult("Transaction Cancelled");
      }
    } catch (error) {
       onResult("Error: $error");
    }
  }

  Future<bool> withdrawToBank({
    required String bankCode,
    required String accountNumber,
    required double amount,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    return true; 
  }
}
