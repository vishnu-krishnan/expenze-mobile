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
  final _phoneController = TextEditingController();
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
      _phoneController.text = user['phone'] ?? '';
      _budgetController.text = user['default_budget']?.toString() ?? '0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
        phone: _phoneController.text.trim(),
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
                        const SizedBox(height: 16),
                        Text(
                          user['full_name'] ?? 'Guest User',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: -1,
                          ),
                        ),
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
                        _buildProfileDetails(
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
            icon: Icon(LucideIcons.arrowLeft, color: textColor),
          ),
          Text(
            'User Profile',
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
                    _isEditing ? LucideIcons.check : LucideIcons.edit3,
                    color: _isEditing ? AppTheme.success : textColor,
                    size: 20,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(dynamic user, Color textColor) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.3), width: 2),
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            child: Text(
              (user['full_name']?[0] ?? 'U').toUpperCase(),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
              ),
            ),
          ),
        ),
        if (_isEditing)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(LucideIcons.camera, color: Colors.white, size: 20),
          ),
      ],
    );
  }

  Widget _buildAccountSummary(
      BuildContext context, Color textColor, Color secondaryTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
              'Member Status', 'Active', LucideIcons.shield, AppTheme.success),
          Container(
              width: 1,
              height: 40,
              color: secondaryTextColor.withValues(alpha: 0.1)),
          _buildSummaryItem(
              'Since',
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
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }

  Widget _buildProfileDetails(
      BuildContext context, Color textColor, Color secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information'.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: secondaryTextColor.withValues(alpha: 0.6),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: AppTheme.glassDecoration(context),
          child: Column(
            children: [
              _buildModernTextField(
                controller: _nameController,
                label: 'Name',
                icon: LucideIcons.user,
                enabled: _isEditing,
                textColor: textColor,
                validator: (v) => v!.isEmpty ? 'Name is required' : null,
              ),
              _buildDivider(),
              _buildModernTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: LucideIcons.mail,
                enabled: _isEditing,
                textColor: textColor,
                validator: (v) => v!.isEmpty || !v.contains('@')
                    ? 'Valid email required'
                    : null,
              ),
              _buildDivider(),
              _buildModernTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: LucideIcons.phone,
                enabled: _isEditing,
                textColor: textColor,
              ),
              _buildDivider(),
              _buildModernTextField(
                controller: _budgetController,
                label: 'Monthly Budget',
                icon: LucideIcons.target,
                enabled: _isEditing,
                textColor: textColor,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityQuickLinks(
      BuildContext context, Color textColor, Color secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security & Preferences'.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: secondaryTextColor.withValues(alpha: 0.6),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildQuickLinkTile(
          context,
          icon: LucideIcons.lock,
          title: 'Security Settings',
          onTap: () => Navigator.pushNamed(context, '/settings'),
          color: AppTheme.primary,
        ),
        const SizedBox(height: 12),
        _buildQuickLinkTile(
          context,
          icon: LucideIcons.bell,
          title: 'Manage Notifications',
          onTap: () {},
          color: AppTheme.secondary,
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassDecoration(context).copyWith(
          color: color.withValues(alpha: 0.05),
        ),
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
                size: 16, color: color.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    required Color textColor,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primary.withValues(alpha: 0.4)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey,
                      letterSpacing: 0.5),
                ),
                TextFormField(
                  controller: controller,
                  enabled: enabled,
                  validator: validator,
                  keyboardType: keyboardType,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color:
                        enabled ? textColor : textColor.withValues(alpha: 0.7),
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            title: const Text('Logout'),
            content: const Text(
                'Are you sure you want to logout? This will clear all local data from this device.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel')),
              TextButton(
                onPressed: () async {
                  final auth = context.read<AuthProvider>();
                  Navigator.pop(dialogContext);
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/onboarding', (route) => false);
                  }
                },
                child: const Text('Logout',
                    style: TextStyle(
                        color: AppTheme.danger, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      icon: const Icon(LucideIcons.logOut, color: AppTheme.danger, size: 20),
      label: const Text(
        'SIGN OUT FROM DEVICE',
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
