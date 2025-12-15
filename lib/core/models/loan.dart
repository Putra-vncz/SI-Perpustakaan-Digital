import '../enums/enums.dart';

class Loan {
  final String id;
  final String bookingId;
  final DateTime loanDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final LoanStatus status;

  const Loan({
    required this.id,
    required this.bookingId,
    required this.loanDate,
    required this.dueDate,
    this.returnDate,
    required this.status,
  });

  bool get isOverdue =>
      status == LoanStatus.active && DateTime.now().isAfter(dueDate);

  Loan copyWith({
    String? id,
    String? bookingId,
    DateTime? loanDate,
    DateTime? dueDate,
    DateTime? returnDate,
    LoanStatus? status,
  }) {
    return Loan(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
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
      loanDate: DateTime.parse(json['loanDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      returnDate: json['returnDate'] != null
          ? DateTime.parse(json['returnDate'] as String)
          : null,
      status: LoanStatus.values.firstWhere((e) => e.name == json['status']),
    );
  }
}
