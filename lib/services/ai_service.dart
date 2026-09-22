import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  final String apiKey;
  late final GenerativeModel _model;

  AIService({required this.apiKey}) {
    if (apiKey.trim().isEmpty) {
      throw StateError(
        'GEMINI_API_KEY is not configured. '
        'Provide it with --dart-define=GEMINI_API_KEY=...',
      );
    }
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  }

  Future<String> getFinancialAdvice(String userQuery) async {
    try {
      final content = [Content.text(userQuery)];
      final response = await _model.generateContent(content);
      return response.text ?? "I couldn't generate a response.";
    } catch (e) {
      throw StateError('Unable to generate financial advice: $e');
    }
  }
}
