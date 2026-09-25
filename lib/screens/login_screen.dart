import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_gate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSignUp = false;
  bool _loading = false;

  Future<void> _submit() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email and password.'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final client = Supabase.instance.client;

    try {
      if (_isSignUp) {
        // Create a new Supabase account.
        final response = await client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // If Supabase immediately creates a session,
        // continue to the authentication gate.
        if (response.session != null && response.user != null) {
          if (!mounted) return;

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const AuthGate(),
            ),
          );
        } else {
          // Email confirmation may be required.
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account created. Check your email to confirm '
                'your account, then log in.',
              ),
            ),
          );

          setState(() => _isSignUp = false);
        }
      } else {
        // Sign in using Supabase authentication.
        final response = await client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (response.user == null) {
          throw Exception('Login failed. Please try again.');
        }

        if (!mounted) return;

        // Continue to AuthGate to unlock the vault.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const AuthGate(),
          ),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon
                CircleAvatar(
                  radius: 40,
                  backgroundColor: colorScheme.primary,
                  child: Icon(
                    Icons.lock,
                    size: 40,
                    color: colorScheme.onPrimary,
                  ),
                ),

                const SizedBox(height: 20),

                // App Name
                Text(
                  'Password Manager',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  _isSignUp
                      ? 'Create an account to continue'
                      : 'Log in to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 32),

                // Email Field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),

                const SizedBox(height: 16),

                // Supabase Account Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!_loading) {
                      _submit();
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Login / Sign Up Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : Text(
                            _isSignUp ? 'Sign Up' : 'Login',
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // Toggle Login / Sign Up
                TextButton(
                  onPressed: _loading
                      ? null
                      : () {
                          setState(() {
                            _isSignUp = !_isSignUp;
                          });
                        },
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Log in'
                        : "Don't have an account? Sign up",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}