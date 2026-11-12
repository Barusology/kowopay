import 'package:cloud_functions/cloud_functions.dart';
import 'package:kowopay/config/app_config.dart';
import 'package:kowopay/utils/secure_logger.dart';

class AiException implements Exception {
  AiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// AI requests are proxied through a Cloud Function.
///
/// The Gemini key lives only in the function environment; it is never shipped
/// inside the Flutter binary where anyone can extract it.
class AIService {
  AIService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);

  final FirebaseFunctions _functions;

  static const int maxInputLength = 500;

  Future<String> getFinancialAdvice(String userQuery) async {
    final String query = userQuery.trim();
    if (query.isEmpty) return 'Please type a question.';
    if (query.length > maxInputLength) {
      throw AiException('Message is too long (max $maxInputLength characters).');
    }

    try {
      final HttpsCallable callable = _functions.httpsCallable(
        'aiAdvice',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      final HttpsCallableResult<dynamic> result =
          await callable.call(<String, dynamic>{'query': query});
      final Object? data = result.data;
      if (data is Map && data['answer'] is String) {
        return data['answer'] as String;
      }
      return 'I could not generate a response right now.';
    } on FirebaseFunctionsException catch (e) {
      SecureLog.error('AI callable', e);
      switch (e.code) {
        case 'resource-exhausted':
          throw AiException('You are sending messages too quickly. Please wait a moment.');
        case 'unauthenticated':
          throw AiException('Please sign in again to use the assistant.');
        case 'permission-denied':
          throw AiException('Verify your email address to use the assistant.');
        case 'failed-precondition':
          throw AiException('The assistant is not configured yet.');
        default:
          throw AiException('The assistant is unavailable. Please try again.');
      }
    }
  }
}
