import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:password_manager/main.dart';
import 'package:password_manager/screens/auth_gate.dart';
import 'package:password_manager/screens/home_screen.dart';
import 'package:password_manager/screens/login_screen.dart';
import 'package:password_manager/screens/unlock_vault_screen.dart';
import 'package:password_manager/services/encryption_service.dart';
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

  test('decryptPassword throws vault locked error when locked', () async {
    EncryptionService.lockMemoryVault();
    expect(
      () => EncryptionService.decryptPassword('enc:v2:dummy'),
      throwsA(isA<StateError>().having(
        (e) => e.message,
        'message',
        contains('Vault is locked'),
      )),
    );
  });

  testWidgets('AuthGate shows LoginScreen when no Supabase session', (tester) async {
    EncryptionService.lockMemoryVault();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const AuthGate(),
      ),
    );
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(UnlockVaultScreen), findsNothing);
    expect(find.byType(HomeScreen), findsNothing);
  });

  test('lockMemoryVault immediately sets isVaultUnlocked to false and notifies false', () {
    EncryptionService.lockMemoryVault();
    expect(EncryptionService.isVaultUnlocked, isFalse);
    expect(EncryptionService.vaultUnlockedNotifier.value, isFalse);
  });
}

