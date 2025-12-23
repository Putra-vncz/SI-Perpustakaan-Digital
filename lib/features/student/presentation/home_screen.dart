import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/core.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/auth_provider.dart';
import '../../books/book_provider.dart';
import '../../notification/notification_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookState = ref.watch(bookListProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.bookOpen, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              'FST Library',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: Stack(
              children: [
                const Icon(LucideIcons.bell, color: AppColors.textSecondary),
                Consumer(
                  builder: (context, ref, _) {
                    final unreadCount = ref.watch(unreadNotificationCountProvider);
                    if (unreadCount == 0) return const SizedBox.shrink();
                    return Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: bookState.isLoading
          ? const LoadingWidget(message: 'Memuat buku...')
          : RefreshIndicator(
              onRefresh: () => ref.read(bookListProvider.notifier).refresh(),
              child: CustomScrollView(
                slivers: [
                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: GestureDetector(
                        onTap: () => context.go('/search'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppShadows.cardShadow,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.search,
                                color: AppColors.textLight,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Cari judul, penulis...',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textLight,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Hero Banner
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildHeroBanner(context, authState),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Buku Terbaru Section
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      context,
                      title: 'Buku Terbaru',
                      onSeeAll: () => context.go('/search'),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 240,
                      child: bookState.books.isEmpty
                          ? const Center(child: Text('Belum ada buku'))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: bookState.books.take(10).length,
                              itemBuilder: (context, index) {
                                final book = bookState.books[index];
                                return _buildBookCard(context, book);
                              },
                            ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Paling Banyak Dibaca Section
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      context,
                      title: 'Paling Banyak Dibaca',
                      onSeeAll: () => context.go('/search'),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= bookState.physicalBooks.take(5).length) {
                            return null;
                          }
                          final book = bookState.physicalBooks[index];
                          return _buildPopularBookItem(context, book, index + 1);
                        },
                        childCount: bookState.physicalBooks.take(5).length,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Loan Statistics Chart
                  const SliverToBoxAdapter(
                    child: LoanStatisticsChart(),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, AuthState authState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang,',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
                Text(
                  '${authState.user?.name.split(' ').first ?? 'Mahasiswa'}!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Temukan Referensi Akademik Terbaik',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/search'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Jelajahi'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.bookOpen,
              size: 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required VoidCallback onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'Lihat Semua',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(BuildContext context, Book book) {
    return GestureDetector(
      onTap: () => context.push('/detail/${book.id}'),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover with tag
            Stack(
              children: [
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppShadows.cardShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      book.coverUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.bookOpen,
                              size: 32,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                book.title,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: book.type == BookType.ebook
                          ? AppColors.primary
                          : AppColors.secondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      book.type == BookType.ebook ? 'E-BOOK' : 'FISIK',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              book.title,
              style: Theme.of(context).textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              book.author,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularBookItem(BuildContext context, Book book, int rank) {
    return GestureDetector(
      onTap: () => context.push('/detail/${book.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.cardShadow,
        ),
        child: Row(
          children: [
            // Rank
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: rank <= 3
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    color: rank <= 3 ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                book.coverUrl,
                width: 50,
                height: 70,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 50,
                    height: 70,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  width: 50,
                  height: 70,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(LucideIcons.bookOpen, size: 20, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: book.isAvailable
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          book.isAvailable ? 'Tersedia' : 'Dipinjam',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: book.isAvailable
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Detail button
            TextButton(
              onPressed: () => context.push('/detail/${book.id}'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Detail'),
            ),
          ],
        ),
      ),
    );
  }
}
