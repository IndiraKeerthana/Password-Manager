import 'package:flutter/material.dart';
import '../models/password_entry.dart';
import '../services/password_service.dart';
import '../utils/entry_colors.dart';
import 'add_password_screen.dart';

class DetailsScreen extends StatefulWidget {
  final PasswordEntry entry;

  const DetailsScreen({super.key, required this.entry});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  bool _obscurePassword = true;
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorForEntry(entry.title);
    return Scaffold(
      appBar: AppBar(title: Text(entry.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: accent,
                  child: Text(
                    entry.title.isNotEmpty ? entry.title[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    entry.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow('Username', entry.username),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _detailRow(
                            'Password',
                            _obscurePassword ? '•' * entry.password.length : entry.password,
                          ),
                        ),
                        IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ],
                    ),
                    if (entry.website.isNotEmpty) ...[
                      const Divider(),
                      _detailRow('Website', entry.website),
                    ],
                    if (entry.notes.isNotEmpty) ...[
                      const Divider(),
                      _detailRow('Notes', entry.notes),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddPasswordScreen(existingEntry: entry)),
                      );
                      // Data changed on the server; go back so Home reloads fresh data.
                      if (mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    ),
                    onPressed: _deleting
                        ? null
                        : () async {
                            setState(() => _deleting = true);
                            await PasswordService.delete(entry.id);
                            if (mounted) Navigator.pop(context);
                          },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Builder(builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 16)),
          ],
        ),
      );
    });
  }
}
