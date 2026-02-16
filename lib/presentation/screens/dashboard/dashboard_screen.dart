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
                        padding: const EdgeInsets.fromLTRB(26, 20, 26, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getTimeBasedGreeting(),
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 14,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  user?['fullName'] ??
                                      user?['username'] ??
                                      'User',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _buildWalletCard(actual, remaining, pctUsed,
                            provider, summary, planned),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildQuickActions(context),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(26, 32, 26, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Category Breakdown',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Icon(LucideIcons.arrowRight,
                                size: 18, color: secondaryTextColor),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = provider.categoryBreakdown[index];
                            return _buildCategoryItem(context, item);
                          },
                          childCount: provider.categoryBreakdown.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120),
        child: FloatingActionButton(
          heroTag: 'dashboard_fab',
          onPressed: () => _showAddExpenseDialog(context),
          backgroundColor: AppTheme.primary,
          elevation: 10,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: const Icon(LucideIcons.plus,
              color: AppTheme.primaryDark, size: 30),
        ),
      ),
    );
  }

  Widget _buildWalletCard(double actual, double remaining, double pctUsed,
      ExpenseProvider provider, Map<String, double> summary, double planned) {
    final statusColor = pctUsed > 0.9
        ? AppTheme.danger
        : (pctUsed > 0.7 ? AppTheme.warning : Colors.white);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          _handleMonthChange(-1); // Swipe Right -> Prev
        } else if (details.primaryVelocity! < 0) {
          _handleMonthChange(1); // Swipe Left -> Next
        }
      },
      child: Container(
        margin: const EdgeInsets.all(24),
        // Removed fixed height to prevent overflow
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
              blurRadius: 25,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: CircleAvatar(
                radius: 80,
                backgroundColor: Colors.white.withOpacity(0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Spent',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      // Date Selector inside Card
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.chevronLeft,
                                color: Colors.white70, size: 18),
                            onPressed: () => _handleMonthChange(-1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              _formatMonthName(provider.currentMonthKey),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.chevronRight,
                                color: Colors.white70, size: 18),
                            onPressed: () => _handleMonthChange(1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${actual.toStringAsFixed(0)}', // Simplified formatting
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBalanceInfo('Remaining', remaining, statusColor),
                      _buildBalanceInfo(
                          'Spending Limit',
                          summary['limit'] ?? (planned > 0 ? planned : 0.0),
                          Colors.white,
                          alignment: CrossAxisAlignment.end),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildProgressBar(pctUsed, statusColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceInfo(String label, double amount, Color color,
      {CrossAxisAlignment alignment = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
        Text(
          '₹${amount.abs().toLocaleString()}',
          style: TextStyle(
              color: color, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double pct, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${(pct * 100).toInt()}% used',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
            Text(pct >= 1.0 ? 'Over limit' : 'On track',
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: pct.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.5), blurRadius: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Row(
        children: [
          _buildActionCard(context, LucideIcons.mail, 'Import',
              AppTheme.primary, () => Navigator.pushNamed(context, '/import')),
          const SizedBox(width: 12),
          _buildActionCard(context, LucideIcons.creditCard, 'Bills',
              AppTheme.primary, () => Navigator.pushNamed(context, '/regular')),
          const SizedBox(width: 12),
          _buildActionCard(context, LucideIcons.stickyNote, 'Notes',
              AppTheme.primary, () => Navigator.pushNamed(context, '/notes')),
          const SizedBox(width: 12),
          _buildActionCard(context, LucideIcons.calendar, 'Planner',
              AppTheme.primary, () => Navigator.pushNamed(context, '/month')),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width *
            0.22, // Slightly smaller to fit 4
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgCardDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context))),
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

    return Container(
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
              color: color.withOpacity(0.1),
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
                const SizedBox(height: 2),
                Text('Updated recently',
                    style: TextStyle(color: secondaryTextColor, fontSize: 11)),
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
              Text(actual > 0 ? 'Actual' : 'Planned',
                  style: TextStyle(
                      color: actual > 0 ? AppTheme.primary : secondaryTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    // Re-using existing dialog logic but with slight UI polish
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
              bottom: MediaQuery.of(context).viewInsets.bottom + 40,
              top: 32,
              left: 32,
              right: 32,
            ),
            decoration: BoxDecoration(
              color: modalBgColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  Text('New Expense Plan',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 32),
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
                            amountController.text.isEmpty) return;
                        final provider = context.read<ExpenseProvider>();
                        await provider.addExpense(Expense(
                          monthKey: provider.currentMonthKey,
                          categoryId: selectedCategoryId,
                          name: nameController.text,
                          plannedAmount:
                              double.tryParse(amountController.text) ?? 0,
                        ));
                        if (mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18))),
                      child: const Text('Add to Plan',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

extension DoubleExtension on double {
  String toLocaleString() {
    return toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}
