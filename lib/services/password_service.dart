import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/password_entry.dart';

class PasswordService {
  static final _client = Supabase.instance.client;

  static Future<List<PasswordEntry>> fetchAll() async {
    final data = await _client
        .from('passwords')
        .select()
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => PasswordEntry.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> add(PasswordEntry entry) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('passwords').insert({
      ...entry.toMap(),
      'user_id': userId,
    });
  }

  static Future<void> update(String id, PasswordEntry entry) async {
    await _client.from('passwords').update(entry.toMap()).eq('id', id);
  }

  static Future<void> delete(String id) async {
    await _client.from('passwords').delete().eq('id', id);
  }
}
