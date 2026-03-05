import 'package:flutter/material.dart';

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
    //_tryBiometricLogin();
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

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Secure Vault',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'PIN',
                  errorText: _error,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _handleLogin(),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Ingresar'),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: _handleBiometricLogin,
                child: const Text('Usar biometría'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}