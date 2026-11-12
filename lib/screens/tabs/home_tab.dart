import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kowopay/providers/auth_provider.dart';
import 'package:kowopay/providers/core_providers.dart';
import 'package:kowopay/providers/navigation_provider.dart';
import 'package:kowopay/routes.dart';
import 'package:kowopay/theme/app_theme.dart';
import 'package:kowopay/utils/formatters.dart';
import 'package:kowopay/widgets/app_surfaces.dart';
import 'package:kowopay/widgets/user_avatar.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _balanceVisible = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null && !kIsWeb) {
      final BannerAd? ad = ref.read(adServiceProvider).createBannerAd();
      if (ad != null) {
        _bannerAd = ad;
        ad.load().then((_) {
          if (mounted) setState(() => _isAdLoaded = true);
        });
      }
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = ref.watch(authStateProvider).valueOrNull;
    final database = ref.watch(databaseServiceProvider);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      bottom: false,
      child: StreamBuilder<DatabaseEvent>(
        stream: database.getUserStream(user.uid),
        builder: (context, profileSnapshot) {
          final Map<String, dynamic>? profile =
              _asMap(profileSnapshot.data?.snapshot.value);
          final String? profileName = profile?['name'] as String?;
          final String name =
              (profileName != null && profileName.trim().isNotEmpty)
                  ? profileName.trim()
                  : (user.displayName ?? 'there');
          final double balance =
              (profile?['balance'] as num?)?.toDouble() ?? 0;
          final String? photoUrl = profile?['photoUrl'] as String?;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 132),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeSlideIn(child: _header(context, user, name, photoUrl)),
                const SizedBox(height: 22),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 90),
                  child: _balanceCard(context, balance),
                ),
                const SizedBox(height: 26),
                const SectionTitle('Services'),
                const SizedBox(height: 14),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: _services(context),
                ),
                const SizedBox(height: 26),
                SectionTitle(
                  'Recent activity',
                  trailing: TextButton(
                    onPressed: () => ref
                        .read(homeTabIndexProvider.notifier)
                        .state = 3,
                    child: const Text('See all'),
                  ),
                ),
                const SizedBox(height: 8),
                _recentActivity(context, user.uid),
                if (!kIsWeb && _isAdLoaded && _bannerAd != null) ...[
                  const SizedBox(height: 22),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      height: _bannerAd!.size.height.toDouble(),
                      width: _bannerAd!.size.width.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(
    BuildContext context,
    User user,
    String name,
    String? photoUrl,
  ) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: UserAvatar(photoUrl: photoUrl, email: user.email ?? ''),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greetingFor(DateTime.now()),
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 12.5,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
        _HeaderButton(
          icon: Icons.settings_outlined,
          onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
        ),
      ],
    );
  }

  Widget _balanceCard(BuildContext context, double balance) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.34),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -50,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -70,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.violet.withValues(alpha: 0.22),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Available balance',
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.78),
                          fontSize: 13,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _balanceVisible = !_balanceVisible),
                        child: Icon(
                          _balanceVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.white.withValues(alpha: 0.8),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: Text(
                      _balanceVisible ? formatNaira(balance) : '₦ ••••••',
                      key: ValueKey<bool>(_balanceVisible),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleAction(
                        icon: Icons.add_rounded,
                        label: 'Deposit',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.deposit),
                      ),
                      _CircleAction(
                        icon: Icons.arrow_upward_rounded,
                        label: 'Withdraw',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.withdraw),
                      ),
                      _CircleAction(
                        icon: Icons.phone_android_rounded,
                        label: 'Airtime',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.airtime),
                      ),
                      _CircleAction(
                        icon: Icons.receipt_long_rounded,
                        label: 'Bills',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.billPay),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _services(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _ServiceTile(
          icon: Icons.auto_awesome_rounded,
          label: 'AI Assistant',
          caption: 'Money advice',
          onTap: () => Navigator.pushNamed(context, AppRoutes.aiChat),
        ),
        _ServiceTile(
          icon: Icons.lightbulb_outline_rounded,
          label: 'Pay bills',
          caption: 'Utilities & more',
          onTap: () => Navigator.pushNamed(context, AppRoutes.billPay),
        ),
        _ServiceTile(
          icon: Icons.signal_cellular_alt_rounded,
          label: 'Airtime',
          caption: 'Instant top-up',
          onTap: () => Navigator.pushNamed(context, AppRoutes.airtime),
        ),
        _ServiceTile(
          icon: Icons.shield_outlined,
          label: 'Insurance',
          caption: 'Protect what matters',
          onTap: () => Navigator.pushNamed(context, AppRoutes.insurance),
        ),
      ],
    );
  }

  Widget _recentActivity(BuildContext context, String uid) {
    final database = ref.watch(databaseServiceProvider);
    return StreamBuilder<DatabaseEvent>(
      stream: database.getTransactionsStream(uid),
      builder: (context, snapshot) {
        final List<Map<String, dynamic>> items = _transactions(snapshot.data);
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const GlassCard(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (items.isEmpty) {
          return const GlassCard(
            child: Row(
              children: [
                Icon(Icons.receipt_long_outlined, color: AppColors.inkMuted),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No activity yet. Your first transaction will appear here.',
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                ),
              ],
            ),
          );
        }
        return GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 64),
                _ActivityRow(item: items[i]),
              ],
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _transactions(DatabaseEvent? event) {
    final Map<String, dynamic>? raw = _asMap(event?.snapshot.value);
    if (raw == null) return <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> list = raw.values
        .whereType<Map>()
        .map((Map value) => Map<String, dynamic>.from(value))
        .toList();
    list.sort((a, b) {
      final int ta = (a['timestamp'] as num?)?.toInt() ?? 0;
      final int tb = (b['timestamp'] as num?)?.toInt() ?? 0;
      return tb.compareTo(ta);
    });
    return list.take(3).toList();
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.8),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(icon, size: 21, color: AppColors.ink),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white.withValues(alpha: 0.16),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.28),
              ),
            ),
            child: Icon(icon, color: AppColors.white, size: 23),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 22,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.buttonGradient,
            ),
            child: Icon(icon, color: AppColors.white, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final bool isCredit = item['isCredit'] == true;
    final num amount = (item['amount'] as num?) ?? 0;
    final String title = (item['title'] as String?) ?? 'Transaction';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (isCredit ? AppColors.success : AppColors.purple)
              .withValues(alpha: 0.10),
        ),
        child: Icon(
          isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
          size: 19,
          color: isCredit ? AppColors.success : AppColors.purple,
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
      ),
      subtitle: Text(
        formatDate(item['timestamp'] ?? item['date']),
        style: const TextStyle(color: AppColors.inkMuted, fontSize: 11.5),
      ),
      trailing: Text(
        '${isCredit ? '+' : '-'}${formatNaira(amount)}',
        style: TextStyle(
          color: isCredit ? AppColors.success : AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
