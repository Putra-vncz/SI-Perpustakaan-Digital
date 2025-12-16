import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';
import '../enums/book_type.dart';

/// Service to fetch e-books from Open Library API
class EbookApiService {
  static final EbookApiService _instance = EbookApiService._internal();
  factory EbookApiService() => _instance;
  EbookApiService._internal();

  static EbookApiService get instance => _instance;

  static const String _baseUrl = 'https://openlibrary.org';

  // Cache for ebooks
  List<Book>? _cachedEbooks;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 30);

  /// Get list of free e-books with readable content
  Future<List<Book>> getEbooks() async {
    // Return cached data if valid
    if (_cachedEbooks != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedEbooks!;
    }

    // Use curated list of books with known Internet Archive IDs
    _cachedEbooks = _getCuratedEbooks();
    _cacheTime = DateTime.now();
    return _cachedEbooks!;
  }

  /// Search ebooks by query from Open Library
  Future<List<Book>> searchEbooks(String query) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/search.json?q=$query&has_fulltext=true&limit=10'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final docs = data['docs'] as List<dynamic>;

        return docs.map((doc) {
          final coverId = doc['cover_i'];
          final coverUrl = coverId != null
              ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
              : 'https://picsum.photos/seed/${doc['key']}/200/300';

          final authors = doc['author_name'] as List<dynamic>?;
          final author = authors?.isNotEmpty == true
              ? authors!.first.toString()
              : 'Unknown Author';

          // Get Internet Archive ID if available
          final iaIds = doc['ia'] as List<dynamic>?;
          final iaId = iaIds?.isNotEmpty == true ? iaIds!.first.toString() : null;
          
          // Create embed URL for Internet Archive reader
          final contentUrl = iaId != null
              ? 'https://archive.org/embed/$iaId'
              : 'https://openlibrary.org${doc['key']}';

          return Book(
            id: 'ebook_${doc['key'].toString().replaceAll('/', '_')}',
            title: doc['title'] ?? 'Untitled',
            author: author,
            description: doc['first_sentence'] != null
                ? (doc['first_sentence'] as List).first.toString()
                : 'E-book tersedia untuk dibaca langsung.',
            coverUrl: coverUrl,
            type: BookType.ebook,
            stock: 0,
            category: 'E-Book',
            contentUrl: contentUrl,
          );
        }).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  /// Curated list of ebooks with known Internet Archive IDs for reliable reading
  List<Book> _getCuratedEbooks() {
    return [
      Book(
        id: 'ebook_001',
        title: 'Pride and Prejudice',
        author: 'Jane Austen',
        description:
            'A classic novel about love and social standing in early 19th-century England. Follow Elizabeth Bennet as she navigates society and her feelings for Mr. Darcy.',
        coverUrl: 'https://covers.openlibrary.org/b/id/8231856-M.jpg',
        type: BookType.ebook,
        stock: 0,
        category: 'Fiction',
        contentUrl: 'https://archive.org/embed/prideandprejudice_1601_librivox',
      ),
      Book(
        id: 'ebook_002',
        title: 'Moby Dick',
        author: 'Herman Melville',
        description:
            'The epic tale of Captain Ahab\'s obsessive quest for the white whale. A masterpiece of American literature.',
        coverUrl: 'https://covers.openlibrary.org/b/id/8228691-M.jpg',
        type: BookType.ebook,
        stock: 0,
        category: 'Fiction',
        contentUrl: 'https://archive.org/embed/moby_dick_librivox',
      ),
      Book(
        id: 'ebook_003',
        title: 'Frankenstein',
        author: 'Mary Shelley',
        description:
            'The story of Victor Frankenstein and his monstrous creation. A pioneering work of science fiction and gothic horror.',
        coverUrl: 'https://covers.openlibrary.org/b/id/6788811-M.jpg',
        type: BookType.ebook,
        stock: 0,
        category: 'Fiction',
        contentUrl: 'https://archive.org/embed/frankenstein_1818_librivox',
      ),
      Book(
        id: 'ebook_004',
        title: 'Dracula',
        author: 'Bram Stoker',
        description:
            'The classic vampire novel that defined the genre. Follow Jonathan Harker as he encounters the mysterious Count Dracula.',
        coverUrl: 'https://covers.openlibrary.org/b/id/8406786-M.jpg',
        type: BookType.ebook,
        stock: 0,
        category: 'Fiction',
        contentUrl: 'https://archive.org/embed/dracula_bram_stoker_librivox',
      ),
      Book(
        id: 'ebook_005',
        title: 'The Adventures of Sherlock Holmes',
        author: 'Arthur Conan Doyle',
        description:
            'A collection of twelve short stories featuring the famous detective Sherlock Holmes and his companion Dr. Watson.',
        coverUrl: 'https://covers.openlibrary.org/b/id/12645114-M.jpg',
        type: BookType.ebook,
        stock: 0,
        category: 'Fiction',
        contentUrl: 'https://archive.org/embed/adventuresofsher00doylrich',
      ),
      Book(
        id: 'ebook_006',
        title: 'Alice\'s Adventures in Wonderland',
        author: 'Lewis Carroll',
        description:
            'Follow Alice down the rabbit hole into a fantastical world of wonder. A beloved classic of children\'s literature.',
        coverUrl: 'https://covers.openlibrary.org/b/id/8479576-M.jpg',
        type: BookType.ebook,
        stock: 0,
        category: 'Fiction',
        contentUrl: 'https://archive.org/embed/alicesadventures19033gut',
      ),
      Book(
        id: 'ebook_007',
        title: 'The Great Gatsby',
        author: 'F. Scott Fitzgerald',
        description:
            'A portrait of the Jazz Age in all of its decadence and excess. The story of the mysteriously wealthy Jay Gatsby.',
        coverUrl: 'https://covers.openlibrary.org/b/id/7222246-M.jpg',
        type: BookType.ebook,
        stock: 0,
        category: 'Fiction',
        contentUrl: 'https://archive.org/embed/greatgatsby0000fitz_k6o4',
      ),
      Book(
        id: 'ebook_008',
        title: 'A Tale of Two Cities',
        author: 'Charles Dickens',
        description:
            'Set during the French Revolution, this novel tells the story of sacrifice and resurrection in London and Paris.',
        coverUrl: 'https://covers.openlibrary.org/b/id/12818044-M.jpg',
        type: BookType.ebook,
        stock: 0,
        category: 'Fiction',
        contentUrl: 'https://archive.org/embed/taleoftwocities00dick',
      ),
      Book(
        id: 'ebook_009',
        title: 'The Picture of Dorian Gray',
        author: 'Oscar Wilde',
        description:
            'A philosophical novel about a young man whose portrait ages while he remains young. A tale of beauty, corruption, and morality.',
        coverUrl: 'https://covers.openlibrary.org/b/id/12818519-M.jpg',
        type: BookType.ebook,
        stock: 0,
        category: 'Fiction',
        contentUrl: 'https://archive.org/embed/pictureofdoriangray00wild',
      ),
      Book(
        id: 'ebook_010',
        title: 'War and Peace',
        author: 'Leo Tolstoy',
        description:
            'An epic novel that chronicles the history of the French invasion of Russia through the stories of five aristocratic families.',
        coverUrl: 'https://covers.openlibrary.org/b/id/12818520-M.jpg',
        type: BookType.ebook,
        stock: 0,
        category: 'Fiction',
        contentUrl: 'https://archive.org/embed/warandpeace00tols',
      ),
    ];
  }

  /// Clear cache
  void clearCache() {
    _cachedEbooks = null;
    _cacheTime = null;
  }
}
