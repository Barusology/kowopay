class AppConfig {
  const AppConfig._();

  static const flutterwavePublicKey = String.fromEnvironment(
    'FLUTTERWAVE_PUBLIC_KEY',
  );
  static const flutterwaveRedirectUrl = String.fromEnvironment(
    'FLUTTERWAVE_REDIRECT_URL',
  );
  static const flutterwaveTestMode = bool.fromEnvironment(
    'FLUTTERWAVE_TEST_MODE',
    defaultValue: true,
  );

  static String requireValue(String name, String value) {
    if (value.trim().isEmpty) {
      throw StateError(
        '$name is not configured. Provide it with --dart-define=$name=...',
      );
    }
    return value;
  }
}
