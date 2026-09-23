import 'package:flutter/material.dart';

import '../models/password_entry.dart';
import '../services/password_service.dart';

class AddPasswordScreen extends StatefulWidget {
  final PasswordEntry? existingEntry;

  // Used when adding another account under a website.
  final String? initialWebsite;

  const AddPasswordScreen({
    super.key,
    this.existingEntry,
    this.initialWebsite,
  });

  @override
  State<AddPasswordScreen> createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  late final TextEditingController _websiteController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _notesController;

  bool _obscurePassword = true;
  bool _saving = false;

  bool get _isEditing => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existingEntry;

    _websiteController = TextEditingController(
      text: existing?.website ?? widget.initialWebsite ?? '',
    );

    _usernameController = TextEditingController(
      text: existing?.username ?? '',
    );

    _passwordController = TextEditingController(
      text: existing?.password ?? '',
    );

    _notesController = TextEditingController(
      text: existing?.notes ?? '',
    );
  }

  @override
  void dispose() {
    _websiteController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    final website = _websiteController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final notes = _notesController.text.trim();

    if (website.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Website and username are required'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final entry = PasswordEntry(
      id: widget.existingEntry?.id ?? '',
      title: website,
      username: username,
      password: password,
      website: website,
      notes: notes,
    );

    try {
      if (_isEditing) {
        // Update now accepts a single PasswordEntry.
        await PasswordService.update(entry);
      } else {
        // Add a new account.
        await PasswordService.add(entry);
      }

      if (!mounted) return;

      // Return true so the previous screen knows data changed.
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Account' : 'Add Account',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Website / App
            TextField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website / App',
                prefixIcon: Icon(Icons.language_rounded),
              ),
            ),

            const SizedBox(height: 16),

            // Username / Email
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username / Email',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),

            const SizedBox(height: 16),

            // Password
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.notes_rounded),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 28),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isEditing
                            ? 'Save Changes'
                            : 'Save Account',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}