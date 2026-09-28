import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kowopay/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

void main() {
  test('maps Firebase auth errors without exposing internal details', () {
    final error = FirebaseAuthException(
      code: 'wrong-password',
      message: 'sensitive provider detail',
    );

    expect(mapAuthError(error), 'Incorrect password. Please try again.');
    expect(mapAuthError(error), isNot(contains('sensitive')));
  });

  test('sign-in trims email but preserves password', () async {
    final auth = MockFirebaseAuth();
    final credential = MockUserCredential();
    when(
      () => auth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => credential);
    final service = FirebaseAuthService(auth: auth);

    await service.signInWithEmailAndPassword(' user@example.com ', ' pass ');

    verify(
      () => auth.signInWithEmailAndPassword(
        email: 'user@example.com',
        password: ' pass ',
      ),
    ).called(1);
  });
}
