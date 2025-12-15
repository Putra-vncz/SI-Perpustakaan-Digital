import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/core.dart';
import '../auth/auth_provider.dart';
import '../books/book_provider.dart';

class BookingState {
  final List<Booking> bookings;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const BookingState({
    this.bookings = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  List<Booking> get activeBookings =>
      bookings.where((b) => b.status == BookingStatus.active).toList();

  List<Booking> get claimedBookings =>
      bookings.where((b) => b.status == BookingStatus.claimed).toList();

  List<Booking> get historyBookings =>
      bookings.where((b) => b.status != BookingStatus.active).toList();

  int get activeBookingCount => activeBookings.length;

  BookingState copyWith({
    List<Booking>? bookings,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return BookingState(
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      error: clearMessages ? null : error,
      successMessage: clearMessages ? null : successMessage,
    );
  }
}

class BookingNotifier extends Notifier<BookingState> {
  static const int maxActiveBookings = 3;

  @override
  BookingState build() => const BookingState();

  MockDataService get _mockService => ref.read(mockDataServiceProvider);

  /// Load user's bookings
  Future<void> loadUserBookings(String userId) async {
    state = state.copyWith(isLoading: true, clearMessages: true);

    try {
      final bookings = await _mockService.getUserBookings(userId);
      state = state.copyWith(bookings: bookings, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load bookings: $e',
      );
    }
  }

  /// Create a new booking (CRITICAL LOGIC)
  Future<bool> createBooking(Book book, User user) async {
    state = state.copyWith(isLoading: true, clearMessages: true);

    try {
      // Validation 1: Check if book is physical
      if (book.type != BookType.physical) {
        state = state.copyWith(
          isLoading: false,
          error: 'E-books do not need booking. Just read directly!',
        );
        return false;
      }

      // Validation 2: Check stock > 0
      if (book.stock <= 0) {
        state = state.copyWith(
          isLoading: false,
          error: 'Out of stock! This book is currently unavailable.',
        );
        return false;
      }

      // Validation 3: Check max active bookings (max 3)
      if (state.activeBookingCount >= maxActiveBookings) {
        state = state.copyWith(
          isLoading: false,
          error:
              'Maximum $maxActiveBookings active bookings. Pick up your booked books first.',
        );
        return false;
      }

      // Validation 4: Check if user already booked this book
      final alreadyBooked =
          state.activeBookings.any((b) => b.bookId == book.id);
      if (alreadyBooked) {
        state = state.copyWith(
          isLoading: false,
          error: 'You have already booked this book.',
        );
        return false;
      }

      // Validation 5: Check for active fines (mock: always false)
      final hasFines = await _mockService.hasActiveFines(user.id);
      if (hasFines) {
        state = state.copyWith(
          isLoading: false,
          error: 'You have unpaid fines.',
        );
        return false;
      }

      // Create booking via MockService
      final booking = await _mockService.createBooking(user.id, book.id);

      if (booking == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to create booking. Please try again.',
        );
        return false;
      }

      // Update local state
      final updatedBookings = [...state.bookings, booking];
      state = state.copyWith(
        bookings: updatedBookings,
        isLoading: false,
        successMessage: 'Booking successful! Pick up within 24 hours.',
      );

      // Update book stock in BookListProvider (UI updates immediately)
      ref.read(bookListProvider.notifier).decrementStock(book.id);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An error occurred: $e',
      );
      return false;
    }
  }

  /// Get booking by ID
  Booking? getBookingById(String id) {
    try {
      return state.bookings.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Clear messages
  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }

  /// Refresh bookings
  Future<void> refresh(String userId) async {
    await loadUserBookings(userId);
  }
}

// Provider
final bookingProvider = NotifierProvider<BookingNotifier, BookingState>(
  BookingNotifier.new,
);

// Booking by ID provider
final bookingByIdProvider = Provider.family<Booking?, String>((ref, id) {
  return ref.watch(bookingProvider.notifier).getBookingById(id);
});
