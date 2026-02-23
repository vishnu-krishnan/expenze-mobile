import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/expense.dart';
import 'recent_expenses_screen.dart' hide RecentDoubleExtension;
import 'category_transactions_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _quoteText = '';
  String _quoteAuthor = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      provider.loadMonthData(provider.currentMonthKey);
    });
    _fetchQuote();
  }

  Future<void> _fetchQuote() async {
    try {
      final response = await http
          .get(Uri.parse('https://zenquotes.io/api/today'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        if (data.isNotEmpty && mounted) {
          setState(() {
            _quoteText = data[0]['q'] as String? ?? '';
            _quoteAuthor = data[0]['a'] as String? ?? '';
          });
        }
      }
    } catch (_) {
      // Silently fail — quotes are non-critical
    }
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
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final summary = provider.summary;
          final actual = summary['actual'] ?? 0.0;
          final planned = summary['planned'] ?? 0.0;
          final remaining = summary['remaining'] ?? 0.0;
          final limit = summary['limit'] ?? 0.0;
          final target = limit > 0 ? limit : planned;
          final pctUsed = target > 0 ? (actual / target) : 0.0;

          return RefreshIndicator(
            onRefresh: () => Future.wait([
              provider.resetToCurrentMonth(),
              _fetchQuote(),
            ]),
            displacement: 40,
            color: AppTheme.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                if (provider.isLoading)
                  const SliverToBoxAdapter(
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: AppTheme.primary,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  automaticallyImplyLeading: false,
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
                          Text(
                            _getTimeBasedGreeting(),
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            user?['full_name'] ?? 'User',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildWalletCard(
                        actual, remaining, pctUsed, provider, summary, planned),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildQuickActions(context),
                ),
                if (_quoteText.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildQuoteCard(textColor, secondaryTextColor),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(26, 32, 26, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Expense Category',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const RecentExpensesScreen()),
                          ),
                          child: Icon(LucideIcons.arrowRight,
                              size: 18, color: secondaryTextColor),
                        ),
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
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CategoryTransactionsScreen(
                                  categoryId: item['id'] as int?,
                                  categoryName:
                                      item['category_name'] ?? 'Imported',
                                  monthKey: provider.currentMonthKey,
                                  categoryIcon: item['icon'],
                                  categoryColor: item['color'],
                                ),
                              ),
                            );
                          },
                          child: _buildCategoryItem(context, item),
                        );
                      },
                      childCount: provider.categoryBreakdown.take(3).length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ),
          );
        },
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
          child: const Icon(LucideIcons.plus, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildWalletCard(double actual, double remaining, double pctUsed,
      ExpenseProvider provider, Map<String, double> summary, double planned) {
    final statusColor = pctUsed > 0.9
        ? AppTheme.danger
        : (pctUsed > 0.7 ? AppTheme.warning : Colors.white);
    final budget = summary['limit'] ?? (planned > 0 ? planned : 0.0);
    final isOverBudget = pctUsed >= 1.0;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          _handleMonthChange(-1); // Swipe Right -> Prev
        } else if (details.primaryVelocity! < 0) {
          _handleMonthChange(1); // Swipe Left -> Next
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle
            Positioned(
              right: -30,
              bottom: -30,
              child: CircleAvatar(
                radius: 90,
                backgroundColor: Colors.white.withValues(alpha: 0.04),
              ),
            ),
            Positioned(
              left: -20,
              top: -20,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withValues(alpha: 0.03),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top row — month navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Spent',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.chevronLeft,
                                color: Colors.white60, size: 18),
                            onPressed: () => _handleMonthChange(-1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
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
                                color: Colors.white60, size: 18),
                            onPressed: () => _handleMonthChange(1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Main amount — large and prominent
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '₹${actual.toLocaleString()}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Divider line
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  const SizedBox(height: 16),

                  // Two-column stats row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatColumn(
                          label: 'Remaining',
                          value: '₹${remaining.abs().toLocaleString()}',
                          valueColor: statusColor,
                          icon: isOverBudget
                              ? LucideIcons.alertTriangle
                              : LucideIcons.trendingDown,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 48,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      Expanded(
                        child: _buildStatColumn(
                          label: 'Monthly Budget',
                          value: budget > 0
                              ? '₹${budget.toLocaleString()}'
                              : 'Not set',
                          valueColor: Colors.white,
                          icon: LucideIcons.target,
                          alignRight: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Progress bar
                  _buildProgressBar(pctUsed, statusColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
    bool alignRight = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
          left: alignRight ? 16 : 0, right: alignRight ? 0 : 16),
      child: Column(
        crossAxisAlignment:
            alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!alignRight)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(icon, size: 11, color: Colors.white54),
                ),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3)),
              if (alignRight)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(icon, size: 11, color: Colors.white54),
                ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment:
                alignRight ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                  color: valueColor, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
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
            color: Colors.white.withValues(alpha: 0.15),
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
                    BoxShadow(
                        color: color.withValues(alpha: 0.5), blurRadius: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteCard(Color textColor, Color secondaryTextColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.08)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('✨', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"$_quoteText"',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                  if (_quoteAuthor.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '— $_quoteAuthor',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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
          _buildActionCard(context, LucideIcons.repeat, 'Regular',
              AppTheme.primary, () => Navigator.pushNamed(context, '/regular')),
          const SizedBox(width: 12),
          _buildActionCard(context, LucideIcons.stickyNote, 'Notes',
              AppTheme.primary, () => Navigator.pushNamed(context, '/notes')),
          const SizedBox(width: 12),
          _buildActionCard(
              context,
              LucideIcons.layoutGrid,
              'Categories',
              AppTheme.primary,
              () => Navigator.pushNamed(context, '/categories')),
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
                color: color.withValues(alpha: 0.1),
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
              Text(
                  (planned == 0 && actual > 0)
                      ? 'Unplanned'
                      : (actual > 0 ? 'Spent' : 'Planned'),
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
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    // Re-using existing dialog logic but with slight UI polish
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    int? selectedCategoryId;
    String selectedPaymentMode = 'Other';

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
                              color: Colors.grey.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  Text('New Expense',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 28),
                  _fieldLabel('Category', textColor),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: selectedCategoryId,
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
                        'Select category', LucideIcons.layoutGrid,
                        context: context),
                  ),
                  const SizedBox(height: 20),
                  _fieldLabel('Payment Mode', textColor),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPaymentMode,
                    dropdownColor: modalBgColor,
                    items: [
                      'Other',
                      'Cash',
                      'Card',
                      'UPI',
                      'Net Banking',
                      'Wallet'
                    ]
                        .map((mode) => DropdownMenuItem(
                            value: mode,
                            child:
                                Text(mode, style: TextStyle(color: textColor))))
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
                        final provider = context.read<ExpenseProvider>();
                        final amount =
                            double.tryParse(amountController.text) ?? 0;
                        await provider.addExpense(Expense(
                          monthKey: provider.currentMonthKey,
                          categoryId: selectedCategoryId,
                          name: nameController.text,
                          plannedAmount: 0.0,
                          actualAmount: amount,
                          isPaid: true,
                          paymentMode: selectedPaymentMode,
                          paidDate: DateTime.now().toIso8601String(),
                        ));
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18))),
                      child: const Text('Add',
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
