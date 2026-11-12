import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kowopay/theme/app_theme.dart';
import 'package:kowopay/utils/rate_limiter.dart';
import 'package:kowopay/utils/validators.dart';
import 'package:kowopay/widgets/circular_nav_bar.dart';

void main() {
  group('Validators', () {
    test('email accepts valid addresses and rejects malformed ones', () {
      expect(Validators.isEmail('user@kowopay.com'), isTrue);
      expect(Validators.isEmail('user@kowopay'), isFalse);
      expect(Validators.isEmail('not-an-email'), isFalse);
      expect(Validators.email(''), isNotNull);
    });

    test('password enforces length and character classes', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('alllowercase1'), isNotNull);
      expect(Validators.password('NoDigitsHere!'), isNotNull);
      expect(Validators.password('GoodPass1'), isNull);
    });

    test('phone accepts 10-15 digits only', () {
      expect(Validators.phone('08012345678'), isNull);
      expect(Validators.phone('12345'), isNotNull);
      expect(Validators.phone('abc1234567'), isNotNull);
    });

    test('amount respects bounds and decimal precision', () {
      expect(Validators.amount('500'), isNull);
      expect(Validators.amount('50'), isNotNull);
      expect(Validators.amount('abc'), isNotNull);
      expect(Validators.amount('10.999'), isNotNull);
    });

    test('UID and image URL guards reject unsafe values', () {
      expect(Validators.isSafeUid('abc123DEF456'), isTrue);
      expect(Validators.isSafeUid('../users'), isFalse);
      expect(
        Validators.isSafeImageUrl(
          'https://firebasestorage.googleapis.com/v0/b/kowopay.appspot.com/o/a.jpg',
        ),
        isTrue,
      );
      expect(Validators.isSafeImageUrl('javascript:alert(1)'), isFalse);
      expect(Validators.isSafeImageUrl('http://evil.example.com/a.png'), isFalse);
    });

    test('external URI allowlist blocks script schemes', () {
      expect(Validators.isSafeExternalUri('mailto:support@kowopay.com'), isTrue);
      expect(Validators.isSafeExternalUri('javascript:alert(1)'), isFalse);
    });
  });

  group('InputSanitizer', () {
    test('strips control characters and collapses whitespace', () {
      expect(InputSanitizer.cleanText('  Ada\u0000  Lovelace  '), 'Ada Lovelace');
    });

    test('caps text length', () {
      expect(InputSanitizer.cleanText('a' * 200, maxLength: 10).length, 10);
    });

    test('normalises phone and amount', () {
      expect(InputSanitizer.cleanPhone('+234 801-234-5678'), '2348012345678');
      expect(InputSanitizer.cleanAmount('1,250.5'), '1250.50');
      expect(InputSanitizer.cleanAmount('NaN'), '');
    });
  });

  group('ImageFileValidator', () {
    test('accepts JPEG magic bytes', () {
      final Uint8List jpeg = Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xE0]);
      expect(ImageFileValidator.validate(jpeg), isNull);
      expect(ImageFileValidator.contentTypeOf(jpeg), 'image/jpeg');
    });

    test('rejects non-image bytes', () {
      final Uint8List text = Uint8List.fromList('<script>'.codeUnits);
      expect(ImageFileValidator.validate(text), isNotNull);
    });
  });

  group('RateLimiter', () {
    test('locks after repeated failures and unlocks on success', () {
      const String key = 'test-login';
      for (int i = 0; i < 5; i++) {
        RateLimiter.recordFailure(key);
      }
      expect(RateLimiter.isLocked(key), isTrue);
      RateLimiter.recordSuccess(key);
      expect(RateLimiter.isLocked(key), isFalse);
    });
  });

  group('CircularNavBar', () {
    testWidgets('renders labels and reports taps', (WidgetTester tester) async {
      int tapped = -1;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: CircularNavBar(
              currentIndex: 0,
              onTap: (int index) => tapped = index,
              items: const <NavItem>[
                NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                ),
                NavItem(
                  icon: Icons.notifications_none,
                  activeIcon: Icons.notifications,
                  label: 'Notifications',
                  badgeCount: 2,
                ),
                NavItem(
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet,
                  label: 'Loans',
                ),
                NavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  label: 'Transactions',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);

      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();

      expect(tapped, 1);
    });
  });
}
