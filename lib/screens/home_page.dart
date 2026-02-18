import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kowopay/providers/auth_provider.dart';
import 'package:kowopay/providers/core_providers.dart';
import 'package:firebase_database/firebase_database.dart';
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

  final List<Widget> _pages = const [
    HomeTab(),
    HistoryTab(),
    LoansTab(),
    RewardsTab(),
  ];

  final List<String> _titles = const [
    'KowoPay',
    'Transactions',
    'Loans',
    'Rewards'
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    final email = user?.email; 

    return StreamBuilder<DatabaseEvent>(
        stream: user != null ? ref.watch(databaseServiceProvider).getUserStream(user.uid) : const Stream.empty(),

        builder: (context, snapshot) {
          String? photoUrl;
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
             final data = snapshot.data!.snapshot.value as Map;
             if (data.containsKey('photoUrl')) photoUrl = data['photoUrl'];
          }

          return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex], style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No new notifications')));
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null 
                  ? Text(
                      (email != null && email.isNotEmpty) ? email[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.deepPurple),
                    )
                  : null,
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monetization_on),
            label: 'Loans',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Rewards',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Needed for 4+ items
      ),
    );
        }
      );
  }
}
