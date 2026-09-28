import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kowopay/providers/auth_provider.dart';
import 'package:kowopay/providers/core_providers.dart';
import 'package:kowopay/models/money.dart';
import 'package:uuid/uuid.dart';

class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  // Real user data, populated from auth + database in initState.
  String _email = '';
  String _fullName = '';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    // FIX: read real user data from auth and database — never use hardcoded
    // placeholder values ("user@example.com", "KowoPay User", "0123456789")
    // in a real payment transaction.  Flutterwave attaches these details to
    // the transaction record for KYC/AML compliance and dispute resolution.
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      final db = ref.read(databaseServiceProvider);
      final profileData = await db.getUserOnce(user.uid);
      if (mounted) {
        setState(() {
          _email = user.email ?? '';
          _fullName = profileData?['name'] as String? ?? user.displayName ?? '';
          _phone = profileData?['phone'] as String? ?? '';
        });
      }
    } catch (_) {
      // Fall back to whatever Firebase Auth knows.
      if (mounted) {
        setState(() {
          _email = user.email ?? '';
          _fullName = user.displayName ?? '';
        });
      }
    }
  }

  Future<void> _initiatePayment() async {
    final rawAmount = _amountController.text.trim();

    final Money amount;
    try {
      amount = Money.fromMajor(currencyCode: 'NGN', amount: rawAmount);
    } on FormatException {
      _showInvalidAmount();
      return;
    } on RangeError {
      _showInvalidAmount();
      return;
    } on ArgumentError {
      _showInvalidAmount();
      return;
    }
    if (amount.minorUnits < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount (minimum ₦100)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User account error. Please log out and back in.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final paymentService = ref.read(paymentServiceProvider);

      final receipt = await paymentService.makePayment(
        email: _email,
        fullName: _fullName.isNotEmpty ? _fullName : 'KowoPay User',
        phoneNumber: _phone.isNotEmpty ? _phone : '',
        amount: amount,
        txRef: const Uuid().v4(),
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Deposit confirmed: ${receipt.amount.format(locale: 'en_NG')}',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showInvalidAmount() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter a valid amount (minimum ₦100)'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refill Wallet'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Show who the payment is for (transparency for users).
            if (_email.isNotEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.account_circle,
                    color: Colors.deepPurple,
                  ),
                  title: Text(_fullName.isNotEmpty ? _fullName : 'You'),
                  subtitle: Text(_email),
                ),
              ),
            const SizedBox(height: 16),

            const Text(
              'Enter Amount to Deposit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('amountField'),
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixText: '₦ ',
                hintText: 'Minimum ₦100',
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _initiatePayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Pay with Flutterwave',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
