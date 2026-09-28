import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/money.dart';

class DatabaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Create or Update User Profile
  Future<void> saveUser({required String uid, required String name}) async {
    try {
      await _db.ref('users/$uid/profile').set({'name': name});
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
    final profileSnapshot = await _db.ref('users/$uid/profile').get();
    final profileValue = profileSnapshot.value;
    if (profileValue is Map) return Map<String, dynamic>.from(profileValue);

    final legacySnapshot = await _db.ref('users/$uid').get();
    final value = legacySnapshot.value;
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  Future<Money> getBalance(String uid, {String currencyCode = 'NGN'}) async {
    final normalizedCode = currencyCode.toUpperCase();
    Money.fractionDigitsFor(normalizedCode);
    final walletSnapshot = await _db
        .ref('users/$uid/wallets/$normalizedCode/balanceMinor')
        .get();
    if (walletSnapshot.value != null) {
      final walletBalance = walletSnapshot.value;
      if (walletBalance is! int) {
        throw StateError('Stored wallet balance must be integer minor units.');
      }
      return Money.fromMinorUnits(
        currencyCode: normalizedCode,
        minorUnits: walletBalance,
      );
    }

    if (normalizedCode == 'NGN') {
      final legacySnapshot = await _db.ref('users/$uid/balance').get();
      final value = legacySnapshot.value;
      if (value is num) {
        return Money.fromMajor(
          currencyCode: normalizedCode,
          amount: value.toString(),
        );
      }
    }
    return Money.zero(normalizedCode);
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
    String? photoPath,
  }) async {
    final Map<String, dynamic> updates = {'name': name, 'phone': phone};
    if (photoPath != null) {
      updates['photoPath'] = photoPath;
    }
    await _db.ref('users/$uid/profile').update(updates);
  }
}
