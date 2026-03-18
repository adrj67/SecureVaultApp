/*
import 'package:flutter/material.dart';
import 'package:secure_vault/utils/constants.dart';

import '../services/session_service.dart';
import '../services/biometric_service.dart';
import 'home_screen.dart';

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
  final TextEditingController _pinController = TextEditingController();
  final BiometricService _biometricService = BiometricService();

  bool _isLoading = false;
  String? _error;
  bool _biometricTried = false;

  @override
  void initState() {
    super.initState();
    //_handleBiometricLogin();
  }

  Future<void> _handleBiometricLogin() async {
    if (_biometricTried) return;
    _biometricTried = true;

    final available = await _biometricService.isBiometricAvailable();
    if (!available) return;

    final authenticated = await _biometricService.authenticate();
    if (!mounted) return;

    if (authenticated) {
      await widget.sessionService.loginWithBiometric();
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            sessionService: widget.sessionService,
          ),
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    final pin = _pinController.text.trim();

    if (pin.isEmpty) {
      setState(() {
        _error = 'Ingrese un PIN válido';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await widget.sessionService.login(pin);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            sessionService: widget.sessionService,
          ),
        ),
      );
    } catch (_) {
      setState(() {
        _error = 'PIN incorrecto';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // indicador de PIN
  Widget _buildPinIndicator() {
    final length = _pinController.text.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final filled = index < length;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: filled ? AppColors.primary : AppColors.primaryShade, //Colors.indigo : Colors.white,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pinEmpty,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Icon(
                Icons.lock_outline,
                size: 72,
                color: AppColors.primary,
              ),

              const SizedBox(height: 16),

              const Text(
                'Secure Vault',
                style: TextStyle(
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

              const SizedBox(height: 32),

              _buildPinIndicator(),

              const SizedBox(height: 32),

              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 4,
                style: const TextStyle(
                  letterSpacing: 8,
                  fontSize: 20,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  labelText: 'PIN',
                  errorText: _error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _handleLogin(),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.pinEmpty,
                          ),
                        )
                      : const Text(
                          'Ingresar',
                          style: TextStyle(fontSize: 16, color: AppColors.pinEmpty),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              TextButton.icon(
                onPressed: _handleBiometricLogin,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Usar Biometría'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'package:secure_vault/utils/constants.dart';
import '../services/session_service.dart';
import '../services/biometric_service.dart';
import 'home_screen.dart';

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
  bool _biometricTried = false;

  @override
  void initState() {
    super.initState();
    //_handleBiometricLogin();
  }

  Future<void> _handleBiometricLogin() async {
    if (_biometricTried) return;
    _biometricTried = true;

    final available = await _biometricService.isBiometricAvailable();
    if (!available) return;

    final authenticated = await _biometricService.authenticate();
    if (!mounted) return;

    if (authenticated) {
      await widget.sessionService.loginWithBiometric();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            sessionService: widget.sessionService,
          ),
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (_pin.length != 4) {
      setState(() {
        _error = 'Ingrese un PIN válido';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await widget.sessionService.login(_pin);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            sessionService: widget.sessionService,
          ),
        ),
      );
    } catch (_) {
      setState(() {
        _error = 'PIN incorrecto';
        //_pin = '';
      });
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _pin = '';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ==========================
  // PIN INDICATOR
  // ==========================
  Widget _buildPinIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
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

  // ==========================
  // NUMBER PRESSED
  // ==========================
  void _onNumberPressed(String number) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += number;
      _error = null;
    });

    if (_pin.length == 4) {
      _handleLogin();
    }
  }

  void _onDeletePressed() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  // ==========================
  // KEY BUTTON
  // ==========================
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

  // ==========================
  // KEYBOARD
  // ==========================
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

  // ==========================
  // UI
  // ==========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pinEmpty,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Icon(
              Icons.lock_outline,
              size: 72,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Secure Vault',
              style: TextStyle(
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
            TextButton.icon(
              onPressed: _handleBiometricLogin,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Usar Biometría'),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}