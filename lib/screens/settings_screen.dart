import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kowopay/providers/auth_provider.dart';
import 'package:kowopay/theme/app_theme.dart';
import 'package:kowopay/utils/rate_limiter.dart';
import 'package:kowopay/utils/secure_logger.dart';
import 'package:kowopay/widgets/app_surfaces.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _notificationsEnabled;
  bool? _biometricsEnabled;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool('notif_enabled') ?? true;
      _biometricsEnabled = prefs.getBool('bio_enabled') ?? false;
    });
  }

  Future<void> _saveNotifications(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_enabled', value);
    if (mounted) setState(() => _notificationsEnabled = value);
  }

  Future<void> _saveBiometrics(bool value) async {
    // Preference only; wiring local_auth is required to actually prompt for
    // biometrics. Tokens themselves are already held in Keystore/Keychain.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bio_enabled', value);
    if (mounted) setState(() => _biometricsEnabled = value);
  }

  Future<void> _sendPasswordReset() async {
    final User? user = ref.read(authServiceProvider).currentUser;
    final String? email = user?.email;
    if (email == null || email.isEmpty) {
      _snack('Could not determine your email address.', AppColors.danger);
      return;
    }
    if (!RateLimiter.allow('password-reset', const Duration(seconds: 60))) {
      _snack('Please wait a minute before requesting another link.',
          AppColors.warning);
      return;
    }
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
      _snack('Password reset link sent to $email', AppColors.success);
    } catch (e) {
      SecureLog.error('Password reset', e);
      _snack('Could not send the reset email.', AppColors.danger);
    }
  }

  void _snack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_notificationsEnabled == null || _biometricsEnabled == null) {
      return const CinematicScaffold(
        title: 'Settings',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final User? user = ref.watch(authStateProvider).valueOrNull;

    return CinematicScaffold(
      title: 'Settings',
      body: ListView(
        children: [
          const SectionTitle('Preferences'),
          const SizedBox(height: 12),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  title: const Text('Notifications',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Alerts for transactions and security'),
                  value: _notificationsEnabled!,
                  activeThumbColor: AppColors.purple,
                  onChanged: _saveNotifications,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile.adaptive(
                  title: const Text('Biometric unlock',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Require fingerprint or face on launch'),
                  value: _biometricsEnabled!,
                  activeThumbColor: AppColors.purple,
                  onChanged: _saveBiometrics,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle('Account security'),
          const SizedBox(height: 12),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.verified_outlined,
                      color: AppColors.success),
                  title: const Text('Email verification'),
                  subtitle: Text(
                    user?.emailVerified == true
                        ? 'Verified'
                        : 'Not verified',
                  ),
                  trailing: user?.emailVerified == true
                      ? const Icon(Icons.check_circle,
                          color: AppColors.success, size: 20)
                      : null,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.lock_reset,
                      color: AppColors.purple),
                  title: const Text('Change password'),
                  subtitle: const Text('Send a reset link to your email'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: _sendPasswordReset,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.shield_outlined,
                      color: AppColors.purple),
                  title: const Text('Session scope'),
                  subtitle: const Text(
                    'Web sessions end when the browser tab closes',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle('About'),
          const SizedBox(height: 12),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline,
                      color: AppColors.purple),
                  title: const Text('App version'),
                  subtitle: const Text('1.0.0'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.language, color: AppColors.purple),
                  title: const Text('Language'),
                  subtitle: const Text('English'),
                  onTap: () => _snack(
                      'More languages are coming soon.', AppColors.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            label: const Text(
              'Sign out',
              style: TextStyle(color: AppColors.danger),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: BorderSide(
                  color: AppColors.danger.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
