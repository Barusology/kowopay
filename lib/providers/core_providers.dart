import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../services/payment_service.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(
    publicKey: AppConfig.requireValue(
      'FLUTTERWAVE_PUBLIC_KEY',
      AppConfig.flutterwavePublicKey,
    ),
    redirectUrl: AppConfig.requireValue(
      'FLUTTERWAVE_REDIRECT_URL',
      AppConfig.flutterwaveRedirectUrl,
    ),
    isTestMode: AppConfig.flutterwaveTestMode,
  );
});

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
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
