import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WebsiteAccountsScreen extends StatefulWidget {
  final String website;
  final List<Map<String, dynamic>> accounts;

  const WebsiteAccountsScreen({
    super.key,
    required this.website,
    required this.accounts,
  });

  @override
  State<WebsiteAccountsScreen> createState() =>
      _WebsiteAccountsScreenState();
}

class _WebsiteAccountsScreenState extends State<WebsiteAccountsScreen> {
  // Tracks password visibility separately for each account.
  final Map<int, bool> _passwordVisibility = {};

  Future<void> _copyPassword(String password) async {
    await Clipboard.setData(ClipboardData(text: password));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(
          widget.website,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),

      body: widget.accounts.isEmpty
          ? const Center(
              child: Text('No saved accounts found'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '${widget.accounts.length} saved '
                  '${widget.accounts.length == 1 ? 'account' : 'accounts'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 16),

                ...List.generate(widget.accounts.length, (index) {
                  final account = widget.accounts[index];

                  final username =
                      account['username']?.toString() ?? '';

                  final password =
                      account['password']?.toString() ?? '';

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
                          color: Colors.black.withOpacity(0.03),
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
                              size: 25,
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

                        // Username
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
                              child: Text(
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
                                  : () async {
                                      await Clipboard.setData(
                                        ClipboardData(
                                          text: username,
                                        ),
                                      );

                                      if (!context.mounted) return;

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Username copied',
                                          ),
                                        ),
                                      );
                                    },
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

                        // Password field
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
                                child: Text(
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
                                : () => _copyPassword(password),

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