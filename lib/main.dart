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
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    widget.sessionService.addListener(_onSessionChanged); // 1
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.sessionService.removeListener(_onSessionChanged); // 2
    super.dispose();
  }

  void _onSessionChanged() {
    final session = widget.sessionService;

    if (navigatorKey.currentState == null) return;

    // 🔒 BLOQUEA durante biometría
    if (session.isAuthenticating) {
      print("⛔ BLOQUEADO: autenticando...");
      return;
    }

    print("👉 NAVIGATION TRIGGER - isLocked: ${session.isLocked}, isLoggedIn: ${session.isLoggedIn}");

    if (session.isLocked) {
      print("➡️ NAVIGATE TO PIN (Bloqueado)");

      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => PinScreen(sessionService: session),
        ),
        (route) => false,
      );
    }
    // Caso 2 No esta logueado (logout completo)
     else if (!session.isLoggedIn) {
      print("➡️ NAVIGATE TO HOME (no logueado)");

      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomeScreen(sessionService: session),
        ),
        (route) => false,
      );
    }
    // Caso 3: sesion activa y desbloqueada
    else {
      // Solo navegar a Home si no estamos ya en una pantalla valida
      final currentRoute = navigatorKey.currentState!.context.widget.toString();
      if(!currentRoute.contains('HomeScreen')) {
        print("Navegate To Home");
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => HomeScreen(sessionService: session),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Cuando la app pasa a segundo plano o se inactiva
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      print("App en segundo plano - Bloqueando");
      widget.sessionService.lock();
    }
    // Cuando la app vuelve a primer plano
    if (state == AppLifecycleState.resumed) {
      print ("App vuelve a primer plano");
      // El listener de session manejara la navegacion si esta bloqueada
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
            navigatorKey: navigatorKey,
            title: 'Secure Vault',
            debugShowCheckedModeBanner: false,

            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
              ),
              useMaterial3: true,
            ),

            home: _buildRootScreen(),
          );
        },
      ),
    );
  }

  Widget _buildRootScreen() {

    final session = widget.sessionService;

    // 🔐 Prioridad: sesión bloqueada
    if (session.isLocked) {
      return PinScreen(sessionService: session);
    }

    // 🔑 Usuario logueado
    if (session.isLoggedIn) {
      return HomeScreen(sessionService: session);
    }

    // 🚪 No logueado
    return PinScreen(sessionService: session);
  }
}