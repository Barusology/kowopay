import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kowopay/providers/auth_provider.dart';
import 'package:kowopay/providers/core_providers.dart';
import 'package:kowopay/services/auth_service.dart';
import 'package:kowopay/theme/app_theme.dart';
import 'package:kowopay/utils/rate_limiter.dart';
import 'package:kowopay/utils/secure_logger.dart';
import 'package:kowopay/utils/validators.dart';
import 'package:kowopay/widgets/app_surfaces.dart';
import 'package:kowopay/widgets/cinematic_background.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _acceptedTerms = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  int get _passwordScore {
    final String value = _passwordController.text;
    int score = 0;
    if (value.length >= 8) score++;
    if (value.contains(RegExp(r'[A-Z]')) && value.contains(RegExp(r'[a-z]'))) {
      score++;
    }
    if (value.contains(RegExp(r'[0-9]'))) score++;
    if (value.contains(RegExp(r'[^A-Za-z0-9]'))) score++;
    return score;
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      setState(() => _errorMessage =
          'Please accept the terms to create your account.');
      return;
    }
    if (RateLimiter.isLocked('register')) {
      setState(() => _errorMessage =
          'Too many attempts. Please wait a couple of minutes.');
      return;
    }
    if (!RateLimiter.allow('register-submit', const Duration(seconds: 2))) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String name =
        InputSanitizer.cleanText(_nameController.text, maxLength: 80);
    final String email = _emailController.text.trim().toLowerCase();

    try {
      final credential = await ref
          .read(authServiceProvider)
          .registerWithEmailAndPassword(email, _passwordController.text);

      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(name);
        // The account exists at this point. A profile write failure must not
        // hide the account from the user, so it is logged and retried on the
        // next profile update.
        try {
          await ref.read(databaseServiceProvider).saveUser(
                uid: user.uid,
                email: email,
                name: name,
              );
        } catch (e) {
          SecureLog.error('Profile provisioning', e);
        }
      }
      RateLimiter.recordSuccess('register');
    } catch (e) {
      RateLimiter.recordFailure('register');
      setState(() => _errorMessage = mapAuthError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CinematicBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    const FadeSlideIn(
                      child: Text(
                        'Create your account',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.9,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const FadeSlideIn(
                      delay: Duration(milliseconds: 60),
                      child: Text(
                        'One wallet for payments, bills and everyday banking.',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: GlassCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                key: const Key('nameField'),
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.name],
                                decoration: const InputDecoration(
                                  labelText: 'Full name',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: Validators.fullName,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: Validators.email,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                key: const Key('passwordField'),
                                controller: _passwordController,
                                obscureText: !_passwordVisible,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.newPassword
                                ],
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _passwordVisible
                                        ? 'Hide password'
                                        : 'Show password',
                                    icon: Icon(
                                      _passwordVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () => setState(() =>
                                        _passwordVisible = !_passwordVisible),
                                  ),
                                ),
                                validator: Validators.password,
                              ),
                              const SizedBox(height: 8),
                              _StrengthMeter(score: _passwordScore),
                              const SizedBox(height: 14),
                              TextFormField(
                                key: const Key('confirmField'),
                                controller: _confirmController,
                                obscureText: !_passwordVisible,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _signUp(),
                                decoration: const InputDecoration(
                                  labelText: 'Confirm password',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                validator: (value) =>
                                    Validators.confirmPassword(
                                  value,
                                  _passwordController.text,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: Checkbox(
                                      value: _acceptedTerms,
                                      activeColor: AppColors.purple,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      onChanged: (value) => setState(
                                          () => _acceptedTerms = value ?? false),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(
                                        'I agree to the Terms of Service and '
                                        'Privacy Policy, and to receive '
                                        'security emails about my account.',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.inkMuted,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              GradientButton(
                                label: 'Create account',
                                loading: _isLoading,
                                onPressed: _isLoading ? null : _signUp,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account?',
                          style: TextStyle(color: AppColors.inkMuted),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Sign in'),
                        ),
                      ],
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

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = <Color>[
      AppColors.danger,
      AppColors.warning,
      AppColors.violet,
      AppColors.success,
    ];
    final String label = switch (score) {
      <= 1 => 'Weak',
      2 => 'Fair',
      3 => 'Good',
      _ => 'Strong',
    };
    return Row(
      children: [
        for (int i = 0; i < 4; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 5,
              decoration: BoxDecoration(
                color: i < score ? colors[score - 1] : AppColors.outline,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          if (i < 3) const SizedBox(width: 5),
        ],
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: score == 0 ? AppColors.inkMuted : colors[score - 1],
          ),
        ),
      ],
    );
  }
}
