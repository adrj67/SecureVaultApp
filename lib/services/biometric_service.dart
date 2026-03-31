import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticating = false;

  Future<bool> isBiometricAvailable() async {
    final canCheckBiometrics = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();
    return canCheckBiometrics && isDeviceSupported;
  }

  Future<bool> authenticate() async {
    // Prevenir autenticaciones concurrentes
    if (_isAuthenticating) {
      // print("⚠️ Autenticación ya en progreso, ignorando nueva solicitud");
      return false;
    }

    _isAuthenticating = true;
    
    try {
      final result = await _localAuth.authenticate(
        localizedReason: 'Autentíquese para acceder a Secure Vault',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
        ),
      );
      return result;
    } catch (e) {
      // print("ERROR BIOMETRIA: $e");
      return false;
    } finally {
      _isAuthenticating = false;
    }
  }

  Future<void> cancel() async {
    try {
      _isAuthenticating = false;
      await _localAuth.stopAuthentication();
    } catch (_) {}
  }
}