import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _budgetController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user['fullName'] ?? '';
      _usernameController.text = user['username'] ?? '';
      _phoneController.text = user['phone'] ?? '';
      _budgetController.text = (user['defaultBudget'] ?? 0).toString();
      _emailController.text = user['email'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: context.watch<ThemeProvider>().isDarkMode
            ? AppTheme.darkBackgroundDecoration
            : AppTheme.backgroundDecoration,
        child: Column(
          children: [
            AppBar(
              title: Text('Account Identity',
                  style:
                      TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                _isEditing
                    ? IconButton(
                        onPressed: () async {
                          await _saveProfile();
                          if (mounted) setState(() => _isEditing = false);
                        },
                        icon: const Icon(LucideIcons.check,
                            color: AppTheme.success, size: 28),
                      )
                    : IconButton(
                        onPressed: () => setState(() => _isEditing = true),
                        icon: Icon(LucideIcons.edit3, color: AppTheme.primary),
                      ),
                const SizedBox(width: 8),
              ],
            ),
            Expanded(
              child: Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  final user = auth.user;
                  if (user == null)
                    return const Center(child: Text('Not logged in'));

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    child: Column(
                      children: [
                        _buildModernAvatar(
                            user['fullName'] ?? user['username'] ?? 'U'),
                        const SizedBox(height: 12),
                        Text(user['fullName'] ?? user['username'] ?? 'Member',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor)),
                        Text('@${user['username'] ?? ''}',
                            style: TextStyle(
                                color: secondaryTextColor, fontSize: 13)),
                        const SizedBox(height: 32),
                        _buildSettingsCard(user, textColor, secondaryTextColor),
                        const SizedBox(height: 24),
                        _buildLogoutButton(auth),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAvatar(String name) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primary, width: 2),
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: AppTheme.primary,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
              fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
      Map<String, dynamic> user, Color textColor, Color secondaryTextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          _buildInfoRow(LucideIcons.user, 'Full Name', _nameController.text,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              controller: _nameController),
          Divider(height: 32, color: secondaryTextColor.withValues(alpha: 0.1)),
          _buildInfoRow(
              LucideIcons.atSign, 'Username', _usernameController.text,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              controller: _usernameController),
          Divider(height: 32, color: secondaryTextColor.withValues(alpha: 0.1)),
          _buildInfoRow(
              LucideIcons.mail, 'Communication', _emailController.text,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              controller: _emailController),
          Divider(height: 32, color: secondaryTextColor.withValues(alpha: 0.1)),
          _buildInfoRow(
              LucideIcons.phone, 'Contact number', _phoneController.text,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              controller: _phoneController),
          Divider(height: 32, color: secondaryTextColor.withValues(alpha: 0.1)),
          _buildInfoRow(
              LucideIcons.wallet, 'Spending Limit', _budgetController.text,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              controller: _budgetController,
              isNumber: true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {required Color textColor,
      required Color secondaryTextColor,
      TextEditingController? controller,
      bool isNumber = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: AppTheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
              if (_isEditing && controller != null)
                TextField(
                  controller: controller,
                  keyboardType:
                      isNumber ? TextInputType.number : TextInputType.text,
                  decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                      border: InputBorder.none),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: textColor),
                )
              else
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(AuthProvider auth) {
    return ElevatedButton(
      onPressed: () => auth.logout(),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.bgCardDark
            : Colors.white,
        foregroundColor: AppTheme.danger,
        side: BorderSide(color: AppTheme.danger.withValues(alpha: 0.2)),
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.logOut, size: 20),
          SizedBox(width: 12),
          Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthProvider>();
    await auth.updateProfile(
      fullName: _nameController.text,
      username: _usernameController.text,
      phone: _phoneController.text,
      defaultBudget: double.tryParse(_budgetController.text) ?? 0,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile synchronized successfully'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}
