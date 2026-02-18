import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/expense_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 6; // Default: 6 months
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadTrends(_selectedPeriod);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        key: UniqueKey(),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              background: Padding(
                padding: const EdgeInsets.fromLTRB(26, 10, 26, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
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
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            sliver: Consumer<ExpenseProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()));
                }

                return SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      _buildPremiumChartCard(provider.trends, textColor),
                      const SizedBox(height: 24),
                      _buildSpendingSummary(
                          provider, textColor, secondaryTextColor),
                      const SizedBox(height: 24),
                      if (provider.periodCategoryBreakdown.isNotEmpty) ...[
                        _buildPieChartCard(
                            provider.periodCategoryBreakdown, textColor),
                        const SizedBox(height: 32),
                      ],
                      Text(
                          _selectedPeriod >= 60
                              ? 'Yearly Total Expenses'
                              : 'Monthly Total Expenses',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              letterSpacing: -0.5)),
                      Text(
                          _selectedPeriod >= 12
                              ? 'Last ${_selectedPeriod ~/ 12} ${(_selectedPeriod ~/ 12) > 1 ? "Years" : "Year"}'
                              : 'Last $_selectedPeriod Months',
                          style: TextStyle(
                              fontSize: 13,
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 16),
                      _buildPerformanceGrid(
                          provider.trends, textColor, secondaryTextColor),
                      if (provider.trends.length > _visibleMonths)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _visibleMonths += 6;
                              });
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.2)),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Show More History',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(width: 8),
                                Icon(Icons.keyboard_arrow_down, size: 20),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 140),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _visibleMonths = 6;

  Widget _buildPeriodSelector(Color textColor) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.12),
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
        setState(() {
          _selectedPeriod = months;
          _visibleMonths = 6; // Reset pagination
        });
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
                ? Colors.white
                : AppTheme.getTextColor(context, isSecondary: true)
                    .withValues(alpha: 0.8),
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
              Row(
                children: [
                  _buildLegendItem('Actual', AppTheme.primary),
                  const SizedBox(width: 12),
                  _buildLegendItem(
                      'Planned', AppTheme.secondary.withValues(alpha: 0.5)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(child: _buildLineChart(trends)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: AppTheme.getTextColor(context, isSecondary: true))),
      ],
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> trends) {
    if (trends.isEmpty) return const Center(child: Text('Not enough data'));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: secondaryTextColor.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              // Dynamic interval based on period
              interval: _selectedPeriod >= 60
                  ? 1
                  : (_selectedPeriod > 12 ? 6 : (_selectedPeriod > 6 ? 2 : 1))
                      .toDouble(),
              getTitlesWidget: (val, meta) {
                if (val.toInt() >= 0 && val.toInt() < trends.length) {
                  final key = trends[val.toInt()]['month_key'] as String;
                  final date = DateTime.parse('$key-01');
                  // Show year if period > 1 year
                  final format = _selectedPeriod >= 60
                      ? 'yyyy'
                      : (_selectedPeriod > 12 ? 'MMM yy' : 'MMM');
                  final monthLabel = DateFormat(format).format(date);
                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Text(monthLabel,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: secondaryTextColor)),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                if (val == 0) return const SizedBox();
                String text;
                if (val >= 1000) {
                  text = '${(val / 1000).toStringAsFixed(0)}k';
                } else {
                  text = val.toStringAsFixed(0);
                }
                return Text(text,
                    style: TextStyle(fontSize: 10, color: secondaryTextColor),
                    textAlign: TextAlign.center);
              },
              reservedSize: 35,
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        minY: 0,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => isDark ? AppTheme.bgCardDark : Colors.white,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final isActual = spot.barIndex == 0;
                return LineTooltipItem(
                  '${isActual ? "Actual" : "Planned"}: ₹${spot.y.toInt()}',
                  TextStyle(
                    color: isActual ? AppTheme.primary : AppTheme.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Actual Spending Line
          LineChartBarData(
            spots: trends.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(),
                  (e.value['total_actual'] as num).toDouble());
            }).toList(),
            isCurved: true,
            preventCurveOverShooting: true,
            color: AppTheme.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.2),
                  AppTheme.primary.withValues(alpha: 0)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Planned Spending Line (Dashed)
          LineChartBarData(
            spots: trends.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(),
                  (e.value['total_planned'] as num).toDouble());
            }).toList(),
            isCurved: true,
            preventCurveOverShooting: true,
            color: AppTheme.secondary.withValues(alpha: 0.5),
            barWidth: 2,
            isStrokeCapRound: true,
            dashArray: [5, 5],
            dotData: const FlDotData(show: false),
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
      itemCount:
          trends.length > _visibleMonths ? _visibleMonths : trends.length,
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
              Text(
                  DateFormat(_selectedPeriod >= 60 ? 'yyyy' : 'MMMM yyyy')
                      .format(DateTime.parse('${data['month_key']}-01')),
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
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildSummaryItem('Average', '₹${provider.avgMonthlySpent.toInt()}',
              Colors.white, Colors.white70),
          Container(height: 40, width: 1, color: Colors.white24),
          _buildSummaryItem('Highest', '₹${provider.maxMonthlySpent.toInt()}',
              Colors.white, Colors.white70),
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

  Widget _buildPieChartCard(
      List<Map<String, dynamic>> breakdown, Color textColor) {
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);
    final total = breakdown.fold(
        0.0, (sum, item) => sum + (item['total_actual'] as num).toDouble());

    // Filter out categories with minimal spending (< 1%) unless it's the only one
    final validItems = breakdown
        .where((e) => (e['total_actual'] as num).toDouble() > 0)
        .toList();

    if (validItems.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spending by Category',
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 15, color: textColor)),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: AspectRatio(
                  aspectRatio: 1.3,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          if (!mounted) return;
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 0, // Space between sections
                      centerSpaceRadius: 40, // Donut chart style
                      sections: List.generate(validItems.length, (i) {
                        final item = validItems[i];
                        final isTouched = i == _touchedIndex;
                        final fontSize = isTouched ? 16.0 : 12.0;
                        final radius = isTouched ? 60.0 : 50.0;
                        final value = (item['total_actual'] as num).toDouble();
                        final percentage = (value / total) * 100;
                        final colorHex = item['color'] as String? ?? '#79D2C1';
                        final color = Color(
                            int.parse(colorHex.replaceFirst('#', '0xff')));

                        return PieChartSectionData(
                          color: color,
                          value: value,
                          title: isTouched
                              ? '${percentage.toStringAsFixed(2)}%'
                              : '',
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black26, blurRadius: 2)
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                      validItems.length > 5 ? 5 : validItems.length, (i) {
                    final item = validItems[i];
                    final colorHex = item['color'] as String? ?? '#79D2C1';
                    final color =
                        Color(int.parse(colorHex.replaceFirst('#', '0xff')));
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildIndicator(
                        color: color,
                        text: (item['category_name'] as String?) ??
                            'Uncategorized',
                        textColor: secondaryTextColor,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator({
    required Color color,
    required String text,
    required Color textColor,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        )
      ],
    );
  }
}
