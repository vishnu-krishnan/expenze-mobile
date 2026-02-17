import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _budgetController = TextEditingController();

  void _handleSubmit() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.setOnboardingComplete(
      name: _nameController.text,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      budget: double.tryParse(_budgetController.text),
    );

    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgPrimaryDark : AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft,
              color: isDark ? Colors.white : AppTheme.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Create Your Profile',
                style: GoogleFonts.outfit(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primaryDark,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Help us personalize your experience. This data stays on your device.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              _buildInputField(
                label: 'YOUR NAME',
                hint: 'How should we call you?',
                controller: _nameController,
                icon: LucideIcons.user,
                isDark: isDark,
              ),
              const SizedBox(height: 28),
              _buildInputField(
                label: 'EMAIL (OPTIONAL)',
                hint: 'For identification only',
                controller: _emailController,
                icon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
                isDark: isDark,
              ),
              const SizedBox(height: 28),
              _buildInputField(
                label: 'MONTHLY BUDGET (OPTIONAL)',
                hint: '0.00',
                controller: _budgetController,
                icon: LucideIcons.indianRupee,
                keyboardType: TextInputType.number,
                isDark: isDark,
              ),
              const SizedBox(height: 64),
              _buildSubmitButton(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: isDark
                ? AppTheme.primary
                : AppTheme.primaryDark.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color:
                isDark ? AppTheme.bgCardDark : AppTheme.info.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? AppTheme.borderDark
                  : AppTheme.primary.withOpacity(0.2),
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.white : AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                  color: isDark ? Colors.white30 : AppTheme.textLight),
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Icon(icon, color: AppTheme.primary, size: 22),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: Text(
          'Complete Setup',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
