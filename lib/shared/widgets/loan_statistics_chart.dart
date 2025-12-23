import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/core.dart';
import '../../features/loan/loan_provider.dart';

enum ChartPeriod { monthly, yearly }
enum ChartGrouping { daily, weekly, monthly }

class LoanStatisticsChart extends ConsumerStatefulWidget {
  const LoanStatisticsChart({super.key});

  @override
  ConsumerState<LoanStatisticsChart> createState() => _LoanStatisticsChartState();
}

class _LoanStatisticsChartState extends ConsumerState<LoanStatisticsChart> {
  ChartPeriod _period = ChartPeriod.monthly;
  ChartGrouping _grouping = ChartGrouping.weekly;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(loanProvider.notifier).loadAllLoans());
  }

  @override
  Widget build(BuildContext context) {
    final loanState = ref.watch(loanProvider);
    final chartData = _generateChartData(loanState.allLoans);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(LucideIcons.trendingUp, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Statistik Peminjaman',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Period Toggle (Monthly/Yearly)
          Row(
            children: [
              _buildPeriodButton(ChartPeriod.monthly, 'Bulanan'),
              const SizedBox(width: 8),
              _buildPeriodButton(ChartPeriod.yearly, 'Tahunan'),
              const Spacer(),
              // Grouping Toggle
              _buildGroupingDropdown(),
            ],
          ),
          const SizedBox(height: 20),

          // Chart
          SizedBox(
            height: 200,
            child: chartData.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada data peminjaman',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  )
                : LineChart(_buildLineChart(chartData)),
          ),

          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Jumlah Peminjaman',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(ChartPeriod period, String label) {
    final isSelected = _period == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          _period = period;
          // Reset grouping based on period
          if (period == ChartPeriod.monthly) {
            _grouping = ChartGrouping.weekly;
          } else {
            _grouping = ChartGrouping.monthly;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupingDropdown() {
    final options = _period == ChartPeriod.monthly
        ? [ChartGrouping.daily, ChartGrouping.weekly]
        : [ChartGrouping.weekly, ChartGrouping.monthly];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ChartGrouping>(
          value: _grouping,
          isDense: true,
          icon: const Icon(LucideIcons.chevronDown, size: 16),
          items: options.map((g) {
            return DropdownMenuItem(
              value: g,
              child: Text(
                _getGroupingLabel(g),
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _grouping = value);
            }
          },
        ),
      ),
    );
  }

  String _getGroupingLabel(ChartGrouping grouping) {
    switch (grouping) {
      case ChartGrouping.daily:
        return 'Per Hari';
      case ChartGrouping.weekly:
        return 'Per Minggu';
      case ChartGrouping.monthly:
        return 'Per Bulan';
    }
  }


  List<FlSpot> _generateChartData(List<Loan> loans) {
    if (loans.isEmpty) return [];

    final now = DateTime.now();
    final Map<int, int> dataPoints = {};

    if (_period == ChartPeriod.monthly) {
      // Monthly view - current month
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      if (_grouping == ChartGrouping.daily) {
        // Group by day (1-31)
        for (int i = 1; i <= endOfMonth.day; i++) {
          dataPoints[i] = 0;
        }
        for (final loan in loans) {
          if (loan.loanDate.year == now.year && loan.loanDate.month == now.month) {
            dataPoints[loan.loanDate.day] = (dataPoints[loan.loanDate.day] ?? 0) + 1;
          }
        }
      } else {
        // Group by week (1-5)
        for (int i = 1; i <= 5; i++) {
          dataPoints[i] = 0;
        }
        for (final loan in loans) {
          if (loan.loanDate.year == now.year && loan.loanDate.month == now.month) {
            final weekOfMonth = ((loan.loanDate.day - 1) ~/ 7) + 1;
            dataPoints[weekOfMonth] = (dataPoints[weekOfMonth] ?? 0) + 1;
          }
        }
      }
    } else {
      // Yearly view - current year
      if (_grouping == ChartGrouping.weekly) {
        // Group by week of year (1-52)
        for (int i = 1; i <= 52; i++) {
          dataPoints[i] = 0;
        }
        for (final loan in loans) {
          if (loan.loanDate.year == now.year) {
            final weekOfYear = _getWeekOfYear(loan.loanDate);
            dataPoints[weekOfYear] = (dataPoints[weekOfYear] ?? 0) + 1;
          }
        }
      } else {
        // Group by month (1-12)
        for (int i = 1; i <= 12; i++) {
          dataPoints[i] = 0;
        }
        for (final loan in loans) {
          if (loan.loanDate.year == now.year) {
            dataPoints[loan.loanDate.month] = (dataPoints[loan.loanDate.month] ?? 0) + 1;
          }
        }
      }
    }

    return dataPoints.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  int _getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDiff = date.difference(firstDayOfYear).inDays;
    return (daysDiff / 7).ceil() + 1;
  }

  LineChartData _buildLineChart(List<FlSpot> spots) {
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final adjustedMaxY = maxY < 5 ? 5.0 : (maxY * 1.2).ceilToDouble();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: adjustedMaxY / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: _getBottomInterval(),
            getTitlesWidget: _getBottomTitle,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: adjustedMaxY / 5,
            reservedSize: 32,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: spots.first.x,
      maxX: spots.last.x,
      minY: 0,
      maxY: adjustedMaxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: AppColors.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: AppColors.primary,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => AppColors.primary,
          tooltipRoundedRadius: 8,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toInt()} peminjaman',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }


  double _getBottomInterval() {
    if (_period == ChartPeriod.monthly) {
      if (_grouping == ChartGrouping.daily) {
        return 5; // Show every 5 days
      } else {
        return 1; // Show every week
      }
    } else {
      if (_grouping == ChartGrouping.weekly) {
        return 4; // Show every 4 weeks
      } else {
        return 1; // Show every month
      }
    }
  }

  Widget _getBottomTitle(double value, TitleMeta meta) {
    String text = '';
    
    if (_period == ChartPeriod.monthly) {
      if (_grouping == ChartGrouping.daily) {
        text = value.toInt().toString();
      } else {
        text = 'M${value.toInt()}';
      }
    } else {
      if (_grouping == ChartGrouping.weekly) {
        text = 'W${value.toInt()}';
      } else {
        text = _getMonthAbbr(value.toInt());
      }
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 
                    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    if (month >= 1 && month <= 12) {
      return months[month];
    }
    return '';
  }
}
