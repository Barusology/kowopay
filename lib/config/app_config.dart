import 'package:flutter/foundation.dart';

/// Compile-time configuration.
///
/// Values are injected with `--dart-define` (or `--dart-define-from-file`), so
/// no provider secret is ever committed. Anything that must stay truly secret
/// (AI keys, payment secret keys, webhook hashes) lives only in Cloud Functions
/// environment variables.
class AppConfig {
  AppConfig._();

  /// Flutterwave *public* key. Safe for client use, but still injected at build
  /// time so different environments can use different keys.
  static const String flutterwavePublicKey = String.fromEnvironment(
    'FLUTTERWAVE_PUBLIC_KEY',
  );

  static const String flutterwaveRedirectUrl = String.fromEnvironment(
    'FLUTTERWAVE_REDIRECT_URL',
    defaultValue: 'https://kowopay.web.app/payment-callback',
  );

  static const bool flutterwaveTestMode = bool.fromEnvironment(
    'FLUTTERWAVE_TEST_MODE',
    defaultValue: true,
  );

  static const String functionsRegion = String.fromEnvironment(
    'FUNCTIONS_REGION',
    defaultValue: 'us-central1',
  );

  static bool get paymentsConfigured => flutterwavePublicKey.isNotEmpty;

  static bool get isRelease => kReleaseMode;
}
