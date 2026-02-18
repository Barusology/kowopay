import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  try {
     // Check if Firebase app is initialized
     Firebase.app(); 
     return AuthService();
  } catch (e) {
    // Return a "Mock" or disabled service if Firebase isn't ready
    return AuthService(isMock: true);
  }
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
