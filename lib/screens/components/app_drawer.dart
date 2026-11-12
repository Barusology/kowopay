import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kowopay/providers/auth_provider.dart';
import 'package:kowopay/providers/core_providers.dart';
import 'package:kowopay/providers/navigation_provider.dart';
import 'package:kowopay/routes.dart';
import 'package:kowopay/screens/tabs/rewards_tab.dart';
import 'package:kowopay/theme/app_theme.dart';
import 'package:kowopay/widgets/app_surfaces.dart';
import 'package:kowopay/widgets/user_avatar.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final User? user = ref.watch(authStateProvider).valueOrNull;
    final database = ref.watch(databaseServiceProvider);

    return Drawer(
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: StreamBuilder<DatabaseEvent>(
        stream: user == null
            ? const Stream<DatabaseEvent>.empty()
            : database.getUserStream(user.uid),
        builder: (context, snapshot) {
          String? photoUrl;
          String name = user?.displayName ?? '';
          if (snapshot.data?.snapshot.value is Map) {
            final Map<Object?, Object?> data =
                snapshot.data!.snapshot.value as Map<Object?, Object?>;
            name = (data['name'] as String?) ?? name;
            photoUrl = data['photoUrl'] as String?;
          }
          final String email = user?.email ?? '';
          if (name.isEmpty) {
            name = email.isNotEmpty ? email.split('@').first : 'KowoPay user';
          }

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(22, 46, 22, 24),
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatar(
                      photoUrl: photoUrl,
                      email: email,
                      radius: 30,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.78),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _DrawerItem(
                icon: Icons.home_outlined,
                label: 'Home',
                onTap: () {
                  ref.read(homeTabIndexProvider.notifier).state = 0;
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                onTap: () {
                  ref.read(homeTabIndexProvider.notifier).state = 1;
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Loans',
                onTap: () {
                  ref.read(homeTabIndexProvider.notifier).state = 2;
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.receipt_long_outlined,
                label: 'Transactions',
                onTap: () {
                  ref.read(homeTabIndexProvider.notifier).state = 3;
                  Navigator.pop(context);
                },
              ),
              const Divider(height: 24, indent: 20, endIndent: 20),
              _DrawerItem(
                icon: Icons.person_outline,
                label: 'Profile',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.profile);
                },
              ),
              _DrawerItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.settings);
                },
              ),
              _DrawerItem(
                icon: Icons.card_giftcard_outlined,
                label: 'Rewards',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const CinematicScaffold(
                        title: 'Rewards',
                        body: RewardsTab(),
                      ),
                    ),
                  );
                },
              ),
              _DrawerItem(
                icon: Icons.help_outline_rounded,
                label: 'Help & support',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.help);
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  final bool isAdmin =
                      ref.watch(adminRoleProvider).valueOrNull ?? false;
                  if (!isAdmin) return const SizedBox.shrink();
                  return _DrawerItem(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Admin console',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.admin);
                    },
                  );
                },
              ),
              const Divider(height: 24, indent: 20, endIndent: 20),
              _DrawerItem(
                icon: Icons.logout_rounded,
                label: 'Sign out',
                color: AppColors.danger,
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authServiceProvider).signOut();
                },
              ),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.inkMuted, size: 21),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? AppColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        ),
      ),
      trailing: color == null
          ? const Icon(Icons.chevron_right_rounded,
              size: 18, color: AppColors.inkMuted)
          : null,
      onTap: onTap,
    );
  }
}
