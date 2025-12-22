import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/core.dart';
import '../../auth/auth_provider.dart';
import '../../books/book_provider.dart';
import '../../booking/booking_provider.dart';
import '../../favorite/favorite_provider.dart';

class BookDetailScreen extends ConsumerWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(bookByIdProvider(bookId));
    final authState = ref.watch(authProvider);
    final bookingState = ref.watch(bookingProvider);

    ref.listen<BookingState>(bookingProvider, (previous, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(bookingProvider.notifier).clearMessages();
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(bookingProvider.notifier).clearMessages();
      }
    });

    if (book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Buku tidak ditemukan')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.1),
                      AppColors.background,
                    ],
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Hero(
                      tag: 'book_${book.id}',
                      child: Container(
                        width: 150,
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            book.coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              child: const Icon(LucideIcons.bookOpen, size: 48),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Book Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Author
                  Text(
                    book.author,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Badges
                  Row(
                    children: [
                      _buildBadge(
                        label: book.isAvailable ? 'Tersedia' : 'Tidak Tersedia',
                        color: book.isAvailable ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      _buildBadge(
                        label: book.type == BookType.ebook ? 'E-Book' : 'Fisik',
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Info Grid
                  _buildInfoGrid(context, book),
                  const SizedBox(height: 24),

                  // Synopsis
                  Text(
                    'Sinopsis',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppShadows.cardShadow,
                    ),
                    child: Text(
                      book.description.isNotEmpty
                          ? book.description
                          : 'Deskripsi buku tidak tersedia.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, ref, book, authState, bookingState),
    );
  }

  Widget _buildBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoGrid(BuildContext context, Book book) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoItem(
              context,
              icon: LucideIcons.calendar,
              label: 'Tahun',
              value: '2024',
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildInfoItem(
              context,
              icon: LucideIcons.folder,
              label: 'Kategori',
              value: book.category,
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildInfoItem(
              context,
              icon: LucideIcons.package,
              label: book.type == BookType.ebook ? 'Format' : 'Stok',
              value: book.type == BookType.ebook ? 'Digital' : '${book.stock}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 50,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    Book book,
    AuthState authState,
    BookingState bookingState,
  ) {
    final favoriteState = ref.watch(favoriteProvider);
    final isFavorite = favoriteState.isFavorite(book.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.bottomBarShadow,
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Favorite Button
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isFavorite ? AppColors.error : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () {
                  if (authState.user != null) {
                    ref.read(favoriteProvider.notifier).toggleFavorite(
                          authState.user!.id,
                          book.id,
                        );
                  }
                },
                icon: Icon(
                  isFavorite ? LucideIcons.heartOff : LucideIcons.heart,
                  color: isFavorite ? AppColors.error : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Action Buttons
            Expanded(
              child: _buildActionButtons(context, ref, book, authState, bookingState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    Book book,
    AuthState authState,
    BookingState bookingState,
  ) {
    if (book.type == BookType.ebook) {
      return SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () => context.push('/reader/${book.id}'),
          icon: const Icon(LucideIcons.bookOpen),
          label: const Text('Baca E-Book'),
        ),
      );
    }

    if (book.stock <= 0) {
      return SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade300,
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: const Text('Stok Habis'),
        ),
      );
    }

    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: bookingState.isLoading
            ? null
            : () {
                if (authState.user != null) {
                  ref
                      .read(bookingProvider.notifier)
                      .createBooking(book, authState.user!);
                }
              },
        icon: bookingState.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(LucideIcons.calendarCheck),
        label: Text(bookingState.isLoading ? 'Memproses...' : 'Booking Sekarang'),
      ),
    );
  }
}
