import 'package:flutter_test/flutter_test.dart';
import 'package:kowopay/config/app_config.dart';
import 'package:kowopay/services/ai_service.dart';
import 'package:kowopay/services/payment_service.dart';

void main() {
  group('AppConfig', () {
    test('rejects missing runtime configuration', () {
      expect(
        () => AppConfig.requireValue('GEMINI_API_KEY', ''),
        throwsA(isA<StateError>()),
      );
    });

    test('returns configured values unchanged', () {
      expect(AppConfig.requireValue('EXAMPLE', 'configured'), 'configured');
    });
  });

  test('AIService rejects an absent API key', () {
    expect(() => AIService(apiKey: ''), throwsA(isA<StateError>()));
  });

  test('PaymentService rejects an absent public key', () {
    expect(() => PaymentService(publicKey: ''), throwsA(isA<StateError>()));
  });
}
