import 'package:flutter/material.dart';
import 'package:kowopay/theme/app_theme.dart';
import 'package:kowopay/utils/validators.dart';
import 'package:kowopay/widgets/app_surfaces.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launch(BuildContext context, String value) async {
    if (!Validators.isSafeExternalUri(value)) {
      _show(context, 'That contact link is not available.');
      return;
    }
    final Uri uri = Uri.parse(value);
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      _show(context, 'Could not open the link on this device.');
    }
  }

  void _show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CinematicScaffold(
      title: 'Help & support',
      body: ListView(
        children: [
          const SectionTitle('Quick answers'),
          const SizedBox(height: 12),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: const [
                ExpansionTile(
                  leading: Icon(Icons.account_balance_wallet_outlined,
                      color: AppColors.purple),
                  title: Text('How do I fund my wallet?'),
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        'Open Home → Deposit, enter the amount and complete '
                        'checkout. Your wallet is credited after the payment '
                        'provider confirms the transaction.',
                        style: TextStyle(color: AppColors.inkMuted),
                      ),
                    ),
                  ],
                ),
                Divider(height: 1, indent: 16, endIndent: 16),
                ExpansionTile(
                  leading: Icon(Icons.phone_android_outlined,
                      color: AppColors.purple),
                  title: Text('How do I buy airtime?'),
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        'Open Home → Airtime, pick a network, enter the phone '
                        'number and amount, then confirm.',
                        style: TextStyle(color: AppColors.inkMuted),
                      ),
                    ),
                  ],
                ),
                Divider(height: 1, indent: 16, endIndent: 16),
                ExpansionTile(
                  leading: Icon(Icons.verified_user_outlined,
                      color: AppColors.purple),
                  title: Text('Why is a verified email required?'),
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        'It proves you own the address on the account, so '
                        'password resets and security alerts reach the right '
                        'person.',
                        style: TextStyle(color: AppColors.inkMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle('Contact us'),
          const SizedBox(height: 12),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined,
                      color: AppColors.purple),
                  title: const Text('Email support'),
                  subtitle: const Text('support@kowopay.com'),
                  onTap: () => _launch(context, 'mailto:support@kowopay.com'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.call_outlined,
                      color: AppColors.success),
                  title: const Text('Call us'),
                  subtitle: const Text('+234 800 KOWOPAY'),
                  onTap: () => _launch(context, 'tel:+2348005696729'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
