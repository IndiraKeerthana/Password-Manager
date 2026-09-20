import 'package:flutter/material.dart';
import '../models/password_entry.dart';
import '../services/password_service.dart';
import '../widgets/password_card.dart';
import 'add_password_screen.dart';
import 'details_screen.dart';
import 'settings_screen.dart';

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
    setState(() => _loading = true);
    final entries = await PasswordService.fetchAll();
    if (mounted) {
      setState(() {
        _entries = entries;
        _loading = false;
      });
    }
  }

  List<PasswordEntry> get _filteredEntries {
    if (_query.isEmpty) return _entries;
    return _entries.where((e) => e.title.toLowerCase().contains(_query.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('My Passwords'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadEntries,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredEntries.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 120),
                            Icon(Icons.lock_outline, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                _entries.isEmpty ? 'No passwords yet' : 'No matching entries',
                                style: const TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ),
                            if (_entries.isEmpty) ...[
                              const SizedBox(height: 4),
                              const Center(
                                child: Text(
                                  'Tap + to add your first password',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ),
                            ],
                          ],
                        )
                      : ListView.builder(
                          itemCount: _filteredEntries.length,
                          itemBuilder: (context, index) {
                            final entry = _filteredEntries[index];
                            return PasswordCard(
                              entry: entry,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => DetailsScreen(entry: entry)),
                                );
                                _loadEntries();
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPasswordScreen()));
          _loadEntries();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
