import 'package:device_preview/device_preview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kowopay/firebase_options.dart';
import 'package:kowopay/providers/auth_provider.dart';
import 'package:kowopay/routes.dart';
import 'package:kowopay/screens/admin_screen.dart';
import 'package:kowopay/screens/airtime_screen.dart';
import 'package:kowopay/screens/ai_chat_screen.dart';
import 'package:kowopay/screens/bill_pay_screen.dart';
import 'package:kowopay/screens/deposit_screen.dart';
import 'package:kowopay/screens/help_support_screen.dart';
import 'package:kowopay/screens/home_page.dart';
import 'package:kowopay/screens/insurance_screen.dart';
import 'package:kowopay/screens/login_page.dart';
import 'package:kowopay/screens/onboarding_screen.dart';
import 'package:kowopay/screens/profile_screen.dart';
import 'package:kowopay/screens/register_page.dart';
import 'package:kowopay/screens/settings_screen.dart';
import 'package:kowopay/screens/splash_screen.dart';
import 'package:kowopay/screens/verify_email_screen.dart';
import 'package:kowopay/screens/withdraw_screen.dart';
import 'package:kowopay/theme/app_theme.dart';
import 'package:kowopay/widgets/cinematic_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Web session tokens die with the browser tab; mobile already stores tokens
  // in Android Keystore / iOS Keychain.
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.SESSION);
  }

  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

  Widget app = const ProviderScope(child: KowoPayApp());
  if (!kReleaseMode && !kIsWeb) {
    // DevicePreview is a developer-only tool and never ships in release builds.
    app = DevicePreview(enabled: true, builder: (_) => app);
  }
  runApp(app);
}

class KowoPayApp extends ConsumerStatefulWidget {
  const KowoPayApp({super.key});

  @override
  ConsumerState<KowoPayApp> createState() => _KowoPayAppState();
}

class _KowoPayAppState extends ConsumerState<KowoPayApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Detects revoked/disabled accounts and expired sessions before the user
      // can start a financial action.
      ref.read(authServiceProvider).refreshToken().catchError((Object _) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<User?> authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'KowoPay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      routes: <String, WidgetBuilder>{
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
        AppRoutes.verifyEmail: (_) => const VerifyEmailScreen(),
        AppRoutes.admin: (_) => const AdminScreen(),
      },
      home: authState.when(
        data: (User? user) {
          if (user == null) return const LoginPage();
          if (!user.emailVerified) return const VerifyEmailScreen();
          return const HomePage();
        },
        loading: () => const SplashScreen(),
        error: (_, __) => const _AuthErrorScreen(),
      ),
    );
  }
}

class _AuthErrorScreen extends ConsumerWidget {
  const _AuthErrorScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CinematicBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 64, color: AppColors.purple),
                  const SizedBox(height: 20),
                  const Text(
                    'Something went wrong',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'We could not verify your session. Check your connection '
                    'and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(authStateProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
