import 'package:flutter_test/flutter_test.dart';
import 'package:kowopay/services/database_service.dart';

void main() {
  test('builds an atomic debit with its audit transaction', () {
    final result = buildAtomicDebitTransaction(
      currentUser: {
        'balance': 100,
        'transactions': {
          'existing': {'amount': 5},
        },
      },
      amount: 25,
      title: 'Airtime',
      isCredit: false,
      transactionKey: 'new',
    );

    expect(result['balance'], 75);
    expect(
      (result['transactions'] as Map).keys,
      containsAll(['existing', 'new']),
    );
    expect((result['transactions'] as Map)['new']['title'], 'Airtime');
  });

  test('rejects a debit larger than the current balance', () {
    expect(
      () => buildAtomicDebitTransaction(
        currentUser: {'balance': 10},
        amount: 25,
        title: 'Airtime',
        isCredit: false,
        transactionKey: 'new',
      ),
      throwsA(isA<StateError>()),
    );
  });
}
