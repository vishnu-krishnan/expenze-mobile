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

  String? _nameError;
  String? _emailError;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // Trigger entrance animation after first frame
    WidgetsBinding.instance
        .addPostFrameCallback((_) => setState(() => _visible = true));

    _nameController.addListener(() {
      if (_nameError != null && _nameController.text.trim().isNotEmpty) {
        setState(() => _nameError = null);
      }
    });
    _emailController.addListener(() {
      if (_emailError != null) {
        final email = _emailController.text.trim();
        if (email.isNotEmpty && email.contains('@')) {
          setState(() => _emailError = null);
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    FocusScope.of(context)
        .unfocus(); // Dismiss keyboard to prevent tap unresponsiveness

    setState(() {
      _nameError = null;
      _emailError = null;
    });

    bool hasError = false;

    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = 'Please enter your name');
      hasError = true;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _emailError = 'Please enter a valid email address');
      hasError = true;
    }

    if (hasError) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final success = await auth.setOnboardingComplete(
        name: _nameController.text.trim(),
        email: email,
        budget: double.tryParse(_budgetController.text.trim()),
      );

      if (success) {
        nav.pushNamedAndRemoveUntil('/main', (route) => false);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'Failed to complete profile setup.'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
            ),
            Expanded(
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      AnimatedOpacity(
                        opacity: _visible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        child: AnimatedSlide(
                          offset:
                              _visible ? Offset.zero : const Offset(0, 0.08),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Almost in — tell us who\'s boss.',
                                style: GoogleFonts.outfit(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.getTextColor(context),
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Quick setup. No forms that ask for your blood type.',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: AppTheme.getTextColor(context,
                                      isSecondary: true),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      _buildInputField(
                        label: 'YOUR NAME',
                        hint: 'The name your wallet answers to',
                        controller: _nameController,
                        icon: LucideIcons.user,
                        isDark: isDark,
                        errorText: _nameError,
                      ),
                      const SizedBox(height: 28),
                      _buildInputField(
                        label: 'EMAIL',
                        hint: 'something@thatactuallymakessense.com',
                        controller: _emailController,
                        icon: LucideIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                        isDark: isDark,
                        errorText: _emailError,
                      ),
                      const SizedBox(height: 28),
                      _buildInputField(
                        label: 'MONTHLY BUDGET (OPTIONAL)',
                        hint: 'How much until panic sets in?',
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
            ),
          ],
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
    String? errorText,
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
            color: errorText != null
                ? AppTheme.danger
                : (isDark
                    ? AppTheme.primary
                    : AppTheme.primaryDark.withValues(alpha: 0.6)),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.bgCardDark
                : AppTheme.info.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: errorText != null
                  ? AppTheme.danger
                  : (isDark
                      ? AppTheme.borderDark
                      : AppTheme.primary.withValues(alpha: 0.2)),
              width: errorText != null ? 1.5 : 1.0,
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
                child: Icon(icon,
                    color:
                        errorText != null ? AppTheme.danger : AppTheme.primary,
                    size: 22),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              errorText,
              style: GoogleFonts.inter(
                color: AppTheme.danger,
                fontSize: 12,
                fontWeight: FontWeight.w500,
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
            color: AppTheme.primary.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: Text(
          'Lock In & Get Started',
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
