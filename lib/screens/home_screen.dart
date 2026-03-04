import 'package:flutter/material.dart';

import '../services/session_service.dart';
import 'pin_screen.dart';

class HomeScreen extends StatefulWidget {
  final SessionService sessionService;

  const HomeScreen({
    super.key,
    required this.sessionService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
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
    if (state == AppLifecycleState.resumed) {
      if (!widget.sessionService.isLoggedIn) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => PinScreen(
              sessionService: widget.sessionService,
            ),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: (){
        widget.sessionService.registerUserActivity();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vault - Home Screen'),
        ),
        body: const Center(
          child: Text('Sesión iniciada correctamente'),
        ),
      ),
    );
  }
}