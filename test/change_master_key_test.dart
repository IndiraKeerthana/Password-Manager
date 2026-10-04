import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:password_manager/services/encryption_service.dart';
import 'package:password_manager/widgets/change_master_key_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  tearDown(() {
    EncryptionService.lockMemoryVault();
  });

  test('changeMasterKey throws StateError if vault is locked or user not logged in', () async {
    EncryptionService.lockMemoryVault();
    expect(
      () => EncryptionService.changeMasterKey(
        currentMasterKey: 'oldKey123',
        newMasterKey: 'newKey123',
      ),
      throwsA(isA<StateError>()),
    );
  });

  testWidgets('ChangeMasterKeyDialog displays required fields', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChangeMasterKeyDialog(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Change Master Key'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Current Master Key'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'New Master Key'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Confirm New Master Key'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('ChangeMasterKeyDialog validates empty current master key', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChangeMasterKeyDialog(),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Update'));
    await tester.pump();

    expect(find.text('Please enter your current master key.'), findsOneWidget);
  });

  testWidgets('ChangeMasterKeyDialog validates short new master key', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChangeMasterKeyDialog(),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextField, 'Current Master Key'),
      'oldSecret123',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'New Master Key'),
      'short',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm New Master Key'),
      'short',
    );

    await tester.tap(find.text('Update'));
    await tester.pump();

    expect(find.text('New master key must be at least 6 characters.'), findsOneWidget);
  });

  testWidgets('ChangeMasterKeyDialog validates mismatched confirmation', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChangeMasterKeyDialog(),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextField, 'Current Master Key'),
      'oldSecret123',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'New Master Key'),
      'newSecret123',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm New Master Key'),
      'differentSecret456',
    );

    await tester.tap(find.text('Update'));
    await tester.pump();

    expect(find.text('New master key and confirmation do not match.'), findsOneWidget);
  });
}
