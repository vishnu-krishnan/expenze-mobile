import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/theme_provider.dart';
import '../../../data/models/expense.dart';

class MonthPlanScreen extends StatefulWidget {
  const MonthPlanScreen({super.key});

  @override
  State<MonthPlanScreen> createState() => _MonthPlanScreenState();
}

class _MonthPlanScreenState extends State<MonthPlanScreen> {
  void _handleMonthChange(int offset) {
    final provider = context.read<ExpenseProvider>();
    final current = DateTime.parse('${provider.currentMonthKey}-01');
    final next = DateTime(current.year, current.month + offset, 1);
    provider.setMonth(DateFormat('yyyy-MM').format(next));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final textColor = AppTheme.getTextColor(context);

    return Container(
      decoration: themeProvider.isDarkMode
          ? AppTheme.darkBackgroundDecoration
          : AppTheme.backgroundDecoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Budget Planner',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Consumer2<ExpenseProvider, CategoryProvider>(
          builder: (context, expenseProvider, categoryProvider, child) {
            if (expenseProvider.isLoading && expenseProvider.expenses.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. Month Navigation
                SliverToBoxAdapter(
                  child: _buildMonthNavigator(expenseProvider.currentMonthKey),
                ),

                // 2. Summary Header (Vibrant)
                SliverToBoxAdapter(
                  child: _buildPremiumSummary(expenseProvider),
                ),

                // 3. Section Title
                if (expenseProvider.expenses.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      child: Text(
                        'Planned Expenses',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),

                // 4. Expense List
                if (expenseProvider.expenses.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final expense = expenseProvider.expenses[index];
                          return _buildExpenseCard(expense, expenseProvider);
                        },
                        childCount: expenseProvider.expenses.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMonthNavigator(String monthKey) {
    final date = DateTime.parse('$monthKey-01');
    final monthName = DateFormat('MMMM yyyy').format(date);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft,
                size: 20, color: AppTheme.primary),
            onPressed: () => _handleMonthChange(-1),
          ),
          Text(
            monthName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.chevronRight,
                size: 20, color: AppTheme.primary),
            onPressed: () => _handleMonthChange(1),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSummary(ExpenseProvider provider) {
    final summary = provider.summary;
    final planned = summary['planned'] ?? 0.0;
    final actual = summary['actual'] ?? 0.0;
    final remaining = summary['remaining'] ?? 0.0;
    final limit = summary['limit'] ?? 0.0;
    final target = limit > 0 ? limit : planned;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Available Balance',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(
                    '₹${remaining.toInt()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showLimitDialog(provider),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.edit2,
                      size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildSummaryItem(
                  limit > 0 ? 'Limit' : 'Planned', '₹${target.toInt()}'),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildSummaryItem('Spent', '₹${actual.toInt()}'),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildSummaryItem('Progress',
                  '${target > 0 ? (actual / target * 100).toInt() : 0}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ],
      ),
    );
  }

  void _showLimitDialog(ExpenseProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(
        text: provider.summary['limit']! > 0
            ? provider.summary['limit']!.toStringAsFixed(0)
            : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Monthly Budget Limit',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppTheme.bgCardDark : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set a total spending limit for this month.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: AppTheme.inputDecoration(
                  'Amount', LucideIcons.indianRupee,
                  context: context),
              style: TextStyle(color: AppTheme.getTextColor(context)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final limit = double.tryParse(controller.text) ?? 0;
              provider.updateMonthlyLimit(limit);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.calendarX,
              size: 64, color: secondaryTextColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('No plans yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context))),
          Text('Plan your month to stay on track',
              style: TextStyle(color: secondaryTextColor)),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense, ExpenseProvider provider) {
    final bool isOver =
        expense.isPaid && (expense.actualAmount > expense.plannedAmount);
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (expense.isPaid ? AppTheme.success : AppTheme.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  expense.isPaid
                      ? LucideIcons.checkCheck
                      : LucideIcons.shoppingBag,
                  size: 20,
                  color: expense.isPaid ? AppTheme.success : AppTheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.name,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor)),
                    Text('Target: ₹${expense.plannedAmount.toInt()}',
                        style:
                            TextStyle(color: secondaryTextColor, fontSize: 12)),
                  ],
                ),
              ),
              Checkbox(
                value: expense.isPaid,
                onChanged: (val) => _showPaidDialog(expense, provider),
                activeColor: AppTheme.success,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
            ],
          ),
          if (expense.isPaid) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Actual Spent:',
                    style: TextStyle(color: secondaryTextColor, fontSize: 13)),
                Text(
                  '₹${expense.actualAmount.toInt()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOver ? AppTheme.danger : textColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showPaidDialog(Expense expense, ExpenseProvider provider) {
    if (expense.isPaid) {
      provider.togglePaid(expense, 0);
      return;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller =
        TextEditingController(text: expense.plannedAmount.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Expense',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppTheme.bgCardDark : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the final amount spent:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: AppTheme.inputDecoration(
                  'Amount', LucideIcons.indianRupee,
                  context: context),
              style: TextStyle(color: AppTheme.getTextColor(context)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount =
                  double.tryParse(controller.text) ?? expense.plannedAmount;
              provider.togglePaid(expense, amount);
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
