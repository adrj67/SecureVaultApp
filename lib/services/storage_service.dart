import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageService {
  static const String _fileName = 'vault.json';

  // Obtiene la ruta del archivo del vault
  Future<File> _getVaultFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$_fileName';
    return File(filePath);
  }

  // Verifica si el vault existe
  Future<bool> exists() async {
    final file = await _getVaultFile();
    return await file.exists();
  }

  // Guarda datos cifrados en el vault
  Future<void> saveEncryptedData(String encryptedData) async {
    final file = await _getVaultFile();

    if (!await file.exists()) {
      await file.create(recursive: true);
    }

    await file.writeAsString(
      encryptedData,
      flush: true,
    );
  }

  // Lee datos cifrados del vault
  Future<String?> readEncryptedData() async {
    final file = await _getVaultFile();

    if (!await file.exists()) {
      return null;
    }

    final content = await file.readAsString();

    if (content.isEmpty) {
      return null;
    }

    return content;
  }

  // Borra completamente el vault
  Future<void> deleteVault() async {
    final file = await _getVaultFile();

    if (await file.exists()) {
      await file.delete();
    }
  }
}