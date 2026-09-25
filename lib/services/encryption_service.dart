import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EncryptionService {
  static final AesGcm _aes = AesGcm.with256bits();

  static final Pbkdf2 _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 210000,
    bits: 256,
  );

  static const String _formatPrefix = 'enc:v2:';
  static const String _verifierPrefix = 'vaultcheck:v1:';
  static const String _verificationText =
      'PasswordManagerVaultVerification';

  static String? _currentUserId;
  static SecretKey? _dek;

  static final ValueNotifier<bool> vaultUnlockedNotifier =
      ValueNotifier<bool>(false);

  static bool get isVaultUnlocked =>
      _dek != null && _currentUserId == _client.auth.currentUser?.id;

  static SupabaseClient get _client =>
      Supabase.instance.client;

  static String get _userId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('Please log in first.');
    }

    return user.id;
  }

  static List<int> _generateRandomBytes(int length) {
    final random = Random.secure();

    return List<int>.generate(
      length,
      (_) => random.nextInt(256),
    );
  }

  static Future<SecretKey> _deriveKek(
    String loginPassword,
    List<int> salt,
  ) async {
    return _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(loginPassword)),
      nonce: salt,
    );
  }

  static Future<String> _wrapDek(
    SecretKey dek,
    SecretKey kek,
  ) async {
    final rawBytes = await dek.extractBytes();

    final secretBox = await _aes.encrypt(
      rawBytes,
      secretKey: kek,
      nonce: _aes.newNonce(),
    );

    final payload = jsonEncode({
      'version': 1,
      'nonce': base64Encode(secretBox.nonce),
      'cipherText': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    });

    return base64Encode(utf8.encode(payload));
  }

  static Future<SecretKey> _unwrapDek(
    String wrappedDek,
    SecretKey kek,
  ) async {
    final payload = jsonDecode(
      utf8.decode(base64Decode(wrappedDek)),
    ) as Map<String, dynamic>;

    final box = SecretBox(
      base64Decode(payload['cipherText'] as String),
      nonce: base64Decode(payload['nonce'] as String),
      mac: Mac(base64Decode(payload['mac'] as String)),
    );

    final clearBytes = await _aes.decrypt(
      box,
      secretKey: kek,
    );

    if (clearBytes.length != 32) {
      throw const FormatException(
        'Invalid un-wrapped DEK length.',
      );
    }

    return SecretKey(clearBytes);
  }

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const String _storageKeyPrefix = 'derived_dek_';

  static String _getStorageKey(String userId) =>
      '$_storageKeyPrefix$userId';

  /// Verifies the DEK against the stored verifier.
  static Future<void> _verifyDek(
    String verifier,
    SecretKey dek,
  ) async {
    if (!verifier.startsWith(_verifierPrefix)) {
      throw StateError(
        'Vault verifier is missing or unsupported.',
      );
    }

    final encodedPayload =
        verifier.substring(_verifierPrefix.length);

    final payload = jsonDecode(
      utf8.decode(base64Decode(encodedPayload)),
    ) as Map<String, dynamic>;

    final box = SecretBox(
      base64Decode(payload['cipherText'] as String),
      nonce: base64Decode(payload['nonce'] as String),
      mac: Mac(base64Decode(payload['mac'] as String)),
    );

    final clearText = await _aes.decrypt(
      box,
      secretKey: dek,
    );

    if (utf8.decode(clearText) != _verificationText) {
      throw StateError('Vault key verification failed.');
    }
  }

  /// Initializes the vault using the Supabase login password.
  ///
  /// Existing vault settings are not modified unless the
  /// candidate encryption key passes verifier validation.
  static Future<void> initializeFromLoginPassword(
    String loginPassword,
  ) async {
    final userId = _userId;

    final settings = await _client
        .from('vault_settings')
        .select('salt, wrapped_dek, verifier')
        .eq('user_id', userId)
        .maybeSingle();

    late SecretKey dek;

    // -----------------------------------------------------
    // CASE 1: No vault settings exist.
    // Create a new vault only if no existing password rows
    // are present. Never silently replace an existing key.
    // -----------------------------------------------------
    if (settings == null) {
      final existingRows = await _client
          .from('passwords')
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      if ((existingRows as List).isNotEmpty) {
        throw StateError(
          'Password records already exist, but vault '
          'settings are missing. No changes were made.',
        );
      }

      final salt = _generateRandomBytes(16);

      dek = SecretKey(_generateRandomBytes(32));

      final kek = await _deriveKek(
        loginPassword,
        salt,
      );

      final wrappedDek = await _wrapDek(dek, kek);

      final verification = await _aes.encrypt(
        utf8.encode(_verificationText),
        secretKey: dek,
        nonce: _aes.newNonce(),
      );

      final verifierPayload = jsonEncode({
        'version': 1,
        'nonce': base64Encode(verification.nonce),
        'cipherText': base64Encode(
          verification.cipherText,
        ),
        'mac': base64Encode(verification.mac.bytes),
      });

      final verifier =
          '$_verifierPrefix'
          '${base64Encode(utf8.encode(verifierPayload))}';

      await _client.from('vault_settings').insert({
        'user_id': userId,
        'salt': base64Encode(salt),
        'wrapped_dek': wrappedDek,
        'verifier': verifier,
      });
    }

    // -----------------------------------------------------
    // CASE 2: Vault settings already exist.
    // Verify the candidate key BEFORE writing wrapped_dek.
    // -----------------------------------------------------
    else {
      final saltValue = settings['salt'] as String?;

      if (saltValue == null || saltValue.isEmpty) {
        throw StateError(
          'Vault salt is missing. No changes were made.',
        );
      }

      final salt = base64Decode(saltValue);

      final kek = await _deriveKek(
        loginPassword,
        salt,
      );

      final storedWrappedDek =
          settings['wrapped_dek'] as String? ?? '';

      final needsWrapping = storedWrappedDek.isEmpty;

      // If wrapped_dek exists, unwrap it.
      // Otherwise, test the legacy login-derived key.
      if (needsWrapping) {
        dek = kek;
      } else {
        dek = await _unwrapDek(
          storedWrappedDek,
          kek,
        );
      }

      final verifier = settings['verifier'] as String?;

      if (verifier == null || verifier.isEmpty) {
        throw StateError(
          'Vault verifier is missing. '
          'No vault settings were changed.',
        );
      }

      // Verify before saving or modifying anything.
      try {
        await _verifyDek(verifier, dek);
      } catch (_) {
        throw StateError(
          'Could not verify the existing vault key. '
          'No vault settings were changed.',
        );
      }

      // Only save wrapped_dek AFTER verification succeeds.
      if (needsWrapping) {
        final wrappedDek = await _wrapDek(dek, kek);

        await _client
            .from('vault_settings')
            .update({
              'wrapped_dek': wrappedDek,
            })
            .eq('user_id', userId);
      }
    }

    // Set active vault state after successful initialization.
    _currentUserId = userId;
    _dek = dek;
    vaultUnlockedNotifier.value = true;

    // Cache DEK in secure storage across all platforms.
    final dekBytes = await dek.extractBytes();

    await _storage.write(
      key: _getStorageKey(userId),
      value: base64Encode(dekBytes),
    );
  }

  /// Restores the cached DEK only if it matches the
  /// currently authenticated user's vault verifier.
  static Future<bool> restoreKeyFromStorage() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      await lockVault();
      return false;
    }

    // Prevent key reuse after switching accounts.
    if (_currentUserId != null &&
        _currentUserId != user.id) {
      await lockVault();
    }

    if (_currentUserId == user.id && _dek != null) {
      return true;
    }

    try {
      final cachedKey = await _storage.read(
        key: _getStorageKey(user.id),
      );

      if (cachedKey == null) {
        return false;
      }

      final keyBytes = base64Decode(cachedKey);

      if (keyBytes.length != 32) {
        return false;
      }

      final candidateDek = SecretKey(keyBytes);

      final settings = await _client
          .from('vault_settings')
          .select('verifier')
          .eq('user_id', user.id)
          .maybeSingle();

      if (settings == null) {
        return false;
      }

      final verifier = settings['verifier'] as String?;

      if (verifier == null || verifier.isEmpty) {
        return false;
      }

      await _verifyDek(verifier, candidateDek);

      _currentUserId = user.id;
      _dek = candidateDek;

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Re-wraps the DEK with a new login password.
  ///
  /// This method should be called only as part of a
  /// coordinated password-change flow.
  static Future<void> rewrapDekWithNewPassword(
    String newPassword,
  ) async {
    final userId = _userId;
    final dek = _dek;

    if (dek == null || _currentUserId != userId) {
      throw StateError(
        'Vault must be active to change login password.',
      );
    }

    final settings = await _client
        .from('vault_settings')
        .select('salt')
        .eq('user_id', userId)
        .maybeSingle();

    if (settings == null) {
      throw StateError('No vault settings found.');
    }

    final salt = base64Decode(
      settings['salt'] as String,
    );

    final newKek = await _deriveKek(
      newPassword,
      salt,
    );

    final newWrappedDek = await _wrapDek(
      dek,
      newKek,
    );

    await _client
        .from('vault_settings')
        .update({
          'wrapped_dek': newWrappedDek,
        })
        .eq('user_id', userId);
  }

  /// Locks the vault in memory without deleting the stored DEK.
  static void lockMemoryVault() {
    _dek = null;
    _currentUserId = null;
    vaultUnlockedNotifier.value = false;
  }

  /// Locks the vault and removes the cached key.
  static Future<void> lockVault() async {
    final userId =
        _client.auth.currentUser?.id ?? _currentUserId;

    _dek = null;
    _currentUserId = null;
    vaultUnlockedNotifier.value = false;

    if (userId != null) {
      try {
        await _storage.delete(
          key: _getStorageKey(userId),
        );
      } catch (_) {
        // Ignore secure storage cleanup failures.
      }
    }
  }

  /// Returns the active encryption key.
  static SecretKey _getKey() {
    final key = _dek;

    if (key == null ||
        _currentUserId != _client.auth.currentUser?.id) {
      throw StateError(
        'Vault is locked. Please log in first.',
      );
    }

    return key;
  }

  @visibleForTesting
  static void setVaultKeyForTesting(SecretKey? key) {
    _dek = key;

    _currentUserId =
        _client.auth.currentUser?.id ?? 'test-user';
  }

  /// Encrypts a password before saving it to Supabase.
  static Future<String> encryptPassword(
    String password,
  ) async {
    final secretBox = await _aes.encrypt(
      utf8.encode(password),
      secretKey: _getKey(),
      nonce: _aes.newNonce(),
    );

    final payload = jsonEncode({
      'version': 2,
      'nonce': base64Encode(secretBox.nonce),
      'cipherText': base64Encode(
        secretBox.cipherText,
      ),
      'mac': base64Encode(secretBox.mac.bytes),
    });

    return '$_formatPrefix'
        '${base64Encode(utf8.encode(payload))}';
  }

  /// Decrypts a password retrieved from Supabase.
  static Future<String> decryptPassword(
    String encryptedPassword,
  ) async {
    try {
      Map<String, dynamic> payload;

      if (encryptedPassword.startsWith(_formatPrefix)) {
        final encodedPayload = encryptedPassword
            .substring(_formatPrefix.length);

        payload = jsonDecode(
          utf8.decode(base64Decode(encodedPayload)),
        ) as Map<String, dynamic>;
      } else if (encryptedPassword.startsWith('enc:v1:')) {
        final encodedPayload = encryptedPassword
            .substring('enc:v1:'.length);

        payload = jsonDecode(
          utf8.decode(base64Decode(encodedPayload)),
        ) as Map<String, dynamic>;
      } else {
        // Legacy JSON format.
        payload = jsonDecode(
          encryptedPassword,
        ) as Map<String, dynamic>;
      }

      final box = SecretBox(
        base64Decode(payload['cipherText'] as String),
        nonce: base64Decode(payload['nonce'] as String),
        mac: Mac(
          base64Decode(payload['mac'] as String),
        ),
      );

      final clearText = await _aes.decrypt(
        box,
        secretKey: _getKey(),
      );

      return utf8.decode(clearText);
    } catch (_) {
      throw StateError(
        'Could not decrypt password. '
        'Check whether the vault is unlocked correctly.',
      );
    }
  }

  /// Detects encrypted formats:
  /// enc:v2:, enc:v1:, or legacy JSON.
  static bool isEncrypted(String value) {
    if (value.startsWith(_formatPrefix)) {
      try {
        final payload = jsonDecode(
          utf8.decode(
            base64Decode(
              value.substring(_formatPrefix.length),
            ),
          ),
        ) as Map<String, dynamic>;

        return payload['nonce'] is String &&
            payload['cipherText'] is String &&
            payload['mac'] is String;
      } catch (_) {
        return false;
      }
    }

    if (value.startsWith('enc:v1:')) {
      try {
        final payload = jsonDecode(
          utf8.decode(
            base64Decode(
              value.substring('enc:v1:'.length),
            ),
          ),
        ) as Map<String, dynamic>;

        return payload['nonce'] is String &&
            payload['cipherText'] is String &&
            payload['mac'] is String;
      } catch (_) {
        return false;
      }
    }

    try {
      final payload = jsonDecode(value)
          as Map<String, dynamic>;

      return payload['nonce'] is String &&
          payload['cipherText'] is String &&
          payload['mac'] is String;
    } catch (_) {
      return false;
    }
  }
}