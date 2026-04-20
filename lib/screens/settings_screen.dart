import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // FIX: initialise to null so we can show a loading indicator while prefs load.
  // Previously these were plain bool fields that were never persisted — every
  // app restart silently reset the user's preferences.
  bool? _notificationsEnabled;
  bool? _biometricsEnabled;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ─── Persistence helpers ───────────────────────────────────────────────────

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool('notif_enabled') ?? true;
        _biometricsEnabled = prefs.getBool('bio_enabled') ?? false;
      });
    }
  }

  Future<void> _saveNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_enabled', value);
    setState(() => _notificationsEnabled = value);
  }

  Future<void> _saveBiometrics(bool value) async {
    // NOTE: biometric *authentication* itself requires the local_auth package.
    // The toggle here persists the user's preference so the login screen knows
    // whether to attempt biometric auth on next launch.
    // Add: flutter pub add local_auth
    // Then gate the toggle on LocalAuthentication().canCheckBiometrics.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bio_enabled', value);
    setState(() => _biometricsEnabled = value);
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> _changePassword() async {
    // FIX: send a real Firebase password reset email instead of a placeholder
    // SnackBar message.  The original code showed 'Password Reset Flow' which
    // is clearly a developer placeholder.
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;

    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not determine your email address.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Password reset email sent to $email'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Failed to send reset email. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loader while SharedPreferences are being read.
    if (_notificationsEnabled == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // FIX: onChange now persists the value to SharedPreferences.
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive alerts for transactions'),
            value: _notificationsEnabled!,
            activeColor: Colors.deepPurple,
            onChanged: _saveNotifications,
          ),

          SwitchListTile(
            title: const Text('Biometric Login'),
            subtitle: const Text('Use fingerprint or face ID to log in'),
            value: _biometricsEnabled!,
            activeColor: Colors.deepPurple,
            onChanged: _saveBiometrics,
          ),

          const Divider(),

          // FIX: sends a real Firebase password reset email.
          ListTile(
            leading: const Icon(Icons.lock_reset, color: Colors.deepPurple),
            title: const Text('Change Password'),
            subtitle: const Text('Send a password reset email'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _changePassword,
          ),

          ListTile(
            leading: const Icon(Icons.language, color: Colors.deepPurple),
            title: const Text('Language'),
            subtitle: const Text('English'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: implement language picker when i18n is added.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language selection coming soon')),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined,
                color: Colors.deepPurple),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: open in-app browser or web URL.
            },
          ),

          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.deepPurple),
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}
