import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/encryption_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Restores the authenticated session and prepares the local vault key before
/// allowing an existing session to enter the password screens.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<void> _vaultInitialization;

  @override
  void initState() {
    super.initState();
    _vaultInitialization = _initializeVault();
  }

  Future<void> _initializeVault() async {
    if (Supabase.instance.client.auth.currentSession != null) {
      await EncryptionService.initializeKey();
    }
  }

  void _retry() {
    setState(() {
      _vaultInitialization = _initializeVault();
    });
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    setState(() {
      _vaultInitialization = _initializeVault();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasSession = Supabase.instance.client.auth.currentSession != null;
    if (!hasSession) return const LoginScreen();

    return FutureBuilder<void>(
      future: _vaultInitialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Could not unlock your password vault',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _retry,
                      child: const Text('Try again'),
                    ),
                    TextButton(
                      onPressed: _signOut,
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const HomeScreen();
      },
    );
  }
}
