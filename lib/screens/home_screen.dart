import 'package:flutter/material.dart';

import '../services/session_service.dart';

class HomeScreen extends StatelessWidget {
  final SessionService sessionService;

  const HomeScreen({
    super.key,
    required this.sessionService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault'),
      ),
      body: const Center(
        child: Text('Sesión iniciada correctamente'),
      ),
    );
  }
}