import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/core.dart';
import '../../books/book_provider.dart';
import '../../loan/loan_provider.dart';

enum AdminListType { allBooks, activeLoans, pendingPickup, overdue, pendingReturn }

class AdminDetailListScreen extends ConsumerStatefulWidget {
  final AdminListType listType;

  const AdminDetailListScreen({super.key, required this.listType});

  @override
  ConsumerState<AdminDetailListScreen> createState() => _AdminDetailListScreenState();
}

class _AdminDetailListScreenState extends ConsumerState<AdminDetailListScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    Future.microtask(() {
      ref.read(loanProvider.notifier).loadAllLoans();
      ref.read(loanProvider.notifier).loadActiveBookings();
      ref.read(loanProvider.notifier).loadPendingReturnLoans();
    });
  }

  String get _title {
    switch (widget.listType) {
      case AdminListType.allBooks:
        return 'Total Koleksi Buku';
      case AdminListType.activeLoans:
        return 'Sedang Dipinjam';
      case AdminListType.pendingPickup:
        return 'Pending Pickup';
      case AdminListType.overdue:
        return 'Terlambat';
      case AdminListType.pendingReturn:
        return 'Pending Pengembalian';
    }
  }

  IconData get _icon {
    switch (widget.listType) {
      case AdminListType.allBooks:
        return LucideIcons.library;
      case AdminListType.activeLoans:
        return LucideIcons.clock;
      case AdminListType.pendingPickup:
        return LucideIcons.users;
      case AdminListType.overdue:
        return LucideIcons.alertTriangle;
      case AdminListType.pendingReturn:
        return LucideIcons.undo2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(_title),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (widget.listType) {
      case AdminListType.allBooks:
        return _buildAllBooksList();
      case AdminListType.activeLoans:
        return _buildActiveLoansList();
      case AdminListType.pendingPickup:
        return _buildPendingPickupList();
      case AdminListType.overdue:
        return _buildOverdueList();
      case AdminListType.pendingReturn:
        return _buildPendingReturnList();
    }
  }

  Widget _buildAllBooksList() {
    final bookState = ref.watch(bookListProvider);

    if (bookState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final books = bookState.books;

    if (books.isEmpty) {
      return _buildEmptyState('Belum ada buku dalam koleksi');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return _buildBookCard(book);
      },
    );
  }

  Widget _buildActiveLoansList() {
    final loanState = ref.watch(loanProvider);

    if (loanState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeLoans = loanState.loans
        .where((l) => l.status == LoanStatus.active && !l.isOverdue)
        .toList();

    if (activeLoans.isEmpty) {
      return _buildEmptyState('Tidak ada buku yang sedang dipinjam');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeLoans.length,
      itemBuilder: (context, index) {
        final loan = activeLoans[index];
        return _buildLoanCard(loan);
      },
    );
  }

  Widget _buildPendingPickupList() {
    final loanState = ref.watch(loanProvider);

    if (loanState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final pendingBookings = loanState.allActiveBookings;

    if (pendingBookings.isEmpty) {
      return _buildEmptyState('Tidak ada booking yang menunggu pickup');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingBookings.length,
      itemBuilder: (context, index) {
        final booking = pendingBookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildOverdueList() {
    final loanState = ref.watch(loanProvider);

    if (loanState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final overdueLoans = loanState.loans
        .where((l) =>
            (l.status == LoanStatus.active ||
                l.status == LoanStatus.pendingReturn) &&
            l.isOverdue)
        .toList();

    if (overdueLoans.isEmpty) {
      return _buildEmptyState('Tidak ada peminjaman yang terlambat');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: overdueLoans.length,
      itemBuilder: (context, index) {
        final loan = overdueLoans[index];
        return _buildLoanCard(loan, isOverdue: true);
      },
    );
  }

  Widget _buildPendingReturnList() {
    final loanState = ref.watch(loanProvider);

    if (loanState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final pendingReturns = loanState.pendingReturnLoans;

    if (pendingReturns.isEmpty) {
      return _buildEmptyState('Tidak ada permintaan pengembalian');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingReturns.length,
      itemBuilder: (context, index) {
        final loan = pendingReturns[index];
        return _buildPendingReturnCard(loan);
      },
    );
  }

  Widget _buildPendingReturnCard(Loan loan) {
    final book = ref.watch(bookByIdProvider(loan.bookId));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning, width: 2),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Book Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  book?.coverUrl ?? '',
                  width: 50,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 50,
                    height: 70,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(LucideIcons.bookOpen, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.bookTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Peminjam: ${loan.userName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.calendar, size: 14, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(
                'Pinjam: ${_formatDate(loan.loanDate)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 16),
              Icon(LucideIcons.calendarClock, size: 14, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(
                'Jatuh tempo: ${_formatDate(loan.dueDate)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRejectConfirmation(loan),
                  icon: const Icon(LucideIcons.x, size: 16),
                  label: const Text('Tolak'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showApproveConfirmation(loan),
                  icon: const Icon(LucideIcons.check, size: 16),
                  label: const Text('Setujui'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showApproveConfirmation(Loan loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setujui Pengembalian?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Buku: ${loan.bookTitle}'),
            const SizedBox(height: 4),
            Text('Peminjam: ${loan.userName}'),
            const SizedBox(height: 8),
            const Text(
              'Pastikan buku fisik sudah diterima sebelum menyetujui.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processApproveReturn(loan.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Setujui'),
          ),
        ],
      ),
    );
  }

  void _showRejectConfirmation(Loan loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Pengembalian?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Buku: ${loan.bookTitle}'),
            const SizedBox(height: 4),
            Text('Peminjam: ${loan.userName}'),
            const SizedBox(height: 8),
            const Text(
              'Pengembalian akan ditolak dan status pinjaman kembali aktif.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processRejectReturn(loan.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Tolak'),
          ),
        ],
      ),
    );
  }

  Future<void> _processApproveReturn(String loanId) async {
    final success = await ref.read(loanProvider.notifier).approveReturnBook(loanId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengembalian buku disetujui!'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadData();
    } else {
      final error = ref.read(loanProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Gagal menyetujui pengembalian'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _processRejectReturn(String loanId) async {
    final success = await ref.read(loanProvider.notifier).rejectReturnBook(loanId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permintaan pengembalian ditolak'),
          backgroundColor: AppColors.warning,
        ),
      );
      _loadData();
    } else {
      final error = ref.read(loanProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Gagal menolak pengembalian'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_icon, size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(Book book) {
    return GestureDetector(
      onTap: () => context.push('/detail/${book.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppShadows.cardShadow,
        ),
        child: Row(
          children: [
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                book.coverUrl,
                width: 50,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 50,
                  height: 70,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(LucideIcons.bookOpen, size: 20),
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTag(
                        book.type == BookType.ebook ? 'E-Book' : 'Fisik',
                        book.type == BookType.ebook
                            ? AppColors.primary
                            : AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      if (book.type == BookType.physical)
                        _buildTag(
                          'Stok: ${book.stock}',
                          book.stock > 0 ? AppColors.success : AppColors.error,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanCard(Loan loan, {bool isOverdue = false}) {
    final book = ref.watch(bookByIdProvider(loan.bookId));
    final daysOverdue = DateTime.now().difference(loan.dueDate).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isOverdue ? Border.all(color: AppColors.error, width: 2) : null,
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Book Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  book?.coverUrl ?? '',
                  width: 50,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 50,
                    height: 70,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(LucideIcons.bookOpen, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.bookTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Peminjam: ${loan.userName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$daysOverdue hari',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.calendar, size: 14, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(
                'Pinjam: ${_formatDate(loan.loanDate)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 16),
              Icon(
                LucideIcons.calendarClock,
                size: 14,
                color: isOverdue ? AppColors.error : AppColors.textLight,
              ),
              const SizedBox(width: 4),
              Text(
                'Jatuh tempo: ${_formatDate(loan.dueDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isOverdue ? AppColors.error : null,
                      fontWeight: isOverdue ? FontWeight.bold : null,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showReturnConfirmation(loan),
              icon: const Icon(LucideIcons.checkCircle, size: 16),
              label: const Text('Kembalikan Buku'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReturnConfirmation(Loan loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pengembalian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Buku: ${loan.bookTitle}'),
            const SizedBox(height: 4),
            Text('Peminjam: ${loan.userName}'),
            const SizedBox(height: 8),
            Text(
              'Apakah Anda yakin ingin memproses pengembalian buku ini?',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processReturn(loan.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Kembalikan'),
          ),
        ],
      ),
    );
  }

  Future<void> _processReturn(String loanId) async {
    final success = await ref.read(loanProvider.notifier).returnBook(loanId);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buku berhasil dikembalikan!'),
          backgroundColor: AppColors.success,
        ),
      );
      // Reload data
      _loadData();
    } else {
      final error = ref.read(loanProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Gagal mengembalikan buku'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildBookingCard(Booking booking) {
    final book = ref.watch(bookByIdProvider(booking.bookId));
    final hoursLeft = booking.expiryDate.difference(DateTime.now()).inHours;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Book Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  book?.coverUrl ?? '',
                  width: 50,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 50,
                    height: 70,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(LucideIcons.bookOpen, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book?.title ?? 'Unknown Book',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'User ID: ${booking.userId}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hoursLeft <= 6 ? AppColors.warning : AppColors.success,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$hoursLeft jam lagi',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.calendar, size: 14, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(
                'Booking: ${_formatDate(booking.bookingDate)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 16),
              Icon(LucideIcons.timer, size: 14, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(
                'Expired: ${_formatDate(booking.expiryDate)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/admin/scan', extra: booking.id),
              icon: const Icon(LucideIcons.scan, size: 16),
              label: const Text('Proses Pickup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
