import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:password_manager/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Mock SharedPreferences for the test environment
    SharedPreferences.setMockInitialValues({});

    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  testWidgets(
    'App displays the login screen without a session',
    (WidgetTester tester) async {
      await tester.pumpWidget(const PasswordManagerApp());
      await tester.pump();

      expect(find.byType(Scaffold), findsWidgets);
      expect(find.text('Password Manager'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    },
  );
}