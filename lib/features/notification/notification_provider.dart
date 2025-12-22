import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/core.dart';
import '../auth/auth_provider.dart';
import '../booking/booking_provider.dart';
import '../loan/loan_provider.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() {
    // Listen to booking and loan changes to generate notifications
    _generateNotifications();
    return const NotificationState();
  }

  void _generateNotifications() {
    Future.microtask(() async {
      final authState = ref.read(authProvider);
      if (authState.user == null) return;

      final userId = authState.user!.id;
      final bookings = ref.read(bookingProvider).bookings;
      final loans = ref.read(loanProvider).loans;

      final notifications = <AppNotification>[];

      // Generate notifications from bookings
      for (final booking in bookings.where((b) => b.userId == userId)) {
        // Booking created notification
        notifications.add(AppNotification(
          id: 'notif_booking_${booking.id}',
          title: 'Booking Berhasil',
          message: 'Booking telah dibuat. Ambil sebelum ${_formatDate(booking.expiryDate)}.',
          type: NotificationType.bookingCreated,
          createdAt: booking.bookingDate,
          relatedId: booking.id,
        ));

        // Check if booking is expiring soon (within 6 hours)
        if (booking.status == BookingStatus.active) {
          final hoursLeft = booking.expiryDate.difference(DateTime.now()).inHours;
          if (hoursLeft <= 6 && hoursLeft > 0) {
            notifications.add(AppNotification(
              id: 'notif_expiring_${booking.id}',
              title: 'Booking Segera Kedaluwarsa',
              message: 'Booking akan kedaluwarsa dalam $hoursLeft jam.',
              type: NotificationType.bookingExpiring,
              createdAt: DateTime.now(),
              relatedId: booking.id,
            ));
          }
        }

        // Expired booking
        if (booking.status == BookingStatus.expired) {
          notifications.add(AppNotification(
            id: 'notif_expired_${booking.id}',
            title: 'Booking Kedaluwarsa',
            message: 'Booking telah kedaluwarsa.',
            type: NotificationType.bookingExpired,
            createdAt: booking.expiryDate,
            relatedId: booking.id,
          ));
        }

        // Cancelled booking
        if (booking.status == BookingStatus.cancelled) {
          notifications.add(AppNotification(
            id: 'notif_cancelled_${booking.id}',
            title: 'Booking Dibatalkan',
            message: 'Booking telah dibatalkan.',
            type: NotificationType.bookingCancelled,
            createdAt: booking.bookingDate,
            relatedId: booking.id,
          ));
        }
      }

      // Generate notifications from loans
      for (final loan in loans.where((l) => l.userId == userId)) {
        // Loan created notification
        notifications.add(AppNotification(
          id: 'notif_loan_${loan.id}',
          title: 'Peminjaman Aktif',
          message: 'Buku "${loan.bookTitle}" harus dikembalikan sebelum ${_formatDate(loan.dueDate)}.',
          type: NotificationType.loanCreated,
          createdAt: loan.loanDate,
          relatedId: loan.id,
        ));

        // Check if loan is due soon (within 3 days)
        if (loan.status == LoanStatus.active) {
          final daysLeft = loan.dueDate.difference(DateTime.now()).inDays;
          if (daysLeft <= 3 && daysLeft >= 0) {
            notifications.add(AppNotification(
              id: 'notif_due_${loan.id}',
              title: 'Batas Pengembalian Dekat',
              message: 'Buku "${loan.bookTitle}" harus dikembalikan dalam $daysLeft hari.',
              type: NotificationType.loanDueSoon,
              createdAt: DateTime.now(),
              relatedId: loan.id,
            ));
          }
        }

        // Overdue loan
        if (loan.status == LoanStatus.overdue || loan.isOverdue) {
          notifications.add(AppNotification(
            id: 'notif_overdue_${loan.id}',
            title: 'Peminjaman Terlambat',
            message: 'Buku "${loan.bookTitle}" sudah melewati batas pengembalian!',
            type: NotificationType.loanOverdue,
            createdAt: loan.dueDate,
            relatedId: loan.id,
          ));
        }

        // Returned loan
        if (loan.status == LoanStatus.returned && loan.returnDate != null) {
          notifications.add(AppNotification(
            id: 'notif_returned_${loan.id}',
            title: 'Pengembalian Berhasil',
            message: 'Buku "${loan.bookTitle}" telah dikembalikan.',
            type: NotificationType.loanReturned,
            createdAt: loan.returnDate!,
            relatedId: loan.id,
          ));
        }
      }

      // Sort by date (newest first)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = state.copyWith(notifications: notifications);
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void refresh() {
    _generateNotifications();
  }

  void markAsRead(String notificationId) {
    final updated = state.notifications.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    state = state.copyWith(notifications: updated);
  }

  void markAllAsRead() {
    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated);
  }

  void clearAll() {
    state = state.copyWith(notifications: []);
  }
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);

// Unread count provider for easy access
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});
