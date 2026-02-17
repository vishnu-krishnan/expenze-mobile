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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? AppTheme.darkBackgroundDecoration
            : AppTheme.backgroundDecoration,
        child: Consumer2<ExpenseProvider, CategoryProvider>(
          builder: (context, expenseProvider, categoryProvider, child) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.transparent,
                  expandedHeight: 100,
                  floating: true,
                  pinned: false,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: EdgeInsets.zero,
                    background: Padding(
                      padding: const EdgeInsets.fromLTRB(26, 10, 26, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Financial Overview',
                              style: TextStyle(
                                  color: themeProvider.isDarkMode
                                      ? AppTheme.getTextColor(context,
                                          isSecondary: true)
                                      : AppTheme.getTextColor(context,
                                          isSecondary: true),
                                  fontSize: 13,
                                  letterSpacing: 0.5)),
                          Text('Monthly Planner',
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                  letterSpacing: -1)),
                        ],
                      ),
                    ),
                  ),
                ),
                if (expenseProvider.isLoading &&
                    expenseProvider.expenses.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
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
                          'Transaction List',
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
    final confirmedPlanned = (summary['confirmed_planned'] ?? 0.0).toDouble();
    final unplanned = (summary['unplanned'] ?? 0.0).toDouble();

    // The user wants only confirmed planned on the card
    final target = confirmedPlanned;

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
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('Planned',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Column(
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                    '₹${confirmedPlanned.toLocaleString()}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ),
                              const Text('Confirmed',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 8)),
                            ],
                          ),
                        ),
                        Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 1,
                            height: 15,
                            color: Colors.white12),
                        Flexible(
                          child: Column(
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                    '₹${(summary['pending_planned'] ?? 0.0).toDouble().toLocaleString()}',
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ),
                              const Text('Pending',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 8)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(
                child: Column(
                  children: [
                    const Text('Unplanned',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('₹${unplanned.toLocaleString()}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Multi-colored Progress Bar
          Builder(builder: (context) {
            // Reference logic: Total Plan vs Unplanned Expenses
            final total = target + unplanned;
            final base = total > 0 ? total : 1.0;

            final pctPlanned = (target / base * 100).toInt();
            final pctUnplanned = (unplanned / base * 100).toInt();

            return Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    if (pctPlanned > 0)
                      Flexible(
                        flex: pctPlanned,
                        child: Container(color: Colors.white),
                      ),
                    if (pctUnplanned > 0)
                      Flexible(
                        flex: pctUnplanned,
                        child: Container(color: const Color(0xFFFFAB40)),
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                const Text('Confirmed',
                    style: TextStyle(color: Colors.white70, fontSize: 10)),
              ]),
              Row(children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Color(0xFFFFAB40), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                const Text('Unplanned',
                    style: TextStyle(color: Colors.white70, fontSize: 10)),
              ]),
            ],
          )
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
    final bool isUnplanned = expense.plannedAmount == 0;
    final bool isConfirmed = expense.isPaid;
    final bool isOver = isConfirmed &&
        !isUnplanned &&
        (expense.actualAmount > expense.plannedAmount);
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get category
    final categoryProvider = context.read<CategoryProvider>();
    final category = categoryProvider.categories.firstWhere(
      (c) => c.id == expense.categoryId,
      orElse: () => categoryProvider.categories.first,
    );

    // Format Date
    String dateStr = '';
    if (expense.createdAt != null) {
      final date = DateTime.parse(expense.createdAt!).toLocal();
      dateStr = DateFormat('MMM d, h:mm a').format(date);
    }

    return GestureDetector(
      onTap: () => _showExpenseDetails(context, expense, category),
      child: Container(
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
                    color:
                        (expense.isPaid ? AppTheme.success : AppTheme.primary)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    category.icon ?? '📁',
                    style: const TextStyle(fontSize: 20),
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
                      if (dateStr.isNotEmpty)
                        Text(dateStr,
                            style: TextStyle(
                                color: secondaryTextColor, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(LucideIcons.edit3,
                      size: 18, color: secondaryTextColor),
                  onPressed: () => _showEditExpenseDialog(context, expense),
                ),
                if (!isUnplanned)
                  Checkbox(
                    value: expense.isPaid,
                    onChanged: (val) => _showPaidDialog(expense, provider),
                    activeColor: AppTheme.success,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(LucideIcons.checkCircle2,
                        color: AppTheme.success, size: 20),
                  ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isUnplanned)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Unplanned',
                          style: TextStyle(
                              color: AppTheme.warning,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                      Text('₹${expense.actualAmount.toInt()}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: textColor)),
                    ],
                  )
                else ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Planned',
                          style: TextStyle(
                              color: secondaryTextColor, fontSize: 12)),
                      Text('₹${expense.plannedAmount.toInt()}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: textColor)),
                    ],
                  ),
                  if (isConfirmed)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Actual',
                            style: TextStyle(
                                color: secondaryTextColor, fontSize: 12)),
                        Text('₹${expense.actualAmount.toInt()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isOver ? AppTheme.danger : textColor,
                            )),
                      ],
                    )
                  else
                    const Text('Pending',
                        style: TextStyle(
                            color: AppTheme.warning,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseDetails(
      BuildContext context, Expense expense, dynamic category) {
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgCardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category.icon ?? '📝',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.name,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor),
                      ),
                      Text(
                        category.name,
                        style:
                            TextStyle(color: secondaryTextColor, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildDetailRow('Status', expense.isPaid ? 'Paid' : 'Pending',
                valueColor:
                    expense.isPaid ? AppTheme.success : AppTheme.warning),
            const SizedBox(height: 16),
            _buildDetailRow(
                'Planned Amount', '₹${expense.plannedAmount.toInt()}'),
            if (expense.isPaid) ...[
              const SizedBox(height: 16),
              _buildDetailRow(
                  'Actual Spent', '₹${expense.actualAmount.toInt()}'),
            ],
            const SizedBox(height: 16),
            if (expense.createdAt != null)
              _buildDetailRow(
                  'Date',
                  DateFormat('MMM d, yyyy h:mm a')
                      .format(DateTime.parse(expense.createdAt!).toLocal())),
            if (expense.notes != null && expense.notes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Inbox Message',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black12 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Text(
                  expense.notes!,
                  style: TextStyle(
                    color: textColor,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
    final amountController = TextEditingController(
        text: (expense.isPaid ? expense.actualAmount : expense.plannedAmount)
            .toStringAsFixed(0));
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

                    final amount = double.tryParse(amountController.text) ?? 0;
                    final bool isUnplanned = expense.plannedAmount == 0;

                    final updated = expense.copyWith(
                      categoryId: selectedCategoryId,
                      name: nameController.text,
                      plannedAmount: isUnplanned
                          ? 0
                          : (expense.isPaid ? expense.plannedAmount : amount),
                      actualAmount: expense.isPaid ? amount : 0,
                    );

                    await context
                        .read<ExpenseProvider>()
                        .updateExpense(updated);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18))),
                  child: const Text('Update',
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

extension DoubleExtension on double {
  String toLocaleString() {
    return toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}
