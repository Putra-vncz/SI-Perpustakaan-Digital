import '../enums/enums.dart';

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? studentId; // NIM

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.studentId,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? studentId,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      studentId: studentId ?? this.studentId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'studentId': studentId,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere((e) => e.name == json['role']),
      studentId: json['studentId'] as String?,
    );
  }
}
