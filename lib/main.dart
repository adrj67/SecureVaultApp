import 'package:flutter/material.dart';
import 'package:secure_vault/screens/home_screen.dart';
import 'package:secure_vault/screens/welcome_screen.dart';
import 'package:secure_vault/utils/constants.dart';

import 'services/session_service.dart';
import 'services/crypto_service.dart';
import 'services/storage_service.dart';
import 'screens/pin_screen.dart';

bool isBackupOperation = false; // Variable global

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  final cryptoService = CryptoService();
  final storageService = StorageService();
  final sessionService = SessionService(cryptoService, storageService);

  runApp(MyApp(sessionService: sessionService));
}

class MyApp extends StatefulWidget {
  final SessionService sessionService;

  const MyApp({super.key, required this.sessionService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Estados de inicialización
  bool _isInitialized = false;
  bool _isFirstTime = false;

  void setBackupOperation(bool value) {
    isBackupOperation = value;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.sessionService.addListener(_onSessionChanged);
    _checkFirstTime();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.sessionService.removeListener(_onSessionChanged);
    super.dispose();
  }

  // Verificar si es primera ejecución
  Future<void> _checkFirstTime() async {
    final exists = await widget.sessionService.vaultExists();
    if (mounted) {
      setState(() {
        _isFirstTime = !exists;
        _isInitialized = true;
      });
    }
  }

  // Manejador de cambios de sesión
  void _onSessionChanged() {
    final session = widget.sessionService;
    
    if (navigatorKey.currentState == null) return;

    // No navegar durante autenticación biométrica
    if (session.isAuthenticating) {
      return;
    }

    // Bloqueado por intentos fallidos
    if (session.isLockedOut) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => PinScreen(sessionService: session)),
        (route) => false,
      );
      return;
    }
    
    // App bloqueada (minimizada o timeout)
    if (session.isLocked) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => PinScreen(sessionService: session)),
        (route) => false,
      );
      return;
    } 
    
    // No logueado
    if (!session.isLoggedIn) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => PinScreen(sessionService: session)),
        (route) => false,
      );
      return;
    } 
    
    // Sesión activa - navegar a Home si es necesario
    final currentRoute = navigatorKey.currentState!.context.widget.toString();
    if (!currentRoute.contains('HomeScreen')) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen(sessionService: session)),
        (route) => false,
      );
    }
  }

  // Ciclo de vida de la app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ✅ NO bloquear durante operaciones de backup 
    if (isBackupOperation) {
      debugPrint("📂 Backup en curso - ignorando bloqueo");
      return;
    }
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      debugPrint("App en segundo plano - Bloqueando");
      widget.sessionService.lock();
    }
    
    if (state == AppLifecycleState.resumed) {
      debugPrint("App vuelve a primer plano");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => widget.sessionService.registerUserActivity(),
      child: AnimatedBuilder(
        animation: widget.sessionService,
        builder: (context, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Santo y Seña',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Primera vez - WelcomeScreen
    if (_isFirstTime) {
      return WelcomeScreen(
        onStart: () {
          setState(() => _isFirstTime = false);
          navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(
              builder: (_) => PinScreen(sessionService: widget.sessionService),
            ),
          );
        },
      );
    }

    final session = widget.sessionService;

    // Prioridad: sesión bloqueada
    if (session.isLocked) {
      return PinScreen(sessionService: session);
    }

    // Usuario logueado
    if (session.isLoggedIn) {
      return HomeScreen(sessionService: session);
    }

    // No logueado
    return PinScreen(sessionService: session);
  }
}