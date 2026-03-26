import 'package:flutter/material.dart';
import 'package:secure_vault/utils/constants.dart';
import '../services/session_service.dart';
import '../services/biometric_service.dart';

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
  
  @override
  void dispose() {
    // Cancelar cualquier autenticación en curso al salir
    _biometricService.cancel();
    super.dispose();
  }

  Future<void> _handleBiometricLogin() async {
    print("👉 BOTON BIOMETRIA PRESIONADO");

    // Evitar múltiples llamadas
    if (_isAuthenticating) {
      print("⚠️ Autenticación ya en curso");
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
      print("✅ BIOMETRIA OK");
      
      try {
        if (widget.sessionService.isLocked) {
          final savedPin = await widget.sessionService.getSavedPin();
          if (savedPin != null) {
            await widget.sessionService.unlockWithPin(savedPin);
            print("✅ App desbloqueada con biometría");
          }
        } else {
          await widget.sessionService.loginWithBiometric();
          print("✅ Login completo con biometría");
        }
      } catch (e) {
        print("❌ Error en biometría: $e");
        if (mounted) {
          setState(() {
            _error = 'Error al desbloquear';
          });
        }
      }
    } else {
      print("❌ BIOMETRIA FALLÓ");
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

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final vaultExists = await widget.sessionService.vaultExists();

      if (!vaultExists) {
        print("Primer inicio - Creando vault con PIN");
        await widget.sessionService.login(_pin);
      } else if (widget.sessionService.isLocked) {
        print("🔓 Desbloqueando app con PIN");
        await widget.sessionService.unlockWithPin(_pin);
        print("✅ App desbloqueada correctamente");
      } else {
        print("🔐 Login completo con PIN");
        await widget.sessionService.login(_pin);
        print("✅ Login completo correcto");
      }
    } catch (e) {
      print("❌ Error en login/desbloqueo: $e");
      if (mounted) {
        setState(() {
          _error = 'PIN incorrecto';
        });
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _pin = '';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    return Column(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUnlockMode = widget.sessionService.isLocked;
    final titleText = isUnlockMode ? 'Desbloquear' : 'Secure Vault';
    
    return Scaffold(
      backgroundColor: AppColors.pinEmpty,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                children: [
                  const Spacer(),
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
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
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
                          onPressed: _isAuthenticating ? null : _handleBiometricLogin,
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
                  const Spacer(),
                ],
              ),
      ),
     );

  }
  
  Future<bool> _hasSavedPin() async {
    final pin = await widget.sessionService.getSavedPin();
    return pin != null;
  }
}