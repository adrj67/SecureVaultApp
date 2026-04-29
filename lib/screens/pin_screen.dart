import 'package:flutter/material.dart';
import 'package:secure_vault/utils/constants.dart';
import '../services/session_service.dart';
import '../services/biometric_service.dart';

import 'dart:async';

class PinScreen extends StatefulWidget {
  final SessionService sessionService;

  const PinScreen({
    super.key,
    required this.sessionService,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final BiometricService _biometricService = BiometricService();
  String _pin = '';
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticating = false;

  Timer? _lockoutTimer; // Timer para actualizar contador

  @override
  void initState() {
    super.initState();
    widget.sessionService.addListener(_onSessionChanged);

    // Si la app se abre en estado de bloqueo, mostrar mensaje
    if (widget.sessionService.isLockedOut) {
      _showLockoutMessage();
    }
  }
  
  @override
  void dispose() {
    widget.sessionService.removeListener(_onSessionChanged);
    _lockoutTimer?.cancel();
    // Cancelar cualquier autenticación en curso al salir
    _biometricService.cancel();
    super.dispose();
  }

  void _onSessionChanged() {
    if (!mounted) return;
    
    // Si el bloqueo terminó, actualizar UI
    if (!widget.sessionService.isLockedOut) {
      _lockoutTimer?.cancel();
      setState(() {
        _error = null;
      });
    }
    /// Si se activa el bloqueo mientras está en PIN, mostrar mensaje
    if (widget.sessionService.isLockedOut) {
      _showLockoutMessage();
    }
  }

  Future<void> _handleBiometricLogin() async {
    debugPrint("👉 BOTON BIOMETRIA PRESIONADO");

    // Evitar múltiples llamadas
    if (_isAuthenticating) {
      debugPrint("⚠️ Autenticación ya en curso");
      return;
    }

    // Verificar disponibilidad
    final available = await _biometricService.isBiometricAvailable();
    if (!available) {
      if (mounted) {
        setState(() {
          _error = 'Biometría no disponible';
        });
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      _isAuthenticating = true;
      _error = null;
    });

    widget.sessionService.setAuthenticating(true);

    final authenticated = await _biometricService.authenticate();

    widget.sessionService.setAuthenticating(false);

    if (!mounted) {
      return;
    }

    if (authenticated) {
      debugPrint("✅ BIOMETRIA OK");
      
      try {
        if (widget.sessionService.isLocked) {
          final savedPin = await widget.sessionService.getSavedPin();
          if (savedPin != null) {
            await widget.sessionService.unlockWithPin(savedPin);
            debugPrint("✅ App desbloqueada con biometría");
          }
        } else {
          await widget.sessionService.loginWithBiometric();
          debugPrint("✅ Login completo con biometría");
        }
      } catch (e) {
        debugPrint("❌ Error en biometría: $e");
        if (mounted) {
          setState(() {
            _error = 'Error al desbloquear';
          });
        }
      }
    } else {
      debugPrint("❌ BIOMETRIA FALLÓ");
      if (mounted) {
        setState(() {
          _error = 'Autenticación fallida';
        });
      }
    }

    if (mounted) {
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  Future<void> _handleLogin() async {
    if (_pin.length != 6) {
      setState(() {
        _error = 'Ingrese un PIN de 6 dígitos';
      });
      return;
    }

    // Verificar si ya está bloqueado ANTES de intentar
    if (widget.sessionService.isLockedOut) {
      _showLockoutMessage();
      setState(() {
        _pin = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final vaultExists = await widget.sessionService.vaultExists();
      
      if (!vaultExists) {
        debugPrint("🔐 Primer inicio - Creando vault con PIN");
        await widget.sessionService.login(_pin);
      } else if (widget.sessionService.isLocked) {
        debugPrint("🔓 Desbloqueando app con PIN");
        await widget.sessionService.unlockWithPin(_pin);
      } else {
        debugPrint("🔐 Login completo con PIN");
        await widget.sessionService.login(_pin);
      }
      debugPrint("✅ Operación exitosa");
      
      // Limpiar cualquier timer de bloqueo
      _lockoutTimer?.cancel();
      
    } catch (e) {
      debugPrint("❌ Error: $e");
      final errorMsg = e.toString();
      
      if (mounted) {
        // Verificar si es un bloqueo activado
        if (errorMsg.contains('BLOQUEO_ACTIVADO') || widget.sessionService.isLockedOut) {
          _showLockoutMessage();
          /// Limpiar PIN y deshabilitar entrada
          setState(() {
            _pin = '';
          });
        } else if (errorMsg.contains('Espere')) {
          // Extraer el tiempo del mensaje
          _error = errorMsg.replaceFirst('Exception: ', '');
          _startLockoutTimer();
        } else {
          setState(() {
            _error = 'PIN incorrecto';
          });
        }
      }

      // Limpiar el PIN después de error (solo si no es bloqueo)
      if (!widget.sessionService.isLockedOut) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _pin = '';
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Método para mostrar mensaje de bloqueo
  void _showLockoutMessage() {
    _startLockoutTimer();
    // Forzar actualización del estado de bloqueo
    if (mounted) {
      final seconds = widget.sessionService.lockoutRemainingSeconds;
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      setState(() {
        _error = '🔒 DEMASIADOS INTENTOS\nLa app se desbloqueará en ${minutes}m ${secs}s';
      });
    }
  }

  // Metodo para actualizar el contador de bloqueo
  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    
    // Actualizar inmediatamente
    _updateLockoutMessage();
    
    // Luego cada segundo
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (!widget.sessionService.isLockedOut) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _error = null;
          });
        }
        return;
      }
      
      _updateLockoutMessage();
    });
  }

  /// Actualizar el mensaje con el tiempo restante
  void _updateLockoutMessage() {
    if (!mounted) return;
    
    final seconds = widget.sessionService.lockoutRemainingSeconds;
    if (seconds <= 0) return;
    
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    
    setState(() {
      _error = '🔒 DEMASIADOS INTENTOS\nLa app se desbloqueará en ${minutes}m ${secs}s';
    });
  }

  Widget _buildPinIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final filled = index < _pin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: filled ? AppColors.pinFilled : AppColors.primaryShade,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  void _onNumberPressed(String number) {
    if (_pin.length >= 6) return;
    setState(() {
      _pin += number;
      _error = null;
    });

    if (_pin.length == 6) {
      _handleLogin();
    }
  }

  void _onDeletePressed() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Widget _buildKey(String number) {
    return GestureDetector(
      onTap: () => _onNumberPressed(number),
      child: Container(
        width: 70,
        height: 70,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          number,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteKey() {
    return GestureDetector(
      onTap: _onDeletePressed,
      child: const SizedBox(
        width: 70,
        height: 70,
        child: Icon(
          Icons.backspace,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildKeyboard() {
    final isDisabled = widget.sessionService.isLockedOut;
  
    return Opacity(
      opacity: isDisabled ? 0.3 : 1.0,
      child: IgnorePointer(
        ignoring: isDisabled,
          child: Column(
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildKey('1'),
                _buildKey('2'),
                _buildKey('3'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildKey('4'),
                _buildKey('5'),
                _buildKey('6'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildKey('7'),
                _buildKey('8'),
                _buildKey('9'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(width: 70),
                _buildKey('0'),
                _buildDeleteKey(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUnlockMode = widget.sessionService.isLocked;
    final titleText = isUnlockMode ? 'Desbloquear' : 'Santo y Seña';
    
    return Scaffold(
      backgroundColor: AppColors.pinEmpty,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 
                              MediaQuery.of(context).padding.top - 
                              MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 1),
                        Icon(
                          isUnlockMode ? Icons.lock_outline : Icons.lock_open_outlined,
                          size: 72,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          titleText,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ingrese su PIN',
                          style: TextStyle(
                            color: AppColors.primaryShade,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildPinIndicator(),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 40),
                        _buildKeyboard(),
                        const SizedBox(height: 30),
                        FutureBuilder<bool>(
                          future: _hasSavedPin(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data == true) {
                              return TextButton.icon(
                                onPressed: (widget.sessionService.isLockedOut || _isAuthenticating) 
                                    ? null 
                                    : _handleBiometricLogin,
                                icon: _isAuthenticating
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.fingerprint),
                                label: const Text('Usar Biometría'),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        const Spacer(flex: 1),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Future<bool> _hasSavedPin() async {
    final pin = await widget.sessionService.getSavedPin();
    return pin != null;
  }
}