import 'package:flutter/material.dart';
import 'package:secure_vault/utils/constants.dart';

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
        vertical: 6,
      ),
      child: ListTile(

        onTap: onEdit,

        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          child: Image.network(
            'https://www.google.com/s2/favicons?domain=${credential.application}.com',
            width: 20,
            height: 20,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.lock_outline, color: AppColors.primary,),
          ),
        ),

        title: Text(
          credential.application,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
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