import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../../data/constants/app_quotes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEditing = false;
  int _quoteIndex = 0;

  @override
  void initState() {
    super.initState();
    _quoteIndex = Random().nextInt(AppQuotes.motivational.length);
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user['fullName'] ?? '';
      _emailController.text = user['email'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.getTextColor(context);
    final secondaryTextColor =
        AppTheme.getTextColor(context, isSecondary: true);

    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark
            ? AppTheme.darkBackgroundDecoration
            : AppTheme.backgroundDecoration,
        child: Column(
          children: [
            AppBar(
              title: Text('User Profile',
                  style:
                      TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: false,
              automaticallyImplyLeading: false,
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
                  if (user == null) {
                    return const Center(child: Text('Not logged in'));
                  }

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
                        const SizedBox(height: 32),
                        _buildSettingsCard(user, textColor, secondaryTextColor),
                        if (!_isEditing) ...[
                          const SizedBox(height: 24),
                          _buildMotivationalCard(),
                          const SizedBox(height: 24),
                          _buildLogoutButton(auth),
                        ],
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
    return Stack(
      children: [
        Container(
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
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ),
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Profile picture upload coming soon!')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.camera,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
      ],
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
              LucideIcons.mail, 'Email Address', _emailController.text,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              controller: _emailController),
          Divider(height: 32, color: secondaryTextColor.withValues(alpha: 0.1)),
          _buildInfoRow(LucideIcons.calendar, 'Member Since',
              _formatDate(user['created_at']),
              textColor: textColor, secondaryTextColor: secondaryTextColor),
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
      onPressed: () => _showLogoutPrompt(context, auth),
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
          Text('Reset App Data', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showLogoutPrompt(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Everything?'),
        content: const Text(
            'This will delete all your local data and security settings. This action is IRREVERSIBLE.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back')),
          TextButton(
            onPressed: () async {
              await auth.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/landing', (route) => false);
              }
            },
            child: const Text('Reset Everything',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthProvider>();
    await auth.updateProfile(
      fullName: _nameController.text,
      email: _emailController.text,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile synchronized successfully'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Widget _buildMotivationalCard() {
    final quote = AppQuotes.motivational[_quoteIndex];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.quote, color: Colors.white, size: 32),
          const SizedBox(height: 16),
          Text(
            '"${quote['text']}"',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          Text(
            '- ${quote['author']}',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return 'Unknown';
    try {
      final date = DateTime.parse(isoString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'Unknown';
    }
  }
}
