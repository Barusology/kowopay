import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/payment_service.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';

// IMPORTANT: Replace with real keys from ENV or remote config
const String FLUTTERWAVE_PUBLIC_KEY = "FLWPUBK_TEST-XXXXXXXXXX-X"; 
const String GEMINI_API_KEY = "AIzaSyBog1Kcb5BmZN8f2WX0uNLjgK_DyGl7Xyg"; 

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(publicKey: FLUTTERWAVE_PUBLIC_KEY);
});



final aiServiceProvider = Provider<AIService>((ref) {
  return AIService(apiKey: GEMINI_API_KEY);
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final adServiceProvider = Provider<AdService>((ref) {
  return AdService();
});


