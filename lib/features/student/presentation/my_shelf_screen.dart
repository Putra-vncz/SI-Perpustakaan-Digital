import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/core.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/auth_provider.dart';
import '../../books/book_provider.dart';
import '../../booking/booking_provider.dart';

class MyShelfScreen extends ConsumerStatefulWidget {
  const MyShelfScreen({super.key});

  @override
  ConsumerState<MyShelfScreen> createState() => _MyShelfScreenState();
}

class _MyShelfScreenState extends ConsumerState<MyShelfScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Schedule after build completes
    Future.microtask(() => _loadData());
  }

  Future<void> _loadData() async {
    final user = ref.read(authProvider).user;
    if (user != null) {
      await ref.read(bookingProvider.notifier).loadUserBookings(user.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCancelConfirmation(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Booking?'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan booking ini? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(bookingProvider.notifier).cancelBooking(booking.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);

    // Listen for cancel results
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Shelf'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(
              icon: const Icon(LucideIcons.calendarClock),
              text: 'Active (${bookingState.activeBookings.length})',
            ),
            Tab(
              icon: const Icon(LucideIcons.history),
              text: 'History (${bookingState.historyBookings.length})',
            ),
          ],
        ),
      ),
      body: bookingState.isLoading
          ? const LoadingWidget(message: 'Loading...')
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveBookings(bookingState.activeBookings),
                _buildHistoryBookings(bookingState.historyBookings),
              ],
            ),
    );
  }

  Widget _buildActiveBookings(List<Booking> bookings) {
    if (bookings.isEmpty) {
      return _buildEmptyState(
        icon: LucideIcons.calendarX,
        title: 'No Active Bookings',
        subtitle: 'Browse our catalog and book your first book!',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildActiveBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildActiveBookingCard(Booking booking) {
    final book = ref.watch(bookByIdProvider(booking.bookId));
    final remainingTime = booking.expiryDate.difference(DateTime.now());
    final isExpiringSoon = remainingTime.inHours < 6;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Info Row
            Row(
              children: [
                // Book Cover
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    book?.coverUrl ?? '',
                    width: 60,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 90,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.book),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Book Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book?.title ?? 'Unknown Book',
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book?.author ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      // Expiry Warning
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isExpiringSoon
                              ? AppColors.warning.withValues(alpha: 0.1)
                              : AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.clock,
                              size: 14,
                              color: isExpiringSoon
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatRemainingTime(remainingTime),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isExpiringSoon
                                    ? AppColors.warning
                                    : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // QR Code Section
            Center(
              child: Column(
                children: [
                  Text(
                    'Show this QR to librarian',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: QrImageView(
                      data: booking.qrCodeData,
                      version: QrVersions.auto,
                      size: 150,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Booking ID: ${booking.id}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelConfirmation(booking),
                      icon: const Icon(LucideIcons.x, size: 18),
                      label: const Text('Batalkan Booking'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryBookings(List<Booking> bookings) {
    if (bookings.isEmpty) {
      return _buildEmptyState(
        icon: LucideIcons.history,
        title: 'No History',
        subtitle: 'Your completed bookings will appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildHistoryCard(booking);
      },
    );
  }

  Widget _buildHistoryCard(Booking booking) {
    final book = ref.watch(bookByIdProvider(booking.bookId));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            book?.coverUrl ?? '',
            width: 50,
            height: 70,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 50,
              height: 70,
              color: Colors.grey.shade200,
              child: const Icon(Icons.book, size: 24),
            ),
          ),
        ),
        title: Text(
          book?.title ?? 'Unknown Book',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Status: ${booking.status.name.toUpperCase()}',
          style: TextStyle(
            color: booking.status == BookingStatus.claimed
                ? AppColors.success
                : AppColors.error,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          booking.status == BookingStatus.claimed
              ? LucideIcons.checkCircle
              : LucideIcons.xCircle,
          color: booking.status == BookingStatus.claimed
              ? AppColors.success
              : AppColors.error,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatRemainingTime(Duration duration) {
    if (duration.isNegative) return 'Expired';
    if (duration.inHours >= 1) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m left';
    }
    return '${duration.inMinutes}m left';
  }
}
