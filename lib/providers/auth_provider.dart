import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kowopay/services/auth_service.dart';

/// Provides the [AuthRepository] implementation used throughout the app.
///
/// There is deliberately no try/catch fallback here: `main()` awaits
/// `Firebase.initializeApp()` and rethrows on failure. A silent "mock mode"
/// would bypass authentication entirely — unacceptable in a financial app.
final authServiceProvider = Provider<AuthRepository>((ref) {
  final AuthRepository service = FirebaseAuthService();
  ref.onDispose(service.dispose);
  return service;
});

/// Reactive stream of the currently authenticated [User].
///
/// A stream error (revoked token, transient network failure) is converted to
/// null, which the app treats as signed out — the only safe fallback here.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref
      .read(authServiceProvider)
      .authStateChanges
      .handleError((Object error, StackTrace stack) {
    debugPrint('[AuthState] Stream error — treating as signed out.');
  });
});

/// True only when the server-issued ID token carries `admin: true`.
///
/// The claim is verified by Firebase Rules and Cloud Functions; this provider
/// only controls what the UI may render. Never trust it as the sole guard.
final adminRoleProvider = FutureProvider<bool>((ref) async {
  final User? user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return false;
  return ref.read(authServiceProvider).hasAdminClaim();
});
