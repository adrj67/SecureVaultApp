import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class CryptoService {
  /// Deriva una clave AES-256 desde el PIN usando SHA256
  encrypt.Key _deriveKeyFromPin(String pin) {
    final pinBytes = utf8.encode(pin);
    final hash = sha256.convert(pinBytes);
    return encrypt.Key(Uint8List.fromList(hash.bytes));
  }

  /// Genera IV aleatorio de 16 bytes
  encrypt.IV _generateRandomIV() {
    final random = Random.secure();
    final ivBytes = List<int>.generate(16, (_) => random.nextInt(256));
    return encrypt.IV(Uint8List.fromList(ivBytes));
  }

  /// Cifra texto plano usando PIN
  String encryptData(String plainText, String pin) {
    final key = _deriveKeyFromPin(pin);
    final iv = _generateRandomIV();

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );

    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Concatenar IV + ciphertext
    final combined = Uint8List.fromList(
      iv.bytes + encrypted.bytes,
    );

    // Convertir a Base64
    return base64Encode(combined);
  }

  /// Descifra texto Base64 usando PIN
  String decryptData(String encryptedBase64, String pin) {
    try {
      final combinedBytes = base64Decode(encryptedBase64);

      // Extraer IV (primeros 16 bytes)
      final ivBytes = combinedBytes.sublist(0, 16);
      final cipherBytes = combinedBytes.sublist(16);

      final key = _deriveKeyFromPin(pin);
      final iv = encrypt.IV(ivBytes);

      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );

      final decrypted = encrypter.decrypt(
        encrypt.Encrypted(cipherBytes),
        iv: iv,
      );

      return decrypted;
    } catch (e) {
      throw Exception('PIN no válido o datos corruptos');
    }
  }
}