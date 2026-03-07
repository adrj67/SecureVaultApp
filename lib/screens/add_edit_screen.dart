import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

import '../models/credential.dart';
import '../repositories/credential_repository.dart';

class AddEditScreen extends StatefulWidget {
  final CredentialRepository repository;
  final Credential? credential;

  const AddEditScreen({
    super.key,
    required this.repository,
    this.credential,
  });

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {

  final _formKey = GlobalKey<FormState>();

  final _applicationController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _notesController = TextEditingController();

  String? _error;

  bool _obscurePassword = true;

  bool get isEditing => widget.credential != null;

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      final c = widget.credential!;

      _applicationController.text = c.application;
      _usernameController.text = c.username;
      _passwordController.text = c.password;
      _notesController.text = c.notes;
    }
  }

  @override
  void dispose() {
    _applicationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+';

    final rand = Random.secure();
    final password =
        List.generate(16, (index) => chars[rand.nextInt(chars.length)]).join();

    setState(() {
      _passwordController.text = password;
    });
  }

  void _copyPassword() {
    Clipboard.setData(
      ClipboardData(text: _passwordController.text),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contraseña copiada al portapapeles'),
      ),
    );
  }

  Future<void> _saveCredential() async {
    final application = _applicationController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final notes = _notesController.text.trim();

    if (application.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Aplicación y contraseña son obligatorias';
      });
      return;
    }

    final isEditing = widget.credential != null;

    if (isEditing) {
      final updated = widget.credential!.copyWith(
        application: application,
        username: username,
        password: password,
        notes: notes,
      );

      print("Intentando guardar credencial");
      await widget.repository.updateCredential(updated);
    } else {
      await widget.repository.addCredential(
        application: application,
        username: username,
        password: password,
        notes: notes,
      );
      print("Credencial guardada");
    }
    
    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar credencial' : 'Nueva credencial',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveCredential,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [

              TextFormField(
                controller: _applicationController,
                decoration: const InputDecoration(
                  labelText: 'Aplicación / Sitio',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese una aplicación';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Usuario / Email',
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: _copyPassword,
                      ),

                      IconButton(
                        icon: const Icon(Icons.password),
                        onPressed: _generatePassword,
                      ),

                      IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

              ElevatedButton(
                onPressed: _saveCredential,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}