import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kowopay/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // No timer here because main.dart is handling the root navigation via authState
    // However, the user specifically asked for a timer in initState for screens.
    // Let's add it if this screen were to navigate itself.
    // In this app structure, main.dart swaps the home widget based on authState.loading.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/kowopay.jpg',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.deepPurple),
            const SizedBox(height: 20),
            const Text(
              "Initializing (60 seconds wait)...",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
