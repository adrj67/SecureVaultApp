import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/session_service.dart';
import '../repositories/credential_repository.dart';
import '../models/credential.dart';
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

  final TextEditingController _searchController = TextEditingController();

  late CredentialRepository _credentialRepository;

  List<Credential> _credentials = [];
  List<Credential> _filteredCredentials = [];

  final Map<String, bool> _visiblePasswords = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _credentialRepository =
        CredentialRepository(widget.sessionService);

    _loadCredentials();

    _searchController.addListener(_filterCredentials);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  // ==========================
  // CICLO DE VIDA APP
  // ==========================

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

  // ==========================
  // CARGAR CREDENCIALES
  // ==========================

  Future<void> _loadCredentials() async {
    final list = await _credentialRepository.getAll();

    setState(() {
      _credentials = list;
      _filteredCredentials = list;
    });
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
  // COPIAR CONTRASEÑA
  // ==========================

  Future<void> _copyPassword(String password) async {
    await Clipboard.setData(ClipboardData(text: password));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contraseña copiada al portapapeles'),
      ),
    );
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
        appBar: AppBar(
          title: const Text('Secure Vault'),
        ),

        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Paso siguiente: crear credencial
          },
          child: const Icon(Icons.add),
        ),

        body: Column(
          children: [

            // ==========================
            // BUSCADOR
            // ==========================

            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar aplicación o usuario...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            // ==========================
            // LISTA
            // ==========================

            Expanded(
              child: _filteredCredentials.isEmpty
                  ? const Center(
                      child: Text('No hay credenciales'),
                    )
                  : ListView.builder(
                      itemCount: _filteredCredentials.length,
                      itemBuilder: (context, index) {
                        final cred =
                            _filteredCredentials[index];

                        final visible =
                            _visiblePasswords[cred.id] ??
                                false;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text(cred.application),
                            subtitle: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [

                                if (cred.username.isNotEmpty)
                                  Text(
                                    'Usuario: ${cred.username}',
                                  ),

                                const SizedBox(height: 4),

                                Text(
                                  visible
                                      ? cred.password
                                      : '••••••••••',
                                ),
                              ],
                            ),

                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [

                                IconButton(
                                  icon: Icon(
                                    visible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () =>
                                      _togglePassword(
                                          cred.id),
                                ),

                                IconButton(
                                  icon: const Icon(
                                      Icons.copy),
                                  onPressed: () =>
                                      _copyPassword(
                                          cred.password),
                                ),
                              ],
                            ),
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