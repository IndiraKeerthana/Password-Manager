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

// Starts empty — entries are added dynamically from the Add Password screen.
List<PasswordEntry> sampleEntries = [];
