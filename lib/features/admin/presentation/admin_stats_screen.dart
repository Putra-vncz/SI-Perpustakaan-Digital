import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/core.dart';
import '../../loan/loan_provider.dart';

enum StatsPeriodType { monthly, yearly }

class AdminStatsScreen extends ConsumerStatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  ConsumerState<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends ConsumerState<AdminStatsScreen> {
  late DateTime _selectedDate;
  StatsPeriodType _periodType = StatsPeriodType.monthly;

  final _monthFormat = DateFormat('MMMM yyyy');
  final _yearFormat = DateFormat('yyyy');

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(DateTime.now().year, DateTime.now().month);
    Future.microtask(() => ref.read(loanProvider.notifier).loadAllLoans());
  }

  List<Loan> _getLoansForPeriod(List<Loan> allLoans) {
    return allLoans.where((loan) {
      if (_periodType == StatsPeriodType.monthly) {
        return loan.loanDate.year == _selectedDate.year &&
            loan.loanDate.month == _selectedDate.month;
      } else {
        return loan.loanDate.year == _selectedDate.year;
      }
    }).toList();
  }

  List<Loan> _getPreviousPeriodLoans(List<Loan> allLoans) {
    return allLoans.where((loan) {
      if (_periodType == StatsPeriodType.monthly) {
        final prevMonth = DateTime(_selectedDate.year, _selectedDate.month - 1);
        return loan.loanDate.year == prevMonth.year &&
            loan.loanDate.month == prevMonth.month;
      } else {
        return loan.loanDate.year == _selectedDate.year - 1;
      }
    }).toList();
  }

  Map<String, int> _calculateStats(List<Loan> loans) {
    int active = 0;
    int returned = 0;
    int overdue = 0;

    for (final loan in loans) {
      final status = loan.effectiveStatus;
      switch (status) {
        case LoanStatus.active:
          active++;
        case LoanStatus.returned:
          returned++;
        case LoanStatus.overdue:
          overdue++;
      }
    }

    return {
      'total': loans.length,
      'active': active,
      'returned': returned,
      'overdue': overdue,
    };
  }


  Map<String, int> _getWeeklyBreakdown(List<Loan> loans) {
    final Map<String, int> weekly = {};

    if (_periodType == StatsPeriodType.monthly) {
      for (int week = 1; week <= 5; week++) {
        weekly['Week $week'] = 0;
      }
      for (final loan in loans) {
        final weekOfMonth = ((loan.loanDate.day - 1) ~/ 7) + 1;
        final key = 'Week $weekOfMonth';
        weekly[key] = (weekly[key] ?? 0) + 1;
      }
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      for (final month in months) {
        weekly[month] = 0;
      }
      for (final loan in loans) {
        final key = months[loan.loanDate.month - 1];
        weekly[key] = (weekly[key] ?? 0) + 1;
      }
    }

    return weekly;
  }

  Map<String, int> _getTopBooks(List<Loan> loans) {
    final Map<String, int> bookCounts = {};
    for (final loan in loans) {
      bookCounts[loan.bookTitle] = (bookCounts[loan.bookTitle] ?? 0) + 1;
    }

    final sorted = bookCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted.take(5));
  }

  void _showMonthPicker() {
    final now = DateTime.now();
    int selectedYear = _selectedDate.year;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Year selector
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: selectedYear > 2020
                              ? () => setModalState(() => selectedYear--)
                              : null,
                          icon: Icon(
                            LucideIcons.chevronLeft,
                            color: selectedYear > 2020
                                ? AppColors.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                        Text(
                          '$selectedYear',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: selectedYear < now.year
                              ? () => setModalState(() => selectedYear++)
                              : null,
                          icon: Icon(
                            LucideIcons.chevronRight,
                            color: selectedYear < now.year
                                ? AppColors.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Month grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final month = index + 1;
                        final isSelected = _selectedDate.year == selectedYear &&
                            _selectedDate.month == month;
                        final isFuture = selectedYear == now.year &&
                            month > now.month;
                        final monthNames = [
                          'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                          'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
                        ];

                        return InkWell(
                          onTap: isFuture
                              ? null
                              : () {
                                  setState(() {
                                    _selectedDate =
                                        DateTime(selectedYear, month);
                                  });
                                  Navigator.pop(context);
                                },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : isFuture
                                      ? Colors.grey.shade100
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                monthNames[index],
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.white
                                      : isFuture
                                          ? Colors.grey.shade400
                                          : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showYearPicker() {
    final now = DateTime.now();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Tahun'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(2020),
              lastDate: DateTime(now.year),
              selectedDate: _selectedDate,
              onChanged: (date) {
                setState(() {
                  _selectedDate = DateTime(date.year, 1);
                });
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loanState = ref.watch(loanProvider);
    final periodLoans = _getLoansForPeriod(loanState.loans);
    final prevPeriodLoans = _getPreviousPeriodLoans(loanState.loans);
    final stats = _calculateStats(periodLoans);
    final prevStats = _calculateStats(prevPeriodLoans);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        toolbarHeight: 56,
        title: const Text('Statistik Peminjaman'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: loanState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(loanProvider.notifier).loadAllLoans(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period Type Toggle
                    _buildPeriodTypeToggle(),
                    const SizedBox(height: 16),

                    // Period Picker Button
                    _buildPeriodPicker(),
                    const SizedBox(height: 24),

                    // Stats Cards
                    _buildStatsCards(stats, prevStats),
                    const SizedBox(height: 24),

                    // Trend Chart
                    _buildTrendSection(periodLoans),
                    const SizedBox(height: 24),

                    // Status Distribution
                    _buildStatusSection(stats),
                    const SizedBox(height: 24),

                    // Top Books
                    _buildTopBooksSection(periodLoans),
                    const SizedBox(height: 24),

                    // Metrics
                    _buildMetricsSection(stats),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }


  Widget _buildPeriodTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              label: 'Bulanan',
              isSelected: _periodType == StatsPeriodType.monthly,
              onTap: () => setState(() => _periodType = StatsPeriodType.monthly),
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              label: 'Tahunan',
              isSelected: _periodType == StatsPeriodType.yearly,
              onTap: () => setState(() => _periodType = StatsPeriodType.yearly),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodPicker() {
    final displayText = _periodType == StatsPeriodType.monthly
        ? _monthFormat.format(_selectedDate)
        : _yearFormat.format(_selectedDate);

    return InkWell(
      onTap: _periodType == StatsPeriodType.monthly
          ? _showMonthPicker
          : _showYearPicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.calendar,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              displayText,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 8),
            Icon(
              LucideIcons.chevronDown,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(Map<String, int> stats, Map<String, int> prevStats) {
    final total = stats['total']!;
    final prevTotal = prevStats['total']!;
    final percentChange = prevTotal > 0
        ? ((total - prevTotal) / prevTotal * 100)
        : 0.0;
    final isPositive = total >= prevTotal;

    return Column(
      children: [
        // Main stats row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: LucideIcons.library,
                label: 'Total',
                value: '${stats['total']}',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: LucideIcons.bookOpen,
                label: 'Aktif',
                value: '${stats['active']}',
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: LucideIcons.checkCircle,
                label: 'Dikembalikan',
                value: '${stats['returned']}',
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: LucideIcons.alertTriangle,
                label: 'Terlambat',
                value: '${stats['overdue']}',
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Comparison badge
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: (isPositive ? AppColors.success : AppColors.error)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                size: 18,
                color: isPositive ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 8),
              Text(
                '${isPositive ? '+' : ''}${percentChange.toStringAsFixed(1)}% dari ${_periodType == StatsPeriodType.monthly ? 'bulan' : 'tahun'} lalu',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }


  Widget _buildTrendSection(List<Loan> periodLoans) {
    final weeklyData = _getWeeklyBreakdown(periodLoans);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _periodType == StatsPeriodType.monthly
                ? 'Tren Mingguan'
                : 'Tren Bulanan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildBarChart(weeklyData),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> data) {
    final maxValue =
        data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.entries.map((entry) {
          final heightPercent = maxValue > 0 ? entry.value / maxValue : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${entry.value}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      height: (100 * heightPercent).clamp(4.0, 100.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.key.length > 3
                        ? entry.key.substring(0, 3)
                        : entry.key,
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusSection(Map<String, int> stats) {
    final total = stats['total']!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribusi Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (total == 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('Tidak ada data')),
            )
          else
            _buildStatusDistribution(stats),
        ],
      ),
    );
  }

  Widget _buildStatusDistribution(Map<String, int> stats) {
    final total = stats['total']!;
    final activePercent = stats['active']! / total;
    final returnedPercent = stats['returned']! / total;
    final overduePercent = stats['overdue']! / total;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 24,
            child: Row(
              children: [
                if (activePercent > 0)
                  Flexible(
                    flex: (activePercent * 100).round().clamp(1, 100),
                    child: Container(color: AppColors.success),
                  ),
                if (returnedPercent > 0)
                  Flexible(
                    flex: (returnedPercent * 100).round().clamp(1, 100),
                    child: Container(color: AppColors.textSecondary),
                  ),
                if (overduePercent > 0)
                  Flexible(
                    flex: (overduePercent * 100).round().clamp(1, 100),
                    child: Container(color: AppColors.error),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendItem('Aktif', stats['active']!, AppColors.success),
            _buildLegendItem(
                'Dikembalikan', stats['returned']!, AppColors.textSecondary),
            _buildLegendItem('Terlambat', stats['overdue']!, AppColors.error),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($value)',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTopBooksSection(List<Loan> periodLoans) {
    final topBooks = _getTopBooks(periodLoans);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Buku Terpopuler',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (topBooks.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('Tidak ada data')),
            )
          else
            _buildTopBooksList(topBooks),
        ],
      ),
    );
  }

  Widget _buildTopBooksList(Map<String, int> topBooks) {
    return Column(
      children: topBooks.entries.toList().asMap().entries.map((entry) {
        final index = entry.key;
        final book = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: index == 0
                      ? AppColors.secondary
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: index == 0 ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  book.key,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${book.value}x',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricsSection(Map<String, int> stats) {
    final total = stats['total']!;
    final returnRate = total > 0 ? (stats['returned']! / total * 100) : 0.0;
    final overdueRate = total > 0 ? (stats['overdue']! / total * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metrik',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildMetricRow(
            'Tingkat Pengembalian',
            '${returnRate.toStringAsFixed(1)}%',
            returnRate >= 70 ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(height: 10),
          _buildMetricRow(
            'Tingkat Keterlambatan',
            '${overdueRate.toStringAsFixed(1)}%',
            overdueRate <= 10 ? AppColors.success : AppColors.error,
          ),
          const SizedBox(height: 10),
          _buildMetricRow(
            'Total Transaksi',
            '$total',
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}
