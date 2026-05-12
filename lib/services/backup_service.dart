import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import '../main.dart';

class BackupService {
  
  // ==========================
  // COMPARTIR BACKUP
  // ==========================
  Future<bool> shareVault(String encryptedVault) async {
    try {
      // Activa bandera antes de abrir el selector de compartir
      isBackupOperation = true;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/santo_y_sena_backup.json');
      await file.writeAsString(encryptedVault);
      
      final instructionText = '''
🔐 BACKUP DE SANTO Y SEÑA 🔐

Este archivo contiene tus contraseñas encriptadas.

✅ PARA RESTAURAR:
   1. Guarda este archivo donde puedas recuperarlo
   2. En el nuevo teléfono, instala Santo y Seña
   3. Ve a Ajustes → Restaurar Backup
   4. Selecciona este archivo
   5. Ingresa tu PIN

⚠️ SIN TU PIN NO PODRÁS RESTAURAR LAS CONTRASEÑAS

📅 Backup: ${DateTime.now().toLocal()}
''';
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: instructionText,
        subject: 'Backup de Santo y Seña - ${DateTime.now().toLocal()}',
      );
      // Esperar un momento antes de desactivar
      await Future.delayed(const Duration(milliseconds: 500));
      // Desactivamos bandera despues de cerrar el selector
      isBackupOperation = false;
      
      // Limpiar archivo temporal (con delay para asegurar que se completo el share)
      Future.delayed(const Duration(seconds: 5), () async {
        await file.delete();
      });
      
      return true;
    } catch (e) {
      debugPrint("❌ Error al compartir: $e");
      return false;
    }
  }
  
  // ==========================
  // IMPORTAR BACKUP
  // ==========================
  Future<String?> selectBackupFile() async {
    try {
      // ✅ Activar bandera global ANTES de abrir file_picker
      isBackupOperation = true;

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Selecciona el archivo de backup',
        allowedExtensions: ['json'],
        type: FileType.custom,
      );

      // ✅ Desactivar bandera global DESPUÉS de cerrar file_picker
      isBackupOperation = false;
      
      if (result != null && result.files.single.path != null) {
        return result.files.single.path;
      }
      return null;
    } catch (e) {
      isBackupOperation = false;  // Asegurar que se desactive en caso de error
      debugPrint("❌ Error al seleccionar archivo: $e");
      return null;
    }
  }
  
  Future<String?> readBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint("❌ Archivo no existe: $filePath");
        return null;
      }
      
      final content = await file.readAsString();
      debugPrint("✅ Archivo leído: ${content.length} caracteres");
      
      if (content.isEmpty) {
        debugPrint("❌ Archivo vacío");
        return null;
      }
      
      return content;
    } catch (e) {
      debugPrint("❌ Error al leer backup: $e");
      return null;
    }
  }
}