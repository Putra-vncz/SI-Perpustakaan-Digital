import 'package:hive/hive.dart';

part 'loan_status.g.dart';

@HiveType(typeId: 13)
enum LoanStatus {
  @HiveField(0)
  active,
  @HiveField(1)
  returned,
  @HiveField(2)
  overdue,
  @HiveField(3)
  pendingReturn,
}
