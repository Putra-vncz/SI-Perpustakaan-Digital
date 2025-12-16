import 'package:hive_flutter/hive_flutter.dart';
import '../enums/user_role.dart';
import '../enums/book_type.dart';
import '../enums/booking_status.dart';
import '../enums/loan_status.dart';
import '../models/user.dart';
import '../models/book.dart';
import '../models/booking.dart';
import '../models/loan.dart';

class HiveDataService {
  static final HiveDataService _instance = HiveDataService._internal();
  factory HiveDataService() => _instance;
  HiveDataService._internal();

  static HiveDataService get instance => _instance;

  // Box names
  static const String _userBoxName = 'users';
  static const String _bookBoxName = 'books';
  static const String _bookingBoxName = 'bookings';
  static const String _loanBoxName = 'loans';
  static const String _settingsBoxName = 'settings';

  // Boxes
  late Box<User> _userBox;
  late Box<Book> _bookBox;
  late Box<Booking> _bookingBox;
  late Box<Loan> _loanBox;
  late Box _settingsBox;

  bool _isInitialized = false;

  /// Initialize Hive and open all boxes
  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize Hive
    await Hive.initFlutter();

    // Register adapters
    _registerAdapters();

    try {
      // Open boxes
      _userBox = await Hive.openBox<User>(_userBoxName);
      _bookBox = await Hive.openBox<Book>(_bookBoxName);
      _bookingBox = await Hive.openBox<Booking>(_bookingBoxName);
      _loanBox = await Hive.openBox<Loan>(_loanBoxName);
      _settingsBox = await Hive.openBox(_settingsBoxName);
    } catch (e) {
      // If there's an error (e.g., schema change), clear all data and retry
      await Hive.deleteBoxFromDisk(_userBoxName);
      await Hive.deleteBoxFromDisk(_bookBoxName);
      await Hive.deleteBoxFromDisk(_bookingBoxName);
      await Hive.deleteBoxFromDisk(_loanBoxName);
      await Hive.deleteBoxFromDisk(_settingsBoxName);

      _userBox = await Hive.openBox<User>(_userBoxName);
      _bookBox = await Hive.openBox<Book>(_bookBoxName);
      _bookingBox = await Hive.openBox<Booking>(_bookingBoxName);
      _loanBox = await Hive.openBox<Loan>(_loanBoxName);
      _settingsBox = await Hive.openBox(_settingsBoxName);
    }

    // Seed data if first launch
    await _seedDataIfNeeded();

    _isInitialized = true;
  }

  void _registerAdapters() {
    // Register enum adapters
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(UserRoleAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(BookTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(BookingStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(LoanStatusAdapter());
    }

    // Register model adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(BookAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(BookingAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(LoanAdapter());
    }
  }


  /// Seed default admin account (registered by university)
  Future<void> _seedDataIfNeeded() async {
    // Only seed admin if no admin exists
    final hasAdminAccount = _userBox.values.any((u) => u.role == UserRole.admin);
    if (!hasAdminAccount) {
      final admin = User(
        id: 'admin_001',
        name: 'Admin Perpustakaan',
        email: 'admin@university.edu',
        password: 'admin123',
        role: UserRole.admin,
        studentId: null,
      );
      await _userBox.put(admin.id, admin);
    }
  }


  // ============ AUTH ============
  
  /// Login student with NIM (9 digits) and password
  Future<User?> loginStudent(String nim, String password) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      final user = _userBox.values.firstWhere(
        (u) => u.studentId == nim && u.role == UserRole.student,
      );
      if (user.password == password) {
        return user;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Login admin with email and password
  Future<User?> loginAdmin(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      final user = _userBox.values.firstWhere(
        (u) => u.email == email && u.role == UserRole.admin,
      );
      if (user.password == password) {
        return user;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Register new user
  Future<User?> registerUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? studentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    // Check if email already exists
    final emailExists = _userBox.values.any((u) => u.email == email);
    if (emailExists) return null;

    // Check if studentId already exists (for students)
    if (studentId != null) {
      final nimExists = _userBox.values.any((u) => u.studentId == studentId);
      if (nimExists) return null;
    }

    final user = User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      password: password,
      role: role,
      studentId: studentId,
    );

    await _userBox.put(user.id, user);
    return user;
  }

  /// Check if any admin exists
  Future<bool> hasAdmin() async {
    return _userBox.values.any((u) => u.role == UserRole.admin);
  }

  /// Check if any user exists
  Future<bool> hasUsers() async {
    return _userBox.values.isNotEmpty;
  }

  Future<User?> getUserById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _userBox.get(id);
  }


  // ============ BOOKS ============
  Future<List<Book>> getAllBooks() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _bookBox.values.toList();
  }

  Future<List<Book>> getBooksByType(BookType type) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _bookBox.values.where((b) => b.type == type).toList();
  }

  Future<Book?> getBookById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _bookBox.get(id);
  }

  Future<List<Book>> searchBooks(String query) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final lowerQuery = query.toLowerCase();
    return _bookBox.values
        .where((b) =>
            b.title.toLowerCase().contains(lowerQuery) ||
            b.author.toLowerCase().contains(lowerQuery))
        .toList();
  }

  Future<Book> addBook(Book book) async {
    await Future.delayed(const Duration(milliseconds: 100));
    await _bookBox.put(book.id, book);
    return book;
  }

  Future<void> updateBook(Book book) async {
    await Future.delayed(const Duration(milliseconds: 100));
    await _bookBox.put(book.id, book);
  }


  // ============ BOOKINGS ============
  Future<Booking?> createBooking(String userId, String bookId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    final book = _bookBox.get(bookId);
    if (book == null) return null;
    if (book.type != BookType.physical || book.stock <= 0) return null;

    // Decrease stock
    final updatedBook = book.copyWith(stock: book.stock - 1);
    await _bookBox.put(bookId, updatedBook);

    final now = DateTime.now();
    final booking = Booking(
      id: 'booking_${now.millisecondsSinceEpoch}',
      userId: userId,
      bookId: bookId,
      bookingDate: now,
      expiryDate: now.add(const Duration(hours: 24)),
      status: BookingStatus.active,
    );

    await _bookingBox.put(booking.id, booking);
    return booking;
  }

  Future<List<Booking>> getUserBookings(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _bookingBox.values.where((b) => b.userId == userId).toList();
  }

  Future<Booking?> getBookingById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _bookingBox.get(id);
  }

  Future<List<Booking>> getAllActiveBookings() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _bookingBox.values
        .where((b) => b.status == BookingStatus.active)
        .toList();
  }

  Future<bool> cancelBooking(String bookingId) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final booking = _bookingBox.get(bookingId);
    if (booking == null) return false;
    if (booking.status != BookingStatus.active) return false;

    // Update booking status to cancelled
    final updatedBooking = booking.copyWith(status: BookingStatus.cancelled);
    await _bookingBox.put(bookingId, updatedBooking);

    // Restore book stock
    final book = _bookBox.get(booking.bookId);
    if (book != null) {
      final updatedBook = book.copyWith(stock: book.stock + 1);
      await _bookBox.put(book.id, updatedBook);
    }

    return true;
  }


  // ============ LOANS ============
  Future<Loan?> claimBooking(String bookingId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    final booking = _bookingBox.get(bookingId);
    if (booking == null) return null;
    if (booking.status != BookingStatus.active) return null;

    // Get user and book info
    final user = _userBox.get(booking.userId);
    final book = _bookBox.get(booking.bookId);
    if (user == null || book == null) return null;

    // Update booking status
    final updatedBooking = booking.copyWith(status: BookingStatus.claimed);
    await _bookingBox.put(bookingId, updatedBooking);

    // Create loan
    final now = DateTime.now();
    final loan = Loan(
      id: 'loan_${now.millisecondsSinceEpoch}',
      bookingId: bookingId,
      userId: booking.userId,
      userName: user.name,
      bookId: booking.bookId,
      bookTitle: book.title,
      loanDate: now,
      dueDate: now.add(const Duration(days: 14)),
      status: LoanStatus.active,
    );

    await _loanBox.put(loan.id, loan);
    return loan;
  }

  Future<Loan?> returnBook(String loanId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    final loan = _loanBox.get(loanId);
    if (loan == null) return null;
    if (loan.status != LoanStatus.active) return null;

    // Update loan
    final updatedLoan = loan.copyWith(
      returnDate: DateTime.now(),
      status: LoanStatus.returned,
    );
    await _loanBox.put(loanId, updatedLoan);

    // Restore book stock
    final booking = _bookingBox.get(loan.bookingId);
    if (booking != null) {
      final book = _bookBox.get(booking.bookId);
      if (book != null) {
        final updatedBook = book.copyWith(stock: book.stock + 1);
        await _bookBox.put(book.id, updatedBook);
      }
    }

    return updatedLoan;
  }

  Future<List<Loan>> getUserLoans(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _loanBox.values.where((l) => l.userId == userId).toList();
  }

  Future<List<Loan>> getAllActiveLoans() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _loanBox.values
        .where((l) => l.status == LoanStatus.active)
        .toList();
  }

  Future<List<Loan>> getAllLoans() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _loanBox.values.toList();
  }

  Future<bool> hasActiveFines(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return false; // Mock - always false
  }
}
