import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/credential.dart';
import '../utils/constants.dart';

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

  Future<void> _copy(BuildContext context, String text, String message) async {

    await Clipboard.setData(
      ClipboardData(text: text),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          child: Image.network(
            'https://www.google.com/s2/favicons?domain=${credential.application}.com',
            width: 20,
            height: 20,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.lock_outline, color: Colors.green, ),
          ),
        ),

        onTap: onEdit,

        title: Text(credential.application),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            if (credential.username.isNotEmpty)
              Text(credential.username),

            const SizedBox(height: 4),

            Text(
              passwordVisible
                  ? credential.password
                  : '••••••••••',
            ),
          ],
        ),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [

            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: credential.username.isEmpty
                  ? null
                  : () => _copy(
                        context,
                        credential.username,
                        AppConstants.copyUsernameMessage,
                      ),
            ),

            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () => _copy(
                context,
                credential.password,
                AppConstants.copyPasswordMessage,
              ),
            ),

            IconButton(
              icon: Icon(
                passwordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: onTogglePassword,
            ),
          ],
        ),
      )
    );
  }
}