import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/vault.dart';
import 'crypto_service.dart';
import 'storage_service.dart';

class SessionService extends ChangeNotifier {
  final CryptoService _cryptoService;
  final StorageService _storageService;

  final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  String? _pin;
  Vault _currentVault = Vault.empty();

  Timer? _inactivityTimer;
  //bool _isLoggedIn = false;
  //DateTime? _lastActivity;

  //bool _isLocked = false;

  //bool get isLocked => _isLocked;

  static const Duration _timeoutDuration =
      Duration(minutes: 10); // Cambiar en producción

  static const String _pinKey = 'vault_pin';

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

  Future<bool> vaultExists() async {
    return await _storageService.exists();
  }

  // ==========================
  // LOGIN
  // ==========================

  Future<void> loginWithBiometric() async {
    final savedPin = await _secureStorage.read(key: _pinKey);

    if (savedPin == null) {
      throw Exception('No hay PIN guardado para biometría');
    }

    await _unlockExistingVault(savedPin);

    //_isLocked = false;

    _startInactivityTimer();
  }

  Future<void> login(String pin) async {
    final exists = await _storageService.exists();

    if (!exists) {
      await _createNewVault(pin);
    } else {
      await _unlockExistingVault(pin);
    }

    // Guardamos PIN en almacenamiento seguro para biometría
    await _secureStorage.write(key: _pinKey, value: pin);

    //_isLocked = false;
    notifyListeners();

    _startInactivityTimer();

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
    final encryptedData =
        await _storageService.readEncryptedData();

    if (encryptedData == null || encryptedData.isEmpty) {
      throw Exception('Archivo de datos inválido');
    }

    try {
      final decrypted =
          _cryptoService.decryptData(encryptedData, pin);

      final Map<String, dynamic> map =
          jsonDecode(decrypted);

      final vault = Vault.fromMap(map);

      _pin = pin;
      _currentVault = vault;
    } catch (_) {
      throw Exception('PIN incorrecto');
    }
  }

  // ==========================
  // BIOMETRÍA
  // ==========================

  Future<String?> getSavedPin() async {
    return await _secureStorage.read(key: _pinKey);
  }

  // ==========================
  // GUARDADO
  // ==========================

  Future<void> saveVault(Vault vault) async {
    if (!isLoggedIn || _pin == null) {
      throw Exception('No hay sesión activa');
    }

    final jsonString = jsonEncode(vault.toMap());
    final encrypted =
        _cryptoService.encryptData(jsonString, _pin!);

    await _storageService.saveEncryptedData(encrypted);

    _currentVault = vault;
    notifyListeners();
    _resetInactivityTimer();
  }

  // ==========================
  // TIMEOUT
  // ==========================

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer =
        Timer(_timeoutDuration, logout);
  }

  void _resetInactivityTimer() {
    if (isLoggedIn) {
      _startInactivityTimer();
    }
  }

  void registerUserActivity() {
    _resetInactivityTimer();
  }

  void lock() {
    print("SESSION BLOQUEADA (lock)");

    _inactivityTimer?.cancel();
    _inactivityTimer = null;

    // ESTO ES LO IMPORTANTE
    _pin = null;

    notifyListeners();
  }
  // ==========================
  // LOGOUT
  // ==========================

  void logout() {
    print("SESSION LOGOUT");

    _inactivityTimer?.cancel();
    _inactivityTimer = null;

    _pin = null;
    _currentVault = Vault.empty();

    notifyListeners(); // FALTABA
  }


}