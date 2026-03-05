class Credential {
  final String id;
  final String application;
  final String username;
  final String password;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Credential({
    required this.id,
    required this.application,
    required this.username,
    required this.password,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'application': application,
      'username': username,
      'password': password,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Credential.fromMap(Map<String, dynamic> map) {
    return Credential(
      id: map['id'] ?? '',
      application: map['application'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      notes: map['notes'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Credential copyWith({
    String? id,
    String? application,
    String? username,
    String? password,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Credential(
      id: id ?? this.id,
      application: application ?? this.application,
      username: username ?? this.username,
      password: password ?? this.password,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}