import 'package:hive/hive.dart';
import '../enums/enums.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final UserRole role;

  @HiveField(4)
  final String? studentId; // NIM (9 digits)

  @HiveField(5)
  final String password;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.password,
    this.studentId,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? studentId,
    String? password,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      studentId: studentId ?? this.studentId,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'studentId': studentId,
      'password': password,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere((e) => e.name == json['role']),
      studentId: json['studentId'] as String?,
      password: json['password'] as String,
    );
  }
}
