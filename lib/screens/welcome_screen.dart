import 'package:flutter/material.dart';
import 'package:secure_vault/utils/constants.dart';


class WelcomeScreen extends StatelessWidget {
  final VoidCallback onStart;
  
  const WelcomeScreen({
    super.key,
    required this.onStart,
    });
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield, size: 80, color: AppColors.primaryClaro),
            SizedBox(height: 24),
            Text(
              '¡Bienvenido a\n Santo y Seña!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Tu gestor de contraseñas',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Al hacer click en ➡️ "COMENZAR" deberas ingresar una clave de\n 6️⃣ digitos. \nEse sera tu 🔐 PIN de la app \nSanto y Seña.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _showResponsibilityDialog(context), //onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryClaro, // Color de fondo
                foregroundColor: AppColors.pinEmpty, // Color del texto/icono
                padding: const EdgeInsets.symmetric(
                  horizontal: 40, vertical:12),
              ),
              child: Text(
                'Comenzar',
                style: TextStyle(fontWeight: FontWeight.bold) ,
                ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResponsibilityDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Responsabilidad del Usuario',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recuerda que:\nSanto y Seña NO puede recuperar tu PIN.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.check_circle, size: 20, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(child: Text('Guarda tu PIN en un lugar seguro')),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.check_circle, size: 20, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(child: Text('Usa un PIN que puedas recordar')),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.cancel, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(child: Text('No compartas tu PIN con nadie')),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Text(
                  'El respaldo del archivo NO sirve sin el PIN correcto.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onStart();
              },
              child: const Text(
                'Entendido',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }
}