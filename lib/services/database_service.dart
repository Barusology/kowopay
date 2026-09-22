import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Create or Update User Profile
  Future<void> saveUser({
    required String uid,
    required String email,
    required String name,
  }) async {
    try {
      await _db.ref('users/$uid').set({
        'name': name,
        'email': email,
        'balance': 0.0, // Initial balance
        'createdAt': ServerValue.timestamp,
      });
    } catch (e) {
      print("Error saving user: $e");
      rethrow;
    }
  }

  // Get User Stream
  Stream<DatabaseEvent> getUserStream(String uid) {
    return _db.ref('users/$uid').onValue;
  }

  Future<Map<String, dynamic>?> getUserOnce(String uid) async {
    final snapshot = await _db.ref('users/$uid').get();
    final value = snapshot.value;
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  Future<double> getBalance(String uid) async {
    final snapshot = await _db.ref('users/$uid/balance').get();
    final value = snapshot.value;
    return value is num ? value.toDouble() : 0;
  }

  // Update Balance (e.g. after deposit)
  Future<void> updateBalance(String uid, double newBalance) async {
    await _db.ref('users/$uid/balance').set(newBalance);
  }

  // Deduct Balance
  Future<bool> deductBalance(String uid, double amount) async {
    final ref = _db.ref('users/$uid/balance');
    final snapshot = await ref.get();
    if (snapshot.exists) {
      double currentBalance = (snapshot.value as num).toDouble();
      if (currentBalance >= amount) {
        await ref.set(currentBalance - amount);
        return true;
      }
    }
    return false;
  }

  Future<bool> deductBalanceAndLog({
    required String uid,
    required double amount,
    required String title,
    required bool isCredit,
  }) async {
    final userRef = _db.ref('users/$uid');
    final result = await userRef.runTransaction((currentData) {
      final userData = currentData is Map
          ? Map<String, dynamic>.from(currentData)
          : <String, dynamic>{};
      final currentBalance = userData['balance'] is num
          ? (userData['balance'] as num).toDouble()
          : 0.0;
      if (currentBalance < amount) return Transaction.abort();
      final transactions = userData['transactions'] is Map
          ? Map<String, dynamic>.from(userData['transactions'])
          : <String, dynamic>{};
      final transactionKey = userRef.child('transactions').push().key;
      if (transactionKey == null) return Transaction.abort();
      transactions[transactionKey] = {
        'title': title,
        'amount': amount,
        'isCredit': isCredit,
        'date': DateTime.now().toIso8601String(),
        'timestamp': ServerValue.timestamp,
      };
      userData['balance'] = currentBalance - amount;
      userData['transactions'] = transactions;
      return Transaction.success(userData);
    });
    if (!result.committed) return false;
    return true;
  }

  // Add Transaction
  Future<void> addTransaction({
    required String uid,
    required String title,
    required double amount,
    required bool isCredit,
  }) async {
    await _db.ref('users/$uid/transactions').push().set({
      'title': title,
      'amount': amount,
      'isCredit': isCredit,
      'date': DateTime.now().toIso8601String(),
      'timestamp': ServerValue.timestamp,
    });
  }

  // Get Transactions Stream
  Stream<DatabaseEvent> getTransactionsStream(String uid) {
    return _db
        .ref('users/$uid/transactions')
        .orderByChild('timestamp')
        .limitToLast(20)
        .onValue;
  }

  // Update Profile
  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
    String? photoUrl,
  }) async {
    final Map<String, dynamic> updates = {'name': name, 'phone': phone};
    if (photoUrl != null) {
      updates['photoUrl'] = photoUrl;
    }
    await _db.ref('users/$uid').update(updates);
  }
}
