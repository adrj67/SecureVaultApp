import 'dart:async';
import 'dart:convert';

import '../models/vault.dart';
import 'crypto_service.dart';
import 'storage_service.dart';

class SessionService {
  final CryptoService _cryptoService;
  final StorageService _storageService;

  String? _pin;
  Vault _currentVault = Vault.empty();

  Timer? _inactivityTimer;

  static const Duration _timeoutDuration = Duration(seconds: 10); 
  // Cambiar a minutos en producción

  SessionService(
    this._cryptoService,
    this._storageService,
  );

  bool get isLoggedIn => _pin != null;

  Vault get currentVault {
    if (!isLoggedIn) {
      throw Exception('No hay sesión activa');
    }
    return _currentVault;
  }

  Future<bool> vaultExists() async {
    return await _storageService.exists();
  }

  Future<void> login(String pin) async {
    final exists = await _storageService.exists();

    if (!exists) {
      await _createNewVault(pin);
    } else {
      await _unlockExistingVault(pin);
    }

    _startInactivityTimer();
  }

  Future<void> _createNewVault(String pin) async {
    final emptyVault = Vault.empty();
    final jsonString = jsonEncode(emptyVault.toMap());
    final encrypted = _cryptoService.encryptData(jsonString, pin);

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
      throw Exception('PIN incorrecto');
    }
  }

  Future<void> saveVault(Vault vault) async {
    if (!isLoggedIn || _pin == null) {
      throw Exception('No hay sesión activa');
    }

    final jsonString = jsonEncode(vault.toMap());
    final encrypted =
        _cryptoService.encryptData(jsonString, _pin!);

    await _storageService.saveEncryptedData(encrypted);

    _currentVault = vault;
    _resetInactivityTimer();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_timeoutDuration, () {
      logout();
    });
  }

  void _resetInactivityTimer() {
    if (isLoggedIn) {
      _startInactivityTimer();
    }
  }

  void registerUserActivity() {
    _resetInactivityTimer();
  }

  void logout() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;

    _pin = null;
    _currentVault = Vault.empty();
  }
}