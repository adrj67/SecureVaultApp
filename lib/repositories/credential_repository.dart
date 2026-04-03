import 'package:uuid/uuid.dart';

import '../models/credential.dart';
import '../services/session_service.dart';

class CredentialRepository {
  final SessionService _sessionService;
  final Uuid _uuid = const Uuid();

  CredentialRepository(this._sessionService);

  /// Obtener todas las credenciales
  List<Credential> getAll() {
    final vault = _sessionService.currentVault;
    return vault.credentials;
  }

  /// Buscar credenciales
  List<Credential> search(String query) {
    final credentials = getAll();

    if (query.isEmpty) return credentials;

    final q = query.toLowerCase();

    return credentials.where((c) {
      return c.application.toLowerCase().contains(q) ||
          c.username.toLowerCase().contains(q);
    }).toList();
  }

  /// Crear credencial
  Future<void> addCredential({
    required String application,
    required String username,
    required String password,
    String notes = '',
  }) async {
    final vault = _sessionService.currentVault;
    final now = DateTime.now();

    final newCredential = Credential(
      id: _uuid.v4(),
      application: application,
      username: username,
      password: password,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    final updatedCredentials = List<Credential>.from(vault.credentials)
      ..add(newCredential);

    final updatedVault = vault.copyWith(
      credentials: updatedCredentials,
    );

    await _sessionService.saveVault(updatedVault);
  }

  /// Actualizar credencial
  Future<void> updateCredential(Credential updated) async {
    final vault = _sessionService.currentVault;

    final updatedCredential = updated.copyWith(
      updatedAt: DateTime.now(),
    );

    final updatedList = vault.credentials.map((c) {
      if (c.id == updated.id) {
        return updatedCredential;
      }
      return c;
    }).toList();

    final updatedVault = vault.copyWith(
      credentials: updatedList,
    );

    await _sessionService.saveVault(updatedVault);
  }

  /// Eliminar credencial
  Future<void> deleteCredential(String id) async {
    final vault = _sessionService.currentVault;

    final updatedList =
        vault.credentials.where((c) => c.id != id).toList();

    final updatedVault = vault.copyWith(
      credentials: updatedList,
    );

    await _sessionService.saveVault(updatedVault);
  }

  /// Obtener credencial por ID
  Future<Credential?> getById(String id) async {
    final credentials = getAll();
    try {
      return credentials.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

}