import 'package:flutter/foundation.dart';

/// Release-safe logging.
///
/// `print` is not stripped by the Dart compiler in release mode, so anything
/// logged can end up in logcat/console. These helpers emit only in debug and
/// never accept tokens, passwords, full emails or account numbers.
class SecureLog {
  SecureLog._();

  static void debug(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  static void warn(String message) {
    if (kDebugMode) {
      debugPrint('WARN: $message');
    }
  }

  static void error(String context, Object error) {
    if (kDebugMode) {
      // Never interpolate user data here; callers pass a safe context string.
      debugPrint('ERROR [$context]: ${error.runtimeType}');
    }
  }
}
