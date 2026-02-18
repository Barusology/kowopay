import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kowopay/providers/auth_provider.dart';
import 'package:kowopay/providers/core_providers.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:kowopay/routes.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    final email = user?.email ?? 'user@kowopay.com';
    String name = email.split('@')[0]; // Changed to String to allow reassignment

    return Drawer(
      child: StreamBuilder<DatabaseEvent>(
        stream: user != null ? ref.watch(databaseServiceProvider).getUserStream(user.uid) : const Stream.empty(),
        builder: (context, snapshot) {
          String? photoUrl;
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final data = snapshot.data!.snapshot.value as Map;
            name = data['name'] ?? name;
            if (data.containsKey('photoUrl')) photoUrl = data['photoUrl'];
          }

          return ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(name),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 40.0, color: Colors.deepPurple),
              ) : null,
            ),
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
               Navigator.pop(context);
               Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
               Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () {
               Navigator.pop(context);
               Navigator.pushNamed(context, AppRoutes.help);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
               await ref.read(authServiceProvider).signOut();
               if (context.mounted) {
                 Navigator.pushReplacementNamed(context, AppRoutes.login);
               }
            },
          ),
        ],
      );
        }
      ),
    );
  }
}
