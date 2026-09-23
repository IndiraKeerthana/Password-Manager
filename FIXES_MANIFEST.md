# Password Manager repair package

This package is based on the newly uploaded `password_manager(5).zip`.

## Updated files

- `lib/main.dart` — Supabase `publishableKey` parameter; app starts through the auth/vault gate.
- `lib/screens/auth_gate.dart` — new startup gate restores an existing session and prepares the vault key before opening Home.
- `lib/screens/login_screen.dart` — handles sign-up responses with and without immediate sessions; initializes the vault after authentication.
- `lib/services/encryption_service.dart` — robust local key validation, encrypted-row/key-loss guard, marked AES-GCM payloads, and compatibility with the previous JSON ciphertext format.
- `lib/services/password_service.dart` — encrypted create/update, decrypt-on-fetch, legacy plaintext compatibility, and user-scoped CRUD.
- `lib/screens/details_screen.dart` — cancel-safe edit navigation and delete error handling.
- `lib/screens/settings_screen.dart` — accurately labels the Supabase account password as the login password.
- `test/widget_test.dart` — initializes Supabase for the widget test.
- `test/password_entry_test.dart` — added model mapping tests.
- `README.md` — updated setup, encryption limitations, and troubleshooting.

## New file

- `supabase_setup.sql` — table and RLS policy setup script matching the app's expected schema.

## Key behavior

- New/updated password values are encrypted locally before being sent to Supabase.
- Older plaintext rows remain readable. No bulk migration is performed.
- Earlier encrypted JSON values are still recognized.
- If encrypted records exist but the local key is missing, the app refuses to create a replacement key. This is intentional to avoid making data loss worse.
- Only the password field is encrypted. Other metadata remains plaintext.

## Validation limitation

The Flutter/Dart SDK was not available in this review environment, so `flutter analyze` and `flutter test` could not be executed here. Run both locally after extracting the package:

```bash
flutter pub get
flutter analyze
flutter test
```

For Flutter Web, use a fixed development port to preserve the browser origin and its secure storage:

```bash
flutter run -d chrome --web-port 7357
```

A Supabase `Invalid login credentials` response still requires valid credentials for a user in the Supabase project configured in `lib/main.dart`; source changes cannot bypass Supabase authentication.
