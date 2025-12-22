import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/core.dart';
import '../auth/auth_provider.dart';

enum LoanFilter { all, active, returned, overdue }

class LoanState {
  final List<Loan> loans;
  final List<Booking> allActiveBookings; // For admin view
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final LoanFilter filter;

  const LoanState({
    this.loans = const [],
    this.allActiveBookings = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.filter = LoanFilter.all,
  });

  List<Loan> get activeLoans =>
      loans.where((l) => l.status == LoanStatus.active && !l.isOverdue).toList();

  List<Loan> get returnedLoans =>
      loans.where((l) => l.status == LoanStatus.returned).toList();

  List<Loan> get overdueLoans =>
      loans.where((l) => l.status == LoanStatus.active && l.isOverdue).toList();

  List<Loan> get filteredLoans {
    switch (filter) {
      case LoanFilter.active:
        return activeLoans;
      case LoanFilter.returned:
        return returnedLoans;
      case LoanFilter.overdue:
        return overdueLoans;
      case LoanFilter.all:
        return loans;
    }
  }

  LoanState copyWith({
    List<Loan>? loans,
    List<Booking>? allActiveBookings,
    bool? isLoading,
    String? error,
    String? successMessage,
    LoanFilter? filter,
    bool clearMessages = false,
  }) {
    return LoanState(
      loans: loans ?? this.loans,
      allActiveBookings: allActiveBookings ?? this.allActiveBookings,
      isLoading: isLoading ?? this.isLoading,
      error: clearMessages ? null : error,
      successMessage: clearMessages ? null : successMessage,
      filter: filter ?? this.filter,
    );
  }
}

class LoanNotifier extends Notifier<LoanState> {
  @override
  LoanState build() => const LoanState();

  HiveDataService get _mockService => ref.read(mockDataServiceProvider);

  /// Load all active bookings (Admin)
  Future<void> loadActiveBookings() async {
    state = state.copyWith(isLoading: true, clearMessages: true);

    try {
      final bookings = await _mockService.getAllActiveBookings();
      state = state.copyWith(allActiveBookings: bookings, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load bookings: $e',
      );
    }
  }

  /// Load all loans (Admin)
  Future<void> loadAllLoans() async {
    state = state.copyWith(isLoading: true, clearMessages: true);

    try {
      final loans = await _mockService.getAllLoans();
      state = state.copyWith(loans: loans, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load loans: $e',
      );
    }
  }

  /// Load user's loans
  Future<void> loadUserLoans(String userId) async {
    state = state.copyWith(isLoading: true, clearMessages: true);

    try {
      final loans = await _mockService.getUserLoans(userId);
      state = state.copyWith(loans: loans, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load loans: $e',
      );
    }
  }

  /// Set filter
  void setFilter(LoanFilter filter) {
    state = state.copyWith(filter: filter);
  }

  /// Claim booking and create loan (Admin action)
  Future<bool> claimBooking(String bookingId) async {
    state = state.copyWith(isLoading: true, clearMessages: true);

    try {
      // Find booking
      final booking = await _mockService.getBookingById(bookingId);

      if (booking == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Booking not found.',
        );
        return false;
      }

      if (booking.status != BookingStatus.active) {
        state = state.copyWith(
          isLoading: false,
          error: 'Booking already claimed or expired.',
        );
        return false;
      }

      if (booking.isExpired) {
        state = state.copyWith(
          isLoading: false,
          error: 'Booking expired (more than 24 hours).',
        );
        return false;
      }

      // Claim booking and create loan
      final loan = await _mockService.claimBooking(bookingId);

      if (loan == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to claim booking.',
        );
        return false;
      }

      // Update local state
      final updatedLoans = [...state.loans, loan];
      final updatedBookings =
          state.allActiveBookings.where((b) => b.id != bookingId).toList();

      state = state.copyWith(
        loans: updatedLoans,
        allActiveBookings: updatedBookings,
        isLoading: false,
        successMessage: 'Book handed over successfully! Loan ID: ${loan.id}',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An error occurred: $e',
      );
      return false;
    }
  }

  /// Return book (Admin action)
  Future<bool> returnBook(String loanId) async {
    state = state.copyWith(isLoading: true, clearMessages: true);

    try {
      final loan = await _mockService.returnBook(loanId);

      if (loan == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to return book.',
        );
        return false;
      }

      // Update local state
      final updatedLoans = state.loans.map((l) {
        if (l.id == loanId) return loan;
        return l;
      }).toList();

      state = state.copyWith(
        loans: updatedLoans,
        isLoading: false,
        successMessage: 'Book returned successfully!',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An error occurred: $e',
      );
      return false;
    }
  }

  /// Validate booking from QR code data
  Future<Map<String, dynamic>?> validateBookingFromQR(String qrData) async {
    state = state.copyWith(isLoading: true, clearMessages: true);

    try {
      // Parse QR data (format: {"bookingId": "xxx", "userId": "xxx"})
      final Map<String, dynamic> data = _parseQRData(qrData);
      final bookingId = data['bookingId'] as String?;

      if (bookingId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid QR Code.',
        );
        return null;
      }

      // Get booking details
      final booking = await _mockService.getBookingById(bookingId);
      if (booking == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Booking not found.',
        );
        return null;
      }

      // Get user details using booking's userId
      final user = await _mockService.getUserById(booking.userId);

      // Get book details
      final book = await _mockService.getBookById(booking.bookId);

      state = state.copyWith(isLoading: false);

      return {
        'booking': booking,
        'user': user,
        'book': book,
      };
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to validate QR: $e',
      );
      return null;
    }
  }

  Map<String, dynamic> _parseQRData(String qrData) {
    try {
      final cleaned = qrData.trim();
      if (cleaned.startsWith('{') && cleaned.endsWith('}')) {
        final bookingIdMatch =
            RegExp(r'"bookingId"\s*:\s*"([^"]+)"').firstMatch(cleaned);
        final userIdMatch =
            RegExp(r'"userId"\s*:\s*"([^"]+)"').firstMatch(cleaned);

        return {
          'bookingId': bookingIdMatch?.group(1),
          'userId': userIdMatch?.group(1),
        };
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }
}

// Provider
final loanProvider = NotifierProvider<LoanNotifier, LoanState>(
  LoanNotifier.new,
);
