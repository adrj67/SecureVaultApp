import 'package:flutter/material.dart';
import 'package:secure_vault/screens/home_screen.dart';
import 'package:secure_vault/utils/constants.dart';

import 'services/session_service.dart';
import 'services/crypto_service.dart';
import 'services/storage_service.dart';

import 'screens/pin_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final cryptoService = CryptoService();
  final storageService = StorageService();

  final sessionService = SessionService(
    cryptoService,
    storageService,
  );

  runApp(
    MyApp(sessionService: sessionService),
  );
}

class MyApp extends StatefulWidget {
  final SessionService sessionService;

  const MyApp({
    super.key,
    required this.sessionService,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();

    // Observa cambios de estado de la app
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {

      // 🔐 Bloquear sesión
      widget.sessionService.lock();
    }

    if (state == AppLifecycleState.resumed) {

      // 🔄 Forzar reconstrucción
      //setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {

    return Listener(
      onPointerDown: (_) {
        widget.sessionService.registerUserActivity();
      },

      child: AnimatedBuilder(
        animation: widget.sessionService,
        builder: (context, _) {

          return MaterialApp(
            title: 'Secure Vault',
            debugShowCheckedModeBanner: false,

            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
              ),
              useMaterial3: true,
            ),

            // 🔥 AQUÍ ESTÁ LA MAGIA
            home: widget.sessionService.isLoggedIn
                ? HomeScreen(
                    sessionService: widget.sessionService,
                  )
                : PinScreen(
                    sessionService: widget.sessionService,
                  ),
          );
        },
      ),
    );
  }
}