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
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      decoration: themeProvider.isDarkMode
          ? AppTheme.darkBackgroundDecoration
          : AppTheme.backgroundDecoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Account Identity'),
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
                    icon:
                        const Icon(LucideIcons.edit3, color: AppTheme.primary),
                  ),
            const SizedBox(width: 8),
          ],
        ),
        body: Consumer<AuthProvider>(
          builder: (context, auth, child) {
            final user = auth.user;
            if (user == null) return const Center(child: Text('Not logged in'));

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  _buildModernAvatar(
                      user['fullName'] ?? user['username'] ?? 'U'),
                  const SizedBox(height: 12),
                  Text(user['fullName'] ?? user['username'] ?? 'Member',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('@${user['username'] ?? ''}',
                      style:
                          TextStyle(color: AppTheme.textLight, fontSize: 13)),
                  const SizedBox(height: 32),
                  _buildSettingsCard(user),
                  const SizedBox(height: 24),
                  _buildAppearanceCard(themeProvider),
                  const SizedBox(height: 32),
                  _buildLogoutButton(auth),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppearanceCard(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Appearance',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: themeProvider.isDarkMode
                            ? AppTheme.accent
                            : AppTheme.bgSecondary,
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(
                        themeProvider.isDarkMode
                            ? LucideIcons.moon
                            : LucideIcons.sun,
                        size: 20,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 16),
                  const Text('Dark Mode',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              Switch.adaptive(
                value: themeProvider.isDarkMode,
                onChanged: (val) => themeProvider.toggleTheme(),
                activeColor: AppTheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernAvatar(String name) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient:
            const LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(Map<String, dynamic> user) {
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
              controller: _nameController),
          const Divider(height: 32),
          _buildInfoRow(
              LucideIcons.atSign, 'Username', _usernameController.text,
              controller: _usernameController),
          const Divider(height: 32),
          _buildInfoRow(
              LucideIcons.mail, 'Communication', _emailController.text,
              controller: _emailController),
          const Divider(height: 32),
          _buildInfoRow(
              LucideIcons.phone, 'Contact number', _phoneController.text,
              controller: _phoneController),
          const Divider(height: 32),
          _buildInfoRow(
              LucideIcons.wallet, 'Spending Limit', _budgetController.text,
              controller: _budgetController, isNumber: true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {TextEditingController? controller, bool isNumber = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color!.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border.withOpacity(0.1))),
          child: Icon(icon, size: 20, color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: AppTheme.textLight,
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
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                )
              else
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
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
        backgroundColor: Theme.of(context).cardTheme.color,
        foregroundColor: AppTheme.danger,
        side: BorderSide(color: AppTheme.danger.withOpacity(0.1)),
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
