import 'dart:io';

import 'package:path_provider/path_provider.dart';

class StorageService {
  static const String _fileName = 'vault.json';

  /// Obtiene el archivo del vault
  Future<File> _getVaultFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$_fileName';
    return File(filePath);
  }

  /// Verifica si el archivo existe
  Future<bool> exists() async {
    final file = await _getVaultFile();
    return file.exists();
  }

  /// Guarda contenido cifrado en el archivo
  Future<void> saveEncryptedData(String encryptedData) async {
    final file = await _getVaultFile();
    await file.writeAsString(encryptedData, flush: true);
  }

  /// Lee contenido cifrado del archivo
  Future<String?> readEncryptedData() async {
    final file = await _getVaultFile();

    if (!await file.exists()) {
      return null;
    }

    return file.readAsString();
  }
}