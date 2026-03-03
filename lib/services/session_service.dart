import 'dart:convert';

import '../models/vault.dart';
import 'crypto_service.dart';
import 'storage_service.dart';

class SessionService {
  final CryptoService _cryptoService;
  final StorageService _storageService;

  String? _pin; // Vive solo en memoria
  Vault _currentVault = Vault.empty();

  SessionService(
    this._cryptoService,
    this._storageService,
  );

  // ==========================
  // GETTERS
  // ==========================

  bool get isLoggedIn => _pin != null;

  Vault get currentVault {
    if (!isLoggedIn) {
      throw Exception('No hay sesión activa');
    }
    return _currentVault;
  }

  // ==========================
  // ESTADO INICIAL
  // ==========================

  /// Indica si ya existe un vault creado en almacenamiento
  Future<bool> vaultExists() async {
    return await _storageService.exists();
  }

  // ==========================
  // LOGIN
  // ==========================

  /// Inicia sesión con PIN
  /// - Si no existe vault → lo crea
  /// - Si existe → intenta descifrar
  Future<void> login(String pin) async {
    final exists = await _storageService.exists();

    if (!exists) {
      await _createNewVault(pin);
      return;
    }

    await _unlockExistingVault(pin);
  }

  Future<void> _createNewVault(String pin) async {
    final emptyVault = Vault.empty();

    final jsonString = jsonEncode(emptyVault.toMap());
    final encrypted =
        _cryptoService.encryptData(jsonString, pin);

    await _storageService.saveEncryptedData(encrypted);

    _pin = pin;
    _currentVault = emptyVault;
  }

  Future<void> _unlockExistingVault(String pin) async {
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
      // Importante: nunca revelar detalles internos
      throw Exception('PIN incorrecto');
    }
  }

  // ==========================
  // GUARDADO
  // ==========================

  /// Guarda cambios en el vault (re-cifra completo)
  Future<void> saveVault(Vault vault) async {
    if (!isLoggedIn || _pin == null) {
      throw Exception('No hay sesión activa');
    }

    final jsonString = jsonEncode(vault.toMap());
    final encrypted =
        _cryptoService.encryptData(jsonString, _pin!);

    await _storageService.saveEncryptedData(encrypted);

    _currentVault = vault;
  }

  // ==========================
  // LOGOUT
  // ==========================

  /// Cierra sesión y limpia completamente la memoria sensible
  void logout() {
    _pin = null;

    // Limpieza defensiva
    _currentVault = Vault.empty();
  }
}