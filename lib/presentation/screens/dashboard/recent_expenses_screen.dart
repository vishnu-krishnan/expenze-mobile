import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/expense_provider.dart';
import 'category_transactions_screen.dart';

class RecentExpensesScreen extends StatelessWidget {
  const RecentExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.getTextColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: isDark
            ? AppTheme.darkBackgroundDecoration
            : AppTheme.backgroundDecoration,
        child: Column(
          children: [
            AppBar(
              title: Text('Recent Expense Category',
                  style:
                      TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              centerTitle: false,
              actions: [
                Consumer<ExpenseProvider>(
                  builder: (context, provider, _) {
                    return PopupMenuButton<SortOption>(
                      icon: Icon(LucideIcons.arrowUpDown, color: textColor),
                      onSelected: (option) {
                        provider.setSortOption(option);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: SortOption.recent,
                          child: Text('Recent'),
                        ),
                        const PopupMenuItem(
                          value: SortOption.amountAsc,
                          child: Text('Amount (Low to High)'),
                        ),
                        const PopupMenuItem(
                          value: SortOption.amountDesc,
                          child: Text('Amount (High to Low)'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 16),
              ],
            ),
            Expanded(
              child: Consumer<ExpenseProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.categoryBreakdown.isEmpty) {
                    return Center(
                      child: Text(
                        'No expenses for this month',
                        style: TextStyle(
                          color:
                              AppTheme.getTextColor(context, isSecondary: true),
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: provider.categoryBreakdown.length,
                    itemBuilder: (context, index) {
                      final item = provider.categoryBreakdown[index];
                      return _buildCategoryItem(context, item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, Map<String, dynamic> item) {
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);
    final actual = (item['total_actual'] as num?)?.toDouble() ?? 0.0;
    final planned = (item['total_planned'] as num?)?.toDouble() ?? 0.0;
    final amountNum = actual > 0 ? actual : planned;
    final colorStr = (item['color'] as String?) ?? '#3b82f6';

    Color color;
    try {
      color = Color(int.parse(colorStr.replaceFirst('#', '0xff')));
    } catch (_) {
      color = AppTheme.primary;
    }

    return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryTransactionsScreen(
                categoryId: item['id'] as int,
                categoryName: item['category_name'] ?? 'Uncategorized',
                monthKey: Provider.of<ExpenseProvider>(context, listen: false)
                    .currentMonthKey,
                categoryIcon: item['icon'],
                categoryColor: item['color'],
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(item['icon'] ?? '📁',
                    style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['category_name'] ?? 'Uncategorized',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: textColor)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${amountNum.toLocaleString()}',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: textColor)),
                  Text(
                      (planned == 0 && actual > 0)
                          ? 'Unplanned'
                          : (actual > 0 ? 'Actual' : 'Planned'),
                      style: TextStyle(
                          color: (planned == 0 && actual > 0)
                              ? AppTheme.warning
                              : (actual > 0
                                  ? AppTheme.primary
                                  : secondaryTextColor),
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ));
  }
}

extension RecentDoubleExtension on double {
  String toLocaleString() {
    return toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}
