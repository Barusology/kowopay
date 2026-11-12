import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kowopay/routes.dart';
import 'package:kowopay/theme/app_theme.dart';
import 'package:kowopay/widgets/app_surfaces.dart';
import 'package:kowopay/widgets/cinematic_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Timer? _timer;
  static const int _autoAdvanceSeconds = 6;

  @override
  void initState() {
    super.initState();
    _timer = Timer(
      const Duration(seconds: _autoAdvanceSeconds),
      () {
        if (mounted) _completeOnboarding();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CinematicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                FadeSlideIn(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      color: AppColors.white,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purple.withValues(alpha: 0.18),
                          blurRadius: 36,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'lib/assets/onboarding.jpg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                const FadeSlideIn(
                  delay: Duration(milliseconds: 100),
                  child: Text(
                    'Banking that feels effortless',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const FadeSlideIn(
                  delay: Duration(milliseconds: 160),
                  child: Text(
                    'Deposits, bills, airtime and smart money advice — '
                    'all in one purple place.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.inkMuted,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 220),
                  child: GradientButton(
                    label: 'Get started',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _completeOnboarding,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Auto-advances in $_autoAdvanceSeconds seconds',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
