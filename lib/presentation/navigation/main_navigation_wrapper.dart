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
        height: 75, // Professional height for vertical icons
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.primary.withValues(alpha: 0.12)
              : AppTheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.1),
              blurRadius: 25,
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
                  _buildNavItem(LucideIcons.home, 'Home', 0),
                  _buildNavItem(LucideIcons.pieChart, 'Analytics', 1),
                  _buildNavItem(LucideIcons.calendar, 'Planner', 2),
                  _buildNavItem(LucideIcons.settings, 'Settings', 3),
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

    return Expanded(
      child: GestureDetector(
        onTap: () {
          Provider.of<ExpenseProvider>(context, listen: false)
              .resetToCurrentMonth();
          setState(() => _selectedIndex = index);
        },
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Selection background bubble
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                width: isSelected ? 72 : 0,
                height: isSelected ? 58 : 0,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primary,
                            AppTheme.primary.withValues(alpha: 0.85),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(24),
                  border: isSelected
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.2,
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: -2,
                          ),
                        ]
                      : [],
                ),
              ),
              // Content Column
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<Color?>(
                    duration: const Duration(milliseconds: 300),
                    tween: ColorTween(
                      end: isSelected
                          ? Colors.white
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : AppTheme.textSecondary.withValues(alpha: 0.5)),
                    ),
                    builder: (context, color, _) => AnimatedScale(
                      scale: isSelected ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        icon,
                        color: color,
                        size: 26,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isSelected ? 18 : 0,
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isSelected ? 1.0 : 0.0,
                      child: Center(
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
