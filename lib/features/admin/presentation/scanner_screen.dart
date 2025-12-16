import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/core.dart';
import '../../loan/loan_provider.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  final String? prefillBookingId;

  const ScannerScreen({super.key, this.prefillBookingId});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _bookingIdController = TextEditingController();
  Map<String, dynamic>? _validatedData;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefillBookingId != null) {
      _bookingIdController.text = widget.prefillBookingId!;
      _validateBooking();
    }
  }

  @override
  void dispose() {
    _bookingIdController.dispose();
    super.dispose();
  }

  Future<void> _validateBooking() async {
    final bookingId = _bookingIdController.text.trim();
    if (bookingId.isEmpty) {
      _showError('Please enter a booking ID');
      return;
    }

    setState(() {
      _isValidating = true;
      _validatedData = null;
    });

    // Create QR data format
    final qrData = '{"bookingId": "$bookingId", "userId": "user_1"}';
    final result =
        await ref.read(loanProvider.notifier).validateBookingFromQR(qrData);

    setState(() {
      _isValidating = false;
      _validatedData = result;
    });

    if (result == null) {
      final error = ref.read(loanProvider).error;
      _showError(error ?? 'Booking not found');
    }
  }

  Future<void> _processHandover() async {
    if (_validatedData == null) return;

    final booking = _validatedData!['booking'] as Booking;
    final success =
        await ref.read(loanProvider.notifier).claimBooking(booking.id);

    if (success && mounted) {
      _showSuccessDialog();
    } else {
      final error = ref.read(loanProvider).error;
      _showError(error ?? 'Failed to process handover');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.checkCircle,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Handover Successful!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'The book has been handed over to the student. A new loan record has been created.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/admin');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                child: const Text('Back to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loanProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        toolbarHeight: 56,
        title: const Text('Scan & Validate'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scanner Simulation Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      LucideIcons.scanLine,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'QR Scanner Simulation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter booking ID manually for testing',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Input Section
            Text(
              'Enter Booking ID',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bookingIdController,
              decoration: InputDecoration(
                hintText: 'e.g., booking_1234567890',
                prefixIcon: const Icon(LucideIcons.hash),
                suffixIcon: _bookingIdController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () {
                          _bookingIdController.clear();
                          setState(() => _validatedData = null);
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _validateBooking(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isValidating ? null : _validateBooking,
                icon: _isValidating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.search),
                label: Text(_isValidating ? 'Validating...' : 'Validate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Validation Result
            if (_validatedData != null) _buildValidationResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationResult() {
    final booking = _validatedData!['booking'] as Booking;
    final user = _validatedData!['user'] as User?;
    final book = _validatedData!['book'] as Book?;
    final loanState = ref.watch(loanProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.checkCircle,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Booking Validated',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.success,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // Book Info
          Row(
            children: [
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book?.title ?? 'Unknown Book',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book?.author ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Shelf: ${book?.shelfLocation ?? '-'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Student Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: LucideIcons.user,
                  label: 'Student',
                  value: user?.name ?? 'Unknown',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: LucideIcons.creditCard,
                  label: 'NIM',
                  value: user?.studentId ?? '-',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: LucideIcons.calendar,
                  label: 'Booked',
                  value: _formatDate(booking.bookingDate),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: loanState.isLoading ? null : _processHandover,
              icon: loanState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(LucideIcons.checkCircle2),
              label: Text(
                loanState.isLoading ? 'Processing...' : 'Confirm Handover',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
