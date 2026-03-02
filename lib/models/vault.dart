import 'credential.dart';

class Vault {
  final List<Credential> credentials;

  const Vault({
    required this.credentials,
  });

  /// Convierte el Vault a Map (para JSON)
  Map<String, dynamic> toMap() {
    return {
      'credentials': credentials.map((c) => c.toMap()).toList(),
    };
  }

  /// Crea Vault desde Map (deserialización JSON)
  factory Vault.fromMap(Map<String, dynamic> map) {
    final credentialList = (map['credentials'] as List<dynamic>? ?? [])
        .map((item) => Credential.fromMap(item))
        .toList();

    return Vault(credentials: credentialList);
  }

  /// Vault vacío inicial
  factory Vault.empty() {
    return const Vault(credentials: []);
  }

  /// Permite crear copia modificada
  Vault copyWith({
    List<Credential>? credentials,
  }) {
    return Vault(
      credentials: credentials ?? this.credentials,
    );
  }
}