import 'package:hive/hive.dart';

part 'booking_status.g.dart';

@HiveType(typeId: 12)
enum BookingStatus {
  @HiveField(0)
  active,
  @HiveField(1)
  claimed,
  @HiveField(2)
  expired,
  @HiveField(3)
  cancelled,
}
