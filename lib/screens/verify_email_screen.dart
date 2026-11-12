import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kowopay/providers/auth_provider.dart';
import 'package:kowopay/theme/app_theme.dart';
import 'package:kowopay/utils/rate_limiter.dart';
import 'package:kowopay/utils/validators.dart';
import 'package:kowopay/widgets/app_surfaces.dart';
import 'package:kowopay/widgets/cinematic_background.dart';

/// Hard gate: no wallet, payment or admin screen is reachable until Firebase
/// reports `emailVerified == true` for the session.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _checking = false;
  bool _sending = false;
  int _cooldown = 0;
  Timer? _timer;
  String? _message;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    if (_sending || _cooldown > 0) return;
    if (!RateLimiter.allow('resend-verification', const Duration(seconds: 60))) {
      setState(() => _message = 'Please wait a moment before resending.');
      return;
    }
    setState(() {
      _sending = true;
      _message = null;
    });
    try {
      await ref.read(authServiceProvider).sendVerificationEmail();
      if (!mounted) return;
      _startCooldown();
      setState(() => _message = 'A fresh verification link has been sent.');
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Could not send the email. Try again later.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldown--);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  Future<void> _checkVerified() async {
    setState(() {
      _checking = true;
      _message = null;
    });
    try {
      final bool verified = await ref.read(authServiceProvider).reloadUser();
      if (!mounted) return;
      if (verified) {
        // Re-subscribe to the auth stream so the root gate rebuilds.
        ref.invalidate(authStateProvider);
      } else {
        setState(() =>
            _message = 'Not verified yet. Open the link in your email first.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Could not check your status. Try again.');
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String email = ref.watch(authStateProvider).valueOrNull?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: CinematicBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(26),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.buttonGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.mark_email_read_outlined,
                          size: 46, color: AppColors.white),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'Verify your email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'We sent a verification link to '
                      '${Validators.isEmail(email) ? email : 'your inbox'}. '
                      'Open it, then come back here.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 26),
                    GlassCard(
                      child: Column(
                        children: [
                          const _Step(
                            number: '1',
                            text: 'Open the email from KowoPay.',
                          ),
                          const SizedBox(height: 14),
                          const _Step(
                            number: '2',
                            text: 'Tap the verification link.',
                          ),
                          const SizedBox(height: 14),
                          const _Step(
                            number: '3',
                            text: 'Return here and confirm below.',
                          ),
                          if (_message != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.mist,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _message!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    GradientButton(
                      label: 'I have verified my email',
                      loading: _checking,
                      icon: Icons.verified_outlined,
                      onPressed: _checking ? null : _checkVerified,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed:
                          (_sending || _cooldown > 0) ? null : _resend,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: AppColors.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        _cooldown > 0
                            ? 'Resend in ${_cooldown}s'
                            : 'Resend verification email',
                        style: const TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        await ref.read(authServiceProvider).signOut();
                      },
                      child: const Text('Use a different account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.lilac,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: AppColors.purple,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, height: 1.35),
          ),
        ),
      ],
    );
  }
}
