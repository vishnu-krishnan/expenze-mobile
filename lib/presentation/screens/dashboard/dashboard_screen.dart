import 'dart:convert';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/expense.dart';
import 'recent_expenses_screen.dart' hide RecentDoubleExtension;
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import '../../widgets/liquid_glass_fab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgAnimationController;
  String _quoteText = '';
  String _quoteAuthor = '';
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      provider.loadMonthData(provider.currentMonthKey);
    });
    _fetchQuote();
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    super.dispose();
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

  Widget _buildHeaderDatePill() {
    final now = DateTime.now();
    final months = [
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
    final dateStr = '${now.day} ${months[now.month - 1]}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.calendar, size: 14, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            dateStr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
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
      body: Column(
        children: [
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: AppTheme.headerOverlayStyle,
            child: Container(
              height: 110 + MediaQuery.of(context).padding.top,
              width: double.infinity,
              decoration: AppTheme.headerDecoration(context),
              padding: EdgeInsets.fromLTRB(
                  26, MediaQuery.of(context).padding.top + 10, 26, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getTimeBasedGreeting(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        user?['full_name'] ?? 'User',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  _buildHeaderDatePill(),
                ],
              ),
            ),
          ),
          Expanded(
            child: Consumer<ExpenseProvider>(
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
                            final double dy =
                                controller.value.clamp(0.0, 1.0) * 80.0;
                            if (dy == 0) return const SizedBox.shrink();
                            return Transform.translate(
                              offset: Offset(0, dy - 40),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppTheme.primary
                                          .withValues(alpha: 0.2)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary
                                          .withValues(alpha: 0.1),
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  AppTheme.primary),
                                        ),
                                      )
                                    : Transform.rotate(
                                        angle: controller.value * 2 * 3.1415,
                                        child: Icon(
                                          LucideIcons.rotateCw,
                                          color: AppTheme.primary,
                                          size: 20,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                        Transform.translate(
                          offset: Offset(
                              0, controller.value.clamp(0.0, 1.0) * 80.0),
                          child: child,
                        ),
                      ],
                    );
                  },
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification notification) {
                      if (notification is ScrollUpdateNotification) {
                        // Force visibility at top
                        if (notification.metrics.pixels <= 10) {
                          if (!_isFabVisible) {
                            setState(() => _isFabVisible = true);
                          }
                          return false;
                        }

                        if (notification.scrollDelta != null) {
                          if (notification.scrollDelta! > 5 && _isFabVisible) {
                            setState(() => _isFabVisible = false);
                          } else if (notification.scrollDelta! < -5 &&
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
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: _buildWalletCard(actual, remaining, pctUsed,
                                provider, summary, planned),
                          ),
                        ),

                        // Action Hub
                        SliverToBoxAdapter(
                          child: _buildActionHub(context),
                        ),

                        if (_quoteText.isNotEmpty)
                          SliverToBoxAdapter(
                            child:
                                _buildQuoteCard(textColor, secondaryTextColor),
                          ),

                        // Recent Pulse (Last 3 Transactions)
                        if (provider.expenses.isNotEmpty)
                          SliverToBoxAdapter(
                            child: _buildRecentPulse(context, provider),
                          ),

                        const SliverToBoxAdapter(child: SizedBox(height: 140)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 110),
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isFabVisible ? 1.0 : 0.0,
            child: LiquidGlassFAB(
              heroTag: 'dashboard_fab',
              onPressed: () => _showAddExpenseDialog(context),
              icon: LucideIcons.plus,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard(double actual, double remaining, double pctUsed,
      ExpenseProvider provider, Map<String, double> summary, double planned) {
    List<Color> cardColors;
    if (pctUsed < 0.5) {
      cardColors = [const Color(0xFF10B981), const Color(0xFF059669)];
    } else if (pctUsed < 0.7) {
      cardColors = [const Color(0xFF84CC16), const Color(0xFF65A30D)];
    } else if (pctUsed < 0.85) {
      cardColors = [const Color(0xFFF59E0B), const Color(0xFFD97706)];
    } else if (pctUsed < 1.1) {
      cardColors = [const Color(0xFFEF4444), const Color(0xFFDC2626)];
    } else {
      cardColors = [const Color(0xFFB91C1C), const Color(0xFF991B1B)];
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final desaturatedColors = cardColors.map((c) {
      Color color = AppTheme.desaturate(c, amount: 0.45);
      if (!isDark) {
        final hsl = HSLColor.fromColor(color);
        color =
            hsl.withLightness((hsl.lightness + 0.3).clamp(0.0, 1.0)).toColor();
      }
      return color;
    }).toList();

    final progressColor = isDark
        ? AppTheme.desaturate(cardColors[0], amount: 0.25).withValues(alpha: 0.7)
        : cardColors[0];
    final contentColor = isDark ? Colors.white : const Color(0xFF020617); // Rich Midnight Slate 950
    final secondaryContentColor = isDark
        ? Colors.white.withValues(alpha: 0.75)
        : const Color(0xFF1E293B); // Rich Slate 800
    final statusColor = contentColor;

    final budgetLimit = summary['limit'] ?? 0.0;
    final budget =
        budgetLimit > 0 ? budgetLimit : (planned > 0 ? planned : 0.0);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          _handleMonthChange(-1);
        } else if (details.primaryVelocity! < 0) {
          _handleMonthChange(1);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Stack(
              children: [
                if (!isDark)
                  Positioned.fill(
                    child: Container(color: Colors.white),
                  ),
                Positioned.fill(
                  child: _buildAnimatedBackground(desaturatedColors),
                ),
                if (!isDark)
                  Positioned.fill(
                    child:
                        Container(color: Colors.white.withValues(alpha: 0.4)),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        desaturatedColors[0].withValues(alpha: 0.25),
                        desaturatedColors[0].withValues(alpha: 0.1),
                        desaturatedColors[1].withValues(alpha: 0.08),
                        desaturatedColors[1].withValues(alpha: 0.2),
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Top Shine / Gloss Layer
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.08),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.3],
                            ),
                          ),
                        ),
                      ),
                      // Decorative circles
                      Positioned(
                        right: -30,
                        bottom: -30,
                        child: CircleAvatar(
                          radius: 90,
                          backgroundColor: Colors.white
                              .withValues(alpha: isDark ? 0.05 : 0.15),
                        ),
                      ),
                      Positioned(
                        left: -20,
                        top: -20,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white
                              .withValues(alpha: isDark ? 0.04 : 0.12),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Spent',
                                  style: TextStyle(
                                    color: contentColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    shadows: isDark
                                        ? [
                                            Shadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.5),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2))
                                          ]
                                        : [],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _handleMonthChange(-1),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text('‹',
                                            style: TextStyle(
                                                color: secondaryContentColor,
                                                fontSize:
                                                    30, // Increased from 22
                                                shadows: isDark
                                                    ? [
                                                        Shadow(
                                                            color: Colors.black
                                                                .withValues(
                                                                    alpha: 0.3),
                                                            blurRadius: 4)
                                                      ]
                                                    : [])),
                                      ),
                                    ),
                                    Text(
                                      _formatMonthName(
                                          provider.currentMonthKey),
                                      style: TextStyle(
                                        color: contentColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        shadows: isDark
                                            ? [
                                                Shadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.5),
                                                    blurRadius: 5)
                                              ]
                                            : [],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _handleMonthChange(1),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text('›',
                                            style: TextStyle(
                                                color: secondaryContentColor,
                                                fontSize:
                                                    30, // Increased from 22
                                                shadows: isDark
                                                    ? [
                                                        Shadow(
                                                            color: Colors.black
                                                                .withValues(
                                                                    alpha: 0.3),
                                                            blurRadius: 4)
                                                      ]
                                                    : [])),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '₹${actual.toLocaleString()}',
                                style: TextStyle(
                                  color: contentColor,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                  height: 1.1,
                                  shadows: isDark
                                      ? [
                                          Shadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.7),
                                              blurRadius: 18,
                                              offset: const Offset(0, 6)),
                                          Shadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2)),
                                        ]
                                      : [
                                          Shadow(
                                            color: Colors.white
                                                .withValues(alpha: 0.8),
                                            offset: const Offset(0, 2),
                                            blurRadius: 4,
                                          )
                                        ],
                                ),
                              ),
                            ),
                            Container(
                              height: 1,
                              color: contentColor.withValues(alpha: 0.12),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatColumn(
                                    label: pctUsed >= 1.0
                                        ? 'Overspent'
                                        : 'Remaining',
                                    value:
                                        '₹${remaining.abs().toLocaleString()}',
                                    valueColor: statusColor,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 48,
                                  color: contentColor.withValues(alpha: 0.15),
                                ),
                                Expanded(
                                  child: _buildStatColumn(
                                    label: 'Monthly Budget',
                                    value: budget > 0
                                        ? '₹${budget.toLocaleString()}'
                                        : 'Not set',
                                    valueColor: contentColor,
                                    alignRight: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildProgressBar(pctUsed, progressColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    required Color valueColor,
    bool alignRight = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                  shadows: isDark
                      ? [
                          Shadow(
                              color: Colors.black.withValues(alpha: 0.65),
                              blurRadius: 4,
                              offset: const Offset(0, 1))
                        ]
                      : [],
                ),
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
                color: valueColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                shadows: isDark
                    ? [
                        Shadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ]
                    : [],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double pct, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentColor = isDark ? Colors.white : Colors.black;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                pct >= 1.0
                    ? 'Oops, over budget!'
                    : (pct >= 0.9
                        ? 'Almost maxed out'
                        : (pct >= 0.8
                            ? 'Getting close'
                            : (pct >= 0.7
                                ? 'Mind the spending'
                                : 'Looking good'))),
                style: TextStyle(
                    color: contentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    shadows: isDark
                        ? [
                            Shadow(
                                color: Colors.black38,
                                blurRadius: 4,
                                offset: const Offset(0, 1))
                          ]
                        : [])),
            Text('${(pct * 100).toInt()}% used',
                style: TextStyle(
                    color: contentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    shadows: isDark
                        ? [
                            Shadow(
                                color: Colors.black38,
                                blurRadius: 4,
                                offset: const Offset(0, 1))
                          ]
                        : [])),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6, // Slightly slimmer for elegance
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.08), // More subtle background
            borderRadius: BorderRadius.circular(3),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: pct.clamp(0.0, 1.0),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color,
                          color.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                  color: color.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2)),
                            ]
                          : [],
                    ),
                  ),
                  // Glossy Highlight & Inner Glow
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        border: isDark
                            ? null
                            : Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 0.5,
                              ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: isDark ? 0.35 : 0.6),
                            Colors.white.withValues(alpha: isDark ? 0.05 : 0.2),
                            Colors.transparent,
                            Colors.black.withValues(alpha: isDark ? 0.1 : 0.05),
                          ],
                          stops: const [0.0, 0.4, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteCard(Color textColor, Color secondaryTextColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 8, 26, 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadow,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '"$_quoteText"',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
            if (_quoteAuthor.isNotEmpty) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '— $_quoteAuthor',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground(List<Color> colors) {
    return AnimatedBuilder(
      animation: _bgAnimationController,
      builder: (context, child) {
        final t = _bgAnimationController.value * 2 * math.pi;
        return Stack(
          children: [
            // Blob 1: Large and slow
            Positioned(
              bottom: -60 + 100 * math.sin(t),
              right: -60 + 120 * math.cos(t),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colors[1].withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Blob 2: Medium and steady
            Positioned(
              top: -80 + 100 * math.cos(t * 2),
              left: -40 + 110 * math.sin(t * 2),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colors[0].withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Blob 3: Accent pulse
            Positioned(
              top: 40 + 60 * math.sin(t * 3),
              right: 20 + 70 * math.cos(t * 3),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colors[colors.length > 2 ? 2 : 0].withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionHub(BuildContext context) {
    final textColor = AppTheme.getTextColor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 10, 26, 16),
          child: Text(
            'Action Hub',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Row(
            children: [
              _AnimatedActionCard(
                icon: LucideIcons.arrowDownToLine,
                label: 'Import',
                color: const Color(0xFF0EA5E9), // Sky Blue
                onTap: () => Navigator.pushNamed(context, '/import'),
              ),
              const SizedBox(width: 14),
              _AnimatedActionCard(
                icon: LucideIcons.repeat,
                label: 'Regular',
                color: const Color(0xFFF59E0B), // Amber
                onTap: () => Navigator.pushNamed(context, '/regular'),
              ),
              const SizedBox(width: 14),
              _AnimatedActionCard(
                icon: LucideIcons.fileText,
                label: 'Notes',
                color: const Color(0xFF10B981), // Emerald
                onTap: () => Navigator.pushNamed(context, '/notes'),
              ),
              const SizedBox(width: 14),
              _AnimatedActionCard(
                icon: LucideIcons.sparkles,
                label: 'Wishes',
                color: const Color(0xFF8B5CF6), // Violet
                onTap: () => Navigator.pushNamed(context, '/wishes'),
              ),
              const SizedBox(width: 14),
              _AnimatedActionCard(
                icon: LucideIcons.layoutGrid,
                label: 'Categories',
                color: const Color(0xFFEF4444), // Rose
                onTap: () => Navigator.pushNamed(context, '/categories'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentPulse(BuildContext context, ExpenseProvider provider) {
    final textColor = AppTheme.getTextColor(context);
    final recentExpenses = provider.expenses.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Pulse',
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
                      builder: (context) => const RecentExpensesScreen()),
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 26),
          itemCount: recentExpenses.length,
          itemBuilder: (context, index) {
            final expense = recentExpenses[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .cardTheme
                          .color
                          ?.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.05),
                      ),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: (expense.actualAmount > 0
                                    ? AppTheme.primary
                                    : AppTheme.warning)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            expense.actualAmount > 0
                                ? LucideIcons.checkCheck
                                : LucideIcons.clock,
                            size: 18,
                            color: expense.actualAmount > 0
                                ? AppTheme.primary
                                : AppTheme.warning,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                expense.paymentMode,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.getTextColor(context,
                                      isSecondary: true),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${(expense.actualAmount > 0 ? expense.actualAmount : expense.plannedAmount).toLocaleString()}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
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
      // Liquid Glass Utility: Create a transparent, blurred container
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
                        'Select category', null,
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
                    decoration: AppTheme.inputDecoration('Select mode', null,
                        context: context),
                  ),
                  const SizedBox(height: 20),
                  _fieldLabel('Description', textColor),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: AppTheme.inputDecoration(
                        'e.g. Electricity bill', null,
                        context: context),
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 20),
                  _fieldLabel('Amount (₹)', textColor),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: AppTheme.inputDecoration('e.g. 1200', null,
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
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.02);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.23,
          height: 110,
          margin: const EdgeInsets.only(bottom: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.5,
                    colors: [
                      widget.color.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Dynamic Inner Light
                    Positioned(
                      top: -10,
                      left: -10,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              widget.color.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.color.withValues(alpha: 0.12),
                                blurRadius: 10,
                                spreadRadius: 0.5,
                              )
                            ],
                          ),
                          child: Icon(
                            widget.icon,
                            color: widget.color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.1,
                              height: 1.2,
                              color: AppTheme.getTextColor(context)
                                  .withValues(alpha: 1.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
