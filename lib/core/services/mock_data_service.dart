import '../enums/enums.dart';
import '../models/models.dart';

class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  // Simulated delay for API calls (reduced for better UX)
  Future<T> _simulateDelay<T>(T data) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return data;
  }

  // Mock Users
  final List<User> _users = [
    const User(
      id: 'user_1',
      name: 'John Student',
      email: 'john@university.edu',
      role: UserRole.student,
      studentId: '2021001',
    ),
    const User(
      id: 'user_2',
      name: 'Jane Librarian',
      email: 'jane@university.edu',
      role: UserRole.admin,
      studentId: null,
    ),
    const User(
      id: 'user_3',
      name: 'Bob Scholar',
      email: 'bob@university.edu',
      role: UserRole.student,
      studentId: '2021002',
    ),
  ];

  // Mock Books (2 Physical, 2 Ebooks, 1 Out of Stock)
  final List<Book> _books = [
    const Book(
      id: 'book_1',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      coverUrl: 'https://images-na.ssl-images-amazon.com/images/I/41xShlnTZTL._SX376_BO1,204,203,200_.jpg',
      type: BookType.physical,
      stock: 3,
      shelfLocation: 'A-12-3',
    ),
    const Book(
      id: 'book_2',
      title: 'The Pragmatic Programmer',
      author: 'David Thomas & Andrew Hunt',
      coverUrl: 'https://images-na.ssl-images-amazon.com/images/I/51cUVaBWZzL._SX380_BO1,204,203,200_.jpg',
      type: BookType.physical,
      stock: 5,
      shelfLocation: 'B-05-1',
    ),
    const Book(
      id: 'book_3',
      title: 'Flutter in Action',
      author: 'Eric Windmill',
      coverUrl: 'https://images-na.ssl-images-amazon.com/images/I/41lYDa+ROHL._SX397_BO1,204,203,200_.jpg',
      type: BookType.ebook,
      stock: 0,
      pdfUrl: 'assets/sample.pdf',
    ),
    const Book(
      id: 'book_4',
      title: 'Dart Programming',
      author: 'Gilad Bracha',
      coverUrl: 'https://images-na.ssl-images-amazon.com/images/I/41Zy7ewMqzL._SX331_BO1,204,203,200_.jpg',
      type: BookType.ebook,
      stock: 0,
      pdfUrl: 'assets/sample.pdf',
    ),
    const Book(
      id: 'book_5',
      title: 'Design Patterns',
      author: 'Gang of Four',
      coverUrl: 'https://images-na.ssl-images-amazon.com/images/I/51szD9HC9pL._SX395_BO1,204,203,200_.jpg',
      type: BookType.physical,
      stock: 0, // Out of Stock
      shelfLocation: 'C-01-7',
    ),
  ];

  // Mock Bookings
  final List<Booking> _bookings = [];

  // Mock Loans
  final List<Loan> _loans = [];

  // ============ AUTH ============
  Future<User?> login(String identifier) async {
    return _simulateDelay(
      _users.cast<User?>().firstWhere(
            (u) => u!.email == identifier || u.studentId == identifier,
            orElse: () => null,
          ),
    );
  }

  Future<User?> getUserById(String id) async {
    return _simulateDelay(
      _users.cast<User?>().firstWhere(
            (u) => u!.id == id,
            orElse: () => null,
          ),
    );
  }

  // ============ BOOKS ============
  Future<List<Book>> getAllBooks() async {
    return _simulateDelay(List.from(_books));
  }

  Future<List<Book>> getBooksByType(BookType type) async {
    return _simulateDelay(
      _books.where((b) => b.type == type).toList(),
    );
  }

  Future<Book?> getBookById(String id) async {
    return _simulateDelay(
      _books.cast<Book?>().firstWhere(
            (b) => b!.id == id,
            orElse: () => null,
          ),
    );
  }

  Future<List<Book>> searchBooks(String query) async {
    final lowerQuery = query.toLowerCase();
    return _simulateDelay(
      _books
          .where((b) =>
              b.title.toLowerCase().contains(lowerQuery) ||
              b.author.toLowerCase().contains(lowerQuery))
          .toList(),
    );
  }

  // ============ BOOKINGS ============
  Future<Booking?> createBooking(String userId, String bookId) async {
    final bookIndex = _books.indexWhere((b) => b.id == bookId);
    if (bookIndex == -1) return _simulateDelay(null);

    final book = _books[bookIndex];
    if (book.type != BookType.physical || book.stock <= 0) {
      return _simulateDelay(null);
    }

    // Decrease stock
    _books[bookIndex] = book.copyWith(stock: book.stock - 1);

    final now = DateTime.now();
    final booking = Booking(
      id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      bookId: bookId,
      bookingDate: now,
      expiryDate: now.add(const Duration(hours: 24)),
      status: BookingStatus.active,
    );

    _bookings.add(booking);
    return _simulateDelay(booking);
  }

  Future<List<Booking>> getUserBookings(String userId) async {
    return _simulateDelay(
      _bookings.where((b) => b.userId == userId).toList(),
    );
  }

  Future<Booking?> getBookingById(String id) async {
    return _simulateDelay(
      _bookings.cast<Booking?>().firstWhere(
            (b) => b!.id == id,
            orElse: () => null,
          ),
    );
  }

  Future<List<Booking>> getAllActiveBookings() async {
    return _simulateDelay(
      _bookings.where((b) => b.status == BookingStatus.active).toList(),
    );
  }

  // ============ LOANS (Admin) ============
  Future<Loan?> claimBooking(String bookingId) async {
    final bookingIndex = _bookings.indexWhere((b) => b.id == bookingId);
    if (bookingIndex == -1) return _simulateDelay(null);

    final booking = _bookings[bookingIndex];
    if (booking.status != BookingStatus.active) {
      return _simulateDelay(null);
    }

    // Update booking status
    _bookings[bookingIndex] = booking.copyWith(status: BookingStatus.claimed);

    // Create loan
    final now = DateTime.now();
    final loan = Loan(
      id: 'loan_${DateTime.now().millisecondsSinceEpoch}',
      bookingId: bookingId,
      loanDate: now,
      dueDate: now.add(const Duration(days: 14)),
      status: LoanStatus.active,
    );

    _loans.add(loan);
    return _simulateDelay(loan);
  }

  Future<Loan?> returnBook(String loanId) async {
    final loanIndex = _loans.indexWhere((l) => l.id == loanId);
    if (loanIndex == -1) return _simulateDelay(null);

    final loan = _loans[loanIndex];
    if (loan.status != LoanStatus.active) {
      return _simulateDelay(null);
    }

    // Update loan
    _loans[loanIndex] = loan.copyWith(
      returnDate: DateTime.now(),
      status: LoanStatus.returned,
    );

    // Restore book stock
    final booking = _bookings.firstWhere((b) => b.id == loan.bookingId);
    final bookIndex = _books.indexWhere((b) => b.id == booking.bookId);
    if (bookIndex != -1) {
      _books[bookIndex] = _books[bookIndex].copyWith(
        stock: _books[bookIndex].stock + 1,
      );
    }

    return _simulateDelay(_loans[loanIndex]);
  }

  Future<List<Loan>> getUserLoans(String userId) async {
    final userBookingIds =
        _bookings.where((b) => b.userId == userId).map((b) => b.id).toSet();
    return _simulateDelay(
      _loans.where((l) => userBookingIds.contains(l.bookingId)).toList(),
    );
  }

  Future<List<Loan>> getAllActiveLoans() async {
    return _simulateDelay(
      _loans.where((l) => l.status == LoanStatus.active).toList(),
    );
  }

  // ============ FINES (Mock - always false) ============
  Future<bool> hasActiveFines(String userId) async {
    return _simulateDelay(false);
  }
}
