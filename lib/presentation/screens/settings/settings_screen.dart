import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/app_version.dart';

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
                    Text('Configuration',
                        style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 13,
                            letterSpacing: 0.5)),
                    Text('Settings',
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
                          icon: LucideIcons.target,
                          label: 'Monthly Budget',
                          subtitle: limit > 0
                              ? 'Target: ₹${limit.toStringAsFixed(0)}'
                              : 'No budget set',
                          onTap: () => _showLimitDialog(context, limit),
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
                          subtitle: 'Require PIN to open app',
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
                            subtitle: 'Unlock using Fingerprint',
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
                          subtitle: 'Coming Soon',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Google Drive sync will be available in the next update!')),
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
                'Set a 4-digit PIN to protect your financial data and enable biometric unlocking.'),
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
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor.withValues(alpha: 0.5),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppTheme.primary,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: secondaryTextColor),
          ],
        ),
      ),
    );
  }

  void _showLimitDialog(BuildContext context, double currentLimit) {
    final controller = TextEditingController(
        text: currentLimit > 0 ? currentLimit.toStringAsFixed(0) : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust Monthly Budget',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: AppTheme.inputDecoration(
              'Budget Amount', LucideIcons.indianRupee,
              context: context),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0.0;
              context.read<ExpenseProvider>().updateMonthlyLimit(val);
              Navigator.pop(context);
            },
            style: AppTheme.primaryButtonStyle,
            child: const Text('Save'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _showChangelogDialog(
      BuildContext context, Color textColor, Color secondaryTextColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Release History',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        content: SizedBox(
          width: double.maxFinite,
          child: Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: AppVersion.history.take(5).map((release) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Version ${release.version}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                  fontSize: 16)),
                          Text(release.date,
                              style: TextStyle(
                                  fontSize: 11, color: secondaryTextColor)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...release.changes.map((change) => Padding(
                            padding: const EdgeInsets.only(bottom: 8, left: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: secondaryTextColor.withValues(
                                        alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    change,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
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
}
