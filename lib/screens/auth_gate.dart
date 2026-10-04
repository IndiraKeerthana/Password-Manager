import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/encryption_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'unlock_vault_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;

    // If there is no active session on startup, ensure memory vault is locked.
    if (client.auth.currentSession == null) {
      EncryptionService.lockMemoryVault();
    }

    _authSubscription = client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session == null) {
        EncryptionService.lockMemoryVault();
      } else if (EncryptionService.currentUserId != null &&
          EncryptionService.currentUserId != session.user.id) {
        EncryptionService.lockMemoryVault();
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

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
  }
}