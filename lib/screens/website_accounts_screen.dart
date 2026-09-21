import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/password_entry.dart';

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
  // Track password visibility for each account individually.
  final Map<int, bool> _passwordVisibility = {};

  Future<void> _copyToClipboard(
    String value,
    String label,
  ) async {
    if (value.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: value));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      appBar: AppBar(
        title: Text(
          widget.websiteName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),

      body: widget.entries.isEmpty
          ? const Center(
              child: Text('No saved accounts found'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '${widget.entries.length} '
                  '${widget.entries.length == 1 ? 'account' : 'accounts'} saved',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 16),

                ...List.generate(widget.entries.length, (index) {
                  final entry = widget.entries[index];

                  final username = entry.username;
                  final password = entry.password;

                  final isVisible =
                      _passwordVisibility[index] ?? false;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Account heading
                        Row(
                          children: [
                            const Icon(
                              Icons.account_circle_outlined,
                              size: 26,
                              color: Color(0xFF5B5FEF),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                'Account ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Username / Email
                        const Text(
                          'Username / Email',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                username.isEmpty
                                    ? 'Not provided'
                                    : username,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            IconButton(
                              tooltip: 'Copy username',
                              icon: const Icon(
                                Icons.copy_rounded,
                                size: 18,
                              ),
                              onPressed: username.isEmpty
                                  ? null
                                  : () => _copyToClipboard(
                                        username,
                                        'Username',
                                      ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Password label
                        const Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Password display
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FC),
                            borderRadius: BorderRadius.circular(12),
                          ),

                          child: Row(
                            children: [
                              Expanded(
                                child: SelectableText(
                                  isVisible
                                      ? password
                                      : '•' * password.length,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),

                              IconButton(
                                tooltip: isVisible
                                    ? 'Hide password'
                                    : 'Show password',
                                icon: Icon(
                                  isVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _passwordVisibility[index] =
                                        !isVisible;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Copy password button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: password.isEmpty
                                ? null
                                : () => _copyToClipboard(
                                      password,
                                      'Password',
                                    ),
                            icon: const Icon(
                              Icons.copy_rounded,
                              size: 17,
                            ),
                            label: const Text('Copy Password'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  const Color(0xFF5B5FEF),
                              side: const BorderSide(
                                color: Color(0xFF5B5FEF),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}