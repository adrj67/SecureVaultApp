import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:secure_vault/screens/pin_screen.dart';
import 'package:secure_vault/services/session_service.dart';
import 'package:secure_vault/utils/constants.dart';
import 'dart:math';

import '../models/credential.dart';
import '../repositories/credential_repository.dart';

class AddEditScreen extends StatefulWidget {
  final CredentialRepository repository;
  final Credential? credential;
  final SessionService sessionService;

  const AddEditScreen({
    super.key,
    required this.repository,
    required this.sessionService,
    this.credential,
  });

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> 
  with WidgetsBindingObserver {

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
    WidgetsBinding.instance.addObserver(this);

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
    WidgetsBinding.instance.removeObserver(this);
    _applicationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {

      // 👇 Si está abierta esta pantalla, cerrarla
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }
  

  /// Generador de claves
  void _generatePassword() {
    const chars =
        'abcdefghijklmnñopqrstuvwxyzABCDEFGHIJKLMNÑOPQRSTUVWXYZ0123456789!@#\$%^&*()_+';

    final rand = Random.secure();
    final password =
        List.generate(16, (index) => chars[rand.nextInt(chars.length)]).join();

    setState(() {
      _passwordController.text = password;
    });
  }

  ///Copiar contraseña
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

  /// Guardar Credencial
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

    try {

      if (isEditing) {

        final updated = widget.credential!.copyWith(
          application: application,
          username: username,
          password: password,
          notes: notes,
        );

        await widget.repository.updateCredential(updated);

      } else {

        await widget.repository.addCredential(
          application: application,
          username: username,
          password: password,
          notes: notes,
        );
      }

      // 🔥 CLAVE: validar estado antes de navegar
      if (!mounted || !widget.sessionService.isLoggedIn) return;

      Navigator.of(context).maybePop(); // 👈 evita crash

    } catch (e) {

      // 🔥 Si la sesión murió, NO navegues desde acá
      if (!mounted) return;

      if (!widget.sessionService.isLoggedIn) {
        return; // 👈 la app ya se va a redirigir sola al PIN
      }

      setState(() {
        _error = "Error al guardar";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar credencial' : 'Nueva credencial',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.pinEmpty,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            //color: AppColors.pinEmpty,
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
                        color: AppColors.primaryClaro,
                        onPressed: _copyPassword,
                      ),

                      IconButton(
                        icon: const Icon(Icons.password),
                        color: AppColors.primaryClaro,
                        onPressed: _generatePassword,
                      ),

                      IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        color: AppColors.primaryClaro,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // Color de fondo
                  foregroundColor: AppColors.pinEmpty, // Color del texto/icono
                ),
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