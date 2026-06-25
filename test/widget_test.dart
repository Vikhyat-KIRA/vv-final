import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidyaverse/screens/auth/auth_screen.dart';

void main() {
  testWidgets('Auth screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame inside ProviderScope.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AuthScreen(),
        ),
      ),
    );

    // Verify that Auth Screen elements load successfully.
    expect(find.text('VIDYAVERSE'), findsOneWidget);
    expect(find.text('Gamified AI-Powered Study Companion'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
