# Password Manager — Flutter + Supabase

A Flutter password manager with a real Supabase backend: user authentication, per-user cloud storage, and a light/dark themed UI. Started as a UI prototype and has since been wired up to real auth and a live database.

## Features

- Real authentication — sign up, log in, log out (Supabase Auth)
- Password list / home screen with live search
- Add, edit, and delete password entries — persisted to Supabase
- Password details screen with visibility toggle
- Settings: change master password, security (sign out of all devices)
- Light/dark theme toggle, persisted across restarts
- Row-level security — each user can only read or edit their own passwords

## Technology

Flutter, Dart, Supabase (Auth + Postgres database), Material Design 3, Android SDK, Git, and GitHub.

## Project Structure

lib/
main.dart
models/
screens/
services/
utils/
widgets/


## How to Run

1. Install Flutter and Android SDK.
2. Clone the repository.
3. Create a Supabase project and run the SQL in `supabase_setup.sql` (creates the `passwords` table and its security policies).
4. Add your Supabase Project URL and anon/publishable key to `lib/main.dart`.
5. Run `flutter pub get`.
6. Start an Android emulator or connect a device.
7. Run `flutter run`.

## Important Note

This app stores real account data in a live Supabase backend, protected by row-level security so users can only access their own entries. Passwords are currently stored as plain text in the database (not client-side encrypted) — this is a portfolio/learning project, not a production-ready secure password manager.

## Future Enhancements

- Client-side encryption of stored passwords
- Biometric authentication
- Secure password generator
- Password strength analysis
- Encrypted backup and restore