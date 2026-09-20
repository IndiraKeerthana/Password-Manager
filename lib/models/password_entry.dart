class PasswordEntry {
  final String title;
  final String username;
  final String password;
  final String website;
  final String notes;

  PasswordEntry({
    required this.title,
    required this.username,
    required this.password,
    this.website = '',
    this.notes = '',
  });
}

List<PasswordEntry> sampleEntries = [
  PasswordEntry(
    title: 'Gmail',
    username: 'nitya@gmail.com',
    password: 'Str0ngP@ss1',
    website: 'gmail.com',
    notes: 'Personal email',
  ),
  PasswordEntry(
    title: 'GitHub',
    username: 'nitya-dev',
    password: 'C0deSecure!22',
    website: 'github.com',
    notes: 'Work account',
  ),
  PasswordEntry(
    title: 'Netflix',
    username: 'nitya@gmail.com',
    password: 'Watch1t@Night',
    website: 'netflix.com',
    notes: '',
  ),
];
