import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kowopay/services/ad_service.dart';
import 'package:kowopay/services/ai_service.dart';
import 'package:kowopay/services/database_service.dart';
import 'package:kowopay/services/payment_service.dart';
import 'package:kowopay/services/storage_service.dart';
import 'package:kowopay/services/wallet_service.dart';

// Provider keys are injected at build time (`--dart-define`) or held in Cloud
// Functions environment variables. No credentials live in source control.
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

final walletServiceProvider = Provider<WalletService>((ref) {
  return WalletService();
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final DatabaseService service = DatabaseService();
  ref.onDispose(service.dispose);
  return service;
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final adServiceProvider = Provider<AdService>((ref) {
  return AdService();
});
