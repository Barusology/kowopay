import 'dart:typed_data';

/// Client-side abuse controls.
///
/// These are UX guards, not a security boundary — the authoritative limits live
/// in Firebase Rules and Cloud Functions. They stop double-taps and casual
/// spam from burning payment/AI quota.
class RateLimiter {
  RateLimiter._();

  static final Map<String, DateTime> _lastAction = <String, DateTime>{};
  static final Map<String, _AttemptWindow> _attempts =
      <String, _AttemptWindow>{};

  /// Returns true when [action] has not run within [minInterval].
  static bool allow(String action, Duration minInterval) {
    final DateTime now = DateTime.now();
    final DateTime? last = _lastAction[action];
    if (last != null && now.difference(last) < minInterval) {
      return false;
    }
    _lastAction[action] = now;
    return true;
  }

  static Duration remaining(String action, Duration minInterval) {
    final DateTime? last = _lastAction[action];
    if (last == null) return Duration.zero;
    final Duration elapsed = DateTime.now().difference(last);
    return elapsed >= minInterval ? Duration.zero : minInterval - elapsed;
  }

  /// Tracks failed authentication attempts and locks the action after
  /// [maxAttempts] failures for [lockout].
  static bool isLocked(String key) {
    final _AttemptWindow? window = _attempts[key];
    if (window == null) return false;
    if (window.lockedUntil == null) return false;
    if (DateTime.now().isAfter(window.lockedUntil!)) {
      _attempts.remove(key);
      return false;
    }
    return true;
  }

  static void recordFailure(
    String key, {
    int maxAttempts = 5,
    Duration lockout = const Duration(minutes: 2),
  }) {
    final _AttemptWindow window =
        _attempts.putIfAbsent(key, () => _AttemptWindow());
    window.failures += 1;
    if (window.failures >= maxAttempts) {
      window.lockedUntil = DateTime.now().add(lockout);
      window.failures = 0;
    }
  }

  static void recordSuccess(String key) => _attempts.remove(key);
}

class _AttemptWindow {
  int failures = 0;
  DateTime? lockedUntil;
}

/// Verifies uploaded bytes really are the image type we claim they are.
///
/// Trusting a filename or the picker's MIME hint is not enough; the Storage
/// Rules also re-check `contentType` and size on the server.
class ImageFileValidator {
  ImageFileValidator._();

  static const int maxBytes = 5 * 1024 * 1024;

  static String? validate(Uint8List bytes) {
    if (bytes.isEmpty) return 'The selected image is empty.';
    if (bytes.length > maxBytes) return 'Image must be smaller than 5 MB.';
    if (_isJpeg(bytes)) return null;
    if (_isPng(bytes)) return null;
    if (_isWebp(bytes)) return null;
    return 'Only JPEG, PNG or WebP images are allowed.';
  }

  static String contentTypeOf(Uint8List bytes) {
    if (_isPng(bytes)) return 'image/png';
    if (_isWebp(bytes)) return 'image/webp';
    return 'image/jpeg';
  }

  static bool _isJpeg(Uint8List b) =>
      b.length > 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF;

  static bool _isPng(Uint8List b) =>
      b.length > 8 &&
      b[0] == 0x89 &&
      b[1] == 0x50 &&
      b[2] == 0x4E &&
      b[3] == 0x47 &&
      b[4] == 0x0D &&
      b[5] == 0x0A &&
      b[6] == 0x1A &&
      b[7] == 0x0A;

  static bool _isWebp(Uint8List b) {
    if (b.length < 12) return false;
    final bool riff = b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46;
    final bool webp = b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50;
    return riff && webp;
  }
}
