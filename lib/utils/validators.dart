/// Input validation and sanitisation for every form in the app.
///
/// Flutter does not render HTML, but values still reach Firebase, payment
/// providers and file paths, so they must be bounded and normalised before
/// use. Server-side Firebase Rules remain the final authority.
class InputSanitizer {
  InputSanitizer._();

  static final RegExp _controlChars = RegExp(r'[\u0000-\u001F\u007F]');

  /// Trims, collapses whitespace, strips control characters and caps length.
  static String cleanText(String? value, {int maxLength = 120}) {
    final String cleaned = (value ?? '')
        .replaceAll(_controlChars, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.length > maxLength
        ? cleaned.substring(0, maxLength)
        : cleaned;
  }

  /// Keeps digits and a single leading `+` only.
  static String cleanPhone(String? value) {
    final String raw = (value ?? '').replaceAll(RegExp(r'[^\d+]'), '');
    final String withoutPlus = raw.replaceAll('+', '');
    return withoutPlus.length > 15
        ? withoutPlus.substring(0, 15)
        : withoutPlus;
  }

  /// Currency amounts are normalised to a dot decimal separator and capped at
  /// two decimal places.
  static String cleanAmount(String? value) {
    final String raw = (value ?? '').replaceAll(',', '').trim();
    final double? parsed = double.tryParse(raw);
    if (parsed == null || !parsed.isFinite) return '';
    return parsed.toStringAsFixed(2);
  }
}

class Validators {
  Validators._();

  static final RegExp _email = RegExp(
    r'^[A-Za-z0-9.!#$%&’*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
  );
  static final RegExp _name = RegExp(r"^[A-Za-z][A-Za-z .'-]{1,79}$");
  static final RegExp _digits = RegExp(r'^\d+$');
  static final RegExp _uid = RegExp(r'^[A-Za-z0-9_-]{6,128}$');

  static bool isEmail(String value) =>
      value.length <= 254 && _email.hasMatch(value.trim());

  static String? email(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return 'Please enter your email';
    if (!isEmail(v)) return 'Please enter a valid email address';
    return null;
  }

  static String? password(String? value, {bool enforceStrength = true}) {
    final String v = value ?? '';
    if (v.isEmpty) return 'Please enter a password';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (v.length > 128) return 'Password is too long';
    if (!enforceStrength) return null;
    if (!v.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!v.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!v.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? fullName(String? value) {
    final String v = InputSanitizer.cleanText(value, maxLength: 80);
    if (v.isEmpty) return 'Please enter your full name';
    if (v.length < 2) return 'Name is too short';
    if (!_name.hasMatch(v)) {
      return 'Use letters, spaces, apostrophes or hyphens only';
    }
    return null;
  }

  static String? phone(String? value, {bool required = false}) {
    final String v = InputSanitizer.cleanPhone(value);
    if (v.isEmpty) return required ? 'Please enter your phone number' : null;
    if (v.length < 10 || v.length > 15) {
      return 'Please enter a valid phone number';
    }
    if (!_digits.hasMatch(v)) return 'Phone number must contain digits only';
    return null;
  }

  static String? accountNumber(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return 'Please enter your account number';
    if (v.length != 10 || !_digits.hasMatch(v)) {
      return 'Account number must be exactly 10 digits';
    }
    return null;
  }

  /// Amounts are parsed as decimal numbers with a minimum and a ceiling.
  static String? amount(
    String? value, {
    double min = 100,
    double max = 10000000,
  }) {
    final String v = (value ?? '').replaceAll(',', '').trim();
    if (v.isEmpty) return 'Please enter an amount';
    final double? parsed = double.tryParse(v);
    if (parsed == null || !parsed.isFinite || parsed <= 0) {
      return 'Please enter a valid amount';
    }
    if (parsed < min) {
      return 'Minimum amount is ₦${min.toStringAsFixed(0)}';
    }
    if (parsed > max) {
      return 'Maximum amount is ₦${max.toStringAsFixed(0)}';
    }
    if (RegExp(r'\.\d{3,}$').hasMatch(v)) {
      return 'Use at most two decimal places';
    }
    return null;
  }

  static bool isSafeUid(String uid) => _uid.hasMatch(uid);

  static bool isSafeImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return false;
    }
    const List<String> allowedHosts = [
      'firebasestorage.googleapis.com',
      'kowopay.firebasestorage.app',
      'storage.googleapis.com',
    ];
    final bool hostAllowed = allowedHosts.contains(uri.host) ||
        uri.host.endsWith('.googleusercontent.com');
    return hostAllowed && url.length <= 2048;
  }

  /// Only external schemes that cannot execute content are allowed.
  static bool isSafeExternalUri(String value) {
    final Uri? uri = Uri.tryParse(value);
    if (uri == null) return false;
    const Set<String> allowed = {'https', 'http', 'mailto', 'tel'};
    return allowed.contains(uri.scheme.toLowerCase());
  }
}
