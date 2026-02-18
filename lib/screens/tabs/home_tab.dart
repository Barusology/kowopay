import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kowopay/providers/auth_provider.dart';
import 'package:kowopay/providers/core_providers.dart';
import 'package:kowopay/routes.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (kIsWeb) return; // Skip on web for now
    
    // We can't access ref directly in initState comfortably without a delay or creating it in didChangeDependencies
    // But since AdService is a Provider, we can just instantiate it or use reading in next frame.
    // However, strictly speaking, we can just create the ad here.
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null && !kIsWeb) {
       final adService = ref.read(adServiceProvider);
       _bannerAd = adService.createBannerAd();
       _bannerAd!.load().then((_) {
         setState(() {
           _isAdLoaded = true;
         });
       });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    final databaseService = ref.watch(databaseServiceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Greeting & Balance Card
          StreamBuilder(
            stream: user != null ? databaseService.getUserStream(user.uid) : const Stream.empty(),
            builder: (context, snapshot) {
              String name = 'User';
              String balance = '0.00';
              
              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  final data = snapshot.data!.snapshot.value as Map;
                  name = data['name'] ?? 'User';
                  balance = (data['balance'] ?? 0).toString();
              }

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.deepPurple, Colors.purpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $name',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '₦ $balance', 
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ActionButton(
                          icon: Icons.add,
                          label: 'Deposit',
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.deposit);
                          },
                        ),
                          _ActionButton(
                          icon: Icons.arrow_upward,
                          label: 'Withdraw',
                          onTap: () {
                              Navigator.pushNamed(context, AppRoutes.withdraw);
                          },
                        ),
                          _ActionButton(
                          icon: Icons.history,
                          label: 'History',
                          onTap: () {
                            // This will now likely navigate to the History Tab effectively
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use the bottom nav to view history')));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }
          ),
          const SizedBox(height: 20),
          
          // Services Grid
          const Text(
            'Services',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _ServiceCard(
                icon: Icons.chat_bubble_outline,
                label: 'AI Assistant',
                color: Colors.purple,
                onTap: () {
                    Navigator.pushNamed(context, AppRoutes.aiChat);
                },
              ),
              _ServiceCard(
                icon: Icons.payment,
                label: 'Bills Payment',
                color: Colors.orange,
                onTap: () {
                    Navigator.pushNamed(context, AppRoutes.billPay);
                },
              ),
                _ServiceCard(
                icon: Icons.phone_android,
                label: 'Airtime',
                color: Colors.green,
                onTap: () {
                    Navigator.pushNamed(context, AppRoutes.airtime);
                },
              ),
                  _ServiceCard(
                icon: Icons.security,
                label: 'Insurance',
                color: Colors.teal,
                onTap: () {
                    Navigator.pushNamed(context, AppRoutes.insurance);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isAdLoaded && _bannerAd != null)
            SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
              BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
