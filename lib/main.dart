import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kowopay/routes.dart';
import 'package:kowopay/providers/auth_provider.dart';

import 'package:kowopay/screens/home_page.dart';
import 'package:kowopay/screens/login_page.dart';
import 'package:kowopay/screens/register_page.dart';
import 'package:kowopay/screens/splash_screen.dart';
import 'package:kowopay/screens/onboarding_screen.dart';
import 'package:kowopay/screens/deposit_screen.dart';
import 'package:kowopay/screens/withdraw_screen.dart';
import 'package:kowopay/screens/ai_chat_screen.dart';
import 'package:kowopay/screens/airtime_screen.dart';
import 'package:kowopay/screens/bill_pay_screen.dart';
import 'package:kowopay/screens/profile_screen.dart';
import 'package:kowopay/screens/settings_screen.dart';
import 'package:kowopay/screens/help_support_screen.dart';
import 'package:kowopay/screens/insurance_screen.dart';

import 'firebase_options.dart';

import 'package:kowopay/providers/core_providers.dart';
import 'package:device_preview/device_preview.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase with platform-specific options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Initialize Ads (fire and forget)
    MobileAds.instance.initialize();
  } catch (e) {
    print("Initialization Failed: $e");
    // We continue to run the app so the user sees something (likely Mock mode fallback)
  }

  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const ProviderScope(child: MyApp()),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      useInheritedMediaQuery: true, // Required for DevicePreview
      locale: DevicePreview.locale(context), // Required for DevicePreview
      debugShowCheckedModeBanner: false,
      title: 'KowoPay',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      builder: DevicePreview.appBuilder,
      routes: {
        // AppRoutes.splash is removed from here because it uses '/' which conflicts with home
        AppRoutes.onboarding: (_) => const OnboardingScreen(),
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.register: (_) => const RegisterPage(),
        AppRoutes.home: (_) => const HomePage(),
        AppRoutes.deposit: (_) => const DepositScreen(),
        AppRoutes.withdraw: (_) => const WithdrawScreen(),
        AppRoutes.aiChat: (_) => const AIChatScreen(),
        AppRoutes.airtime: (_) => const AirtimeScreen(),
        AppRoutes.billPay: (_) => const BillPayScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
        AppRoutes.settings: (_) => const SettingsScreen(),
        AppRoutes.help: (_) => const HelpSupportScreen(),
        AppRoutes.insurance: (_) => const InsuranceScreen(),
      },
      home: DelayedSplash(
        child: authState.when(
          data: (user) {
            if (user != null) {
              return const HomePage();
            } else {
              return const LoginPage(); 
            }
          },
          loading: () => const SplashScreen(),
          error: (e, stack) => Scaffold(body: Center(child: Text('Error: $e'))),
        ),
      ),
    );
  }
}

class DelayedSplash extends StatefulWidget {
  final Widget child;
  const DelayedSplash({super.key, required this.child});

  @override
  State<DelayedSplash> createState() => _DelayedSplashState();
}

class _DelayedSplashState extends State<DelayedSplash> {
  bool _showChild = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          _showChild = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showChild) return widget.child;
    return const SplashScreen();
  }
}
