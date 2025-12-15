import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/core.dart';
import '../auth/auth_provider.dart';

class BookListState {
  final List<Book> books;
  final bool isLoading;
  final String? error;
  final BookType? filterType;

  const BookListState({
    this.books = const [],
    this.isLoading = false,
    this.error,
    this.filterType,
  });

  List<Book> get filteredBooks {
    if (filterType == null) return books;
    return books.where((b) => b.type == filterType).toList();
  }

  List<Book> get physicalBooks =>
      books.where((b) => b.type == BookType.physical).toList();

  List<Book> get ebooks => books.where((b) => b.type == BookType.ebook).toList();

  List<Book> get availableBooks => books.where((b) => b.isAvailable).toList();

  BookListState copyWith({
    List<Book>? books,
    bool? isLoading,
    String? error,
    BookType? filterType,
    bool clearFilter = false,
  }) {
    return BookListState(
      books: books ?? this.books,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filterType: clearFilter ? null : (filterType ?? this.filterType),
    );
  }
}

class BookListNotifier extends Notifier<BookListState> {
  @override
  BookListState build() {
    // Schedule loading after build completes
    Future.microtask(() => _loadBooks());
    return const BookListState(isLoading: true);
  }

  MockDataService get _mockService => ref.read(mockDataServiceProvider);

  Future<void> _loadBooks() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final books = await _mockService.getAllBooks();
      state = state.copyWith(books: books, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load books: $e',
      );
    }
  }

  Future<void> refresh() async {
    await _loadBooks();
  }

  void setFilter(BookType? type) {
    if (type == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(filterType: type);
    }
  }

  /// Update stock locally (called after booking)
  void decrementStock(String bookId) {
    final updatedBooks = state.books.map((book) {
      if (book.id == bookId && book.stock > 0) {
        return book.copyWith(stock: book.stock - 1);
      }
      return book;
    }).toList();

    state = state.copyWith(books: updatedBooks);
  }

  /// Restore stock locally (called after return)
  void incrementStock(String bookId) {
    final updatedBooks = state.books.map((book) {
      if (book.id == bookId) {
        return book.copyWith(stock: book.stock + 1);
      }
      return book;
    }).toList();

    state = state.copyWith(books: updatedBooks);
  }

  Book? getBookById(String id) {
    try {
      return state.books.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}

// Providers
final bookListProvider = NotifierProvider<BookListNotifier, BookListState>(
  BookListNotifier.new,
);

// Search query notifier
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final bookSearchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

final searchedBooksProvider = Provider<List<Book>>((ref) {
  final query = ref.watch(bookSearchQueryProvider).toLowerCase();
  final books = ref.watch(bookListProvider).books;

  if (query.isEmpty) return books;

  return books
      .where((b) =>
          b.title.toLowerCase().contains(query) ||
          b.author.toLowerCase().contains(query))
      .toList();
});

// Single book provider
final bookByIdProvider = Provider.family<Book?, String>((ref, id) {
  final books = ref.watch(bookListProvider).books;
  try {
    return books.firstWhere((b) => b.id == id);
  } catch (_) {
    return null;
  }
});
