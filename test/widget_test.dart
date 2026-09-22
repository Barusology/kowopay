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

  test('PaymentService fails closed without a backend', () {
    expect(
      () => PaymentService().makePayment(
        context: Object(),
        email: 'user@example.com',
        fullName: 'Test User',
        phoneNumber: '08000000000',
        amount: '100',
        txRef: 'test-ref',
        onResult: (_) {},
      ),
      throwsA(isA<UnsupportedError>()),
    );
  });
}
