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
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? _pin;
  Vault _currentVault = Vault.empty();
  Timer? _inactivityTimer;
  bool _isLocked = false;
  
  // 👇 NUEVO: Variables para rate limiting
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  Timer? _lockoutTimer;

  bool get isLocked => _isLocked;
  
  // 👇 NUEVO: Getter para saber si está bloqueado por intentos
  bool get isLockedOut => _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);
  
  // 👇 NUEVO: Getter para tiempo restante de bloqueo (en segundos)
  int get lockoutRemainingSeconds {
    if (_lockoutUntil == null) return 0;
    final remaining = _lockoutUntil!.difference(DateTime.now());
    return remaining.isNegative ? 0 : remaining.inSeconds;
  }

  static const Duration _timeoutDuration = Duration(minutes: 10);
  static const String _pinKey = 'vault_pin';
  
  // 👇 NUEVO: Configuración de rate limiting
  static const int _maxFailedAttempts = 2; // cambiar en produccion
  static const Duration _lockoutDuration = Duration(minutes: 2); // cambiar en produccion

  bool _isAuthenticating = false;
  bool get isAuthenticating => _isAuthenticating;

  void setAuthenticating(bool value) {
    _isAuthenticating = value;
  }

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
  // RATE LIMITING METHODS
  // ==========================
  
  /// Verificar si está bloqueado y lanzar excepción
  void _checkLockout() {
    if (isLockedOut) {
      final remaining = _lockoutUntil!.difference(DateTime.now());
      final seconds = remaining.inSeconds;
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      throw Exception('Demasiados intentos. Espere ${minutes}m ${secs}s');
    }
  }
  
  /// Resetear el contador de intentos fallidos
  void _resetFailedAttempts() {
    _failedAttempts = 0;
    _lockoutUntil = null;
    _lockoutTimer?.cancel();
    _lockoutTimer = null;
    notifyListeners(); // Para actualizar UI si está mostrando bloqueo
  }
  
  /// Registrar intento fallido y posiblemente bloquear
  void _registerFailedAttempt() {
    _failedAttempts++;
    
    print("⚠️ Intento fallido $_failedAttempts/$_maxFailedAttempts");
    
    if (_failedAttempts >= _maxFailedAttempts) {
      // Bloquear por _lockoutDuration
      _lockoutUntil = DateTime.now().add(_lockoutDuration);
      _failedAttempts = 0;
      
      print("🔒 BLOQUEO ACTIVADO por $_lockoutDuration minutos");
      
      // Notificar para actualizar UI
      notifyListeners();
      
      // Iniciar timer para desbloquear automáticamente
      _lockoutTimer?.cancel();
      _lockoutTimer = Timer(_lockoutDuration, () {
        _lockoutUntil = null;
        print("🔓 Bloqueo por intentos expirado");
        notifyListeners();
      });
    }
  }

  // ==========================
  // LOGIN CON RATE LIMITING
  // ==========================
  
  Future<void> loginWithBiometric() async {
    print("🔐 loginWithBiometric START");
    
    // Verificar bloqueo antes de intentar
    if (isLockedOut) {
      throw Exception('App bloqueada temporalmente por seguridad');
    }
    
    final savedPin = await _secureStorage.read(key: _pinKey);
    if (savedPin == null) {
      throw Exception('No hay PIN guardado');
    }
    await _unlockExistingVault(savedPin);
    _isLocked = false;
    notifyListeners();
    _startInactivityTimer();
    print("🔐 loginWithBiometric END");
  }

  Future<void> login(String pin) async {
    // Verificar bloqueo antes de intentar
    _checkLockout();
    
    final exists = await _storageService.exists();
    if (!exists) {
      await _createNewVault(pin);
    } else {
      await _unlockExistingVault(pin);
    }

    await _secureStorage.write(key: _pinKey, value: pin);
    _isLocked = false;
    notifyListeners();
    _startInactivityTimer();
  }

  Future<void> unlockWithPin(String pin) async {
    // Verificar bloqueo antes de intentar
    _checkLockout();
    
    await _unlockExistingVault(pin);
    _isLocked = false;
    notifyListeners();
    _startInactivityTimer();
  }

  Future<void> _createNewVault(String pin) async {
    final emptyVault = Vault.empty();
    final jsonString = jsonEncode(emptyVault.toMap());
    final encrypted = _cryptoService.encryptData(jsonString, pin);
    await _storageService.saveEncryptedData(encrypted);
    _pin = pin;
    _currentVault = emptyVault;
    
    // Resetear contador de intentos al crear nuevo vault
    _resetFailedAttempts();
  }

  Future<void> _unlockExistingVault(String pin) async {
    final encryptedData = await _storageService.readEncryptedData();
    if (encryptedData == null || encryptedData.isEmpty) {
      throw Exception('Archivo de datos inválido');
    }

    try {
      final decrypted = _cryptoService.decryptData(encryptedData, pin);
      final Map<String, dynamic> map = jsonDecode(decrypted);
      final vault = Vault.fromMap(map);
      _pin = pin;
      _currentVault = vault;
      
      // ✅ ÉXITO: Resetear contador de intentos
      _resetFailedAttempts();
      
    } catch (_) {
      // ❌ FALLO: Registrar intento fallido
      final wasLockedOut = isLockedOut;
      _registerFailedAttempt();
      
      // Si después de registrar el fallo ahora estamos bloqueados
      if (!wasLockedOut && isLockedOut) {
        throw Exception('BLOQUEO_ACTIVADO');
      } else {
        throw Exception('PIN incorrecto');
      }
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
    final encrypted = _cryptoService.encryptData(jsonString, _pin!);
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
    _inactivityTimer = Timer(_timeoutDuration, logout);
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
    print("🔒 SESSION LOCKED");
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _isLocked = true;
    notifyListeners();
  }
  
  void unlock() {
    _isLocked = false;
    notifyListeners();
    _startInactivityTimer();
  }

  // ==========================
  // LOGOUT
  // ==========================
  void logout() {
    print("🚪 SESSION LOGOUT COMPLETO");
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _pin = null;
    _isLocked = false;
    _currentVault = Vault.empty();
    
    // Resetear rate limiting al hacer logout completo
    _resetFailedAttempts();
    
    notifyListeners();
  }
}