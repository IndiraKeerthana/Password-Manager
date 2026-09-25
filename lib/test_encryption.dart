import 'package:cryptography/cryptography.dart';
import 'services/encryption_service.dart';

Future<void> main() async {
  try {
    // Initialize test encryption key
    final testKey = SecretKey(List<int>.generate(32, (i) => i));
    // ignore: invalid_use_of_visible_for_testing_member
    EncryptionService.setVaultKeyForTesting(testKey);

    const original = 'TestPassword123!';

    // Encrypt
    final encrypted =
        await EncryptionService.encryptPassword(original);

    // Decrypt
    final decrypted =
        await EncryptionService.decryptPassword(encrypted);

    // Verify
    if (original == decrypted && EncryptionService.isEncrypted(encrypted)) {
      // ignore: avoid_print
      print('SUCCESS: Encryption and decryption work!');
    } else {
      // ignore: avoid_print
      print('FAILED: Values do not match or format unrecognized.');
    }
  } catch (e) {
    // ignore: avoid_print
    print('Encryption test failed: $e');
  }
}