import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => setState(() => _visible = true));
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final success = await auth.register(
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        setState(() => _errorMessage = auth.error ?? 'Registration failed');
      }
    } catch (e) {
      setState(() => _errorMessage = 'An error occurred during registration');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 48),
                      // Back Button
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(LucideIcons.arrowLeft,
                            color: AppTheme.getTextColor(context)),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      const SizedBox(height: 24),
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
                                'Let\'s get you sorted.',
                                style: GoogleFonts.outfit(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.getTextColor(context),
                                  letterSpacing: -1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No credit card. No spam. Just you and your money — finally on speaking terms.',
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
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            const Text('💡', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Pro tip: set a monthly budget right after signup. Future-you will be very thankful.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppTheme.getTextColor(context),
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      if (_errorMessage != null)
                        _buildErrorBanner(_errorMessage!),

                      _buildPremiumField(
                        controller: _fullNameController,
                        label: 'FULL NAME',
                        hint: 'The name on your unofficial rich-person card',
                        icon: LucideIcons.user,
                        isDark: isDark,
                        validator: (v) =>
                            v!.isEmpty ? 'Please enter your name' : null,
                      ),
                      const SizedBox(height: 24),

                      _buildPremiumField(
                        controller: _emailController,
                        label: 'EMAIL ADDRESS',
                        hint: 'For identification — we won\'t spam, promise',
                        icon: LucideIcons.mail,
                        isDark: isDark,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 24),

                      _buildPremiumField(
                        controller: _passwordController,
                        label: 'SECURITY PIN / PASSCODE',
                        hint: 'Something only you know (and remember)',
                        icon: LucideIcons.lock,
                        isDark: isDark,
                        obscureText: true,
                        validator: (v) =>
                            v!.length < 4 ? 'Min 4 characters required' : null,
                      ),
                      const SizedBox(height: 48),

                      _buildSubmitButton(context),
                      const SizedBox(height: 32),

                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already using Expenze? ',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.getTextColor(context,
                                    isSecondary: true),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushReplacementNamed(
                                  context, '/login'),
                              child: Text(
                                'Sign In',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle, color: AppTheme.danger, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: AppTheme.danger,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: isDark
                ? AppTheme.primary
                : AppTheme.primaryDark.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.bgCardDark
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? AppTheme.borderDark
                  : AppTheme.primary.withValues(alpha: 0.15),
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: isDark ? Colors.white : AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                  color: isDark ? Colors.white24 : Colors.black26),
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Icon(icon, color: AppTheme.primary, size: 22),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
              errorStyle: const TextStyle(
                  height: 0), // Use manual validation messages if needed
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
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 3, color: Colors.white))
            : Text(
                'I\'m Ready — Let\'s Go!',
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
