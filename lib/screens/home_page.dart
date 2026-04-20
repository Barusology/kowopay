import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kowopay/providers/auth_provider.dart';
import 'package:kowopay/providers/core_providers.dart';
import 'package:kowopay/screens/tabs/home_tab.dart';
import 'package:kowopay/screens/tabs/history_tab.dart';
import 'package:kowopay/screens/tabs/loans_tab.dart';
import 'package:kowopay/screens/tabs/rewards_tab.dart';
import 'package:kowopay/screens/components/app_drawer.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    HomeTab(),
    HistoryTab(),
    LoansTab(),
    RewardsTab(),
  ];

  static const List<String> _titles = [
    'KowoPay',
    'Transactions',
    'Loans',
    'Rewards',
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // FIX: use authStateProvider (the reactive stream) instead of
    // authServiceProvider.currentUser (a synchronous snapshot).
    // authStateProvider correctly notifies the widget on sign-in/sign-out.
    final user = ref.watch(authStateProvider).valueOrNull;
    final email = user?.email ?? '';

    // FIX: pre-read databaseServiceProvider outside the StreamBuilder.
    // Calling ref.watch inside the builder function caused Riverpod to
    // re-subscribe to the stream on every state change, risking infinite
    // rebuild loops.
    final dbService = ref.watch(databaseServiceProvider);

    return StreamBuilder(
      stream: user != null
          ? dbService.getUserStream(user.uid)
          : const Stream.empty(),
      builder: (context, snapshot) {
        String? photoUrl;

        if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
          // FIX: safe dynamic cast — Firebase returns Map<Object?, Object?>.
          // The plain `as Map` cast throws TypeError at runtime.
          final raw = snapshot.data!.snapshot.value;
          if (raw is Map) {
            final data = Map<String, dynamic>.from(raw);
            photoUrl = data['photoUrl'] as String?;
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _titles[_selectedIndex],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No new notifications')),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? Text(
                          email.isNotEmpty ? email[0].toUpperCase() : 'U',
                          style:
                              const TextStyle(color: Colors.deepPurple),
                        )
                      : null,
                ),
              ),
            ],
          ),
          drawer: const AppDrawer(),
          body: _pages[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.history), label: 'History'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.monetization_on), label: 'Loans'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.card_giftcard), label: 'Rewards'),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.deepPurple,
            unselectedItemColor: Colors.grey,
            onTap: _onItemTapped,
            // Required for 4+ items to show labels correctly.
            type: BottomNavigationBarType.fixed,
          ),
        );
      },
    );
  }
}
