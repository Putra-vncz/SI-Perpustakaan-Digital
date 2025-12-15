import 'dart:convert';
import '../enums/enums.dart';

class Booking {
  final String id;
  final String userId;
  final String bookId;
  final DateTime bookingDate;
  final DateTime expiryDate;
  final BookingStatus status;

  const Booking({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.bookingDate,
    required this.expiryDate,
    required this.status,
  });

  /// Generate QR code data as JSON string
  String get qrCodeData => jsonEncode({
        'bookingId': id,
        'userId': userId,
      });

  bool get isExpired => DateTime.now().isAfter(expiryDate);

  Booking copyWith({
    String? id,
    String? userId,
    String? bookId,
    DateTime? bookingDate,
    DateTime? expiryDate,
    BookingStatus? status,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      bookingDate: bookingDate ?? this.bookingDate,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'bookId': bookId,
      'bookingDate': bookingDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'status': status.name,
    };
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      userId: json['userId'] as String,
      bookId: json['bookId'] as String,
      bookingDate: DateTime.parse(json['bookingDate'] as String),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      status: BookingStatus.values.firstWhere((e) => e.name == json['status']),
    );
  }
}
