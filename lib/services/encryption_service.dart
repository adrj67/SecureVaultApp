import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class EncryptionService {

  /// Deriva una clave desde el PIN usando PBKDF2 simplificado
  String deriveKey(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Genera un salt aleatorio
  String generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(values);
  }

  /// Cifra datos (implementación simplificada para el proyecto)
  String encrypt(String plainText, String key) {
    final plainBytes = utf8.encode(plainText);
    final keyBytes = utf8.encode(key);

    final encrypted = List<int>.generate(
      plainBytes.length,
      (i) => plainBytes[i] ^ keyBytes[i % keyBytes.length],
    );

    return base64Encode(encrypted);
  }

  /// Descifra datos
  String decrypt(String encryptedText, String key) {
    final encryptedBytes = base64Decode(encryptedText);
    final keyBytes = utf8.encode(key);

    final decrypted = List<int>.generate(
      encryptedBytes.length,
      (i) => encryptedBytes[i] ^ keyBytes[i % keyBytes.length],
    );

    return utf8.decode(decrypted);
  }
}