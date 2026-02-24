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
            return GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! > 0) {
                    _handleMonthChange(-1); // Swipe right → previous month
                  } else if (details.primaryVelocity! < 0) {
                    _handleMonthChange(1); // Swipe left → next month
                  }
                }
              },
              child: CustomScrollView(
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
                              return _buildExpenseCard(
                                  expense, expenseProvider);
                            },
                            childCount: expenseProvider.expenses.length,
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ],
              ),
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
    final pendingPlanned = (summary['pending_planned'] ?? 0.0).toDouble();
    final unplanned = (summary['unplanned'] ?? 0.0).toDouble();

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
          // ── Stat Row: Confirmed | Pending | Unplanned ──
          Row(
            children: [
              // Confirmed (high priority)
              Expanded(
                child: _buildSummaryStatColumn(
                  label: 'Confirmed',
                  amount: confirmedPlanned,
                  valueColor: Colors.white,
                  labelColor: Colors.white70,
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white24),
              // Pending (high priority)
              Expanded(
                child: _buildSummaryStatColumn(
                  label: 'Pending',
                  amount: pendingPlanned,
                  valueColor: const Color(0xFFFFB74D), // amber
                  labelColor: Colors.white70,
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white24),
              // Unplanned (low priority — muted)
              Expanded(
                child: _buildSummaryStatColumn(
                  label: 'Unplanned',
                  amount: unplanned,
                  valueColor: Colors.white38,
                  labelColor: Colors.white38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ── 3-segment Progress Bar ──
          Builder(builder: (context) {
            final total = confirmedPlanned + pendingPlanned + unplanned;
            final base = total > 0 ? total : 1.0;
            final pctConfirmed = (confirmedPlanned / base * 100).toInt();
            final pctPending = (pendingPlanned / base * 100).toInt();
            final pctUnplanned = (unplanned / base * 100).toInt();

            return Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Row(
                  children: [
                    if (pctConfirmed > 0)
                      Flexible(
                        flex: pctConfirmed,
                        child: Container(color: Colors.white),
                      ),
                    if (pctPending > 0)
                      Flexible(
                        flex: pctPending,
                        child:
                            Container(color: const Color(0xFFFFB74D)), // amber
                      ),
                    if (pctUnplanned > 0)
                      Flexible(
                        flex: pctUnplanned,
                        child: Container(color: Colors.white24), // muted
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          // ── Legend ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(Colors.white, 'Confirmed'),
              const SizedBox(width: 16),
              _buildLegendDot(const Color(0xFFFFB74D), 'Pending'),
              const SizedBox(width: 16),
              _buildLegendDot(Colors.white38, 'Unplanned'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStatColumn({
    required String label,
    required double amount,
    required Color valueColor,
    required Color labelColor,
  }) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: labelColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '₹${amount.toLocaleString()}',
            style: TextStyle(
                color: valueColor, fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(children: [
      Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              color: color == Colors.white38 ? Colors.white38 : Colors.white70,
              fontSize: 9)),
    ]);
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

    // Status-driven colour palette
    final Color statusColor = isConfirmed
        ? const Color(0xFF66BB6A) // green  — confirmed
        : isUnplanned
            ? Colors.grey // grey   — unplanned (low priority)
            : const Color(0xFFFFB74D); // amber — pending

    return GestureDetector(
      onTap: () => _showExpenseDetails(context, expense, category),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgCardDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadow,
          // Left accent border indicates priority/status
          border: Border(
            left: BorderSide(
              color: isUnplanned
                  ? Colors.grey.withValues(alpha: 0.4)
                  : statusColor,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(
                          alpha: isUnplanned ? 0.07 : 0.12),
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(expense.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: textColor)),
                            ),
                            if (expense.paymentMode != 'Other')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  expense.paymentMode.toUpperCase(),
                                  style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
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
                      activeColor:
                          const Color(0xFF66BB6A), // green when checked
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(LucideIcons.checkCircle2,
                          color: Colors.grey.withValues(alpha: 0.5), size: 20),
                    ),
                ],
              ),
              Divider(height: 24, color: statusColor.withValues(alpha: 0.15)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isUnplanned)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Spent',
                            style: TextStyle(
                                color: Color(0xFF66BB6A),
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                        Text('₹${expense.actualAmount.toInt()}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF66BB6A))),
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
                          Text('Spent',
                              style: TextStyle(
                                  color: const Color(0xFF66BB6A),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          Text('₹${expense.actualAmount.toInt()}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isOver
                                    ? AppTheme.danger
                                    : const Color(0xFF66BB6A),
                              )),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                                color: Color(0xFFFFB74D),
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 5),
                          const Text('Pending',
                              style: TextStyle(
                                  color: Color(0xFFFFB74D),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ],
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  } // end _buildExpenseCard

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
            if (expense.plannedAmount > 0) ...[
              const SizedBox(height: 16),
              _buildDetailRow(
                  'Planned Amount', '₹${expense.plannedAmount.toInt()}'),
            ],
            if (expense.isPaid) ...[
              const SizedBox(height: 16),
              _buildDetailRow(
                  'Amount Spent', '₹${expense.actualAmount.toInt()}'),
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
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
              const SizedBox(height: 20),
              const Text('Payment Date:'),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: isDark
                              ? const ColorScheme.dark(
                                  primary: AppTheme.primary,
                                  onPrimary: Colors.white,
                                  surface: AppTheme.bgCardDark,
                                  onSurface: Colors.white,
                                )
                              : const ColorScheme.light(
                                  primary: AppTheme.primary,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.black,
                                ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null && picked != selectedDate) {
                    setDialogState(() {
                      selectedDate = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        DateTime.now().hour,
                        DateTime.now().minute,
                      );
                    });
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.calendar,
                          size: 20,
                          color: AppTheme.getTextColor(context,
                              isSecondary: true)),
                      const SizedBox(width: 12),
                      Text(DateFormat('MMM d, yyyy').format(selectedDate),
                          style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.getTextColor(context))),
                    ],
                  ),
                ),
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
                provider.togglePaid(expense, amount,
                    paidDate: selectedDate.toIso8601String());
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditExpenseDialog(BuildContext context, Expense expense) {
    // Logic similar to add expense but with pre-filled data
    final nameController = TextEditingController(text: expense.name);
    final amountController = TextEditingController(
        text: (expense.isPaid ? expense.actualAmount : expense.plannedAmount)
            .toStringAsFixed(0));
    final remarksController = TextEditingController(text: expense.notes ?? '');
    int? selectedCategoryId = expense.categoryId;
    String selectedPaymentMode = expense.paymentMode;

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
              const SizedBox(height: 28),
              _fieldLabel('Category', textColor),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                initialValue: selectedCategoryId,
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
                    'Select category', LucideIcons.layoutGrid,
                    context: context),
              ),
              const SizedBox(height: 20),
              _fieldLabel('Payment Mode', textColor),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedPaymentMode,
                dropdownColor: modalBgColor,
                items: ['Other', 'Cash', 'Card', 'UPI', 'Net Banking', 'Wallet']
                    .map((mode) => DropdownMenuItem(
                        value: mode,
                        child: Text(mode, style: TextStyle(color: textColor))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => selectedPaymentMode = val);
                  }
                },
                decoration: AppTheme.inputDecoration(
                    'Select mode', LucideIcons.creditCard,
                    context: context),
              ),
              const SizedBox(height: 20),
              _fieldLabel('Description', textColor),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                decoration: AppTheme.inputDecoration(
                    'e.g. Electricity bill', LucideIcons.edit3,
                    context: context),
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 20),
              _fieldLabel('Amount (₹)', textColor),
              const SizedBox(height: 6),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: AppTheme.inputDecoration(
                    'e.g. 1200', LucideIcons.indianRupee,
                    context: context),
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 20),
              _fieldLabel('Remarks', textColor, optional: true),
              const SizedBox(height: 6),
              TextField(
                controller: remarksController,
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: AppTheme.inputDecoration(
                    'Add a note or comment…', LucideIcons.messageSquare,
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
                      paymentMode: selectedPaymentMode,
                      notes: remarksController.text.trim().isEmpty
                          ? null
                          : remarksController.text.trim(),
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

  Widget _fieldLabel(String label, Color textColor, {bool optional = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 4),
          Text(
            '(optional)',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}

extension DoubleExtension on double {
  String toLocaleString() {
    return toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}
