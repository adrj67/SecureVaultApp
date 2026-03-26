import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:secure_vault/services/session_service.dart';
import 'package:secure_vault/utils/constants.dart';

import '../models/credential.dart';
import '../repositories/credential_repository.dart';
import 'add_edit_screen.dart';

class DetailScreen extends StatefulWidget {
  final Credential credential;
  final CredentialRepository repository;
  final SessionService sessionService;

  const DetailScreen({
    super.key,
    required this.credential,
    required this.repository,
    required this.sessionService,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _passwordVisible = false;

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

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

    //Navigator.pop(context, true);
    Navigator.of(context).pushNamedAndRemoveUntil('/HomeScreen', (Route<dynamic> route) => false);
  }

  Future<void> _editCredential() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditScreen(
          repository: widget.repository,
          sessionService: widget.sessionService,
          credential: widget.credential,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    };
  }

  Widget _buildField(String label, String value, {bool isMultiline = false}) {

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
          style: TextStyle(
            fontSize: 16,
            height: isMultiline ? 1.4 : 1.0,
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime date) {
    return Column (
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
          _formatDate(date),
          style:  const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16,)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

        final cred = widget.credential;

        return Scaffold(
          appBar: AppBar(
            title: Text(cred.application),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.pinEmpty,
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

          floatingActionButton: FloatingActionButton(
            onPressed: _editCredential,
            elevation: 6,
            backgroundColor: AppColors.resalta,
            foregroundColor: AppColors.primary,
            child: const Icon(Icons.edit),
          ),

          body: SingleChildScrollView (
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.grey.shade200,
                    child: ClipOval(
                      child: Image.network(
                        'https://www.google.com/s2/favicons?domain=${cred.application}.com&sz=128',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Text(
                            cred.application.isNotEmpty
                                ? cred.application.substring(0, 1).toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
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
                      color: AppColors.primaryClaro,
                      onPressed: cred.username.isEmpty
                          ? null
                          : () => _copy(cred.username, "Usuario copiado"),
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
                      color: AppColors.primaryClaro,
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      color: AppColors.primaryClaro,
                      onPressed: () =>
                          _copy(cred.password, "Contraseña copiada"),
                    ),
                  ],
                ),
                
                if (cred.notes.isNotEmpty)
                  _buildField("Notas", cred.notes, isMultiline: true),
                
                const Divider(height: 32, thickness: 1,),

                _buildDateField("Fecha de Creacion", cred.createdAt),
                _buildDateField("Ultima Modificacion", cred.updatedAt),
              ],
            ),
          ),
        );
  }
}