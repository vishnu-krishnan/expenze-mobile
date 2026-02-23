import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? AppTheme.darkBackgroundDecoration
            : AppTheme.backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, textColor),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(context, secondaryTextColor),
                      const SizedBox(height: 32),
                      _buildSectionTitle('General Notifications', textColor),
                      const SizedBox(height: 12),
                      _buildSettingsCard(
                        context,
                        child: _buildSettingsToggle(
                          context: context,
                          icon: LucideIcons.bell,
                          label: 'App Alerts',
                          subtitle: 'Enable push notifications for activity',
                          value: authProvider.notificationsEnabled,
                          onChanged: (val) => authProvider
                              .updateNotificationSettings(alerts: val),
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Expense Management', textColor),
                      const SizedBox(height: 12),
                      _buildSettingsCard(
                        context,
                        child: Column(
                          children: [
                            _buildSettingsToggle(
                              context: context,
                              icon: LucideIcons.mailCheck,
                              label: 'SMS Auto-Import',
                              subtitle: 'Automatically process expense SMS',
                              value: authProvider.smsScraperEnabled,
                              onChanged: (val) => authProvider
                                  .updateNotificationSettings(smsScraper: val),
                              textColor: textColor,
                              secondaryTextColor: secondaryTextColor,
                            ),
                            _buildDivider(),
                            _buildSettingsToggle(
                              context: context,
                              icon: LucideIcons.alarmClock,
                              label: 'Daily Reminders',
                              subtitle: 'Morning summary of your budget',
                              value: authProvider.dailyReminderEnabled,
                              onChanged: (val) => authProvider
                                  .updateNotificationSettings(reminders: val),
                              textColor: textColor,
                              secondaryTextColor: secondaryTextColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Smart Alerts', textColor),
                      const SizedBox(height: 12),
                      _buildSettingsCard(
                        context,
                        child: _buildSettingsToggle(
                          context: context,
                          icon: LucideIcons.trendingUp,
                          label: 'Budget Thresholds',
                          subtitle: 'Notify when reaching 80% and 100%',
                          value: true, // Mocked for now
                          onChanged: (val) {},
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(LucideIcons.chevronLeft, color: textColor),
          ),
          Text(
            'Notifications',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 48), // Placeholder for symmetry
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Color secondaryTextColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.info, color: AppTheme.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Customize how Expenze keeps you updated on your financial goals.',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
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
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.withValues(alpha: 0.05));
  }
}
