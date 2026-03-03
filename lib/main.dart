import 'package:flutter/material.dart';
// Paso 1 OK, continuar
import 'screens/pin_screen.dart';
import 'services/crypto_service.dart';
import 'services/session_service.dart';
import 'services/storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final cryptoService = CryptoService();
  final storageService = StorageService();
  final sessionService = SessionService(
    cryptoService,
    storageService,
  );

  runApp(
    SecureVaultApp(sessionService: sessionService),
  );
}

class SecureVaultApp extends StatelessWidget {
  final SessionService sessionService;

  const SecureVaultApp({
    super.key,
    required this.sessionService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Vault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: PinScreen(sessionService: sessionService),
    );
  }
}