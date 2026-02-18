import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kowopay/providers/core_providers.dart';

class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  final _amountController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _bankCodeController = TextEditingController(); // Should be a dropdown
  bool _isLoading = false;

  void _withdraw() async {
    if (_amountController.text.isEmpty || _accountNumberController.text.isEmpty) return;

    setState(() => _isLoading = true);
    
    // Simulate delay or call service
    await Future.delayed(const Duration(seconds: 2));
    
    // Call withdrawal service (mocked for now)
    // final success = await ref.read(paymentServiceProvider).withdrawToBank(...);

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Withdrawal Request Submitted!")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Withdraw to Bank")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             TextField(
              controller: _bankCodeController,
              decoration: const InputDecoration(labelText: "Bank Code (e.g., 057)"),
            ),
             const SizedBox(height: 10),
            TextField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Account Number"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount",
                prefixText: "₦ ",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _withdraw,
              child: _isLoading ? const CircularProgressIndicator() : const Text("Withdraw"),
            ),
          ],
        ),
      ),
    );
  }
}
