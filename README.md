# 🔐 Password Manager (Flutter)

A secure, cross-platform password manager built with **Flutter** and **Supabase**. Passwords are encrypted on the device before being stored, so the server never sees them in plain text.

**Course:** CS506PC – UI Design (Flutter Lab)
**Student:** Pulla Indira Keerthana
**College:** Ace Engineering College, Hyderabad
**Branch / Year:** B.Tech CSE, 3rd Year

---

## 📌 Project Description

This app lets a user register, log in, and store website/app credentials in an encrypted vault. It uses envelope encryption (see `ENCRYPTION_SETUP_NOTES.md`) with keys held in secure storage, and Supabase as the backend for authentication and data.

The project was built to demonstrate all 10 prescribed lab experiments in a real application.

---

## ✨ Features

- User sign up / login (Supabase Auth)
- Add, view, edit and delete saved credentials
- Client-side encryption of stored passwords (`encrypt`, `cryptography`)
- Secure key storage (`flutter_secure_storage`)
- Form validation with clear error messages
- Light/dark theme support <!-- TODO: keep only if implemented -->
- Responsive layout for mobile, tablet and laptop <!-- TODO: keep only if implemented -->
- Animated screen transitions and UI elements <!-- TODO: keep only if implemented -->
- Unit and widget tests

---

## 🧰 Tech Stack

| Area | Technology |
|------|-----------|
| Framework | Flutter (Dart SDK ^3.13.3) |
| Backend | Supabase (`supabase_flutter`) |
| Encryption | `encrypt`, `cryptography` |
| Secure storage | `flutter_secure_storage`, `shared_preferences` |
| State management | `setState` + Provider <!-- TODO: confirm after adding provider --> |
| Testing | `flutter_test` |

---

## 🗺️ Syllabus Concept Mapping

Each row maps a lab experiment to where it is used in this project.
*(Fill in the exact file names before submitting.)*

| Exp. | Concept | Where it is used in this project | Source file(s) |
|------|---------|----------------------------------|----------------|
| 1 | Flutter & Dart SDK setup, Dart basics | Project built on Flutter SDK; Dart classes, models, async/await used throughout | `lib/main.dart`, `lib/models/...` |
| 2 | Widgets and layouts (Text, Image, Container, Row, Column, Stack) | Login screen, vault list, credential cards | `lib/screens/...` |
| 3 | Responsive UI, MediaQuery, breakpoints | Layout adapts across mobile, tablet and laptop widths | `lib/...` |
| 4 | Navigation, named routes | Login → Vault → Add/Edit credential, using `Navigator` and named routes | `lib/main.dart`, `lib/screens/...` |
| 5 | Stateful/stateless widgets, setState, Provider | Vault list and auth state managed with Provider; local UI state with `setState` | `lib/providers/...`, `lib/screens/...` |
| 6 | Custom widgets, themes and styling | Reusable input fields, buttons and credential cards; central `ThemeData` | `lib/widgets/...`, `lib/theme/...` |
| 7 | Forms, validation, error handling | Login/register/add-credential forms with validators and error messages | `lib/screens/...` |
| 8 | Animations (fade, slide) | Animated transitions on screens/cards | `lib/...` |
| 9 | REST API fetch and display | Supabase REST calls to load/save credentials; <!-- TODO: add external REST API if added --> | `lib/services/...` |
| 10 | Unit/widget tests, debugging tools | Tests in `test/`; DevTools used to debug issues | `test/...` |

---

## 🔍 Implementation Details

### 1. Setup & Dart Basics
- Flutter and Dart SDK installed; verified with `flutter doctor`.
- Dart concepts used: classes, null safety, `async/await`, `Future`s, collections.

### 2. Widgets & Layouts
- Used `Text`, `Image`, `Container`, `Icon`, `ListView`, `Card`.
- Layouts built with `Row`, `Column` and `Stack`.

### 3. Responsive Design
- Uses `MediaQuery` / `LayoutBuilder` with breakpoints to change layout.

### 4. Navigation
- `Navigator.push` / `pop` between screens.
- Named routes defined in `MaterialApp(routes: {...})`.

### 5. State Management
- **Stateless widgets** for static UI (labels, cards).
- **Stateful widgets** with `setState` for local UI (e.g., show/hide password).
- **Provider** with `ChangeNotifier` for shared app state.

### 6. Custom Widgets & Themes
- Reusable custom widgets for text fields, buttons and credential tiles.
- App-wide `ThemeData` for colors, typography and component styling.

### 7. Forms & Validation
- `Form` with `GlobalKey<FormState>` and `TextFormField` validators.
- Validation covers: empty fields, email format, password rules.
- Errors from Supabase (wrong credentials, network failure) shown to the user.

### 8. Animations
- Implicit/explicit animations such as `AnimatedContainer`, `FadeTransition`, `SlideTransition`.

### 9. REST API Integration
- Supabase exposes a REST API; the app fetches the user's saved credentials and displays them in a list.
- Loading and error states are handled in the UI.

### 10. Testing & Debugging
- Widget/unit tests in the `test/` folder, run with:

```bash
flutter test
```

- Flutter DevTools (inspector, debugger, console) used to find and fix UI and logic issues.

---

## 🔒 Security Notes

- Passwords are encrypted on the device before upload.
- Encryption keys are kept in secure storage, not in plain preferences.
- Details: [`ENCRYPTION_SETUP_NOTES.md`](ENCRYPTION_SETUP_NOTES.md)
- Database migration scripts: `supabase_setup.sql`, `supabase_envelope_migration.sql` (and rollback).

---

## 🚀 How to Run

### Prerequisites
- Flutter SDK installed (`flutter --version`)
- A Supabase project

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/IndiraKeerthana/Password-Manager.git
cd Password-Manager

# 2. Install dependencies
flutter pub get

# 3. Set up the database
#    Run supabase_setup.sql (then supabase_envelope_migration.sql)
#    in the Supabase SQL editor.

# 4. Add your Supabase URL and anon key
#    (TODO: state exactly where, e.g. lib/main.dart or an env file)

# 5. Run the app
flutter run            # mobile / emulator
flutter run -d chrome  # web
```

### Run tests

```bash
flutter test
```

---

## 📂 Project Structure

```
lib/            Application source code
test/           Unit and widget tests
android/ ios/ web/ windows/ linux/ macos/   Platform folders
Project Documents/                          Project documentation
supabase_*.sql                              Database setup and migrations
```
*(Update the `lib/` section with your actual subfolders.)*

---

## 🕒 Development Progress

Development is tracked through commits in this repository, covering project setup, authentication, encryption, UI screens, state management, validation, animations and testing. See the [commit history](https://github.com/IndiraKeerthana/Password-Manager/commits/main).

---

## 🖼️ Screenshots

**1. Responsive design – mobile, tablet and laptop views**

<img width="1080" height="2260" alt="image" src="https://github.com/user-attachments/assets/3d64ff90-142e-4be9-a437-127c250fc8c2" />


**2. App flow – login, vault, add-credential form with validation error**

<img width="750" height="1600" alt="image" src="https://github.com/user-attachments/assets/46b917e3-e531-4b87-86a4-6b3bdf68bcfa" />


---

## 📄 License

For academic use as part of CS506PC – UI Design (Flutter Lab).
