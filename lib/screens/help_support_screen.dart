import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const ExpansionTile(
            title: Text('How do I fund my wallet?'),
            children: [Padding(padding: EdgeInsets.all(8.0), child: Text('Click on the "Deposit" button on the home screen and follow the prompts to pay via Card or Bank Transfer.'))],
          ),
          const ExpansionTile(
            title: Text('How do I buy Airtime?'),
            children: [Padding(padding: EdgeInsets.all(8.0), child: Text('Go to Services > Airtime, select your network, enter phone number and amount.'))],
          ),
          const SizedBox(height: 20),
          const Text(
            'Contact Us',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.email, color: Colors.deepPurple),
            title: const Text('Email Support'),
            subtitle: const Text('support@kowopay.com'),
            onTap: () async {
              try {
                await _launchUrl('mailto:support@kowopay.com');
              } catch (e) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch email app')));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.phone, color: Colors.green),
            title: const Text('Call Us'),
            subtitle: const Text('+234 800 KOWOPAY'),
            onTap: () async {
               try {
                await _launchUrl('tel:+2348005696729');
              } catch (e) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch phone app')));
              }
            },
          ),
        ],
      ),
    );
  }
}
