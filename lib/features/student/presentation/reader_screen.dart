import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/core.dart';
import '../../books/book_provider.dart';

// Conditional import for web
import 'reader_web.dart' if (dart.library.io) 'reader_mobile.dart' as reader;

class ReaderScreen extends ConsumerStatefulWidget {
  final String bookId;

  const ReaderScreen({super.key, required this.bookId});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate loading
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _openInBrowser(String? url) async {
    if (url == null || url.isEmpty) return;

    // Convert embed URL to regular URL for browser
    final browserUrl = url.replaceAll('/embed/', '/details/');
    
    try {
      final uri = Uri.parse(browserUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(bookByIdProvider(widget.bookId));

    if (book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Buku tidak ditemukan')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          book.title,
          style: const TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.externalLink),
            onPressed: () => _openInBrowser(book.contentUrl),
            tooltip: 'Buka di Browser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat e-book...'),
                ],
              ),
            )
          : _buildReaderContent(book),
    );
  }

  Widget _buildReaderContent(Book book) {
    if (book.contentUrl == null || book.contentUrl!.isEmpty) {
      return _buildNoContentView(book);
    }

    // Use platform-specific reader
    return reader.buildEbookReader(
      context: context,
      book: book,
      onError: () => _buildNoContentView(book),
    );
  }

  Widget _buildNoContentView(Book book) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            LucideIcons.bookX,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Konten tidak tersedia',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'E-book ini tidak memiliki konten yang dapat ditampilkan.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (book.contentUrl != null)
            ElevatedButton.icon(
              onPressed: () => _openInBrowser(book.contentUrl),
              icon: const Icon(LucideIcons.externalLink),
              label: const Text('Buka di Browser'),
            ),
        ],
      ),
    );
  }
}
