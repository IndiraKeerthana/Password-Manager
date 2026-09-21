import 'package:flutter/material.dart';

import '../models/password_entry.dart';
import '../services/password_service.dart';
import '../utils/entry_colors.dart';

import 'add_password_screen.dart';
import 'settings_screen.dart';
import 'website_accounts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';

  List<PasswordEntry> _entries = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final entries = await PasswordService.fetchAll();

      if (!mounted) return;

      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load passwords: $e'),
        ),
      );
    }
  }

  // Normalize website URLs so that:
  // https://google.com
  // http://google.com/
  // www.google.com
  // google.com
  // are treated as the same website.

  String _normalizeWebsite(String website) {
    String value = website.trim().toLowerCase();

    if (value.isEmpty) {
      return '';
    }

    if (!value.startsWith('http://') &&
        !value.startsWith('https://')) {
      value = 'https://$value';
    }

    final uri = Uri.tryParse(value);

    if (uri != null && uri.host.isNotEmpty) {
      String host = uri.host.toLowerCase();

      if (host.startsWith('www.')) {
        host = host.substring(4);
      }

      return host;
    }

    return website.trim().toLowerCase();
  }

  // Use the website field for grouping.
  // Fall back to title if website is empty.

  String _groupKey(PasswordEntry entry) {
    final website = entry.website.trim().isNotEmpty
        ? entry.website
        : entry.title;

    return _normalizeWebsite(website);
  }

  // Group credentials belonging to the same website.

  Map<String, List<PasswordEntry>> get _groupedEntries {
    final Map<String, List<PasswordEntry>> groups = {};

    for (final entry in _entries) {
      final key = _groupKey(entry);

      groups.putIfAbsent(key, () => []);

      groups[key]!.add(entry);
    }

    return groups;
  }

  // Search websites and usernames.
  // A matching username will display its website group.

  Map<String, List<PasswordEntry>> get _filteredGroups {
    final groups = _groupedEntries;

    if (_query.trim().isEmpty) {
      return groups;
    }

    final query = _query.trim().toLowerCase();

    final Map<String, List<PasswordEntry>> filtered = {};

    groups.forEach((key, entries) {
      final websiteMatches = entries.any((entry) {
        return entry.title.toLowerCase().contains(query) ||
            entry.website.toLowerCase().contains(query);
      });

      final usernameMatches = entries.any((entry) {
        return entry.username.toLowerCase().contains(query);
      });

      if (websiteMatches || usernameMatches) {
        filtered[key] = entries;
      }
    });

    return filtered;
  }

  String _websiteName(List<PasswordEntry> entries) {
    if (entries.isEmpty) return 'Unknown';

    final title = entries.first.title.trim();

    if (title.isNotEmpty) return title;

    return entries.first.website;
  }

  Future<void> _openWebsite(
    String website,
    List<PasswordEntry> entries,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebsiteAccountsScreen(
          websiteName: website,
          entries: entries,
        ),
      ),
    );

    _loadEntries();
  }

  Future<void> _addPassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddPasswordScreen(),
      ),
    );

    _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final groups = _filteredGroups;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Password Manager',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // Search bar

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: TextField(
              onChanged: (value) {
                setState(() => _query = value);
              },
              decoration: InputDecoration(
                hintText: 'Search passwords',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : groups.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 120),

                          Icon(
                            Icons.lock_outline,
                            size: 52,
                            color: colorScheme.onSurfaceVariant,
                          ),

                          const SizedBox(height: 16),

                          Center(
                            child: Text(
                              _entries.isEmpty
                                  ? 'No passwords yet'
                                  : 'No matching passwords',
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),

                          if (_entries.isEmpty) ...[
                            const SizedBox(height: 8),

                            const Center(
                              child: Text(
                                'Tap + to add your first password',
                              ),
                            ),
                          ],
                        ],
                      )
                    : RefreshIndicator(
                        onRefresh: _loadEntries,
                        child: ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 90),

                          children: groups.entries.map((group) {
                            final entries = group.value;

                            final website = _websiteName(entries);

                            final accountCount = entries.length;

                            final color = colorForEntry(website);

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),

                              elevation: 0,

                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),

                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: color,
                                  child: Text(
                                    website.isNotEmpty
                                        ? website[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),

                                title: Text(
                                  website,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),

                                subtitle: Text(
                                  accountCount == 1
                                      ? '1 account'
                                      : '$accountCount accounts',
                                ),

                                trailing: const Icon(
                                  Icons.chevron_right,
                                ),

                                onTap: () {
                                  _openWebsite(website, entries);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _addPassword,
        child: const Icon(Icons.add),
      ),
    );
  }
}