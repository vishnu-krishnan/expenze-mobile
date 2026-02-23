import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _budgetController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user['full_name'] ?? '';
      _emailController.text = user['email'] ?? '';
      _budgetController.text = user['default_budget']?.toString() ?? '0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    try {
      await auth.updateProfile(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        defaultBudget: double.tryParse(_budgetController.text),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

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
              _buildHeader(context, user, textColor),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildUserAvatar(user, textColor),
                        const SizedBox(height: 20),
                        Text(
                          user['full_name'] ?? 'Guest User',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user['email'] ?? 'No email set',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildAccountSummary(
                            context, textColor, secondaryTextColor),
                        const SizedBox(height: 32),
                        _buildSecurityQuickLinks(
                            context, textColor, secondaryTextColor),
                        const SizedBox(height: 40),
                        _buildLogoutButton(context),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user, Color textColor) {
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
            'Account',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
                  onPressed: () {
                    if (_isEditing) {
                      _saveProfile();
                    } else {
                      setState(() => _isEditing = true);
                    }
                  },
                  icon: Icon(
                    _isEditing ? LucideIcons.check : LucideIcons.settings,
                    color: _isEditing ? AppTheme.success : textColor,
                    size: 22,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(dynamic user, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppTheme.primary,
            AppTheme.primary.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 64,
        backgroundColor: Theme.of(context).cardColor,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primary.withValues(alpha: 0.05),
          ),
          alignment: Alignment.center,
          child: Text(
            (user['full_name']?[0] ?? 'U').toUpperCase(),
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSummary(
      BuildContext context, Color textColor, Color secondaryTextColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Status',
            (context.read<AuthProvider>().user?['is_verified'] == true)
                ? 'Verified'
                : 'Unverified',
            (context.read<AuthProvider>().user?['is_verified'] == true)
                ? LucideIcons.badgeCheck
                : LucideIcons.alertCircle,
            (context.read<AuthProvider>().user?['is_verified'] == true)
                ? AppTheme.success
                : AppTheme.danger,
          ),
          Container(
              width: 1,
              height: 40,
              color: secondaryTextColor.withValues(alpha: 0.1)),
          _buildSummaryItem(
              'Joined',
              _formatDate(context.read<AuthProvider>().user?['created_at']),
              LucideIcons.calendar,
              AppTheme.primary),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        Text(label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppTheme.getTextColor(context, isSecondary: true)
                  .withValues(alpha: 0.6),
              letterSpacing: 0.5,
            )),
      ],
    );
  }

  // Monthly Budget section removed entirely.
  Widget _buildSecurityQuickLinks(
      BuildContext context, Color textColor, Color secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            'Preferences & Security'.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: secondaryTextColor.withValues(alpha: 0.6),
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            children: [
              _buildQuickLinkTile(
                context,
                icon: LucideIcons.bell,
                title: 'Manage Notifications',
                onTap: () => Navigator.pushNamed(context, '/notifications'),
                color: AppTheme.secondary,
              ),
              _buildDivider(),
              _buildQuickLinkTile(
                context,
                icon: LucideIcons.helpCircle,
                title: 'Help & Support',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Help & Support',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'For any issues or feedback, please reach out to us:'),
                          SizedBox(height: 16),
                          Text('Email: support@expenze.com',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          SizedBox(height: 8),
                          Text('Website: www.expenze.com',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          SizedBox(height: 16),
                          Text('App Version: 1.2.1+9',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'))
                      ],
                    ),
                  );
                },
                color: Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLinkTile(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap,
      required Color color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 16, color: color.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.05)),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Clear App Data',
                style: TextStyle(fontWeight: FontWeight.w900)),
            content: const Text(
                'Are you sure you want to clear all app data? This will delete all local records and sign you out.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final auth = context.read<AuthProvider>();
                  Navigator.pop(dialogContext);
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/landing', (route) => false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Clear Data'),
              ),
            ],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
        );
      },
      icon: const Icon(LucideIcons.trash2, color: AppTheme.danger, size: 20),
      label: const Text(
        'CLEAR APP DATA',
        style: TextStyle(
            color: AppTheme.danger,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1),
      ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      final date = DateTime.parse(isoString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'N/A';
    }
  }
}
