class AIService {
  AIService();

  Future<String> getFinancialAdvice(String userQuery) async {
    throw UnsupportedError(
      'Financial advice requires the authenticated server-side AI endpoint.',
    );
  }
}
