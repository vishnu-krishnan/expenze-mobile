import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/expense_provider.dart';
import '../../providers/theme_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 6; // Default: 6 months

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadTrends(_selectedPeriod);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      decoration: themeProvider.isDarkMode
          ? AppTheme.darkBackgroundDecoration
          : AppTheme.backgroundDecoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Spending Analytics'),
          elevation: 0,
        ),
        body: Consumer<ExpenseProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodSelector(),
                  const SizedBox(height: 24),
                  _buildTrendChart(provider.trends),
                  const SizedBox(height: 32),
                  _buildInsightCards(),
                  const SizedBox(height: 24),
                  _buildCategoryBreakdown(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          _buildPeriodButton('6M', 6),
          _buildPeriodButton('1Y', 12),
          _buildPeriodButton('3Y', 36),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, int months) {
    final isSelected = _selectedPeriod == months;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPeriod = months);
          context.read<ExpenseProvider>().loadTrends(months);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendChart(List<Map<String, dynamic>> trends) {
    if (trends.isEmpty) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadow,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.trendingUp,
                  size: 48, color: AppTheme.textLight.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                'No data available',
                style: TextStyle(color: AppTheme.textLight, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final trendData = trends;
    final spotsActual = <FlSpot>[];
    final spotsPlanned = <FlSpot>[];
    double maxY = 0;

    for (int i = 0; i < trendData.length; i++) {
      final actual = (trendData[i]['total_actual'] as num?)?.toDouble() ?? 0.0;
      final planned =
          (trendData[i]['total_planned'] as num?)?.toDouble() ?? 0.0;

      spotsActual.add(FlSpot(i.toDouble(), actual));
      spotsPlanned.add(FlSpot(i.toDouble(), planned));

      if (actual > maxY) maxY = actual;
      if (planned > maxY) maxY = planned;
    }

    if (maxY == 0) maxY = 5000;

    return Container(
      height: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Spending Trend',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.trendingUp,
                        size: 14, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      _selectedPeriod == 6
                          ? '6 Months'
                          : _selectedPeriod == 12
                              ? '1 Year'
                              : '3 Years',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 1000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.border.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= trendData.length)
                          return const SizedBox();
                        final monthKey =
                            trendData[value.toInt()]['month_key'] as String;
                        final parts = monthKey.split('-');
                        if (parts.length == 2) {
                          final month = int.parse(parts[1]);
                          const months = [
                            'J',
                            'F',
                            'M',
                            'A',
                            'M',
                            'J',
                            'J',
                            'A',
                            'S',
                            'O',
                            'N',
                            'D'
                          ];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              months[month - 1],
                              style: TextStyle(
                                  color: AppTheme.textLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: maxY > 0 ? maxY / 4 : 1000,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${(value / 1000).toStringAsFixed(0)}k',
                          style: TextStyle(
                              color: AppTheme.textLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (trendData.length - 1).toDouble() < 0
                    ? 0
                    : (trendData.length - 1).toDouble(),
                minY: 0,
                maxY: maxY * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: spotsPlanned,
                    isCurved: true,
                    color: AppTheme.secondary.withOpacity(0.3),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: spotsActual,
                    isCurved: true,
                    gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.accent]),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: AppTheme.primary,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withOpacity(0.1),
                          AppTheme.primary.withOpacity(0.0)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCards() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                'Avg Monthly',
                '₹${provider.avgMonthlySpent.toStringAsFixed(0)}',
                LucideIcons.barChart3,
                AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInsightCard(
                'Highest',
                '₹${provider.maxMonthlySpent.toStringAsFixed(0)}',
                LucideIcons.trendingUp,
                AppTheme.warning,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInsightCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
                color: AppTheme.textLight,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final breakdown = provider.categoryBreakdown;
        final totalAll = breakdown.fold<double>(0, (sum, item) {
          final actual = (item['total_actual'] as num).toDouble();
          final planned = (item['total_planned'] as num).toDouble();
          return sum + (actual > 0 ? actual : planned);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (breakdown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('No breakdown data for this month',
                      style: TextStyle(color: AppTheme.textLight)),
                ),
              )
            else
              ...breakdown.take(5).map((item) {
                final name = (item['category_name'] as String?) ?? 'Other';
                final actual = (item['total_actual'] as num).toDouble();
                final planned = (item['total_planned'] as num).toDouble();
                final amount = actual > 0 ? actual : planned;
                final progress = totalAll > 0 ? amount / totalAll : 0.0;
                final emoji = (item['icon'] as String?) ?? '📁';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCategoryItem(name, amount, progress, emoji),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildCategoryItem(
      String name, double amount, double progress, String emoji) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('₹${amount.toStringAsFixed(0)}',
                        style:
                            TextStyle(color: AppTheme.textLight, fontSize: 13)),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.bgSecondary.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
