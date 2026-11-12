import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kowopay/providers/auth_provider.dart';
import 'package:kowopay/providers/core_providers.dart';
import 'package:kowopay/services/wallet_service.dart';
import 'package:kowopay/theme/app_theme.dart';
import 'package:kowopay/utils/formatters.dart';
import 'package:kowopay/utils/rate_limiter.dart';
import 'package:kowopay/utils/secure_logger.dart';
import 'package:kowopay/utils/validators.dart';
import 'package:kowopay/widgets/app_surfaces.dart';

class _Bank {
  const _Bank(this.name, this.code);
  final String name;
  final String code;
}

const List<_Bank> _nigeriaBanks = <_Bank>[
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();

  _Bank? _selectedBank;
  bool _isLoading = false;
  double _balance = 0;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    final User? user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;
    try {
      final double balance =
          await ref.read(databaseServiceProvider).getBalance(user.uid);
      if (mounted) setState(() => _balance = balance);
    } catch (e) {
      SecureLog.error('Withdraw balance load', e);
    }
  }

  Future<void> _withdraw() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBank == null) {
      _snack('Please select your bank', AppColors.warning);
      return;
    }
    if (!RateLimiter.allow('withdraw', const Duration(seconds: 3))) return;

    final double amount =
        double.parse(InputSanitizer.cleanAmount(_amountController.text));
    if (amount > _balance) {
      _snack(
        'Insufficient balance. Available ${formatNaira(_balance)}',
        AppColors.danger,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(walletServiceProvider).requestWithdrawal(
            amount: amount,
            bankCode: _selectedBank!.code,
            accountNumber:
                InputSanitizer.cleanPhone(_accountController.text),
          );
      if (!mounted) return;
      _snack(
        'Withdrawal submitted. You will receive an alert when it settles.',
        AppColors.success,
      );
      Navigator.pop(context);
    } on WalletException catch (e) {
      _snack(e.message, AppColors.danger);
    } catch (e) {
      SecureLog.error('Withdrawal', e);
      _snack('Withdrawal failed. Please try again.', AppColors.danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CinematicScaffold(
      title: 'Withdraw',
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available balance',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.78),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatNaira(_balance),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              GlassCard(
                child: Column(
                  children: [
                    DropdownButtonFormField<_Bank>(
                      initialValue: _selectedBank,
                      decoration: const InputDecoration(
                        labelText: 'Bank',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                      ),
                      items: _nigeriaBanks
                          .map((bank) => DropdownMenuItem<_Bank>(
                                value: bank,
                                child: Text(bank.name),
                              ))
                          .toList(),
                      onChanged: (bank) =>
                          setState(() => _selectedBank = bank),
                      validator: (v) =>
                          v == null ? 'Please select your bank' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('accountField'),
                      controller: _accountController,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: 'Account number',
                        prefixIcon: Icon(Icons.credit_card_outlined),
                        counterText: '',
                      ),
                      validator: Validators.accountNumber,
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
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      validator: (value) => Validators.amount(
                        value,
                        min: 500,
                        max: _balance <= 0
                            ? 500000
                            : (_balance < 500000 ? _balance : 500000),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(
                label: 'Withdraw to bank',
                icon: Icons.arrow_upward_rounded,
                loading: _isLoading,
                onPressed: _isLoading ? null : _withdraw,
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_outlined,
                      size: 14, color: AppColors.inkMuted),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Balance and limits are verified server-side before any '
                      'money moves.',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
