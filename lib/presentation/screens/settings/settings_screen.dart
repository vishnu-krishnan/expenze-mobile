import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/app_version.dart';
import '../../../data/services/api_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);
    final expenseProvider = context.watch<ExpenseProvider>();
    final summary = expenseProvider.summary;
    final limit = summary['limit'] ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            expandedHeight: 120,
            floating: true,
            pinned: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              background: Padding(
                padding: const EdgeInsets.fromLTRB(26, 20, 26, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Tweak it your way',
                        style: GoogleFonts.inter(
                            color: secondaryTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                    Text('Settings',
                        style: GoogleFonts.outfit(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: -1)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Account Profile', textColor),
                  const SizedBox(height: 12),
                  _buildSettingsCard(
                    context,
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          icon: LucideIcons.user,
                          label: 'User Profile',
                          subtitle: authProvider.user?['fullName'] ??
                              'Set up your profile',
                          onTap: () => Navigator.pushNamed(context, '/profile'),
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                        Divider(
                            height: 32,
                            color: secondaryTextColor.withValues(alpha: 0.1)),
                        _buildSettingsItem(
                          icon: LucideIcons.bell,
                          label: 'Manage Notifications',
                          subtitle: 'Alerts, reminders & SMS scraping',
                          onTap: () =>
                              Navigator.pushNamed(context, '/notifications'),
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                        Divider(
                            height: 32,
                            color: secondaryTextColor.withValues(alpha: 0.1)),
                        _buildSettingsItem(
                          icon: LucideIcons.target,
                          label: 'Monthly Budget',
                          subtitle: limit > 0
                              ? 'Target: ₹${limit.toStringAsFixed(0)}'
                              : 'No budget set',
                          onTap: () => _showLimitDialog(
                              context, limit, expenseProvider.currentMonthKey),
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Security & Privacy', textColor),
                  const SizedBox(height: 12),
                  _buildSettingsCard(
                    context,
                    child: Column(
                      children: [
                        _buildSettingsToggle(
                          context: context,
                          icon: LucideIcons.lock,
                          label: 'App Lock',
                          subtitle: 'Your finances, your fortress.',
                          value: authProvider.isLockEnabled,
                          onChanged: (val) {
                            if (val) {
                              _showPinSetupDialog(context);
                            } else {
                              authProvider.disableAppLock();
                            }
                          },
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                        if (authProvider.isLockEnabled) ...[
                          Divider(
                              height: 32,
                              color: secondaryTextColor.withValues(alpha: 0.1)),
                          _buildSettingsToggle(
                            context: context,
                            icon: LucideIcons.fingerprint,
                            label: 'Biometric Lock',
                            subtitle: 'One finger to rule them all.',
                            value: authProvider.useBiometrics,
                            onChanged: (val) {
                              authProvider.updateBiometrics(val);
                            },
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Cloud & Backup', textColor),
                  const SizedBox(height: 12),
                  _buildSettingsCard(
                    context,
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          icon: LucideIcons.cloud,
                          label: 'Google Drive Sync',
                          subtitle: 'Coming soon — good things take time.',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Cloud backup is on the roadmap! Check back soon.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          textColor: textColor.withValues(alpha: 0.5),
                          secondaryTextColor:
                              secondaryTextColor.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('AI Configuration', textColor),
                  const SizedBox(height: 12),
                  _buildSettingsCard(
                    context,
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          icon: authProvider.aiProvider == 'claude'
                              ? LucideIcons.sparkles
                              : LucideIcons.zap,
                          label: 'AI Engine',
                          subtitle: authProvider.aiProvider == 'claude'
                              ? 'Claude 3.5 Sonnet'
                              : authProvider.aiProvider == 'openai'
                                  ? 'OpenAI (GPT-4o mini)'
                                  : 'Groq (Llama 3)',
                          onTap: () =>
                              _showAiProviderDialog(context, authProvider),
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                        Divider(
                            height: 32,
                            color: secondaryTextColor.withValues(alpha: 0.1)),
                        _buildSettingsItem(
                          icon: LucideIcons.refreshCw,
                          label: 'Refresh AI Keys',
                          subtitle: 'Reload keys from local pool',
                          onTap: () async {
                            await context.read<ApiService>().reloadKeys();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('AI Key Pool Reloaded'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Appearance', textColor),
                  const SizedBox(height: 12),
                  _buildSettingsCard(
                    context,
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          icon: themeProvider.themeMode == ThemeMode.system
                              ? LucideIcons.monitor
                              : themeProvider.themeMode == ThemeMode.dark
                                  ? LucideIcons.moon
                                  : LucideIcons.sun,
                          label: 'App Theme',
                          subtitle: themeProvider.themeMode == ThemeMode.system
                              ? 'System Default'
                              : themeProvider.themeMode == ThemeMode.dark
                                  ? 'Dark'
                                  : 'Light',
                          onTap: () => _showThemeDialog(context, themeProvider),
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('App Info', textColor),
                  const SizedBox(height: 12),
                  _buildSettingsCard(
                    context,
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          icon: LucideIcons.info,
                          label: 'Version',
                          subtitle:
                              '${AppVersion.current} (${AppVersion.releaseName})',
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () => _showChangelogDialog(
                              context, textColor, secondaryTextColor),
                        ),
                        _buildSettingsItem(
                          icon: LucideIcons.helpCircle,
                          label: 'Help & Support',
                          subtitle: 'Reach out to our team',
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () => _showHelpDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPinSetupDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Setup',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Keep the bad guys out. Set a 4-digit PIN — and for bonus security, enable fingerprint unlock below.'),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 10),
              decoration: AppTheme.inputDecoration('PIN', LucideIcons.lock,
                  context: context),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.length == 4) {
                final auth = context.read<AuthProvider>();
                // Enable PIN and default biometrics to true if supported
                await auth.setAppLock(controller.text, true);
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: AppTheme.primaryButtonStyle,
            child: const Text('Secure App'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: textColor.withValues(alpha: 0.5),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSettingsToggle({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 22, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: textColor,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: textColor.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    String? subtitle,
    VoidCallback? onTap,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 22, color: AppTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: secondaryTextColor,
                      ),
                    ),
                  ]
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 18, color: textColor.withValues(alpha: 0.2)),
          ],
        ),
      ),
    );
  }

  void _showLimitDialog(BuildContext context, double currentLimit,
      [String? currentMonthKey]) {
    final controller = TextEditingController(
        text: currentLimit > 0 ? currentLimit.toStringAsFixed(0) : '');

    // Determine if the viewed month is in the past
    final liveMonthKey = DateTime.now().toIso8601String().substring(0, 7);
    final isPastMonth =
        currentMonthKey != null && currentMonthKey.compareTo(liveMonthKey) < 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set Monthly Budget',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              isPastMonth
                  ? 'Heads up: you\'re editing a past month'
                  : 'A budget is basically a plan not to panic.',
              style: TextStyle(
                  fontSize: 13,
                  color: isPastMonth
                      ? AppTheme.warning
                      : AppTheme.getTextColor(ctx, isSecondary: true),
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: AppTheme.inputDecoration(
              'Budget Amount (₹)', LucideIcons.indianRupee,
              context: ctx),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0.0;
              if (val <= 0) return;
              Navigator.pop(ctx);
              if (isPastMonth) {
                // Past months: always apply to that month only — no scope dialog
                context
                    .read<ExpenseProvider>()
                    .updateMonthlyLimitThisMonthOnly(val);
              } else {
                // Current or future month: show scope confirmation
                _showBudgetScopeDialog(context, val);
              }
            },
            style: AppTheme.primaryButtonStyle,
            child: Text(isPastMonth ? 'Update This Month' : 'Apply Budget'),
          ),
        ],
      ),
    );
  }

  void _showBudgetScopeDialog(BuildContext context, double amount) {
    showDialog(
      context: context,
      builder: (ctx) {
        final secondaryText = AppTheme.getTextColor(ctx, isSecondary: true);
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titlePadding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          actionsPadding: EdgeInsets.zero,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apply Budget',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppTheme.getTextColor(ctx),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₹${amount.toStringAsFixed(0)}  /  month',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pick your scope — no take-backs, but you can always change it again.',
                style:
                    TextStyle(fontSize: 13, color: secondaryText, height: 1.5),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildScopeOption(
                      ctx: ctx,
                      icon: LucideIcons.calendar,
                      title: 'This Month',
                      subtitle: 'Applies only to\nthe current month',
                      filled: false,
                      onTap: () {
                        context
                            .read<ExpenseProvider>()
                            .updateMonthlyLimitThisMonthOnly(amount);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildScopeOption(
                      ctx: ctx,
                      icon: LucideIcons.calendarRange,
                      title: 'All Future',
                      subtitle: 'Applies now and\ngoing forward',
                      filled: true,
                      onTap: () {
                        context
                            .read<ExpenseProvider>()
                            .updateMonthlyLimitFuture(amount);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    foregroundColor: secondaryText,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScopeOption({
    required BuildContext ctx,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: filled
              ? AppTheme.primary
              : AppTheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: filled ? 1 : 0.25),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: filled ? Colors.white : AppTheme.primary,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: filled ? Colors.white : AppTheme.primary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: filled
                    ? Colors.white.withValues(alpha: 0.75)
                    : AppTheme.getTextColor(ctx, isSecondary: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangelogDialog(
      BuildContext context, Color textColor, Color secondaryTextColor) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Changelog',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Release History',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'What\'s new in Expenze',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(LucideIcons.x, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                AppTheme.primary.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: 1,
                      itemBuilder: (context, index) {
                        final release = AppVersion.history[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: index == 0
                                          ? AppTheme.primary
                                          : AppTheme.primary
                                              .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'v${release.version}',
                                      style: TextStyle(
                                        color: index == 0
                                            ? Colors.white
                                            : AppTheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    release.date,
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (index == 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.success
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'LATEST',
                                        style: TextStyle(
                                          color: AppTheme.success,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...release.changes.map((change) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 12, left: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 6),
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary
                                              .withValues(alpha: 0.4),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          change,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 14,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
    );
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Choose Theme',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(context, themeProvider, ThemeMode.system,
                'System Default', LucideIcons.monitor),
            _buildThemeOption(context, themeProvider, ThemeMode.light,
                'Light Mode', LucideIcons.sun),
            _buildThemeOption(context, themeProvider, ThemeMode.dark,
                'Dark Mode', LucideIcons.moon),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, ThemeProvider themeProvider,
      ThemeMode mode, String label, IconData icon) {
    final isSelected = themeProvider.themeMode == mode;
    final textColor = AppTheme.getTextColor(context);

    return ListTile(
      leading: Icon(icon,
          color: isSelected
              ? AppTheme.primary
              : AppTheme.getTextColor(context, isSecondary: true)),
      title: Text(label,
          style: TextStyle(
              color: textColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected
          ? const Icon(LucideIcons.check, color: AppTheme.primary, size: 20)
          : null,
      onTap: () {
        themeProvider.setThemeMode(mode);
        Navigator.pop(context);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showAiProviderDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Choose AI Engine',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAiProviderOption(context, authProvider, 'groq',
                'Groq (Llama 3 8B)', LucideIcons.zap),
            _buildAiProviderOption(context, authProvider, 'claude',
                'Claude 3.5 Sonnet', LucideIcons.sparkles),
            _buildAiProviderOption(context, authProvider, 'openai',
                'OpenAI (GPT-4o mini)', LucideIcons.bot),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  Widget _buildAiProviderOption(BuildContext context, AuthProvider authProvider,
      String provider, String label, IconData icon) {
    final isSelected = authProvider.aiProvider == provider;
    final textColor = AppTheme.getTextColor(context);

    return ListTile(
      leading: Icon(icon,
          color: isSelected
              ? AppTheme.primary
              : AppTheme.getTextColor(context, isSecondary: true)),
      title: Text(label,
          style: TextStyle(
              color: textColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected
          ? const Icon(LucideIcons.check, color: AppTheme.primary, size: 20)
          : null,
      onTap: () {
        authProvider.updateAiProvider(provider);
        Navigator.pop(context);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.helpCircle,
                  color: Colors.orange, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Help & Support',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.5)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'For any issues, feedback, or just to say hi, reach out to us:',
                style: TextStyle(color: secondaryTextColor, fontSize: 13)),
            const SizedBox(height: 24),
            _buildSupportTile(
              context,
              icon: LucideIcons.mail,
              label: 'Email Support',
              value: AppVersion.supportEmail,
              onTap: () => _launchURL('mailto:${AppVersion.supportEmail}'),
            ),
            const SizedBox(height: 12),
            _buildSupportTile(
              context,
              icon: LucideIcons.globe,
              label: 'Official Website',
              value: 'expenze-elite.netlify.app',
              onTap: () => _launchURL(AppVersion.website),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.info, size: 12, color: secondaryTextColor),
                const SizedBox(width: 4),
                Text(
                  'App Version: ${AppVersion.current}+${AppVersion.buildNumber}',
                  style: TextStyle(
                      fontSize: 11,
                      color: secondaryTextColor.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close',
                style: TextStyle(
                    color: secondaryTextColor, fontWeight: FontWeight.bold)),
          )
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }

  Widget _buildSupportTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
              color: AppTheme.getTextColor(context).withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: secondaryTextColor.withValues(alpha: 0.6),
                          letterSpacing: 0.5)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(LucideIcons.externalLink,
                size: 14, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Could add a snackbar here if launch fails
    }
  }
}
