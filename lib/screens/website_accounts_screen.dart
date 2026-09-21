import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/password_entry.dart';
import '../services/password_service.dart';
import 'add_password_screen.dart';

class WebsiteAccountsScreen extends StatefulWidget {
  final String websiteName;
  final List<PasswordEntry> entries;

  const WebsiteAccountsScreen({
    super.key,
    required this.websiteName,
    required this.entries,
  });

  @override
  State<WebsiteAccountsScreen> createState() =>
      _WebsiteAccountsScreenState();
}

class _WebsiteAccountsScreenState
    extends State<WebsiteAccountsScreen> {
  late List<PasswordEntry> _entries;

  final Map<String, bool> _passwordVisibility = {};

  bool _isWorking = false;

  @override
  void initState() {
    super.initState();
    _entries = List.from(widget.entries);
  }

  // Copy username or password.
  Future<void> _copyText(String value, String label) async {
    if (value.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: value));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Add another account for the same website.
  Future<void> _addAccount() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddPasswordScreen(
          initialWebsite: widget.websiteName,
        ),
      ),
    );

    if (!mounted) return;

    // Return to Home so it can reload the latest entries.
    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  // Edit an existing account.
  Future<void> _editAccount(PasswordEntry entry) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddPasswordScreen(
          existingEntry: entry,
        ),
      ),
    );

    if (!mounted) return;

    // Home will reload updated data.
    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  // Delete an account after confirmation.
  Future<void> _deleteAccount(PasswordEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete account?'),
          content: Text(
            'Delete the saved credentials for '
            '${entry.username.isNotEmpty ? entry.username : 'this account'}?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    setState(() => _isWorking = true);

    try {
      await PasswordService.delete(entry.id);

      if (!mounted) return;

      // Return to Home and refresh the saved credentials.
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isWorking = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete account: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.websiteName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),

      body: _entries.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_entries.length} saved '
                          '${_entries.length == 1 ? 'account' : 'accounts'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: Color(0xFF68708A),
                      ),

                      const SizedBox(width: 6),

                      Text(
                        'Private',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Account cards
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      4,
                      16,
                      16,
                    ),
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      final entry = _entries[index];

                      return _buildAccountCard(entry);
                    },
                  ),
                ),
              ],
            ),

      // Add account button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            16,
          ),
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _isWorking ? null : _addAccount,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add another account',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5B5FEF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Individual account card.
  Widget _buildAccountCard(PasswordEntry entry) {
    final username = entry.username;
    final password = entry.password;

    final isVisible = _passwordVisibility[entry.id] ?? false;

    final displayName = username.isNotEmpty
        ? username
        : 'Saved account';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8EAF1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Username heading + menu
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFEEEEFF),
                child: Text(
                  displayName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF5B5FEF),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202338),
                  ),
                ),
              ),

              PopupMenuButton<String>(
                enabled: !_isWorking,
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: Color(0xFF777D91),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _editAccount(entry);
                  } else if (value == 'delete') {
                    _deleteAccount(entry);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 19),
                        SizedBox(width: 10),
                        Text('Edit account'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                          size: 19,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Delete account',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Username field
          _buildDetailField(
            label: 'Username / Email',
            value: username,
            trailing: IconButton(
              tooltip: 'Copy username',
              onPressed: username.isEmpty
                  ? null
                  : () => _copyText(username, 'Username'),
              icon: const Icon(
                Icons.copy_rounded,
                size: 19,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Password field
          _buildDetailField(
            label: 'Password',
            value: isVisible
                ? password
                : '•' * (password.isEmpty ? 8 : password.length),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: isVisible
                      ? 'Hide password'
                      : 'Show password',
                  onPressed: () {
                    setState(() {
                      _passwordVisibility[entry.id] = !isVisible;
                    });
                  },
                  icon: Icon(
                    isVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                ),

                IconButton(
                  tooltip: 'Copy password',
                  onPressed: password.isEmpty
                      ? null
                      : () => _copyText(password, 'Password'),
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 19,
                  ),
                ),
              ],
            ),
          ),

          // Notes, if available
          if (entry.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Note',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    entry.notes,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF34384B),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Edit + Delete actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isWorking
                      ? null
                      : () => _editAccount(entry),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 17,
                  ),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5B5FEF),
                    side: const BorderSide(
                      color: Color(0xFFE0E2F0),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isWorking
                      ? null
                      : () => _deleteAccount(entry),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 17,
                  ),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(
                      color: Colors.red.shade100,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Reusable username/password field.
  Widget _buildDetailField({
    required String label,
    required String value,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 4),

                SelectableText(
                  value.isEmpty ? 'Not provided' : value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF25283A),
                  ),
                ),
              ],
            ),
          ),

          trailing,
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 12),
          Text(
            'No saved accounts yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Add an account to get started.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}