import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

// Mock User class since we can't easily instantiate a real User
class MockUser {
  final String email;
  final String uid;
  MockUser({required this.email, required this.uid});
}

class AuthService {
  final FirebaseAuth? _auth;
  final bool _isMock;

  // Stream controller for mock auth state
  // We use RxDart BehaviorSubject behavior manually or just a simple stream that yields current value
  // But strictly, Stream.value(null) or similar is needed for the first listen.
  
  // ignore: close_sinks
  final _mockUserStreamController = StreamController<User?>.broadcast();
  User? _mockUser;

  AuthService({bool isMock = false}) 
      : _auth = isMock ? null : FirebaseAuth.instance,
        _isMock = isMock {
     if (_isMock) {
        // Emit initial state (null = logged out) slightly delayed to simulate startup or just rely on the controller logic if we were using a BehaviorSubject.
        // But for StreamController, we can't easily "replay" subscription.
        // Better approach for StreamProvider is to return a Stream that starts with a value.
     }
  }

  /*
  Stream<User?> get authStateChanges {
    if (_isMock) {
      return Stream.value(_mockUser).concatWith([_mockUserStreamController.stream]);
    }
    // ...
  }
  */
  // Since we don't have rxdart listed, let's use standard Dart streams:
  // Use async* to ensure initial value is emitted
  Stream<User?> get authStateChanges async* {
     if (_isMock) {
       yield _mockUser;
       yield* _mockUserStreamController.stream;
     } else {
       yield* _auth!.authStateChanges();
     }
  }

  // Get current user
  User? get currentUser => 
      _isMock ? _mockUser : _auth!.currentUser;

  // Sign in
  Future<void> signIn(String email, String password) async {
    if (_isMock) {
       // Simulate network delay
       await Future.delayed(const Duration(seconds: 1));
       if (email == "error@test.com") throw Exception("Mock Login Failed");
       // We can't return a real User object easily without casting hacks, 
       // so for this mock we might need to change the Provider type or generic.
       // BUT, to keep it simple and safe:
       // We will rely on the fact that we might NOT need this if we fix Firebase.
       // However, to unblock the user, let's just allow the UI to load.
       // Since 'User' is from firebase_auth, we can't create it manually easily.
       // Recommendation: If Firebase fails, we just warn the user.
       throw Exception("Firebase not configured. Cannot login.");
    } else {
      await _auth!.signInWithEmailAndPassword(email: email, password: password);
    }
  }

  // Sign up
  Future<void> signUp(String email, String password) async {
    if (_isMock) {
      throw Exception("Firebase not configured. Cannot register.");
    } else {
      await _auth!.createUserWithEmailAndPassword(email: email, password: password);
    }
  }

  // Sign out
  Future<void> signOut() async {
     if (_isMock) return;
    await _auth!.signOut();
  }
}
