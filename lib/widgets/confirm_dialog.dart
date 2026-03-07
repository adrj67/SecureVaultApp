import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {

  final String title;
  final String message;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [

        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: const Text('Cancelar'),
        ),

        TextButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}