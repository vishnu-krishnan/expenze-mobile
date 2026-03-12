import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../providers/expense_provider.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/month/month_plan_screen.dart';
import '../screens/settings/settings_screen.dart';

class MainNavigationWrapper extends StatefulWidget {
  final int initialIndex;
  const MainNavigationWrapper({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  late int _selectedIndex;
  bool _isDockVisible = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AnalyticsScreen(),
    const MonthPlanScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() => _selectedIndex = 0);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light, // White icons for Android
          statusBarBrightness: Brightness.dark,      // White text for iOS
          systemNavigationBarColor: const Color(0x00000000),
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarContrastEnforced: false,
          systemStatusBarContrastEnforced: false,
        ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: isDark
              ? AppTheme.darkBackgroundDecoration
              : AppTheme.backgroundDecoration,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBody: true,
            body: Stack(
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification) {
                      final delta = notification.scrollDelta ?? 0;

                      // Show dock when at top or scrolling up
                      if (notification.metrics.pixels <= 20 || delta < -2) {
                        if (!_isDockVisible) {
                          setState(() => _isDockVisible = true);
                        }
                      }
                      // Hide dock when scrolling down
                      else if (delta > 2 && notification.metrics.pixels > 40) {
                        if (_isDockVisible) {
                          setState(() => _isDockVisible = false);
                        }
                      }
                    }
                    return false;
                  },
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _screens,
                  ),
                ),
                // Bottom Scrim/Background Overlay
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 350),
                    opacity: _isDockVisible ? 1.0 : 0.0,
                    child: Container(
                      height:
                          MediaQuery.of(context).viewPadding.bottom + 110,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            (isDark ? Colors.black : Colors.white)
                                .withOpacity(0.1),
                            (isDark ? Colors.black : Colors.white)
                                .withOpacity(0.35),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Navigation Bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildModernNavBar(isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernNavBar(bool isDark) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      offset: _isDockVisible ? Offset.zero : const Offset(0, 2),
      child: Container(
        margin: EdgeInsets.fromLTRB(
            24, 0, 24, MediaQuery.of(context).viewPadding.bottom + 12),
        height: 70,
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.bgCardDark.withOpacity(0.8)
              : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(child: _buildNavItem(LucideIcons.home, 'Home', 0)),
                  Expanded(
                      child:
                          _buildNavItem(LucideIcons.pieChart, 'Analytics', 1)),
                  Expanded(
                      child: _buildNavItem(LucideIcons.calendar, 'Planner', 2)),
                  Expanded(
                      child:
                          _buildNavItem(LucideIcons.settings, 'Settings', 3)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        // Always reset data to the current real-time month when switching tabs.
        // This prevents stale month navigation from dashboard carrying over.
        Provider.of<ExpenseProvider>(context, listen: false)
            .resetToCurrentMonth();
        setState(() => _selectedIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.primary
                  : (isDark
                      ? Colors.white60
                      : AppTheme.textSecondary.withValues(alpha: 0.5)),
              size: isSelected ? 24 : 22,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900, // Matching the dashboard bold headings
                  letterSpacing: -0.2, // Tighter look
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
