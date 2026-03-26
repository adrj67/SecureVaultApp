import 'package:flutter/material.dart';
import 'package:secure_vault/utils/constants.dart';

import '../services/session_service.dart';
import '../repositories/credential_repository.dart';
import '../models/credential.dart';
import 'add_edit_screen.dart';
import 'detail_screen.dart';

import '../widgets/credential_tile.dart';

class HomeScreen extends StatefulWidget {
  final SessionService sessionService;

  const HomeScreen({
    super.key,
    required this.sessionService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final TextEditingController _searchController = TextEditingController();

  late CredentialRepository _credentialRepository;

  List<Credential> _credentials = [];
  List<Credential> _filteredCredentials = [];

  final Map<String, bool> _visiblePasswords = {};

  @override
  void initState() {
    super.initState();

    _credentialRepository =
        CredentialRepository(widget.sessionService);

    _loadCredentials();

    _searchController.addListener(_filterCredentials);
  }

  @override
  void dispose() {
    
    _searchController.dispose();
    super.dispose();
  }
  
  // ==========================
  // CARGAR CREDENCIALES
  // ==========================

  Future <void> _loadCredentials() async {
    try{
      final list = await _credentialRepository.getAll();

      list.sort(
      (a, b) => a.application.toLowerCase().compareTo(
        b.application.toLowerCase(),
        )
      );

      if (!mounted) return;

      setState(() {
        _credentials = list;
        _filteredCredentials = list;
      });
    } catch(e) {

    }

  }

  // ==========================
  // BUSCADOR
  // ==========================

  void _filterCredentials() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredCredentials = _credentials.where((cred) {
        return cred.application.toLowerCase().contains(query) ||
            cred.username.toLowerCase().contains(query);
      }).toList();
    });
  }

  // ==========================
  // MOSTRAR / OCULTAR
  // ==========================

  void _togglePassword(String id) {
    setState(() {
      _visiblePasswords[id] =
          !(_visiblePasswords[id] ?? false);
    });
  }

  // ==========================
  // ABRIR ADD CREDENTIAL
  // ==========================

  Future<void> _openAddCredential() async {
    widget.sessionService.registerUserActivity();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditScreen(
          repository: _credentialRepository,
          sessionService: widget.sessionService,
        ),
      ),
    );

    _loadCredentials();
  }

  // ==========================
  // BORRAR CREDENTIAL
  // ==========================

  Future<void> _deleteCredential(Credential credential) async {

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Eliminar credencial'),
          content: Text(
            '¿Seguro que deseas eliminar "${credential.application}"?',
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

    await _credentialRepository.deleteCredential(credential.id);

    _loadCredentials();
  }

  // ==========================
  // UI
  // ==========================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        widget.sessionService.registerUserActivity();
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          title: const Text('Listado de Apps'),
          centerTitle: true,
        ),

       floatingActionButton: FloatingActionButton(
        
          onPressed: _openAddCredential,
          elevation: 6,
          backgroundColor: AppColors.resalta,
          foregroundColor: AppColors.primary,
          child: const Icon(Icons.add),
        ),

        body: Column(
          children: [

            // BUSCADOR
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar aplicación o usuario...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterCredentials();
                            setState(() {});
                          },
                        )
                      : null,

                  filled: true,
                  fillColor: Colors.white,

                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),

            // LISTA
            Expanded(
              child: _filteredCredentials.isEmpty
                  ? const Center(
                      child: Text('No hay credenciales'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _filteredCredentials.length,
                      itemBuilder: (context, index) {

                        final cred =
                            _filteredCredentials[index];

                        final visible =
                            _visiblePasswords[cred.id] ??
                                false;

                        return Dismissible(
                          key: ValueKey(cred.id),

                          direction: DismissDirection.endToStart,

                          confirmDismiss: (_) async {
                            await _deleteCredential(cred);
                            return false;
                          },

                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),

                        child: CredentialTile(
                          credential: cred,
                          passwordVisible: visible,

                          onTogglePassword: () => _togglePassword(cred.id),

                          onEdit: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen (
                                  credential: cred,
                                  repository: _credentialRepository,
                                  sessionService: widget.sessionService,
                                ),
                              ),
                            );

                            _loadCredentials();
                          },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}