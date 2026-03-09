import 'package:flutter/material.dart';

class AppConstants {
  static const appName = 'Secure Vault';

  static const copyPasswordMessage =
      'Contraseña copiada al portapapeles';

  static const copyUsernameMessage =
      'Usuario copiado al portapapeles';

  static const deleteCredentialTitle =
      'Eliminar credencial';

  static const deleteCredentialMessage =
      '¿Seguro que deseas eliminar esta credencial?';
}

class AppColors {

  static const primary = Color(0xFF3949AB); // Indigo
  static const primaryClaro = Color.fromARGB(255, 57, 129, 171); // Indigo claro
  static const primaryShade = Colors.grey; // Gris
  static const background = Color.fromARGB(255, 175, 176, 177);

  static const pinFilled = Color(0xFF3949AB);
  static const pinEmpty = Color(0xFFD6D9E6);

}