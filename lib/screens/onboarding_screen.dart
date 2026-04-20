import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kowopay/routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Timer? _timer;

  // FIX: 5 seconds is appropriate for an onboarding splash.
  // The original timer was set to Duration(minutes: 3) while the UI label read
  // "(Auto-advance in 60 seconds)" — a 3× mismatch that made users think the
  // app was frozen.
  static const _autoAdvanceSeconds = 5;

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
    // Persist the flag BEFORE navigating so the check in main() sees it.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);

    // Check mounted after the async gap — the timer might fire just as the
    // user taps the button, so both code paths arrive here.
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Image.asset(
                    // FIX: asset path without the lib/ prefix.
                    // pubspec.yaml should list: assets: - assets/onboarding.jpg
                    // and the file should live at assets/onboarding.jpg.
                    'assets/onboarding.jpg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Welcome to KowoPay',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your all-in-one financial partner for seamless payments and more.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // FIX: label now matches the actual timer duration.
              Text(
                '(Auto-advances in $_autoAdvanceSeconds seconds)',
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _completeOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Start Now',
                      style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
