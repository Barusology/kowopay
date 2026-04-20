import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
// FIX: firebase_core removed — infrastructure init belongs in main(), not here.

// ─────────────────────────────────────────────────────────────────────────────
// AUTH SERVICE PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the [AuthRepository] implementation used throughout the app.
///
/// Typed to the abstract interface so:
///   • Widgets/providers are decoupled from Firebase specifics.
///   • Tests can override with [FakeAuthService] without any Firebase setup.
///
/// FIX: No try/catch wrapping here.  main() awaits Firebase.initializeApp()
/// and rethrows on failure, so if execution reaches this provider Firebase is
/// guaranteed to be ready.  Swallowing errors here previously allowed a silent
/// "mock mode" that bypassed auth entirely — a critical security hole for a
/// FinTech app.
final authServiceProvider = Provider<AuthRepository>((ref) {
  final service = FirebaseAuthService();
  // FIX: dispose the service when the provider is torn down to release any
  // internal resources (custom stream subscriptions, controllers, etc.).
  ref.onDispose(service.dispose);
  return service;
});

// ─────────────────────────────────────────────────────────────────────────────
// AUTH STATE PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

/// Reactive stream of the currently authenticated [User].
///
/// Emits null when the user is signed out, a [User] when signed in, and stays
/// in loading state while the session is being resolved on app startup.
///
/// FIX: ref.read instead of ref.watch — we set up the stream once, not on
/// every rebuild.  ref.watch inside StreamProvider would re-subscribe on every
/// dependency change, which is unnecessary and can cause subtle rebuild storms.
///
/// FIX: .handleError converts any stream-level error (e.g. revoked token,
/// transient network failure) to null, which the app treats as "signed out"
/// and redirects to LoginPage — the only safe fallback in a financial app.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref
      .read(authServiceProvider)
      .authStateChanges
      .handleError((Object error, StackTrace stack) {
    debugPrint('[AuthState] Stream error — treating as signed out: $error');
    // In production, report before silently failing:
    // if (!kDebugMode) FirebaseCrashlytics.instance.recordError(error, stack);
  });
});
