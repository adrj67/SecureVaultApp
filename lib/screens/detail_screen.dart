import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/credential.dart';
import '../repositories/credential_repository.dart';
import 'add_edit_screen.dart';

class DetailScreen extends StatefulWidget {
  final Credential credential;
  final CredentialRepository repository;

  const DetailScreen({
    super.key,
    required this.credential,
    required this.repository,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {

  bool _passwordVisible = false;

  Future<void> _copy(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _deleteCredential() async {

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Eliminar credencial'),
          content: Text(
            '¿Seguro que deseas eliminar "${widget.credential.application}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await widget.repository.deleteCredential(widget.credential.id);

    if (!mounted) return;

    Navigator.pop(context);
  }

  Future<void> _editCredential() async {

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditScreen(
          repository: widget.repository,
          credential: widget.credential,
        ),
      ),
    );

    if (!mounted) return;

    Navigator.pop(context);
  }

  Widget _buildField(String label, String value) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          value.isEmpty ? '-' : value,
          style: const TextStyle(fontSize: 16),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    final cred = widget.credential;

    return Scaffold(
      appBar: AppBar(
        title: Text(cred.application),
        actions: [

          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editCredential,
          ),

          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteCredential,
          ),

        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Center(
              child: CircleAvatar(
                radius: 36,
                child: Text(
                  cred.application.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),

            const SizedBox(height: 30),

            _buildField("Aplicación", cred.application),

            Row(
              children: [

                Expanded(
                  child: _buildField("Usuario", cred.username),
                ),

                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: cred.username.isEmpty
                      ? null
                      : () => _copy(
                            cred.username,
                            "Usuario copiado",
                          ),
                ),

              ],
            ),

            Row(
              children: [

                Expanded(
                  child: _buildField(
                    "Contraseña",
                    _passwordVisible
                        ? cred.password
                        : "••••••••••",
                  ),
                ),

                IconButton(
                  icon: Icon(
                    _passwordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                ),

                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copy(
                    cred.password,
                    "Contraseña copiada",
                  ),
                ),

              ],
            ),

            if (cred.notes.isNotEmpty)
              _buildField("Notas", cred.notes),

          ],
        ),
      ),
    );
  }
}