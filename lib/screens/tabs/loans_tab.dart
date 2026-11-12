import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kowopay/providers/auth_provider.dart';
import 'package:kowopay/theme/app_theme.dart';
import 'package:kowopay/utils/formatters.dart';
import 'package:kowopay/widgets/app_surfaces.dart';

class LoansTab extends ConsumerStatefulWidget {
  const LoansTab({super.key});

  @override
  ConsumerState<LoansTab> createState() => _LoansTabState();
}

class _LoansTabState extends ConsumerState<LoansTab> {
  double _amount = 50000;
  int _tenureMonths = 3;

  static const double _minAmount = 10000;
  static const double _maxAmount = 500000;
  static const double _illustrativeMonthlyRate = 0.05;

  @override
  Widget build(BuildContext context) {
    final bool signedIn = ref.watch(authStateProvider).valueOrNull != null;
    final double monthly = _amount / _tenureMonths +
        (_amount * _illustrativeMonthlyRate);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 132),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loans',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Flexible credit built around your cash flow.',
              style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.30),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'PRE-QUALIFIED',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.white.withValues(alpha: 0.8),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Up to ${formatNaira(_maxAmount, withDecimals: false)}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Based on your KowoPay activity',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle('Choose an amount'),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'You need',
                        style: TextStyle(color: AppColors.inkMuted),
                      ),
                      const Spacer(),
                      Text(
                        formatNaira(_amount, withDecimals: false),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.purple,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _amount,
                    min: _minAmount,
                    max: _maxAmount,
                    divisions: 49,
                    activeColor: AppColors.purple,
                    inactiveColor: AppColors.lilac,
                    onChanged: (value) => setState(() => _amount = value),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('₦10,000',
                          style: TextStyle(
                              color: AppColors.inkMuted, fontSize: 11)),
                      Text('₦500,000',
                          style: TextStyle(
                              color: AppColors.inkMuted, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Repayment window',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final int months in const [1, 3, 6]) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _tenureMonths = months),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              margin: EdgeInsets.only(
                                  right: months == 6 ? 0 : 8),
                              decoration: BoxDecoration(
                                gradient: _tenureMonths == months
                                    ? AppColors.buttonGradient
                                    : null,
                                color: _tenureMonths == months
                                    ? null
                                    : AppColors.mist,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                '$months ${months == 1 ? 'month' : 'months'}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _tenureMonths == months
                                      ? AppColors.white
                                      : AppColors.inkMuted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.mist,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calculate_outlined,
                            color: AppColors.purple, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Illustrative monthly repayment',
                            style: TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          formatNaira(monthly),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Final rate and fees are shown in your personalised offer.',
                    style: TextStyle(color: AppColors.inkMuted, fontSize: 10.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: signedIn
                  ? () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'You are on the list. We will notify you when '
                            'loans open in your region.',
                          ),
                        ),
                      )
                  : null,
              child: const Text('Join the waitlist'),
            ),
            const SizedBox(height: 24),
            const SectionTitle('Why KowoPay loans'),
            const SizedBox(height: 12),
            const GlassCard(
              child: Column(
                children: [
                  _LoanFeature(
                    icon: Icons.bolt_outlined,
                    title: 'Fast decisions',
                    text: 'Eligibility is checked against your wallet activity — '
                        'no paperwork.',
                  ),
                  SizedBox(height: 16),
                  _LoanFeature(
                    icon: Icons.lock_outline_rounded,
                    title: 'Transparent terms',
                    text: 'Every fee is disclosed before you accept an offer.',
                  ),
                  SizedBox(height: 16),
                  _LoanFeature(
                    icon: Icons.schedule_rounded,
                    title: 'Flexible repayment',
                    text: 'Choose a window that matches your income cycle.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoanFeature extends StatelessWidget {
  const _LoanFeature({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.lilac,
          ),
          child: Icon(icon, color: AppColors.purple, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
