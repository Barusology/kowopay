import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode, debugPrint;
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
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // FIX: await MobileAds — prevents race condition where ads are requested
    // before the SDK has finished initialising.
    await MobileAds.instance.initialize();
  } catch (e, stackTrace) {
    // FIX: debugPrint instead of print (stripped in release, no logcat leak).
    debugPrint('[KowoPay] Initialization failed: $e');
    // In production, report to crash analytics before rethrowing:
    // if (!kDebugMode) FirebaseCrashlytics.instance.recordError(e, stackTrace);
    // FIX: rethrow — do NOT silently continue.  Every downstream Firebase call
    // (auth, database, storage) will fail anyway; surface the problem early.
    rethrow;
  }

  runApp(
    DevicePreview(
      // FIX: disabled in release builds and on web — DevicePreview is a
      // developer tool and must never ship to real users.
      enabled: !kReleaseMode && !kIsWeb,
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
      // FIX: removed useInheritedMediaQuery — deprecated and removed in
      // Flutter 3.4+; causes compile errors on current SDK.
      locale: DevicePreview.locale(context),
      debugShowCheckedModeBanner: false,
      title: 'KowoPay',
      theme: ThemeData(
        // FIX: ColorScheme.fromSeed is the Material 3-correct way to theme.
        // primarySwatch is deprecated when useMaterial3 is true.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
      // FIX: authState drives routing directly.
      // DelayedSplash (30-second timer) has been completely removed — it served
      // no purpose and forced every user to wait half a minute.
      // authState.when(loading:) already shows SplashScreen while Firebase
      // resolves the session, which is the correct pattern.
      home: authState.when(
        data: (user) => user != null ? const HomePage() : const LoginPage(),
        loading: () => const SplashScreen(),
        // FIX: Friendly error screen — no raw exception text shown to users.
        error: (_, __) => const _AuthErrorScreen(),
      ),
    );
  }
}

/// Shown when the auth stream itself errors (e.g. token refresh failure on
/// first launch).  Presents a safe, user-friendly message with a retry option.
class _AuthErrorScreen extends StatelessWidget {
  const _AuthErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'We couldn\'t connect to our services. '
                  'Please check your connection and restart the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Re-trigger by hot-restarting or using a retry mechanism.
                    // In production wire this to a retry notifier.
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
