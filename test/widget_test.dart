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

  test('AIService does not accept client-side credentials', () {
    expect(AIService(), isA<AIService>());
  });

  test('PaymentService rejects incomplete configuration', () {
    expect(
      () => PaymentService(
        publicKey: '',
        redirectUrl: '',
        isTestMode: true,
      ),
      throwsA(isA<StateError>()),
    );
  });
}
