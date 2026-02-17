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

    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? AppTheme.darkBackgroundDecoration
            : AppTheme.backgroundDecoration,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              automaticallyImplyLeading: false,
              title: Text(
                'Monthly Planner',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  letterSpacing: -1,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              floating: true,
              pinned: true,
            ),
          ],
          body: Consumer2<ExpenseProvider, CategoryProvider>(
            builder: (context, expenseProvider, categoryProvider, child) {
              if (expenseProvider.isLoading &&
                  expenseProvider.expenses.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // 1. Month Navigation
                  SliverToBoxAdapter(
                    child:
                        _buildMonthNavigator(expenseProvider.currentMonthKey),
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
    final planned = (summary['planned'] ?? 0.0).toDouble();
    final actual = (summary['actual'] ?? 0.0).toDouble();
    // Use planned amount as target for this screen (ignoring global limit)
    final target = planned;
    final remaining = target - actual;
    // limit is available in summary but we ignore it here as requested

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
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
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildSummaryItem('Planned', '₹${target.toInt()}'),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildSummaryItem('Spent', '₹${actual.toInt()}'),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildSummaryItem('Progress',
                  '${target > 0 ? (actual / target * 100).toInt() : 0}%'),
            ],
          ),
          const SizedBox(height: 24),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (actual / (target > 0 ? target : 1)).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                (actual / (target > 0 ? target : 1)) > 1.0
                    ? const Color(0xFFFF5252) // Red
                    : (actual / (target > 0 ? target : 1)) > 0.75
                        ? const Color(0xFFFFAB40) // Orange
                        : Colors.white,
              ),
              minHeight: 8,
            ),
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
              IconButton(
                icon: Icon(LucideIcons.edit3,
                    size: 18, color: secondaryTextColor),
                onPressed: () => _showEditExpenseDialog(context, expense),
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
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showEditExpenseDialog(BuildContext context, Expense expense) {
    // Logic similar to add expense but with pre-filled data
    final nameController = TextEditingController(text: expense.name);
    final amountController =
        TextEditingController(text: expense.plannedAmount.toStringAsFixed(0));
    int? selectedCategoryId = expense.categoryId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final modalBgColor = isDark ? AppTheme.bgCardDark : Colors.white;
        final textColor = AppTheme.getTextColor(context);
        final categories = context.read<CategoryProvider>().categories;

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 40,
            top: 32,
            left: 32,
            right: 32,
          ),
          decoration: BoxDecoration(
            color: modalBgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Expense',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: textColor)),
              const SizedBox(height: 32),
              DropdownButtonFormField<int>(
                value: selectedCategoryId,
                dropdownColor: modalBgColor,
                items: categories
                    .map((c) => DropdownMenuItem(
                        value: c.id,
                        child:
                            Text(c.name, style: TextStyle(color: textColor))))
                    .toList(),
                onChanged: (val) =>
                    setModalState(() => selectedCategoryId = val),
                decoration: AppTheme.inputDecoration(
                    'Category', LucideIcons.layoutGrid,
                    context: context),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: AppTheme.inputDecoration(
                    'Description', LucideIcons.edit3,
                    context: context),
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: AppTheme.inputDecoration(
                    'Amount', LucideIcons.target,
                    context: context),
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty ||
                        selectedCategoryId == null ||
                        amountController.text.isEmpty) {
                      return;
                    }

                    final updated = expense.copyWith(
                      categoryId: selectedCategoryId,
                      name: nameController.text,
                      plannedAmount:
                          double.tryParse(amountController.text) ?? 0,
                    );

                    await context
                        .read<ExpenseProvider>()
                        .updateExpense(updated);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18))),
                  child: const Text('Update Plan',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
