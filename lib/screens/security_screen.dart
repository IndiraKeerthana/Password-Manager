import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/encryption_service.dart';
import 'login_screen.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _signingOutEverywhere = false;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Signed in as', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(user?.email ?? 'Unknown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    user?.createdAt != null ? 'Account created ${user!.createdAt.split('T').first}' : '',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your passwords are stored per-account and protected by row-level '
            'security, so only you can read or edit them.',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: _signingOutEverywhere
                ? null
                : () async {
                    setState(() => _signingOutEverywhere = true);
                    final navigator = Navigator.of(context);
                    await EncryptionService.lockVault();
                    await Supabase.instance.client.auth.signOut(scope: SignOutScope.global);
                    if (!mounted) return;
                    navigator.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
            icon: const Icon(Icons.logout),
            label: Text(_signingOutEverywhere ? 'Signing out...' : 'Sign out of all devices'),
          ),
        ],
      ),
    );
  }
}
