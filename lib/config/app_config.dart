class AppConfig {
  const AppConfig._();

  static String requireValue(String name, String value) {
    if (value.trim().isEmpty) {
      throw StateError(
        '$name is not configured. Provide it with --dart-define=$name=...',
      );
    }
    return value;
  }
}
