import 'dart:math' as math;

import 'package:intl/intl.dart';

class Money {
  Money._(this.currencyCode, this.minorUnits);

  static const int maxSafeInteger = 9007199254740991;

  static const Set<String> iso4217Codes = {
    'AED',
    'AFN',
    'ALL',
    'AMD',
    'AOA',
    'ARS',
    'AUD',
    'AWG',
    'AZN',
    'BAM',
    'BBD',
    'BDT',
    'BHD',
    'BIF',
    'BMD',
    'BND',
    'BOB',
    'BOV',
    'BRL',
    'BSD',
    'BTN',
    'BWP',
    'BYN',
    'BZD',
    'CAD',
    'CDF',
    'CHE',
    'CHF',
    'CHW',
    'CLF',
    'CLP',
    'CNY',
    'COP',
    'COU',
    'CRC',
    'CUP',
    'CVE',
    'CZK',
    'DJF',
    'DKK',
    'DOP',
    'DZD',
    'EGP',
    'ERN',
    'ETB',
    'EUR',
    'FJD',
    'FKP',
    'GBP',
    'GEL',
    'GHS',
    'GIP',
    'GMD',
    'GNF',
    'GTQ',
    'GYD',
    'HKD',
    'HNL',
    'HTG',
    'HUF',
    'IDR',
    'ILS',
    'INR',
    'IQD',
    'IRR',
    'ISK',
    'JMD',
    'JOD',
    'JPY',
    'KES',
    'KGS',
    'KHR',
    'KMF',
    'KPW',
    'KRW',
    'KWD',
    'KYD',
    'KZT',
    'LAK',
    'LBP',
    'LKR',
    'LRD',
    'LSL',
    'LYD',
    'MAD',
    'MDL',
    'MGA',
    'MKD',
    'MMK',
    'MNT',
    'MOP',
    'MRU',
    'MUR',
    'MVR',
    'MWK',
    'MXN',
    'MXV',
    'MYR',
    'MZN',
    'NAD',
    'NGN',
    'NIO',
    'NOK',
    'NPR',
    'NZD',
    'OMR',
    'PAB',
    'PEN',
    'PGK',
    'PHP',
    'PKR',
    'PLN',
    'PYG',
    'QAR',
    'RON',
    'RSD',
    'RUB',
    'RWF',
    'SAR',
    'SBD',
    'SCR',
    'SDG',
    'SEK',
    'SGD',
    'SHP',
    'SLE',
    'SOS',
    'SRD',
    'SSP',
    'STN',
    'SVC',
    'SYP',
    'SZL',
    'THB',
    'TJS',
    'TMT',
    'TND',
    'TOP',
    'TRY',
    'TTD',
    'TWD',
    'TZS',
    'UAH',
    'UGX',
    'USD',
    'USN',
    'UYI',
    'UYU',
    'UYW',
    'UZS',
    'VED',
    'VES',
    'VND',
    'VUV',
    'WST',
    'XAD',
    'XAF',
    'XCD',
    'XCG',
    'XOF',
    'XPF',
    'YER',
    'ZAR',
    'ZMW',
    'ZWG',
  };

  static const Map<String, int> _fractionDigits = {
    'BIF': 0,
    'CLF': 4,
    'CLP': 0,
    'DJF': 0,
    'GNF': 0,
    'ISK': 0,
    'JPY': 0,
    'KMF': 0,
    'KRW': 0,
    'PYG': 0,
    'RWF': 0,
    'UGX': 0,
    'UYW': 4,
    'VND': 0,
    'VUV': 0,
    'UYI': 0,
    'XAF': 0,
    'XOF': 0,
    'XPF': 0,
    'BHD': 3,
    'IQD': 3,
    'JOD': 3,
    'KWD': 3,
    'LYD': 3,
    'OMR': 3,
    'TND': 3,
  };

  final String currencyCode;
  final int minorUnits;

  static int fractionDigitsFor(String currencyCode) {
    final code = currencyCode.toUpperCase();
    if (!iso4217Codes.contains(code) || code == 'XXX') {
      throw ArgumentError.value(
        currencyCode,
        'currencyCode',
        'Unknown ISO 4217 currency code',
      );
    }
    return _fractionDigits[code] ?? 2;
  }

  factory Money.fromMinorUnits({
    required String currencyCode,
    required int minorUnits,
  }) {
    final normalizedCode = currencyCode.toUpperCase();
    fractionDigitsFor(normalizedCode);
    if (minorUnits.abs() > maxSafeInteger) {
      throw RangeError.value(
        minorUnits,
        'minorUnits',
        'Amount exceeds safe integer range',
      );
    }
    return Money._(normalizedCode, minorUnits);
  }

  factory Money.zero(String currencyCode) =>
      Money.fromMinorUnits(currencyCode: currencyCode, minorUnits: 0);

  factory Money.fromMajor({
    required String currencyCode,
    required String amount,
  }) {
    final normalizedCode = currencyCode.toUpperCase();
    final digits = fractionDigitsFor(normalizedCode);
    final value = amount.trim();
    final match = RegExp(r'^(-?)(\d+)(?:\.(\d+))?$').firstMatch(value);
    if (match == null) {
      throw FormatException('Amount must be a plain decimal number.', amount);
    }

    final fraction = match.group(3) ?? '';
    if (fraction.length > digits) {
      throw FormatException(
        '$normalizedCode supports at most $digits fractional digits.',
        amount,
      );
    }

    final factor = math.pow(10, digits).toInt();
    final whole = int.tryParse(match.group(2)!);
    if (whole == null || whole > maxSafeInteger ~/ factor) {
      throw FormatException('Amount exceeds safe integer range.', amount);
    }
    final fractionalUnits = fraction.isEmpty
        ? 0
        : int.parse(fraction.padRight(digits, '0'));
    final absoluteMinorUnits = whole * factor + fractionalUnits;
    if (absoluteMinorUnits > maxSafeInteger) {
      throw FormatException('Amount exceeds safe integer range.', amount);
    }
    return Money._(
      normalizedCode,
      match.group(1) == '-' ? -absoluteMinorUnits : absoluteMinorUnits,
    );
  }

  String format({String locale = 'en'}) {
    final fractionDigits = fractionDigitsFor(currencyCode);
    final factor = math.pow(10, fractionDigits).toInt();
    final absolute = minorUnits.abs();
    final whole = NumberFormat.decimalPattern(
      locale,
    ).format(absolute ~/ factor);
    final sign = minorUnits < 0 ? '-' : '';
    if (fractionDigits == 0) return '$currencyCode $sign$whole';
    final fraction = (absolute % factor).toString().padLeft(
      fractionDigits,
      '0',
    );
    final separator = NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP;
    return '$currencyCode $sign$whole$separator$fraction';
  }

  Map<String, Object> toJson() => {
    'currencyCode': currencyCode,
    'amountMinor': minorUnits,
  };

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.currencyCode == currencyCode &&
      other.minorUnits == minorUnits;

  @override
  int get hashCode => Object.hash(currencyCode, minorUnits);
}
