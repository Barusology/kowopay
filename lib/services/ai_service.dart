import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  final String apiKey;
  late final GenerativeModel _model;

  AIService({required this.apiKey}) {
    print("Initializing AIService with model: gemini-1.5-flash");
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  }

  Future<String> getFinancialAdvice(String userQuery) async {
    try {
      final content = [Content.text(userQuery)];
      final response = await _model.generateContent(content);
      return response.text ?? "I couldn't generate a response.";
    } catch (e) {
      print("Gemini Error: $e");
      return "Error: $e";
    }
  }
}
