import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Local AES-GCM encryption for password values.
///
/// The encryption key is stored on this device/browser, separately for each
/// Supabase user. It is NOT synced or recoverable from Supabase. Losing this
/// key makes previously encrypted values unrecoverable.
class EncryptionService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final AesGcm _algorithm = AesGcm.with256bits();
  static const String _keyPrefix = 'vault_encryption_key_';
  static const String _formatPrefix = 'enc:v1:';

  static SupabaseClient get _client => Supabase.instance.client;

  static String get _userId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('You must be logged in to access the password vault.');
    }
    return user.id;
  }

  static String _storageKey(String userId) => '$_keyPrefix$userId';

  static Future<List<int>> _generateKeyBytes() async {
    final random = Random.secure();
    return List<int>.generate(32, (_) => random.nextInt(256));
  }

  /// Ensures the current user has a local key.
  ///
  /// If the key is missing, checks the user's existing rows first. A vault
  /// containing encrypted rows must not silently receive a new key, because
  /// that would make those rows undecryptable. Legacy plaintext rows remain
  /// readable and can be migrated gradually.
  static Future<void> initializeKey() async {
    final userId = _userId;
    final keyName = _storageKey(userId);
    final storedKey = await _storage.read(key: keyName);

    if (storedKey != null) {
      _decodeAndValidateKey(storedKey);
      return;
    }

    final rows = await _client
        .from('passwords')
        .select('password')
        .eq('user_id', userId);

    final hasEncryptedRows = (rows as List).any((row) {
      final value = (row as Map<String, dynamic>)['password'];
      return value is String && isEncrypted(value);
    });

    if (hasEncryptedRows) {
      throw StateError(
        'This vault contains encrypted passwords, but its local encryption '
        'key is missing. Do not create a new key or overwrite these records. '
        'Use the original device/browser where the vault was created.',
      );
    }

    final keyBytes = await _generateKeyBytes();
    await _storage.write(
      key: keyName,
      value: base64Encode(keyBytes),
    );
  }

  static List<int> _decodeAndValidateKey(String encodedKey) {
    try {
      final bytes = base64Decode(encodedKey);
      if (bytes.length != 32) {
        throw const FormatException('Incorrect AES-256 key length.');
      }
      return bytes;
    } catch (_) {
      throw StateError(
        'The locally stored encryption key is invalid. '
        'Do not clear storage if you need existing encrypted passwords.',
      );
    }
  }

  static Future<SecretKey> _getKey() async {
    final storedKey = await _storage.read(key: _storageKey(_userId));
    if (storedKey == null) {
      throw StateError(
        'Encryption key is missing. Sign in on the device/browser where '
        'this vault was initialized.',
      );
    }
    return SecretKey(_decodeAndValidateKey(storedKey));
  }

  /// Encrypts plain text and returns a versioned, explicitly marked value.
  static Future<String> encryptText(String plainText) async {
    final key = await _getKey();
    final secretBox = await _algorithm.encrypt(
      utf8.encode(plainText),
      secretKey: key,
      nonce: _algorithm.newNonce(),
    );

    final payload = <String, dynamic>{
      'version': 1,
      'nonce': base64Encode(secretBox.nonce),
      'cipherText': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };
    return '$_formatPrefix${base64Encode(utf8.encode(jsonEncode(payload)))}';
  }

  /// Decrypts newly marked values and legacy JSON-format AES-GCM values.
  static Future<String> decryptText(String encryptedText) async {
    final String jsonPayload;
    if (encryptedText.startsWith(_formatPrefix)) {
      try {
        jsonPayload = utf8.decode(
          base64Decode(encryptedText.substring(_formatPrefix.length)),
        );
      } catch (_) {
        throw const FormatException('Invalid encrypted password payload.');
      }
    } else {
      // Backward compatibility for encrypted values produced by the previous
      // app version, which stored the JSON object directly.
      jsonPayload = encryptedText;
    }

    final Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(jsonPayload);
      if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
        throw const FormatException();
      }
      payload = decoded;
    } catch (_) {
      throw const FormatException('Invalid encrypted password format.');
    }

    try {
      final nonce = base64Decode(payload['nonce'] as String);
      final cipherText = base64Decode(payload['cipherText'] as String);
      final macBytes = base64Decode(payload['mac'] as String);
      if (nonce.length != 12 || macBytes.length != 16) {
        throw const FormatException('Invalid AES-GCM parameters.');
      }

      final box = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      );
      final clearBytes = await _algorithm.decrypt(
        box,
        secretKey: await _getKey(),
      );
      return utf8.decode(clearBytes);
    } catch (_) {
      throw StateError(
        'Could not decrypt a saved password. The local key may not match '
        'the key used to encrypt this record. The saved value was not changed.',
      );
    }
  }

  static Future<String> encryptPassword(String password) => encryptText(password);

  static Future<String> decryptPassword(String encryptedPassword) =>
      decryptText(encryptedPassword);

  /// Format detection only; it does not prove the current device has the key.
  static bool isEncrypted(String value) {
    try {
      final String jsonPayload;
      if (value.startsWith(_formatPrefix)) {
        jsonPayload = utf8.decode(
          base64Decode(value.substring(_formatPrefix.length)),
        );
      } else {
        jsonPayload = value;
      }

      final decoded = jsonDecode(jsonPayload);
      if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
        return false;
      }
      if (decoded['nonce'] is! String ||
          decoded['cipherText'] is! String ||
          decoded['mac'] is! String) {
        return false;
      }
      return base64Decode(decoded['nonce'] as String).length == 12 &&
          base64Decode(decoded['mac'] as String).length == 16;
    } catch (_) {
      return false;
    }
  }
}
