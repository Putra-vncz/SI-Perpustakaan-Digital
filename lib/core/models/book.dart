import 'package:hive/hive.dart';
import '../enums/enums.dart';

part 'book.g.dart';

@HiveType(typeId: 1)
class Book {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String author;

  @HiveField(3)
  final String coverUrl;

  @HiveField(4)
  final BookType type;

  @HiveField(5)
  final int stock;

  @HiveField(6)
  final String? pdfUrl;

  @HiveField(7)
  final String? shelfLocation;

  @HiveField(8)
  final String description;

  @HiveField(9)
  final String category;

  @HiveField(10)
  final String? contentUrl;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.type,
    required this.stock,
    this.pdfUrl,
    this.shelfLocation,
    this.description = '',
    this.category = 'Umum',
    this.contentUrl,
  });

  bool get isAvailable => type == BookType.ebook || stock > 0;

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? coverUrl,
    BookType? type,
    int? stock,
    String? pdfUrl,
    String? shelfLocation,
    String? description,
    String? category,
    String? contentUrl,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      type: type ?? this.type,
      stock: stock ?? this.stock,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      shelfLocation: shelfLocation ?? this.shelfLocation,
      description: description ?? this.description,
      category: category ?? this.category,
      contentUrl: contentUrl ?? this.contentUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'type': type.name,
      'stock': stock,
      'pdfUrl': pdfUrl,
      'shelfLocation': shelfLocation,
      'description': description,
      'category': category,
      'contentUrl': contentUrl,
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      coverUrl: json['coverUrl'] as String,
      type: BookType.values.firstWhere((e) => e.name == json['type']),
      stock: json['stock'] as int,
      pdfUrl: json['pdfUrl'] as String?,
      shelfLocation: json['shelfLocation'] as String?,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Umum',
      contentUrl: json['contentUrl'] as String?,
    );
  }
}
