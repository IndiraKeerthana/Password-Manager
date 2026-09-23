# Encryption integration notes

## What changed

- `lib/services/encryption_service.dart`: versioned AES-GCM encryption, local per-user key storage, old-format compatibility, and a guard against silently creating a new key when encrypted database rows already exist.
- `lib/services/password_service.dart`: encrypts new/updated password values; decrypts marked ciphertext on fetch; preserves legacy plaintext values; scopes operations to the authenticated user.
- `lib/screens/auth_gate.dart`: initializes the vault key when restoring an existing Supabase session.
- `lib/main.dart`: uses Supabase's `publishableKey` parameter and starts through `AuthGate`.
- `lib/screens/login_screen.dart`: initializes the vault after login and supports immediate-session sign-up versus email-confirmation sign-up.
- `lib/screens/details_screen.dart`: avoids closing the details page when edit is cancelled and handles delete failures.
- `lib/screens/settings_screen.dart`: calls the Supabase credential a login password, rather than implying it changes the encryption key.
- `supabase_setup.sql`: creates the table and RLS policies used by the app.

## Safe test sequence

1. Back up existing database records before testing.
2. Use a test account and dummy credentials.
3. Sign up or log in, add a record, and confirm the `password` column in Supabase contains a value beginning with `enc:v1:`.
4. Confirm the app can fetch and display that record, edit it, and delete it.
5. Do not clear app/browser storage after creating encrypted records. The local key is required to decrypt them.

The `enc:v1:` prefix marks newly encrypted values. Earlier ciphertexts stored as raw JSON are still recognized. Legacy plaintext rows are left as plaintext when fetched; editing one will save its password encrypted.
