import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kowopay/providers/core_providers.dart';
import 'package:kowopay/services/wallet_service.dart';
import 'package:kowopay/theme/app_theme.dart';
import 'package:kowopay/utils/rate_limiter.dart';
import 'package:kowopay/utils/secure_logger.dart';
import 'package:kowopay/utils/validators.dart';
import 'package:kowopay/widgets/app_surfaces.dart';

class AirtimeScreen extends ConsumerStatefulWidget {
  const AirtimeScreen({super.key});

  @override
  ConsumerState<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends ConsumerState<AirtimeScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String? _selectedCarrier;
  bool _isLoading = false;

  static const List<String> _carriers = <String>['MTN', 'Airtel', 'Glo', '9mobile'];

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _buyAirtime() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCarrier == null) {
      _snack('Please select a network provider', AppColors.warning);
      return;
    }
    if (!RateLimiter.allow('airtime', const Duration(seconds: 3))) return;

    final double amount =
        double.parse(InputSanitizer.cleanAmount(_amountController.text));

    setState(() => _isLoading = true);
    try {
      await ref.read(walletServiceProvider).purchaseAirtime(
            amount: amount,
            carrier: _selectedCarrier!,
            phone: InputSanitizer.cleanPhone(_phoneController.text),
          );
      if (!mounted) return;
      _snack('Airtime purchase successful.', AppColors.success);
      Navigator.pop(context);
    } on WalletException catch (e) {
      _snack(e.message, AppColors.danger);
    } catch (e) {
      SecureLog.error('Airtime purchase', e);
      _snack('Purchase failed. Please try again.', AppColors.danger);
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
      title: 'Buy airtime',
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Top up any network'),
              const SizedBox(height: 14),
              GlassCard(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCarrier,
                      decoration: const InputDecoration(
                        labelText: 'Network',
                        prefixIcon: Icon(Icons.signal_cellular_alt_rounded),
                      ),
                      items: _carriers
                          .map((carrier) => DropdownMenuItem<String>(
                                value: carrier,
                                child: Text(carrier),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedCarrier = value),
                      validator: (v) =>
                          v == null ? 'Please select a network' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('phoneField'),
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (value) =>
                          Validators.phone(value, required: true),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('amountField'),
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: false),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₦ ',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      validator: (value) =>
                          Validators.amount(value, min: 50, max: 50000),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final int preset in const [100, 200, 500, 1000])
                    ActionChip(
                      label: Text('₦$preset'),
                      backgroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.outline),
                      onPressed: () => setState(
                          () => _amountController.text = preset.toString()),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              GradientButton(
                label: 'Buy airtime',
                icon: Icons.flash_on_rounded,
                loading: _isLoading,
                onPressed: _isLoading ? null : _buyAirtime,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
