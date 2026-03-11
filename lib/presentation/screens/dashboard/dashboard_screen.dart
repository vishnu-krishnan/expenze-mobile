import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _quoteText = '';
  String _quoteAuthor = '';
  bool _isFabVisible = true;

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
          .get(Uri.parse('https://zenquotes.io/api/random'))
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
    if (hour < 6) return 'Burning midnight oil,';
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    if (hour < 21) return 'Good evening,';
    return 'Up late?';
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
          // If actual > 0 and no target (budget) is set, we are effectively over budget
          final pctUsed =
              target > 0 ? (actual / target) : (actual > 0 ? 1.01 : 0.0);

          return CustomRefreshIndicator(
            onRefresh: () => Future.wait([
              provider.resetToCurrentMonth(),
              _fetchQuote(),
            ]),
            builder: (context, child, controller) {
              return Stack(
                alignment: Alignment.topCenter,
                children: [
                  AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) {
                      final double dy = controller.value.clamp(0.0, 1.0) * 80.0;
                      if (dy == 0) return const SizedBox.shrink();
                      return Transform.translate(
                        offset: Offset(0, dy - 40),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                blurRadius: 20,
                                spreadRadius: -5,
                              )
                            ],
                          ),
                          child: controller.state.isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.primary),
                                  ),
                                )
                              : Transform.rotate(
                                  angle: controller.value * 2 * 3.1415,
                                  child: Icon(
                                    LucideIcons.sparkles,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                  Transform.translate(
                    offset: Offset(0, controller.value.clamp(0.0, 1.0) * 80.0),
                    child: child,
                  ),
                ],
              );
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification is ScrollUpdateNotification) {
                  if (notification.scrollDelta != null) {
                    if (notification.scrollDelta! > 2 && _isFabVisible) {
                      setState(() => _isFabVisible = false);
                    } else if (notification.scrollDelta! < -2 &&
                        !_isFabVisible) {
                      setState(() => _isFabVisible = true);
                    }
                  }
                }
                return false;
              },
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
                        padding: EdgeInsets.fromLTRB(
                            26, MediaQuery.of(context).padding.top + 10, 26, 0),
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
                      child: _buildWalletCard(actual, remaining, pctUsed,
                          provider, summary, planned),
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
                            'Where your money ran off to',
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
            ),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120),
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isFabVisible ? 1.0 : 0.0,
            child: FloatingActionButton(
              heroTag: 'dashboard_fab',
              onPressed: () => _showAddExpenseDialog(context),
              backgroundColor: AppTheme.primary,
              elevation: 10,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              child:
                  const Icon(LucideIcons.plus, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard(double actual, double remaining, double pctUsed,
      ExpenseProvider provider, Map<String, double> summary, double planned) {
    List<Color> cardColors;
    Color shadowBase;

    if (pctUsed < 0.5) {
      // 0-50%: Safe (Teal/Green)
      cardColors = [AppTheme.primary, AppTheme.primaryDark];
      shadowBase = AppTheme.primary;
    } else if (pctUsed < 0.7) {
      // 50-70%: Caution (Lime-Yellow)
      cardColors = [const Color(0xFF84CC16), const Color(0xFF65A30D)];
      shadowBase = const Color(0xFF84CC16);
    } else if (pctUsed < 0.85) {
      // 70-85%: Warning (Amber/Yellow)
      cardColors = [AppTheme.warning, AppTheme.warningDark];
      shadowBase = AppTheme.warning;
    } else if (pctUsed < 1.1) {
      // 85-110%: Danger (Red)
      cardColors = [AppTheme.danger, AppTheme.dangerDark];
      shadowBase = AppTheme.danger;
    } else {
      // >110%: Critical (Dark Red)
      cardColors = [const Color(0xFF991B1B), const Color(0xFF7F1D1D)];
      shadowBase = const Color(0xFF991B1B);
    }

    final cardShadowColor = shadowBase.withValues(alpha: 0.3);
    final statusColor = Colors.white;

    // Correctly determine budget display: Prioritize limit, fallback to planned sum
    final budgetLimit = summary['limit'] ?? 0.0;
    final budget =
        budgetLimit > 0 ? budgetLimit : (planned > 0 ? planned : 0.0);

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
          gradient: LinearGradient(
            colors: cardColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: cardShadowColor,
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
                      Text(
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
                              style: TextStyle(
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        height: 1.1,
                      ),
                    ),
                  ),

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
                          label: pctUsed >= 1.0 ? 'Overspent' : 'Remaining',
                          value: '₹${remaining.abs().toLocaleString()}',
                          valueColor: statusColor,
                          icon: pctUsed >= 1.0
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
                  style: TextStyle(
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
            Text(
                pct >= 1.0
                    ? '🔴 Oops, over budget!'
                    : (pct >= 0.9
                        ? '🚨 Almost maxed out'
                        : (pct >= 0.8
                            ? '⚠️ Getting close'
                            : (pct >= 0.7
                                ? 'Mind the spending'
                                : '✅ Looking good'))),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight:
                        pct >= 0.8 ? FontWeight.bold : FontWeight.normal)),
            Text('${(pct * 100).toInt()}% used',
                style: TextStyle(
                    color: pct >= 0.9 ? Colors.white : Colors.white70,
                    fontSize: 10,
                    fontWeight:
                        pct >= 0.8 ? FontWeight.bold : FontWeight.normal)),
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
              child: Text('✨', style: TextStyle(fontSize: 18)),
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
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AnimatedActionCard(
            icon: LucideIcons.downloadCloud,
            label: 'Import',
            color: AppTheme.primary,
            onTap: () => Navigator.pushNamed(context, '/import'),
          ),
          const SizedBox(width: 14),
          _AnimatedActionCard(
            icon: LucideIcons.repeat,
            label: 'Regular',
            color: const Color(0xFFE67E22), // Orange
            onTap: () => Navigator.pushNamed(context, '/regular'),
          ),
          const SizedBox(width: 14),
          _AnimatedActionCard(
            icon: LucideIcons.stickyNote,
            label: 'Notes',
            color: AppTheme.success, // Green
            onTap: () => Navigator.pushNamed(context, '/notes'),
          ),
          const SizedBox(width: 14),
          _AnimatedActionCard(
            icon: LucideIcons.gift,
            label: 'Wishes',
            color: const Color(0xFF9B59B6), // Purple
            onTap: () => Navigator.pushNamed(context, '/wishes'),
          ),
          const SizedBox(width: 14),
          _AnimatedActionCard(
            icon: LucideIcons.layoutGrid,
            label: 'Categories',
            color: const Color(0xFFE74C3C), // Red
            onTap: () => Navigator.pushNamed(context, '/categories'),
          ),
        ],
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
            child: Text(item['icon'] ?? '📁', style: TextStyle(fontSize: 24)),
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
                      child: Text('Add',
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

class _AnimatedActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AnimatedActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AnimatedActionCard> createState() => _AnimatedActionCardState();
}

class _AnimatedActionCardState extends State<_AnimatedActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.22,
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
                  color: widget.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              const SizedBox(height: 12),
              Text(widget.label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context))),
            ],
          ),
        ),
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
