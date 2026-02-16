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

    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgPrimaryDark : AppTheme.bgPrimary,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? AppTheme.darkBackgroundDecoration
            : AppTheme.backgroundDecoration,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 20, 26, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Insights & Trends',
                            style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 13,
                                letterSpacing: 0.5)),
                        Text('Analytics',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                                letterSpacing: -1)),
                      ],
                    ),
                    _buildPeriodSelector(textColor),
                  ],
                ),
              ),
              Expanded(
                child: Consumer<ExpenseProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPremiumChartCard(provider.trends, textColor),
                          const SizedBox(height: 24),
                          _buildSpendingSummary(
                              provider, textColor, secondaryTextColor),
                          const SizedBox(height: 32),
                          Text('Monthly Performance',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  letterSpacing: -0.5)),
                          const SizedBox(height: 16),
                          _buildPerformanceGrid(
                              provider.trends, textColor, secondaryTextColor),
                          const SizedBox(height: 32),
                          const SizedBox(height: 120),
                          const SizedBox(height: 120),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(Color textColor) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPeriodButton('6M', 6),
          _buildPeriodButton('1Y', 12),
          _buildPeriodButton('5Y', 60),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, int months) {
    final isSelected = _selectedPeriod == months;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPeriod = months);
        context.read<ExpenseProvider>().loadTrends(months);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppTheme.primaryDark
                : AppTheme.primaryDark.withOpacity(0.5),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumChartCard(
      List<Map<String, dynamic>> trends, Color textColor) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Net Spending Trend',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: textColor)),
              Icon(LucideIcons.trendingUp, size: 16, color: AppTheme.primary),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(child: _buildLineChart(trends)),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> trends) {
    if (trends.isEmpty) return const Center(child: Text('Not enough data'));

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                if (val.toInt() >= 0 && val.toInt() < trends.length) {
                  final key = trends[val.toInt()]['month_key'] as String;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(key.split('-')[1],
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textSecondary)),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: trends.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(),
                  (e.value['total_actual'] as num).toDouble());
            }).toList(),
            isCurved: true,
            color: AppTheme.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.3),
                  AppTheme.primary.withOpacity(0)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceGrid(List<Map<String, dynamic>> trends,
      Color textColor, Color secondaryTextColor) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: trends.length > 4 ? 4 : trends.length,
      itemBuilder: (context, index) {
        final data = trends[trends.length - 1 - index];
        final actual = (data['total_actual'] as num).toDouble();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(data['month_key'],
                  style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('₹${actual.toStringAsFixed(0)}',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpendingSummary(
      ExpenseProvider provider, Color textColor, Color secondaryTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildSummaryItem(
              'Average',
              provider.trends.isEmpty
                  ? '₹0'
                  : '₹${(provider.trends.map((e) => e['total_actual'] as num).reduce((a, b) => a + b) / provider.trends.length).toStringAsFixed(0)}',
              Colors.white,
              Colors.white70),
          Container(height: 40, width: 1, color: Colors.white24),
          _buildSummaryItem(
              'Highest',
              provider.trends.isEmpty
                  ? '₹0'
                  : '₹${provider.trends.map((e) => e['total_actual'] as num).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)}',
              Colors.white,
              Colors.white70),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, Color textColor, Color secondaryTextColor) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: textColor, fontSize: 20, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
