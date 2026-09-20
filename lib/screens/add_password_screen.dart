import 'package:flutter/material.dart';
import '../models/password_entry.dart';
import '../services/password_service.dart';

class AddPasswordScreen extends StatefulWidget {
  final PasswordEntry? existingEntry; // null = adding new, otherwise editing this entry

  const AddPasswordScreen({super.key, this.existingEntry});

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
    _websiteController = TextEditingController(text: existing?.website ?? '');
    _usernameController = TextEditingController(text: existing?.username ?? '');
    _passwordController = TextEditingController(text: existing?.password ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
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
    if (_websiteController.text.isEmpty || _usernameController.text.isEmpty) return;
    setState(() => _saving = true);
    final entry = PasswordEntry(
      id: widget.existingEntry?.id ?? '',
      title: _websiteController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      website: _websiteController.text,
      notes: _notesController.text,
    );
    try {
      if (_isEditing) {
        await PasswordService.update(widget.existingEntry!.id, entry);
      } else {
        await PasswordService.add(entry);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Password' : 'Add Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _websiteController,
              decoration: const InputDecoration(labelText: 'Website / App'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username / Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary),
                      )
                    : Text(_isEditing ? 'Update' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
