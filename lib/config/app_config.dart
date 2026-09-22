class AppConfig {
  const AppConfig._();

  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const flutterwavePublicKey = String.fromEnvironment(
    'FLUTTERWAVE_PUBLIC_KEY',
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
