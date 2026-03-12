import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/expense_provider.dart';
import 'category_transactions_screen.dart';

class RecentExpensesScreen extends StatelessWidget {
  const RecentExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? AppTheme.darkBackgroundDecoration
            : AppTheme.backgroundDecoration,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              automaticallyImplyLeading: false,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              expandedHeight: 110,
              collapsedHeight: 110,
              toolbarHeight: 110,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.zero,
                background: Container(
                  decoration: AppTheme.headerDecoration(context),
                  padding: EdgeInsets.fromLTRB(
                      26, MediaQuery.of(context).padding.top + 10, 26, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Recent Pitstops",
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1)),
                          Text("The Money Trail",
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5)),
                        ],
                      ),
                      Consumer<ExpenseProvider>(
                        builder: (context, provider, _) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: PopupMenuButton<SortOption>(
                              icon: const Icon(LucideIcons.arrowUpDown,
                                  color: Colors.white, size: 20),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
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
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              sliver: Consumer<ExpenseProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()));
                  }

                  if (provider.categoryBreakdown.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No expenses for this month',
                          style: TextStyle(
                            color: AppTheme.getTextColor(context,
                                isSecondary: true),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = provider.categoryBreakdown[index];
                        return _buildCategoryItem(context, item);
                      },
                      childCount: provider.categoryBreakdown.length,
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
                categoryId: item['id'] as int?,
                categoryName: item['category_name'] ?? 'Imported',
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
                child:
                    Text(item['icon'] ?? '📁', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['category_name'] ?? 'Imported',
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
                  Text(actual > 0 ? 'Spent' : 'Planned',
                      style: TextStyle(
                          color: actual > 0
                              ? AppTheme.primary
                              : secondaryTextColor,
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
