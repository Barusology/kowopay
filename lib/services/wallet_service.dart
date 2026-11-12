import 'package:cloud_functions/cloud_functions.dart';
import 'package:kowopay/config/app_config.dart';
import 'package:kowopay/utils/secure_logger.dart';

class WalletException implements Exception {
  WalletException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// All balance-changing operations go through Cloud Functions.
///
/// The user identity is taken from the verified ID token on the server, never
/// from a client-supplied uid, and the functions perform the debit + ledger
/// write in a single transaction.
class WalletService {
  WalletService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);

  final FirebaseFunctions _functions;

  Future<void> purchaseAirtime({
    required double amount,
    required String carrier,
    required String phone,
  }) async {
    await _call(
      'purchaseAirtime',
      <String, dynamic>{
        'amount': amount,
        'carrier': carrier,
        'phone': phone,
      },
    );
  }

  Future<void> requestWithdrawal({
    required double amount,
    required String bankCode,
    required String accountNumber,
  }) async {
    await _call(
      'requestWithdrawal',
      <String, dynamic>{
        'amount': amount,
        'bankCode': bankCode,
        'accountNumber': accountNumber,
      },
    );
  }

  Future<void> _call(String name, Map<String, dynamic> payload) async {
    try {
      final HttpsCallableResult<dynamic> result = await _functions
          .httpsCallable(name)
          .call<dynamic>(payload);
      final Object? data = result.data;
      if (data is Map && data['ok'] == false) {
        throw WalletException(
          (data['message'] as String?) ?? 'The request could not be completed.',
        );
      }
    } on FirebaseFunctionsException catch (e) {
      SecureLog.error('Wallet callable $name', e);
      switch (e.code) {
        case 'failed-precondition':
          throw WalletException(
            (e.message ?? '').isEmpty
                ? 'Your account is not ready for this action.'
                : e.message!,
          );
        case 'permission-denied':
          throw WalletException('Verify your email address to continue.');
        case 'unauthenticated':
          throw WalletException('Please sign in again.');
        case 'resource-exhausted':
          throw WalletException('Too many attempts. Please wait and try again.');
        case 'invalid-argument':
          throw WalletException('Please check the details you entered.');
        default:
          throw WalletException('Service unavailable. Please try again later.');
      }
    }
  }
}
