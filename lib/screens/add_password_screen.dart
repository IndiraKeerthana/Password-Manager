import 'package:flutter/material.dart';
import '../models/password_entry.dart';

class AddPasswordScreen extends StatefulWidget {
  final int? editIndex; // null = adding new, otherwise index into sampleEntries to update

  const AddPasswordScreen({super.key, this.editIndex});

  @override
  State<AddPasswordScreen> createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  late final TextEditingController _websiteController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _notesController;
  bool _obscurePassword = true;

  bool get _isEditing => widget.editIndex != null;

  @override
  void initState() {
    super.initState();
    final existing = _isEditing ? sampleEntries[widget.editIndex!] : null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Password' : 'Add Password'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _websiteController,
              decoration: _inputDecoration('Website / App'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: _inputDecoration('Username / Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: _inputDecoration('Password').copyWith(
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
              decoration: _inputDecoration('Notes'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (_websiteController.text.isNotEmpty && _usernameController.text.isNotEmpty) {
                    final updated = PasswordEntry(
                      title: _websiteController.text,
                      username: _usernameController.text,
                      password: _passwordController.text,
                      website: _websiteController.text,
                      notes: _notesController.text,
                    );
                    if (_isEditing) {
                      sampleEntries[widget.editIndex!] = updated;
                    } else {
                      sampleEntries.add(updated);
                    }
                  }
                  Navigator.pop(context, true);
                },
                child: Text(
                  _isEditing ? 'Update' : 'Save',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
