import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);

    return Container(
      decoration: themeProvider.isDarkMode
          ? AppTheme.darkBackgroundDecoration
          : AppTheme.backgroundDecoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'App Settings',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Appearance', textColor),
              const SizedBox(height: 12),
              _buildSettingsCard(
                context,
                child: Column(
                  children: [
                    _buildSettingsToggle(
                      context: context,
                      icon: themeProvider.isDarkMode
                          ? LucideIcons.moon
                          : LucideIcons.sun,
                      label: 'Dark Mode',
                      subtitle: 'Enable dark theme for the app',
                      value: themeProvider.isDarkMode,
                      onChanged: (val) => themeProvider.toggleTheme(),
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('About', textColor),
              const SizedBox(height: 12),
              _buildSettingsCard(
                context,
                child: Column(
                  children: [
                    _buildSettingsItem(
                      icon: LucideIcons.info,
                      label: 'Version',
                      trailingText: '1.0.0',
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    Divider(
                        height: 32, color: secondaryTextColor.withOpacity(0.1)),
                    _buildSettingsItem(
                      icon: LucideIcons.shieldCheck,
                      label: 'Privacy Policy',
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textColor.withOpacity(0.7),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
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
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    String? trailingText,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: textColor,
            ),
          ),
        ),
        if (trailingText != null)
          Text(
            trailingText,
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          )
        else
          Icon(LucideIcons.chevronRight, size: 16, color: secondaryTextColor),
      ],
    );
  }
}
