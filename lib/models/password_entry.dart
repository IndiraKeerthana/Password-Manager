class PasswordEntry {
  final String id;
  final String title;
  final String username;
  final String password;
  final String website;
  final String notes;

  PasswordEntry({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    this.website = '',
    this.notes = '',
  });

  factory PasswordEntry.fromMap(Map<String, dynamic> map) {
    return PasswordEntry(
      id: map['id'] as String,
      title: map['title'] as String,
      username: map['username'] as String,
      password: map['password'] as String,
      website: map['website'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'username': username,
      'password': password,
      'website': website,
      'notes': notes,
    };
  }
}
