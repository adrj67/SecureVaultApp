import 'package:flutter/material.dart';
import 'package:secure_vault/screens/home_screen.dart';
import 'package:secure_vault/screens/welcome_screen.dart';
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

  bool _isInitialized = false;
  bool _isFirstTime = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    widget.sessionService.addListener(_onSessionChanged);

    _checkFirstTime();
  }

  // Método para verificar primera ejecución
  Future<void> _checkFirstTime() async {
    final exists = await widget.sessionService.vaultExists();
    if (mounted) {
      setState(() {
        _isFirstTime = !exists;
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.sessionService.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    final session = widget.sessionService;
    
    if (navigatorKey.currentState == null) return;

    // No navegar durante autenticación biométrica
    if (session.isAuthenticating) {
      debugPrint("⛔ BLOQUEADO: autenticando...");
      return;
    }

    debugPrint("👉 NAVIGATION TRIGGER - isLocked: ${session.isLocked}, isLoggedIn: ${session.isLoggedIn}, isLockedOut: ${session.isLockedOut}");

    // Si está bloqueado por intentos, NUNCA navegar a Home
    if (session.isLockedOut) {
      debugPrint("➡️ NAVIGATE TO PIN (bloqueado por intentos)");
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => PinScreen(sessionService: session),
        ),
        (route) => false,
      );
      return; // Salir para no continuar con otras condiciones
    }
    
    // Caso 1: Está bloqueado (app minimizada o timeout)
    if (session.isLocked) {
      debugPrint("➡️ NAVIGATE TO PIN (bloqueado)");
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => PinScreen(sessionService: session),
        ),
        (route) => false,
      );
      return; // Salir
    } 
    
    // Caso 2: No está logueado (logout completo)
    if (!session.isLoggedIn) {
      debugPrint("➡️ NAVIGATE TO PIN (no logueado)");
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => PinScreen(sessionService: session),
        ),
        (route) => false,
      );
      return; // Salir
    } 
    
    // Caso 3: Sesión activa y desbloqueada
    // Solo navegar a Home si no estamos ya en una pantalla válida
    final currentRoute = navigatorKey.currentState!.context.widget.toString();
    if (!currentRoute.contains('HomeScreen')) {
      debugPrint("➡️ NAVIGATE TO HOME");
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomeScreen(sessionService: session),
        ),
        (route) => false,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Cuando la app pasa a segundo plano o se inactiva
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      debugPrint("App en segundo plano - Bloqueando");
      widget.sessionService.lock();
    }
    // Cuando la app vuelve a primer plano
    if (state == AppLifecycleState.resumed) {
      debugPrint ("App vuelve a primer plano");
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

    // Mostrar loading mientras verificamos
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Si es la primera vez, muestra WelcomeScreen
    if (_isFirstTime) { 
      return WelcomeScreen(
        onStart: () {
          setState(() {
            _isFirstTime = false;
          });
          // Navegar a PinScreen para crear el PIN
          navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(
              builder: (_) => PinScreen(sessionService: widget.sessionService),
            ),
          );
        }
      );
    }

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