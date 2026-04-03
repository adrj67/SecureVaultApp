import 'package:flutter/material.dart';
import '../models/credential.dart';

class CredentialTile extends StatelessWidget {

  final Credential credential;
  final bool passwordVisible;

  final VoidCallback onTogglePassword;
  final VoidCallback onEdit;

  const CredentialTile({
    super.key,
    required this.credential,
    required this.passwordVisible,
    required this.onTogglePassword,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(

        onTap: onEdit,

        leading: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey.shade100,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              'https://www.google.com/s2/favicons?domain=${credential.application}.com',
              width: 24,
              height: 24,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return const Icon(
                  Icons.lock_outline,
                  color: Colors.green,
                );
              },
            ),
          ),
        ),

        title: Row(
          children: [
            // Nombre de la aplicación (con peso, puede expandirse)
            Expanded(
              child: Text(
                '${credential.application} ',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.fade,//TextOverflow.ellipsis,
                maxLines: 1, // Limita a una línea
              ),
            ),
            // Username (con color gris, más pequeño, no se expande)
            if (credential.username.isNotEmpty)
              Flexible(
                child: Text(
                  credential.username,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  maxLines: 1, // Limita a una línea
                ),
              ),
          ],
        ),
        subtitle: Text(
          passwordVisible
              ? credential.password
              : '••••••••••',
        ),

        trailing: IconButton(
          icon: Icon(
            passwordVisible
                ? Icons.visibility_off
                : Icons.visibility,
          ),
          onPressed: onTogglePassword,
        ),
      ),
    );
  }
}