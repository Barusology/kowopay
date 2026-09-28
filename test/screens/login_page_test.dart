import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kowopay/providers/auth_provider.dart';
import 'package:kowopay/screens/login_page.dart';
import 'package:kowopay/services/auth_service.dart';

class TestAuthService extends FakeAuthService {
  @override
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) => Future.error(StateError('not used'));
}

void main() {
  testWidgets('shows validators for empty login fields', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(TestAuthService())],
        child: const MaterialApp(home: LoginPage()),
      ),
    );

    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });
}
