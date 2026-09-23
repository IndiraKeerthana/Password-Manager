import 'package:flutter_test/flutter_test.dart';
import 'package:password_manager/models/password_entry.dart';

void main() {
  test('PasswordEntry maps database fields correctly', () {
    final entry = PasswordEntry.fromMap({
      'id': 'entry-id',
      'title': 'Example',
      'username': 'user@example.com',
      'password': 'dummy-password',
      'website': 'example.com',
      'notes': 'test note',
    });

    expect(entry.id, 'entry-id');
    expect(entry.title, 'Example');
    expect(entry.username, 'user@example.com');
    expect(entry.password, 'dummy-password');
    expect(entry.website, 'example.com');
    expect(entry.notes, 'test note');
  });

  test('PasswordEntry toMap omits database-generated id', () {
    final entry = PasswordEntry(
      id: 'entry-id',
      title: 'Example',
      username: 'test-user',
      password: 'dummy-password',
      website: 'example.com',
      notes: '',
    );

    final map = entry.toMap();
    expect(map.containsKey('id'), isFalse);
    expect(map['title'], 'Example');
    expect(map['password'], 'dummy-password');
  });
}
