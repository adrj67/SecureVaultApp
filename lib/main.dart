import 'package:flutter/material.dart';

import 'screens/pin_screen.dart';
import 'services/crypto_service.dart';
import 'services/session_service.dart';
import 'services/storage_service.dart';

// Funciona!! Paso 8 OK, continuar

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

class SecureVaultApp extends StatefulWidget {
  final SessionService sessionService;

  const SecureVaultApp({
    super.key,
    required this.sessionService,
  });

  @override
  State<SecureVaultApp> createState() => _SecureVaultAppState();
}

class _SecureVaultAppState extends State<SecureVaultApp>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Si la app pasa a segundo plano o se bloquea
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      widget.sessionService.logout();
    }
  }

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
      home: PinScreen(sessionService: widget.sessionService),
    );
  }
}