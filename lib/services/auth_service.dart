import 'package:firebase_auth/firebase_auth.dart';
import 'package:kowopay/utils/secure_logger.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ABSTRACT INTERFACE
// All widgets and providers depend on AuthRepository, never on the concrete
// FirebaseAuthService. This keeps the auth layer testable and swappable.
// ─────────────────────────────────────────────────────────────────────────────

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;

  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password);

  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password);

  Future<void> sendVerificationEmail();
  Future<void> sendPasswordResetEmail(String email);
  Future<bool> reloadUser();
  Future<bool> hasAdminClaim();
  Future<void> signOut();
  Future<void> refreshToken();
  void dispose();
}

// ─────────────────────────────────────────────────────────────────────────────
// FIREBASE IMPLEMENTATION
// ─────────────────────────────────────────────────────────────────────────────

class FirebaseAuthService implements AuthRepository {
  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) {
    // Never trim the password — spaces may be intentional.
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    final UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password, // never trim passwords
    );
    // Ask Firebase to send the verification link immediately. The app gates all
    // financial screens behind emailVerified.
    await credential.user?.sendEmailVerification();
    return credential;
  }

  @override
  Future<void> sendVerificationEmail() async {
    final User? user = _auth.currentUser;
    if (user == null) return;
    if (user.emailVerified) return;
    await user.sendEmailVerification();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<bool> reloadUser() async {
    final User? user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<bool> hasAdminClaim() async {
    final User? user = _auth.currentUser;
    if (user == null) return false;
    try {
      // Force refresh so a freshly granted/revoked admin claim takes effect.
      final IdTokenResult result = await user.getIdTokenResult(true);
      return result.claims?['admin'] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> refreshToken() async {
    final User? user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.getIdToken(true);
    } on FirebaseAuthException catch (e) {
      SecureLog.warn('Token refresh failed: ${e.code}');
      if (e.code == 'user-disabled' ||
          e.code == 'user-token-expired' ||
          e.code == 'user-not-found') {
        await signOut();
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    // FirebaseAuth streams are owned by the SDK.
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TEST DOUBLE
// ─────────────────────────────────────────────────────────────────────────────

class FakeAuthService implements AuthRepository {
  FakeAuthService({this.fakeUser});

  final User? fakeUser;

  @override
  Stream<User?> get authStateChanges => Stream<User?>.value(fakeUser);

  @override
  User? get currentUser => fakeUser;

  @override
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    throw UnimplementedError('Stub signIn — override in tests.');
  }

  @override
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    throw UnimplementedError('Stub register');
  }

  @override
  Future<void> sendVerificationEmail() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<bool> reloadUser() async => fakeUser?.emailVerified ?? false;

  @override
  Future<bool> hasAdminClaim() async => false;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> refreshToken() async {}

  @override
  void dispose() {}
}

/// Maps Firebase error codes to user-safe strings. Raw Firebase messages leak
/// internal codes and are confusing to end users.
String mapAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return 'Email or password is incorrect.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Choose a stronger password (8+ characters).';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'requires-recent-login':
        return 'Please sign in again to continue.';
      case 'operation-not-allowed':
        return 'This sign-in method is unavailable. Contact support.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
  return 'An unexpected error occurred. Please try again.';
}
