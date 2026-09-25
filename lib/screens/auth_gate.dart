import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/encryption_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'unlock_vault_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session =
            snapshot.data?.session ?? client.auth.currentSession;

        // No active Supabase session -> Supabase LoginScreen
        if (session == null) {
          return const LoginScreen();
        }

        // User is authenticated in Supabase.
        // Listen to in-memory vault lock state.
        return ValueListenableBuilder<bool>(
          valueListenable: EncryptionService.vaultUnlockedNotifier,
          builder: (context, isUnlocked, _) {
            if (isUnlocked && EncryptionService.isVaultUnlocked) {
              return const HomeScreen();
            }

            // Vault is locked in memory.
            // Prompt user for vault password without re-authenticating with Supabase.
            return const UnlockVaultScreen();
          },
        );
      },
    );
  }
}