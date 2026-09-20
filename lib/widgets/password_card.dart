import 'package:flutter/material.dart';
import '../models/password_entry.dart';
import '../utils/entry_colors.dart';

class PasswordCard extends StatelessWidget {
  final PasswordEntry entry;
  final VoidCallback onTap;

  const PasswordCard({super.key, required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = colorForEntry(entry.title);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            entry.title.isNotEmpty ? entry.title[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(entry.username),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
