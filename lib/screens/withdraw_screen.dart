import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kowopay/providers/auth_provider.dart';
import 'package:kowopay/providers/core_providers.dart';

// Sample bank list — in production fetch this from the Flutterwave banks API:
// GET https://api.flutterwave.com/v3/banks/NG
class _Bank {
  const _Bank(this.name, this.code);
  final String name;
  final String code;
}

const _nigeriaBanks = [
  _Bank('Access Bank', '044'),
  _Bank('Fidelity Bank', '070'),
  _Bank('First Bank of Nigeria', '011'),
  _Bank('Guaranty Trust Bank', '058'),
  _Bank('Stanbic IBTC', '221'),
  _Bank('Sterling Bank', '232'),
  _Bank('United Bank for Africa', '033'),
  _Bank('Zenith Bank', '057'),
  _Bank('Kuda Bank', '50211'),
  _Bank('Opay', '100004'),
  _Bank('Palmpay', '100033'),
];

class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountNumberController = TextEditingController();

  // FIX: bank replaced with a typed dropdown — free-text bank code input leads
  // to invalid API calls and user confusion.
  _Bank? _selectedBank;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _withdraw() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your bank')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) throw Exception('User not authenticated');

      final db = ref.read(databaseServiceProvider);

      // FIX: check balance BEFORE initiating withdrawal.  Sending a withdrawal
      // request for more than the user has causes API errors and poor UX.
      final currentBalance = await db.getBalance(user.uid);
      if (amount > currentBalance) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Insufficient balance. Available: ₦${currentBalance.toStringAsFixed(2)}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // FIX: call the real withdrawal service.
      // Previously this was a fake Future.delayed(2s) that always "succeeded".
      // Wiring this up requires your paymentServiceProvider to implement
      // withdrawToBank().  The commented-out call has been restored and
      // structured correctly.
      final paymentService = ref.read(paymentServiceProvider);
      final success = await paymentService.withdrawToBank(
        accountNumber: _accountNumberController.text.trim(),
        bankCode: _selectedBank!.code,
        amount: amount,
        narration: 'KowoPay Withdrawal',
        userId: user.uid,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Withdrawal request submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Withdrawal failed. Please check your account details and try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Withdrawal failed. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdraw to Bank'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // FIX: bank selection is now a dropdown, not a free-text field.
              DropdownButtonFormField<_Bank>(
                decoration: const InputDecoration(
                  labelText: 'Select Bank',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance),
                ),
                value: _selectedBank,
                items: _nigeriaBanks
                    .map((b) => DropdownMenuItem(
                          value: b,
                          child: Text(b.name),
                        ))
                    .toList(),
                onChanged: (bank) => setState(() => _selectedBank = bank),
                validator: (v) =>
                    v == null ? 'Please select your bank' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                key: const Key('accountField'),
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your account number';
                  }
                  if (v.trim().length != 10) {
                    return 'Account number must be exactly 10 digits';
                  }
                  if (int.tryParse(v.trim()) == null) {
                    return 'Account number must contain digits only';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                key: const Key('amountField'),
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₦ ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (parsed < 100) {
                    return 'Minimum withdrawal amount is ₦100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _withdraw,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Withdraw',
                        style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
