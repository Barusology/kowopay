import 'package:flutter/material.dart';
import 'package:kowopay/theme/app_theme.dart';
import 'package:kowopay/widgets/app_surfaces.dart';

class RewardsTab extends StatelessWidget {
  const RewardsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 132),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rewards',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Little perks for banking with KowoPay.',
              style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
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
                  Text(
                    'Your points',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.78),
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '0',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Earn points on deposits, bill payments and airtime.',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.8),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle('Ways to earn'),
            const SizedBox(height: 12),
            const GlassCard(
              child: Column(
                children: [
                  _RewardRow(
                    icon: Icons.savings_outlined,
                    title: 'Fund your wallet',
                    caption: 'Points on every cleared deposit',
                  ),
                  SizedBox(height: 16),
                  _RewardRow(
                    icon: Icons.receipt_long_outlined,
                    title: 'Pay bills',
                    caption: 'Bonus points on utilities',
                  ),
                  SizedBox(height: 16),
                  _RewardRow(
                    icon: Icons.people_outline_rounded,
                    title: 'Invite a friend',
                    caption: 'Both of you earn when they verify',
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

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.icon,
    required this.title,
    required this.caption,
  });

  final IconData icon;
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.lilac,
          ),
          child: Icon(icon, color: AppColors.purple, size: 20),
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
              Text(
                caption,
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
