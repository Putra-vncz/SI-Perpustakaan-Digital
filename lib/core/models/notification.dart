import 'package:flutter/material.dart';

enum NotificationType {
  bookingCreated,
  bookingExpiring,
  bookingExpired,
  bookingCancelled,
  loanCreated,
  loanDueSoon,
  loanOverdue,
  loanReturned,
  general,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedId; // bookingId or loanId

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.relatedId,
  });

  IconData get icon {
    switch (type) {
      case NotificationType.bookingCreated:
        return Icons.bookmark_added;
      case NotificationType.bookingExpiring:
        return Icons.timer;
      case NotificationType.bookingExpired:
        return Icons.timer_off;
      case NotificationType.bookingCancelled:
        return Icons.cancel;
      case NotificationType.loanCreated:
        return Icons.library_books;
      case NotificationType.loanDueSoon:
        return Icons.warning_amber;
      case NotificationType.loanOverdue:
        return Icons.error;
      case NotificationType.loanReturned:
        return Icons.check_circle;
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.bookingCreated:
      case NotificationType.loanCreated:
      case NotificationType.loanReturned:
        return Colors.green;
      case NotificationType.bookingExpiring:
      case NotificationType.loanDueSoon:
        return Colors.orange;
      case NotificationType.bookingExpired:
      case NotificationType.loanOverdue:
        return Colors.red;
      case NotificationType.bookingCancelled:
        return Colors.grey;
      case NotificationType.general:
        return Colors.blue;
    }
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    String? relatedId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type.index,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
        'relatedId': relatedId,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: NotificationType.values[json['type'] as int],
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      relatedId: json['relatedId'] as String?,
    );
  }
}
