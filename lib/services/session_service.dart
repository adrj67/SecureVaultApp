import 'dart:convert';

import '../models/vault.dart';
import 'crypto_service.dart';
import 'storage_service.dart';

class SessionService {
  final CryptoService _cryptoService;
  final StorageService _storageService;

  String? _pin; // Solo vive en memoria
  Vault _currentVault = Vault.empty();

  SessionService(
    this._cryptoService,
    this._storageService,
  );

  bool get isLoggedIn => _pin != null;

  Vault get currentVault => _currentVault;

  /// Inicia sesión con PIN
  Future<void> login(String pin) async {
    final exists = await _storageService.exists();

    if (!exists) {
      // Crear vault inicial vacío
      final emptyVault = Vault.empty();
      final jsonString = jsonEncode(emptyVault.toMap());
      final encrypted = _cryptoService.encryptData(jsonString, pin);
      await _storageService.saveEncryptedData(encrypted);

      _pin = pin;
      _currentVault = emptyVault;
      return;
    }

    final encryptedData = await _storageService.readEncryptedData();

    if (encryptedData == null || encryptedData.isEmpty) {
      throw Exception('Archivo de datos inválido');
    }

    try {
      final decrypted =
          _cryptoService.decryptData(encryptedData, pin);

      final Map<String, dynamic> map = jsonDecode(decrypted);
      final vault = Vault.fromMap(map);

      _pin = pin;
      _currentVault = vault;
    } catch (_) {
      throw Exception('PIN incorrecto');
    }
  }

  /// Guarda cambios en el vault (re-cifra completo)
  Future<void> saveVault(Vault vault) async {
    if (_pin == null) {
      throw Exception('No hay sesión activa');
    }

    final jsonString = jsonEncode(vault.toMap());
    final encrypted =
        _cryptoService.encryptData(jsonString, _pin!);

    await _storageService.saveEncryptedData(encrypted);

    _currentVault = vault;
  }

  /// Cierra sesión y limpia memoria
  void logout() {
    _pin = null;
    _currentVault = Vault.empty();
  }
}