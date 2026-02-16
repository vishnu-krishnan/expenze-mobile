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
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: themeProvider.isDarkMode
            ? AppTheme.darkBackgroundDecoration
            : AppTheme.backgroundDecoration,
        child: Column(
          children: [
            AppBar(
              title: Text('Spending Analytics',
                  style:
                      TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              centerTitle: true,
            ),
            Expanded(
              child: Consumer<ExpenseProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPeriodSelector(textColor, secondaryTextColor),
                        const SizedBox(height: 24),
                        _buildTrendChart(
                            provider.trends, textColor, secondaryTextColor),
                        const SizedBox(height: 32),
                        _buildInsightCards(textColor, secondaryTextColor),
                        const SizedBox(height: 32),
                        _buildCategoryBreakdown(textColor, secondaryTextColor),
                        const SizedBox(height: 100),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(Color textColor, Color secondaryTextColor) {
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
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);

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
              color: isSelected ? Colors.white : secondaryTextColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendChart(List<Map<String, dynamic>> trends, Color textColor,
      Color secondaryTextColor) {
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
                  size: 48, color: secondaryTextColor.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                'No data available',
                style: TextStyle(color: secondaryTextColor, fontSize: 16),
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
      height: 320,
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
              Text(
                'Spending Trend',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.trendingUp,
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
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 1000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: secondaryTextColor.withValues(alpha: 0.1),
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
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'May',
                            'Jun',
                            'Jul',
                            'Aug',
                            'Sep',
                            'Oct',
                            'Nov',
                            'Dec'
                          ];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              months[month - 1][0],
                              style: TextStyle(
                                  color: secondaryTextColor,
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
                              color: secondaryTextColor,
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
                    color: AppTheme.secondary.withValues(alpha: 0.3),
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
                          AppTheme.primary.withValues(alpha: 0.15),
                          AppTheme.primary.withValues(alpha: 0.0)
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

  Widget _buildInsightCards(Color textColor, Color secondaryTextColor) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                context,
                'Avg Monthly',
                '₹${provider.avgMonthlySpent.toStringAsFixed(0)}',
                LucideIcons.barChart3,
                AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInsightCard(
                context,
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

  Widget _buildInsightCard(BuildContext context, String label, String value,
      IconData icon, Color color) {
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);

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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
                color: secondaryTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(Color textColor, Color secondaryTextColor) {
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
            Text('Top Categories',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 16),
            if (breakdown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('No breakdown data for this month',
                      style: TextStyle(color: secondaryTextColor)),
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
                  child: _buildCategoryItem(
                      context, name, amount, progress, emoji),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildCategoryItem(BuildContext context, String name, double amount,
      double progress, String emoji) {
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);

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
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: textColor)),
                    Text('₹${amount.toStringAsFixed(0)}',
                        style:
                            TextStyle(color: secondaryTextColor, fontSize: 13)),
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
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
