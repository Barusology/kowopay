import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kowopay/providers/auth_provider.dart';
import 'package:kowopay/providers/core_providers.dart';
import 'package:kowopay/services/payment_service.dart';
import 'package:kowopay/theme/app_theme.dart';
import 'package:kowopay/utils/formatters.dart';
import 'package:kowopay/utils/rate_limiter.dart';
import 'package:kowopay/utils/secure_logger.dart';
import 'package:kowopay/utils/validators.dart';
import 'package:kowopay/widgets/app_surfaces.dart';
import 'package:uuid/uuid.dart';

class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();

  bool _isLoading = false;
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
    final User? user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    _email = user.email ?? '';
    _fullName = user.displayName ?? '';

    try {
      final Map<String, dynamic>? profile =
          await ref.read(databaseServiceProvider).getUserOnce(user.uid);
      if (!mounted) return;
      setState(() {
        _fullName = (profile?['name'] as String?) ?? _fullName;
        _phone = (profile?['phone'] as String?) ?? '';
      });
    } catch (e) {
      SecureLog.error('Deposit profile load', e);
    }
  }

  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (!RateLimiter.allow('deposit', const Duration(seconds: 2))) return;

    final double amount =
        double.parse(InputSanitizer.cleanAmount(_amountController.text));

    setState(() => _isLoading = true);
    try {
      final PaymentResult result =
          await ref.read(paymentServiceProvider).makePayment(
                context: context,
                email: _email,
                fullName: _fullName.isNotEmpty ? _fullName : 'KowoPay User',
                phoneNumber: _phone,
                amount: amount.toStringAsFixed(2),
                txRef: const Uuid().v4(),
              );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? AppColors.success : AppColors.warning,
        ),
      );
      if (result.success) Navigator.pop(context);
    } catch (e) {
      SecureLog.error('Deposit', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment failed. Please try again.'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool configured = ref.watch(paymentServiceProvider).isConfigured;

    return CinematicScaffold(
      title: 'Add money',
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.lilac,
                      child: const Icon(Icons.account_balance_wallet_outlined,
                          color: AppColors.purple),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fullName.isEmpty ? 'Your wallet' : _fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _email.isEmpty ? 'Signed in' : _email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!configured)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    'Payments are not configured for this build. Set '
                    'FLUTTERWAVE_PUBLIC_KEY with --dart-define.',
                    style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
                  ),
                ),
              const SectionTitle('Amount'),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('amountField'),
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  prefixText: '₦ ',
                  hintText: 'Minimum ₦100',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (value) =>
                    Validators.amount(value, min: 100, max: 5000000),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final int preset in const [1000, 2000, 5000, 10000])
                    ActionChip(
                      label: Text(formatNaira(preset, withDecimals: false)),
                      backgroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.outline),
                      onPressed: () => setState(() => _amountController.text =
                          preset.toString()),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              GradientButton(
                label: 'Continue to secure checkout',
                icon: Icons.lock_outline_rounded,
                loading: _isLoading,
                onPressed: (configured && !_isLoading)
                    ? _initiatePayment
                    : null,
              ),
              const SizedBox(height: 12),
              const Text(
                'You will be redirected to Flutterwave. Your wallet is credited '
                'only after the provider confirms the payment via a signed '
                'webhook.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.inkMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
