import 'package:hive/hive.dart';
import '../enums/enums.dart';

part 'loan.g.dart';

@HiveType(typeId: 3)
class Loan {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String bookingId;

  @HiveField(2)
  final String userId;

  @HiveField(3)
  final String userName;

  @HiveField(4)
  final String bookId;

  @HiveField(5)
  final String bookTitle;

  @HiveField(6)
  final DateTime loanDate;

  @HiveField(7)
  final DateTime dueDate;

  @HiveField(8)
  final DateTime? returnDate;

  @HiveField(9)
  final LoanStatus status;

  const Loan({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.userName,
    required this.bookId,
    required this.bookTitle,
    required this.loanDate,
    required this.dueDate,
    this.returnDate,
    required this.status,
  });

  bool get isOverdue =>
      status == LoanStatus.active && DateTime.now().isAfter(dueDate);

  LoanStatus get effectiveStatus {
    if (status == LoanStatus.active && isOverdue) {
      return LoanStatus.overdue;
    }
    return status;
  }

  Loan copyWith({
    String? id,
    String? bookingId,
    String? userId,
    String? userName,
    String? bookId,
    String? bookTitle,
    DateTime? loanDate,
    DateTime? dueDate,
    DateTime? returnDate,
    LoanStatus? status,
  }) {
    return Loan(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      loanDate: loanDate ?? this.loanDate,
      dueDate: dueDate ?? this.dueDate,
      returnDate: returnDate ?? this.returnDate,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'userId': userId,
      'userName': userName,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'loanDate': loanDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'returnDate': returnDate?.toIso8601String(),
      'status': status.name,
    };
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      bookId: json['bookId'] as String,
      bookTitle: json['bookTitle'] as String,
      loanDate: DateTime.parse(json['loanDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      returnDate: json['returnDate'] != null
          ? DateTime.parse(json['returnDate'] as String)
          : null,
      status: LoanStatus.values.firstWhere((e) => e.name == json['status']),
    );
  }
}
