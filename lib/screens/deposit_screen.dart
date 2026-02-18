import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kowopay/providers/core_providers.dart';
import 'package:uuid/uuid.dart';

class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  final _amountController = TextEditingController();
  final _emailController = TextEditingController(text: "user@example.com"); // Pre-fill or get from Auth
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _initiatePayment() async {
    final amount = _amountController.text;
    if (amount.isEmpty) return;

    setState(() => _isLoading = true);

    final paymentService = ref.read(paymentServiceProvider);
    
    // In a real app, get user details from AuthProvider
    await paymentService.makePayment(
      context: context,
      email: _emailController.text,
      fullName: "KowoPay User",
      phoneNumber: "0123456789",
      amount: amount,
      txRef: const Uuid().v4(),
      onResult: (message) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        if (message.contains("Successful")) {
             Navigator.pop(context); // Go back to home
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Refill Wallet")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Enter Amount to Deposit"),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixText: "₦ ",
              ),
            ),
             const SizedBox(height: 10),
             // Hidden email field or pre-filled
             TextField(
              controller: _emailController,
               decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Email",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _initiatePayment,
              child: _isLoading ? const CircularProgressIndicator() : const Text("Pay with Flutterwave"),
            ),
          ],
        ),
      ),
    );
  }
}
