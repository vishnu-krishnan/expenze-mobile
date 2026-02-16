import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/theme_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/expense.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      provider.loadMonthData(provider.currentMonthKey);
    });
  }

  void _handleMonthChange(int offset) {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final parts = provider.currentMonthKey.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]) + offset, 1);
    final nextKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    provider.setMonth(nextKey);
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  String _formatMonthName(String key) {
    if (key.isEmpty) return 'Select Month';
    final parts = key.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
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
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
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
        child: SafeArea(
          child: Consumer<ExpenseProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final summary = provider.summary;
              final actual = summary['actual'] ?? 0.0;
              final planned = summary['planned'] ?? 0.0;
              final remaining = summary['remaining'] ?? 0.0;
              final limit = summary['limit'] ?? 0.0;
              final target = limit > 0 ? limit : planned;
              final pctUsed = target > 0 ? (actual / target) : 0.0;

              return RefreshIndicator(
                onRefresh: () =>
                    provider.loadMonthData(provider.currentMonthKey),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getTimeBasedGreeting(),
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              user?['fullName'] ?? user?['username'] ?? 'User',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if ((summary['limit'] ?? 0) <= 0)
                      SliverToBoxAdapter(
                        child: _buildMonthIndicator(provider),
                      ),
                    SliverToBoxAdapter(
                      child: _buildWalletCard(actual, remaining, pctUsed,
                          provider, summary, planned),
                    ),
                    SliverToBoxAdapter(
                      child: _buildQuickActions(context),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Spending Insights',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/analytics');
                              },
                              child: const Text('Details'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = provider.categoryBreakdown[index];
                            final title = (item['category_name'] as String?) ??
                                'Uncategorized';
                            final actualCost =
                                (item['total_actual'] as num?)?.toDouble() ??
                                    0.0;
                            final plannedCost =
                                (item['total_planned'] as num?)?.toDouble() ??
                                    0.0;
                            final amountNum =
                                actualCost > 0 ? actualCost : plannedCost;
                            final amount = '₹${amountNum.toStringAsFixed(0)}';

                            final iconStr = (item['icon'] as String?) ?? '📁';
                            final colorStr =
                                (item['color'] as String?) ?? '#3b82f6';

                            Color color;
                            try {
                              color = Color(int.parse(
                                  colorStr.replaceFirst('#', '0xff')));
                            } catch (_) {
                              color = AppTheme.primary;
                            }

                            return _buildCategoryItem(
                                context, title, amount, iconStr, color);
                          },
                          childCount: provider.categoryBreakdown.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    int? selectedCategoryId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final modalBgColor = isDark ? AppTheme.bgCardDark : Colors.white;
          final textColor = AppTheme.getTextColor(context);
          final categories = context.read<CategoryProvider>().categories;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 24,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: modalBgColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Expense',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<int>(
                    value: selectedCategoryId,
                    dropdownColor: modalBgColor,
                    items: categories
                        .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name,
                                style: TextStyle(color: textColor))))
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedCategoryId = val),
                    decoration: AppTheme.inputDecoration(
                        'Category', LucideIcons.layoutGrid,
                        context: context),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: AppTheme.inputDecoration(
                        'What is it for?', LucideIcons.edit3,
                        context: context),
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: AppTheme.inputDecoration(
                        'Amount (Planned)', LucideIcons.target,
                        context: context),
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty ||
                            selectedCategoryId == null ||
                            amountController.text.isEmpty) return;

                        final provider = context.read<ExpenseProvider>();
                        final expense = Expense(
                          monthKey: provider.currentMonthKey,
                          categoryId: selectedCategoryId,
                          name: nameController.text,
                          plannedAmount:
                              double.tryParse(amountController.text) ?? 0,
                        );

                        await provider.addExpense(expense);

                        if (mounted) Navigator.pop(context);
                      },
                      child: const Text('Add to Plan'),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWalletCard(double actual, double remaining, double pctUsed,
      ExpenseProvider provider, Map<String, double> summary, double planned) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          _handleMonthChange(-1);
        } else if (details.primaryVelocity! < 0) _handleMonthChange(1);
      },
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        height: 220,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Spent',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text(
                      '₹${actual.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                        (summary['limit'] ?? 0) > 0
                            ? 'Monthly Limit'
                            : 'Total Planned',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    Row(
                      children: [
                        Text(
                          '₹${((summary['limit'] ?? 0) > 0 ? summary['limit']! : planned).toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _showSetLimitDialog(context, provider),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.edit2,
                                size: 10, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        remaining >= 0 ? 'Remaining' : 'Exceeded',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '₹${remaining.abs().toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.landmark,
                    color: Colors.white54, size: 24),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pctUsed.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetLimitDialog(BuildContext context, ExpenseProvider provider) {
    final controller = TextEditingController(
        text: (provider.summary['limit'] ?? 0) > 0
            ? provider.summary['limit']!.toStringAsFixed(0)
            : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Monthly Limit',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).cardTheme.color,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your spending goal for this month:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: AppTheme.inputDecoration(
                  'Monthly Limit', LucideIcons.indianRupee,
                  context: context),
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
            child: const Text('Save Limit'),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthIndicator(ExpenseProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _formatMonthName(provider.currentMonthKey),
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionItem(context, LucideIcons.calendar, 'Plan',
              () => Navigator.pushNamed(context, '/month')),
          _buildActionItem(context, LucideIcons.mail, 'Import',
              () => Navigator.pushNamed(context, '/import')),
          _buildActionItem(context, LucideIcons.grid, 'Types',
              () => Navigator.pushNamed(context, '/categories')),
        ],
      ),
    );
  }

  Widget _buildActionItem(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppTheme.softShadow,
            ),
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: secondaryTextColor)),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, String title, String amount,
      String icon, Color color) {
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor)),
                Text('Monthly spending',
                    style: TextStyle(color: secondaryTextColor, fontSize: 11)),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
          ),
        ],
      ),
    );
  }
}
