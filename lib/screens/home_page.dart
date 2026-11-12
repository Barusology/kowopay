import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kowopay/providers/auth_provider.dart';
import 'package:kowopay/providers/core_providers.dart';
import 'package:kowopay/providers/navigation_provider.dart';
import 'package:kowopay/screens/components/app_drawer.dart';
import 'package:kowopay/screens/tabs/home_tab.dart';
import 'package:kowopay/screens/tabs/loans_tab.dart';
import 'package:kowopay/screens/tabs/notifications_tab.dart';
import 'package:kowopay/screens/tabs/transactions_tab.dart';
import 'package:kowopay/theme/app_theme.dart';
import 'package:kowopay/widgets/cinematic_background.dart';
import 'package:kowopay/widgets/circular_nav_bar.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const List<Widget> _pages = <Widget>[
    HomeTab(),
    NotificationsTab(),
    LoansTab(),
    TransactionsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final User? user = ref.watch(authStateProvider).valueOrNull;
    final database = ref.watch(databaseServiceProvider);
    final int selectedIndex = ref.watch(homeTabIndexProvider);

    return StreamBuilder<DatabaseEvent>(
      stream: user == null
          ? const Stream<DatabaseEvent>.empty()
          : database.getNotificationsStream(user.uid),
      builder: (context, snapshot) {
        int unread = 0;
        if (snapshot.hasData && snapshot.data?.snapshot.value is Map) {
          final Map<Object?, Object?> raw =
              snapshot.data!.snapshot.value as Map<Object?, Object?>;
          for (final Object? value in raw.values) {
            if (value is Map && value['read'] != true) unread++;
          }
        }
        return Scaffold(
          backgroundColor: AppColors.white,
          drawer: const AppDrawer(),
          extendBody: true,
          body: CinematicBackground(
            child: IndexedStack(index: selectedIndex, children: _pages),
          ),
          bottomNavigationBar: CircularNavBar(
            currentIndex: selectedIndex,
            onTap: (index) =>
                ref.read(homeTabIndexProvider.notifier).state = index,
            items: <NavItem>[
              const NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
              ),
              NavItem(
                icon: Icons.notifications_none_rounded,
                activeIcon: Icons.notifications_rounded,
                label: 'Notifications',
                badgeCount: unread,
              ),
              const NavItem(
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet_rounded,
                label: 'Loans',
              ),
              const NavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Transactions',
              ),
            ],
          ),
        );
      },
    );
  }
}
