import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

Map<String, dynamic> buildAtomicDebitTransaction({
  required Map<String, dynamic> currentUser,
  required double amount,
  required String title,
  required bool isCredit,
  required String transactionKey,
}) {
  final currentBalance = currentUser['balance'] is num
      ? (currentUser['balance'] as num).toDouble()
      : 0.0;
  if (currentBalance < amount) {
    throw StateError('Insufficient balance');
  }
  final userData = Map<String, dynamic>.from(currentUser);
  final transactions = userData['transactions'] is Map
      ? Map<String, dynamic>.from(userData['transactions'])
      : <String, dynamic>{};
  transactions[transactionKey] = {
    'title': title,
    'amount': amount,
    'isCredit': isCredit,
    'date': DateTime.now().toIso8601String(),
    'timestamp': ServerValue.timestamp,
  };
  userData['balance'] = currentBalance - amount;
  userData['transactions'] = transactions;
  return userData;
}

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
      debugPrint("Error saving user: $e");
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
