import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:secure_vault/utils/constants.dart';
import '../services/session_service.dart';
import '../services/backup_service.dart';
import '../services/crypto_service.dart';
import '../repositories/credential_repository.dart';

class SettingsScreen extends StatefulWidget {
  final SessionService sessionService;
  final CredentialRepository repository;
  final VoidCallback onBackupDone;

  const SettingsScreen({
    super.key,
    required this.sessionService,
    required this.repository,
    required this.onBackupDone,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  final BackupService _backupService = BackupService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.pinEmpty,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    _buildSettingsButton(
                      icon: Icons.backup,
                      title: 'Respaldar Vault',
                      subtitle: 'Compartir copia de seguridad',
                      color: Colors.blue,
                      onPressed: _backupVault,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildSettingsButton(
                      icon: Icons.restore,
                      title: 'Restaurar Backup',
                      subtitle: 'Recuperar contraseñas desde backup',
                      color: Colors.orange,
                      onPressed: _restoreBackup,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildSettingsButton(
                      icon: Icons.home,
                      title: 'Listado de Credenciales',
                      subtitle: 'Volver a la pantalla principal',
                      color: Colors.green,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildSettingsButton(
                      icon: Icons.logout,
                      title: 'Cerrar Aplicación',
                      subtitle: 'Cerrar sesión y salir',
                      color: Colors.red,
                      onPressed: _logoutAndExit,
                    ),
                  ],
                ),
              ),
          ),
    );
  }

  Widget _buildSettingsButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  //color: color.withOpacity(0.1),
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================
  // BACKUP (SOLO COMPARTIR)
  // ==========================
  
  Future<void> _backupVault() async {
    final encryptedVault = await widget.sessionService.getEncryptedVault();
    if (!mounted) return;
    
    if (encryptedVault == null) {
      _showError('No hay datos para respaldar');
      return;
    }
    
    setState(() => _isLoading = true);
    
    final success = await _backupService.shareVault(encryptedVault);
    
    if (!mounted) return;
    setState(() => _isLoading = false);
    
    if (success) {
      _showSuccess('Backup listo para compartir');
    } else {
      _showError('Error al crear backup');
    }
  }

  // ==========================
  // RESTAURAR BACKUP
  // ==========================
  
  Future<void> _restoreBackup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restaurar Backup'),
        content: const Text(
          '⚠️ ADVERTENCIA\n\n'
          'Restaurar un backup reemplazará TODAS tus contraseñas actuales.\n\n'
          '¿Estás seguro de continuar?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurar', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
    
    if (!mounted) return;
    if (confirm != true) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Seleccionar archivo
      final filePath = await _backupService.selectBackupFile();
      if (!mounted) return;
      
      if (filePath == null) {
        _showError('No se seleccionó ningún archivo');
        setState(() => _isLoading = false);
        return;
      }
      
      // Leer archivo
      final encryptedVault = await _backupService.readBackupFile(filePath);
      if (!mounted) return;
      
      if (encryptedVault == null) {
        _showError('El archivo es inválido o está corrupto');
        setState(() => _isLoading = false);
        return;
      }
      
      // Pedir PIN
      final pin = await _showPinDialog();
      if (!mounted) return;
      
      if (pin == null || pin.length != 6) {
        _showError('PIN inválido');
        setState(() => _isLoading = false);
        return;
      }
      
      // Verificar PIN
      final cryptoService = CryptoService();
      final decrypted = cryptoService.decryptData(encryptedVault, pin);
      
      if (decrypted.isEmpty) {
        _showError('PIN incorrecto');
        setState(() => _isLoading = false);
        return;
      }
      
      // Restaurar
      await widget.sessionService.restoreVault(encryptedVault);
      
      // Notificar a HomeScreen para recargar
      widget.onBackupDone();
      
      if (!mounted) return;
      _showSuccess('Backup restaurado correctamente');
      
      // Cerrar SettingsScreen y volver a Home
      Navigator.of(context).maybePop();
      
    } catch (e) {
      debugPrint("❌ Error en restauración: $e");
      _showError('Error al restaurar backup');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _showPinDialog() async {
    String pin = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Verificar PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa tu PIN para restaurar el backup:'),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              maxLength: 6,
              keyboardType: TextInputType.number,
              onChanged: (value) => pin = value,
              decoration: const InputDecoration(
                labelText: 'PIN',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, pin), child: const Text('Verificar')),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, duration: const Duration(seconds: 2)),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 3)),
    );
  }

  void _logoutAndExit() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas cerrar sesión y salir?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    widget.sessionService.logout();
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) Navigator.of(context).maybePop();
    SystemNavigator.pop();
  }
}