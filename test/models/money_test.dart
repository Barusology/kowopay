import 'package:flutter_test/flutter_test.dart';
import 'package:kowopay/models/money.dart';

void main() {
  group('Money', () {
    test('parses amounts into exact minor units', () {
      expect(
        Money.fromMajor(currencyCode: 'NGN', amount: '1234.56'),
        Money.fromMinorUnits(currencyCode: 'NGN', minorUnits: 123456),
      );
      expect(
        Money.fromMajor(currencyCode: 'JPY', amount: '1234'),
        Money.fromMinorUnits(currencyCode: 'JPY', minorUnits: 1234),
      );
      expect(
        Money.fromMajor(currencyCode: 'KWD', amount: '12.345'),
        Money.fromMinorUnits(currencyCode: 'KWD', minorUnits: 12345),
      );
      expect(
        Money.fromMajor(currencyCode: 'CLF', amount: '1.2345'),
        Money.fromMinorUnits(currencyCode: 'CLF', minorUnits: 12345),
      );
    });

    test(
      'normalizes ISO currency codes and formats with an unambiguous code',
      () {
        final money = Money.fromMajor(currencyCode: 'usd', amount: '1234.50');

        expect(money.currencyCode, 'USD');
        expect(money.format(), 'USD 1,234.50');
        expect(
          Money.fromMinorUnits(currencyCode: 'JPY', minorUnits: 1234).format(),
          'JPY 1,234',
        );
      },
    );

    test('serializes ledger values as an ISO code and integer minor units', () {
      expect(Money.fromMajor(currencyCode: 'NGN', amount: '1.01').toJson(), {
        'currencyCode': 'NGN',
        'amountMinor': 101,
      });
    });

    test('uses the current ISO currency list and fractional precision', () {
      expect(Money.fractionDigitsFor('UYI'), 0);
      expect(Money.fractionDigitsFor('UYW'), 4);
      expect(Money.fractionDigitsFor('ZWG'), 2);
      expect(Money.fractionDigitsFor('XAD'), 2);
      expect(Money.iso4217Codes, isNot(contains('ANG')));
      expect(Money.iso4217Codes, isNot(contains('BGN')));
      expect(Money.iso4217Codes, isNot(contains('XAG')));
      expect(Money.iso4217Codes, isNot(contains('XXX')));
    });

    test(
      'rejects invalid currency codes, unsupported precision, and unsafe values',
      () {
        expect(
          () => Money.fromMajor(currencyCode: 'ZZZ', amount: '1.00'),
          throwsArgumentError,
        );
        expect(
          () => Money.fromMajor(currencyCode: 'XXX', amount: '1.00'),
          throwsArgumentError,
        );
        expect(
          () => Money.fromMajor(currencyCode: 'JPY', amount: '1.01'),
          throwsFormatException,
        );
        expect(
          () => Money.fromMajor(currencyCode: 'NGN', amount: '1.001'),
          throwsFormatException,
        );
        expect(
          () => Money.fromMajor(currencyCode: 'USD', amount: '1e4'),
          throwsFormatException,
        );
        expect(
          () => Money.fromMinorUnits(
            currencyCode: 'USD',
            minorUnits: Money.maxSafeInteger + 1,
          ),
          throwsRangeError,
        );
      },
    );
  });
}
