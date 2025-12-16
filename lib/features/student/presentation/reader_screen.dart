import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/core.dart';
import '../../books/book_provider.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String bookId;

  const ReaderScreen({super.key, required this.bookId});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  int _currentPage = 35;
  final int _totalPages = 100;
  bool _isBookmarked = false;

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() => _currentPage--);
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() => _currentPage++);
    }
  }

  void _toggleBookmark() {
    setState(() => _isBookmarked = !_isBookmarked);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBookmarked ? 'Bookmark added' : 'Bookmark removed'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Reader Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(LucideIcons.sun),
              title: const Text('Brightness'),
              subtitle: const Text('Adjust screen brightness'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(LucideIcons.type),
              title: const Text('Font Size'),
              subtitle: const Text('Change text size'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(LucideIcons.moon),
              title: const Text('Night Mode'),
              subtitle: const Text('Dark theme for reading'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(bookByIdProvider(widget.bookId));

    if (book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Book not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          book.title,
          style: const TextStyle(fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? LucideIcons.bookmarkMinus : LucideIcons.bookmark,
              color: _isBookmarked ? AppColors.secondary : null,
            ),
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: _currentPage / _totalPages,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          // PDF Content Placeholder
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.fileText,
                        size: 80,
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'PDF Reader',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reading: ${book.title}',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              LucideIcons.info,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This is a demo PDF reader.\nIn production, integrate with a PDF viewer package like syncfusion_flutter_pdfviewer or flutter_pdfview.',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bottom Controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.chevronLeft),
                    onPressed: _currentPage > 1 ? _previousPage : null,
                  ),
                  Text(
                    'Page $_currentPage of $_totalPages',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.chevronRight),
                    onPressed: _currentPage < _totalPages ? _nextPage : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
