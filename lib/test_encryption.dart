import 'services/encryption_service.dart';

Future<void> main() async {
  try {
    // Initialize encryption key
    await EncryptionService.initializeKey();

    const original = 'TestPassword123!';

    // Encrypt
    final encrypted =
        await EncryptionService.encryptPassword(original);

    print('Encrypted: $encrypted');

    // Decrypt
    final decrypted =
        await EncryptionService.decryptPassword(encrypted);

    print('Decrypted: $decrypted');

    // Verify
    if (original == decrypted) {
      print('SUCCESS: Encryption and decryption work!');
    } else {
      print('FAILED: Values do not match.');
    }
  } catch (e) {
    print('Encryption test failed: $e');
  }
}