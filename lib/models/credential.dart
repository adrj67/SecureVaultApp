class Credential {
  final String id;
  final String application;
  final String username;
  final String password;
  final String notes;

  const Credential({
    required this.id,
    required this.application,
    required this.username,
    required this.password,
    required this.notes,
  });

  /// Convierte la entidad a Map para serialización JSON
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'application': application,
      'username': username,
      'password': password,
      'notes': notes,
    };
  }

  /// Crea una entidad desde un Map (deserialización JSON)
  factory Credential.fromMap(Map<String, dynamic> map) {
    return Credential(
      id: map['id'] ?? '',
      application: map['application'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      notes: map['notes'] ?? '',
    );
  }

  /// Permite crear una copia modificada sin mutar el objeto original
  Credential copyWith({
    String? id,
    String? application,
    String? username,
    String? password,
    String? notes,
  }) {
    return Credential(
      id: id ?? this.id,
      application: application ?? this.application,
      username: username ?? this.username,
      password: password ?? this.password,
      notes: notes ?? this.notes,
    );
  }
}