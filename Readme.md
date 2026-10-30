# 🔐 Password Manager (Flutter)

A cross-platform password manager built with **Flutter, Dart and
Supabase**. Users can register, log in, unlock a secure vault, and add,
view, edit and delete saved website credentials. Passwords are encrypted
on the device before they are stored in Supabase.

**Course:** CS506PC -- UI Design (Flutter Lab)\
**Student:** Pulla Indira Keerthana\
**College:** Ace Engineering College, Hyderabad\
**Branch / Year:** B.Tech CSE, 3rd Year

------------------------------------------------------------------------

## Project overview

The application demonstrates Flutter UI development through a practical
Password Manager. It includes authentication, credential management,
client-side encryption, secure key storage, theme switching and
automated tests.

## Tech stack

  Area                         Technology
  ---------------------------- ---------------------------
  UI framework                 Flutter
  Language                     Dart
  Backend and authentication   Supabase
  Encryption                   `cryptography`, `encrypt`
  Local preferences            `shared_preferences`
  Secure storage               `flutter_secure_storage`
  Testing                      `flutter_test`

------------------------------------------------------------------------

# Syllabus Experiments -- Code and Outputs

The experiment numbers and names below follow the lab syllabus. Code
samples are shortened extracts from the project source files. The output
descriptions explain what the application displays or what the command
produces; they are not claims that a fresh run was performed in this
documentation step.

## Experiment 1(a): Install Flutter and Dart SDK

**Aim:** To install and configure Flutter and Dart SDK for application
development.

**Commands:**

``` bash
flutter --version
dart --version
flutter doctor
```

**Output:** - Flutter and Dart version information is displayed. -
`flutter doctor` checks the development environment and reports the
status of required tools.

**Project files:** `pubspec.yaml`, `lib/main.dart`

## Experiment 1(b): Write a simple Dart program to understand language basics

**Aim:** To understand the Dart entry point, variables, functions,
asynchronous programming and classes.

**Code -- `lib/main.dart`:**

``` dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
  );

  await loadSavedThemeMode();
  runApp(const PasswordManagerApp());
}
```

**Concepts used:** `main()`, `Future<void>`, `async`, `await`, constants
and class-based widgets.

**Output:** The Flutter application starts, initializes Supabase, loads
the saved theme preference and displays the Password Manager interface.

## Experiment 2(a): Explore various Flutter widgets (Text, Image, Container, etc.)

**Aim:** To explore and use basic Flutter widgets to build the
application interface.

**Code -- `lib/widgets/password_card.dart`:**

``` dart
return Card(
  child: ListTile(
    leading: CircleAvatar(
      child: Text(entry.title[0].toUpperCase()),
    ),
    title: Text(entry.title),
    subtitle: Text(entry.username),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  ),
);
```

**Widgets used:** `Card`, `ListTile`, `CircleAvatar`, `Text`, `Icon`.

**Output:** Each saved account is displayed as a card with its
website/app name, username and navigation icon.

## Experiment 2(b): Implement different layout structures using Row, Column, and Stack widgets

**Aim:** To arrange UI elements using Flutter layout widgets.

**Code -- `lib/screens/details_screen.dart`:**

``` dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      children: [
        CircleAvatar(child: Text(entry.title[0])),
        const SizedBox(width: 16),
        Expanded(child: Text(entry.title)),
      ],
    ),
    const SizedBox(height: 20),
    Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _detailRow('Username', entry.username),
          ],
        ),
      ),
    ),
  ],
)
```

**Output:** The details screen displays the account icon and title in a
horizontal row, followed by account information arranged vertically.

**Note:** A `Stack` is not used in this extracted implementation.

## Experiment 3(a): Design a responsive UI that adapts to different screen sizes

**Aim:** To make the application usable on screens with different
available heights and widths.

**Code -- `lib/screens/add_password_screen.dart`:**

``` dart
body: SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: Column(
    children: [
      // Input fields and Save button
    ],
  ),
)
```

**Output:** The form can scroll vertically when its contents do not fit
in the available screen height.

**Implementation status:** Scrollable layouts are present. A dedicated
tablet/laptop layout with width-based breakpoints was not found in the
inspected source.

## Experiment 3(b): Implement media queries and breakpoints for responsiveness

**Aim:** To use screen dimensions and breakpoints to change the layout
for mobile, tablet and desktop.

**Flutter syntax:**

``` dart
final screenWidth = MediaQuery.of(context).size.width;

if (screenWidth >= 600) {
  // Tablet or wider layout
} else {
  // Mobile layout
}
```

**Output:** When implemented, the UI can select a different layout
depending on the screen width.

**Implementation status:** The above is the Flutter syntax for this
syllabus concept, not an existing code extract from this repository.
`MediaQuery`, `LayoutBuilder` and explicit breakpoints were not found in
the inspected project source.

## Experiment 4(a): Set up navigation between different screens using Navigator

**Aim:** To navigate between screens using Flutter Navigator.

**Code -- `lib/screens/home_screen.dart`:**

``` dart
await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const AddPasswordScreen(),
  ),
);
```

**Output:** Tapping the add-password action opens the Add Account
screen. The user can return to the previous screen after saving or
cancelling.

## Experiment 4(b): Implement navigation with named routes

**Aim:** To navigate between screens using named routes.

**Flutter syntax:**

``` dart
MaterialApp(
  routes: {
    '/login': (context) => const LoginScreen(),
    '/home': (context) => const HomeScreen(),
  },
);

// Navigate using:
Navigator.pushNamed(context, '/home');
```

**Output:** When implemented, the application opens the screen
registered with the requested route name.

**Implementation status:** The inspected project uses `Navigator.push`
with `MaterialPageRoute` and a global `navigatorKey`. A
`MaterialApp(routes: ...)` named-route table and `pushNamed` calls were
not found.

## Experiment 5(a): Learn about stateful and stateless widgets

**Aim:** To understand widgets with mutable state and widgets that
display data without managing local mutable state.

**Code -- Stateful widget, `lib/screens/login_screen.dart`:**

``` dart
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
}
```

**Code -- Stateless widget, `lib/widgets/password_card.dart`:**

``` dart
class PasswordCard extends StatelessWidget {
  final PasswordEntry entry;
  final VoidCallback onTap;

  const PasswordCard({
    super.key,
    required this.entry,
    required this.onTap,
  });
}
```

**Output:** Stateful screens can update their UI when values change.
Password cards display the supplied account details without maintaining
their own mutable state.

## Experiment 5(b): Implement state management using setState and Provider

**Aim:** To update the UI when application state changes.

**Code -- `lib/screens/login_screen.dart`:**

``` dart
setState(() {
  _obscurePassword = !_obscurePassword;
});
```

**Code -- `lib/main.dart`:**

``` dart
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.light);

ValueListenableBuilder<ThemeMode>(
  valueListenable: themeModeNotifier,
  builder: (context, mode, _) {
    return MaterialApp(
      themeMode: mode,
      // Theme configuration
    );
  },
)
```

**Output:** Tapping the password visibility icon shows or hides the
password. Changing the Dark Mode switch updates the application theme.

**Implementation status:** The project uses `setState`, `ValueNotifier`
and `ValueListenableBuilder`. Provider/`ChangeNotifier` is not present
in the inspected dependencies or source files.

## Experiment 6(a): Create custom widgets for specific UI elements

**Aim:** To create reusable widgets for the application interface.

**Code -- `lib/widgets/password_card.dart`:**

``` dart
class PasswordCard extends StatelessWidget {
  final PasswordEntry entry;
  final VoidCallback onTap;

  const PasswordCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(entry.title),
        subtitle: Text(entry.username),
        onTap: onTap,
      ),
    );
  }
}
```

**Output:** A reusable password card is displayed for each saved account
in the vault.

## Experiment 6(b): Apply styling using themes and custom styles

**Aim:** To apply a consistent theme and styling to the application.

**Code -- `lib/main.dart`:**

``` dart
ThemeData _buildTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
  );
}
```

**Output:** The application uses a Material 3 indigo-based theme. Light
and dark themes are selected through the Settings screen.

## Experiment 7(a): Design a form with various input fields

**Aim:** To create input fields to collect website and account
information.

**Code -- `lib/screens/add_password_screen.dart`:**

``` dart
Column(
  children: [
    TextField(
      controller: _websiteController,
      decoration: const InputDecoration(
        labelText: 'Website / App',
      ),
    ),
    TextField(
      controller: _usernameController,
      decoration: const InputDecoration(
        labelText: 'Username / Email',
      ),
    ),
    TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: const InputDecoration(
        labelText: 'Password',
      ),
    ),
    TextField(
      controller: _notesController,
      maxLines: 3,
      decoration: const InputDecoration(labelText: 'Notes'),
    ),
  ],
)
```

**Output:** The Add Account screen displays fields for website/app,
username/email, password and notes.

## Experiment 7(b): Implement form validation and error handling

**Aim:** To validate user input and display errors for invalid or
missing data.

**Code -- `lib/screens/add_password_screen.dart`:**

``` dart
if (website.isEmpty || username.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Website and username are required'),
    ),
  );
  return;
}
```

**Output:** If the website or username is empty, an error message
appears and the account is not saved. Save failures are also displayed
using a SnackBar.

**Implementation note:** This project performs manual validation with an
`if` condition and SnackBar. A Flutter `Form`, `GlobalKey<FormState>`
and `TextFormField.validator` implementation was not found in the
inspected screen.

## Experiment 8(a): Add animations to UI elements using Flutter's animation framework

**Aim:** To add motion and transitions to UI elements using Flutter
animations.

**Flutter syntax:**

``` dart
AnimatedOpacity(
  opacity: isVisible ? 1.0 : 0.0,
  duration: const Duration(milliseconds: 300),
  child: const Text('Password saved'),
)
```

**Output:** When implemented, the message gradually appears or
disappears.

**Implementation status:** No explicit Flutter animation widget or
animation controller was found in the inspected application source.

## Experiment 8(b): Experiment with different types of animations (fade, slide, etc.)

**Aim:** To understand fade and slide animations in Flutter.

**Flutter syntax -- Fade transition:**

``` dart
FadeTransition(
  opacity: animation,
  child: const Text('Welcome'),
)
```

**Flutter syntax -- Slide transition:**

``` dart
SlideTransition(
  position: animation,
  child: const Icon(Icons.lock),
)
```

**Output:** When implemented, the text fades into view and the lock icon
slides into position.

**Implementation status:** These are reference syntax examples for the
syllabus; they are not currently implemented in the inspected project
files.

## Experiment 9(a): Fetch data from a REST API

**Aim:** To fetch saved password records from the backend.

**Code -- `lib/services/password_service.dart`:**

``` dart
static Future<List<PasswordEntry>> fetchAll() async {
  final response = await _client
      .from('passwords')
      .select()
      .eq('user_id', _userId)
      .order('created_at', ascending: false);

  // Convert the returned records into PasswordEntry objects.
}
```

**Output:** The application retrieves the signed-in user's password
records from the Supabase `passwords` table, ordered by creation date.

## Experiment 9(b): Display the fetched data in a meaningful way in the UI

**Aim:** To display backend records in the application interface.

**Code -- `lib/screens/home_screen.dart`:**

``` dart
final entries = await PasswordService.fetchAll();

if (!mounted || !EncryptionService.isVaultUnlocked) return;

setState(() {
  _entries = entries;
  _loading = false;
});
```

**Output:** After fetching, saved accounts are displayed in the vault as
website/account cards. A loading indicator is shown while data is being
fetched, and an empty-state message is displayed when there are no saved
passwords.

## Experiment 10(a): Write unit tests for UI components

**Aim:** To test application widgets and model behaviour.

**Code -- `test/widget_test.dart`:**

``` dart
testWidgets(
  'App displays the login screen without a session',
  (WidgetTester tester) async {
    await tester.pumpWidget(const PasswordManagerApp());
    await tester.pump();

    expect(find.byType(Scaffold), findsWidgets);
    expect(find.text('Password Manager'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  },
);
```

**Run command:**

``` bash
flutter test
```

**Output:** Flutter Test runs the widget and unit tests and reports
passed or failed test cases in the terminal.

## Experiment 10(b): Use Flutter's debugging tools to identify and fix issues

**Aim:** To inspect the widget tree, monitor errors and debug the
application.

**Commands:**

``` bash
flutter analyze
flutter run
flutter test
```

**Tools used:** Flutter DevTools, Widget Inspector, Debug Console and
Flutter terminal output.

**Output:** Static analysis reports code issues, the debug console
displays runtime messages and errors, and the Widget Inspector helps
inspect the widget hierarchy.

------------------------------------------------------------------------

## Implementation coverage note

The following concepts are represented by actual code in the inspected
repository: Flutter/Dart setup, basic Dart entry point, Material
widgets, Row/Column layouts, Navigator-based navigation, Stateful and
Stateless widgets, `setState`, `ValueNotifier`, custom widgets, themes,
text input, manual validation, Supabase data fetching, UI data display
and automated tests.

The following syllabus concepts were **not found as implemented
features** in the inspected source: explicit media-query breakpoints,
named routes, Provider/`ChangeNotifier`, Flutter `Form` validators, and
explicit fade/slide animations. Reference syntax is included in the
relevant experiments so the syllabus topics are documented without
misrepresenting the current project.

## How to run the project

**Prerequisites:** Flutter SDK, Dart SDK and a configured Supabase
project.

``` bash
# Clone the repository
git clone https://github.com/IndiraKeerthana/Password-Manager.git
cd Password-Manager

# Install packages
flutter pub get

# Run on a connected device or emulator
flutter run

# Run in Chrome (if web support is configured)
flutter run -d chrome

# Run tests and static analysis
flutter test
flutter analyze
```

The Supabase URL and publishable key are configured in `lib/main.dart`.
The database setup and migration scripts are available in
`supabase_setup.sql`, `supabase_envelope_migration.sql` and
`supabase_envelope_migration_rollback.sql`. Configure the Supabase
database and authentication before testing account and vault operations.

## Project structure

``` text
lib/
  main.dart
  models/
  screens/
  services/
  utils/
  widgets/
test/
  change_master_key_test.dart
  password_entry_test.dart
  vault_lifecycle_test.dart
  widget_test.dart
Project Documents/
supabase_setup.sql
supabase_envelope_migration.sql
```

## Screenshots

**Responsive design -- mobile, tablet and laptop views**

`<img width="1080" alt="Password Manager responsive screens" src="https://github.com/user-attachments/assets/3d64ff90-142e-4be9-a437-127c250fc8c2" />`{=html}

**App flow -- login, vault and add-account form**

`<img width="750" alt="Password Manager app flow" src="https://github.com/user-attachments/assets/46b917e3-e531-4b87-86a4-6b3bdf68bcfa" />`{=html}

## Security

-   Passwords are encrypted on the device before being stored.
-   Encryption keys are cached using secure storage.
-   The vault can be locked when the application moves to the
    background.
-   Encryption implementation notes are available in
    `ENCRYPTION_SETUP_NOTES.md`.

## License

For academic use as part of CS506PC -- UI Design (Flutter Lab).
