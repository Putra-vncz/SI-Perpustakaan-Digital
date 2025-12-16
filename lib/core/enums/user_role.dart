import 'package:hive/hive.dart';

part 'user_role.g.dart';

@HiveType(typeId: 10)
enum UserRole {
  @HiveField(0)
  student,
  @HiveField(1)
  admin,
}
