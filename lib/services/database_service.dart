import 'package:firebase_database/firebase_database.dart';
import 'package:kowopay/utils/secure_logger.dart';
import 'package:kowopay/utils/validators.dart';

/// Realtime Database access for profile, ledger and notification reads.
///
/// Security model: the client may only read its own subtree. Balance and
/// transaction writes are rejected by `database.rules.json`; money movement is
/// performed by Cloud Functions with the Admin SDK.
class DatabaseService {
  DatabaseService({FirebaseDatabase? database})
      : _db = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;

  static final RegExp _safeKey = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  DatabaseReference _userRef(String uid) {
    // Validating the UID prevents path traversal / injection via interpolated
    // database paths (e.g. a crafted uid containing '/', '.', '#', '$').
    if (!Validators.isSafeUid(uid)) {
      throw ArgumentError('Invalid user identifier.');
    }
    return _db.ref().child('users').child(uid);
  }

  DatabaseReference _childRef(String uid, String key, [String? child]) {
    if (!_safeKey.hasMatch(key)) {
      throw ArgumentError('Invalid record identifier.');
    }
    final DatabaseReference base = _userRef(uid).child(key);
    return child == null ? base : base.child(child);
  }

  // ── Profile ────────────────────────────────────────────────────────────────

  Future<void> saveUser({
    required String uid,
    required String email,
    required String name,
  }) async {
    // Leaf-level writes: Rules grant write access to these fields only, so the
    // client can never touch balance, ledger or notification records here.
    // Ordering keeps a retry after a partial failure idempotent.
    final DatabaseReference userRef = _userRef(uid);
    await userRef.child('name').set(name);
    await userRef.child('balance').set(0.0);
    await userRef.child('email').set(email);
    await userRef.child('createdAt').set(ServerValue.timestamp);
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
    String? photoUrl,
  }) async {
    final DatabaseReference userRef = _userRef(uid);
    // Separate leaf writes so Rules can allow profile edits while keeping
    // balance, ledger and notifications read-only for the client.
    await userRef.child('name').set(name);
    if (phone.isNotEmpty) {
      await userRef.child('phone').set(phone);
    }
    if (photoUrl != null && Validators.isSafeImageUrl(photoUrl)) {
      await userRef.child('photoUrl').set(photoUrl);
    }
  }

  Future<Map<String, dynamic>?> getUserOnce(String uid) async {
    final DataSnapshot snapshot = await _userRef(uid).get();
    return _asMap(snapshot.value);
  }

  Stream<DatabaseEvent> getUserStream(String uid) => _userRef(uid).onValue;

  Future<double> getBalance(String uid) async {
    final DataSnapshot snapshot = await _userRef(uid).child('balance').get();
    final Object? value = snapshot.value;
    return value is num ? value.toDouble() : 0.0;
  }

  // ── Ledger (read-only on the client) ───────────────────────────────────────

  Stream<DatabaseEvent> getTransactionsStream(String uid) => _userRef(uid)
      .child('transactions')
      .orderByChild('timestamp')
      .limitToLast(50)
      .onValue;

  // ── Notifications ──────────────────────────────────────────────────────────

  Stream<DatabaseEvent> getNotificationsStream(String uid) => _userRef(uid)
      .child('notifications')
      .orderByChild('timestamp')
      .limitToLast(50)
      .onValue;

  /// Rules only permit a user to flip the `read` flag on their own records.
  Future<void> markNotificationRead(String uid, String notificationId) async {
    await _childRef(uid, 'notifications', notificationId)
        .child('read')
        .set(true);
  }

  // ── Admin ──────────────────────────────────────────────────────────────────

  /// Requires the `admin` custom claim; Rules reject this for normal users.
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final DataSnapshot snapshot = await _db.ref().child('users').get();
    final Map<String, dynamic>? raw = _asMap(snapshot.value);
    if (raw == null) return <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> users = <Map<String, dynamic>>[];
    raw.forEach((String uid, dynamic value) {
      final Map<String, dynamic>? profile = _asMap(value);
      if (profile != null) {
        users.add(<String, dynamic>{'uid': uid, ...profile});
      }
    });
    return users;
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  void dispose() {
    // No subscriptions are held by this service; callers own their streams.
    SecureLog.debug('[DatabaseService] disposed');
  }
}
