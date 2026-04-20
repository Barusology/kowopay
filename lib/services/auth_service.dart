import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;

// ─────────────────────────────────────────────────────────────────────────────
// ABSTRACT INTERFACE
// All widgets and providers depend on AuthRepository, never on the concrete
// FirebaseAuthService.  This makes the auth layer fully testable without
// Firebase and lets you swap implementations (Google, Apple, biometric) without
// touching any consumer.
// ─────────────────────────────────────────────────────────────────────────────

abstract class AuthRepository {
  /// Stream that emits the current [User] or null on sign-out.
  Stream<User?> get authStateChanges;

  /// The synchronously available current user (may lag one tick behind the
  /// stream).  Prefer watching [authStateProvider] in widgets.
  User? get currentUser;

  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password);

  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password);

  Future<void> signOut();

  /// Force-refresh the Firebase ID token.  Call when the app returns to
  /// foreground to detect revoked / disabled accounts before any financial
  /// operation is attempted.
  Future<void> refreshToken();

  /// Release any resources held by this service (stream subscriptions, etc.).
  void dispose();
}

// ─────────────────────────────────────────────────────────────────────────────
// FIREBASE IMPLEMENTATION
// ─────────────────────────────────────────────────────────────────────────────

class FirebaseAuthService implements AuthRepository {
  FirebaseAuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    // Intentionally do NOT trim the password — spaces may be intentional.
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // FirebaseAuthException is not caught here — it should propagate to the UI
    // layer so the correct error code can be mapped to a user-friendly message.
  }

  @override
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password, // never trim passwords
    );
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> refreshToken() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.getIdToken(true); // forceRefresh: true
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] Token refresh failed: ${e.code}');
      // Force re-login for these codes — do NOT let stale sessions persist in
      // a financial app.
      if (e.code == 'user-disabled' || e.code == 'user-token-expired') {
        await signOut();
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    // FirebaseAuth streams are managed by the SDK — nothing custom to close.
    // Add any custom StreamController.close() calls here if you extend this.
    debugPrint('[AuthService] disposed');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TEST DOUBLE
// Use this in widget tests via ProviderScope overrides.  Zero Firebase deps.
// ─────────────────────────────────────────────────────────────────────────────

class FakeAuthService implements AuthRepository {
  FakeAuthService({this.fakeUser});

  final User? fakeUser;

  @override
  Stream<User?> get authStateChanges => Stream.value(fakeUser);

  @override
  User? get currentUser => fakeUser;

  @override
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    throw UnimplementedError(
        'Stub signIn — override in tests that need sign-in behaviour.');
  }

  @override
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    throw UnimplementedError('Stub register');
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> refreshToken() async {}

  @override
  void dispose() {}
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER — map Firebase error codes to user-facing strings
// Place this here so both LoginPage and RegisterPage can import it from one
// location without duplicating the switch statement.
// ─────────────────────────────────────────────────────────────────────────────

String mapAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a moment and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
  return 'An unexpected error occurred. Please try again.';
}
