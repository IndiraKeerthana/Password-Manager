import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/password_entry.dart';
import 'encryption_service.dart';

class PasswordService {
  static SupabaseClient get _client => Supabase.instance.client;

  static String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Please log in before accessing your passwords.');
    }
    return user.id;
  }

  /// Fetches the signed-in user's records. Legacy plaintext values are left
  /// readable; encrypted values are decrypted locally.
  static Future<List<PasswordEntry>> fetchAll() async {
    final response = await _client
        .from('passwords')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    final entries = <PasswordEntry>[];
    for (final item in response) {
      final row = Map<String, dynamic>.from(item as Map);
      final storedPassword = row['password'] as String? ?? '';

      if (EncryptionService.isEncrypted(storedPassword)) {
        row['password'] =
            await EncryptionService.decryptPassword(storedPassword);
      }
      entries.add(PasswordEntry.fromMap(row));
    }
    return entries;
  }

  static Future<void> add(PasswordEntry entry) async {
    final userId = _userId;
    final data = entry.toMap();
    data['password'] =
        await EncryptionService.encryptPassword(entry.password);
    data['user_id'] = userId;
    await _client.from('passwords').insert(data);
  }

  static Future<void> update(PasswordEntry entry) async {
    final userId = _userId;
    final data = entry.toMap();
    data['password'] =
        await EncryptionService.encryptPassword(entry.password);

    await _client
        .from('passwords')
        .update(data)
        .eq('id', entry.id)
        .eq('user_id', userId);
  }

  static Future<void> delete(String id) async {
    await _client
        .from('passwords')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
