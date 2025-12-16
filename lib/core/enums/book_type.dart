import 'package:hive/hive.dart';

part 'book_type.g.dart';

@HiveType(typeId: 11)
enum BookType {
  @HiveField(0)
  physical,
  @HiveField(1)
  ebook,
}
