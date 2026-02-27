import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // ── Edit Profile bottom sheet ────────────────────────────────────────────
  void _showEditProfileSheet(BuildContext context, Map<String, dynamic> user) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user['full_name'] ?? '');
    final emailController = TextEditingController(text: user['email'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return _EditProfileSheet(
          formKey: formKey,
          nameController: nameController,
          emailController: emailController,
        );
      },
    ).then((_) {
      nameController.dispose();
      emailController.dispose();
    });
  }

  // ── Verification Sheet ──────────────────────────────────────────────────
  void _showVerificationDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => const _VerificationSheet(),
    );
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
              _buildHeader(context, textColor),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    children: [
                      _buildUserAvatar(context, user, textColor),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                        ],
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
                      _buildPreferencesSection(
                          context, user, textColor, secondaryTextColor),
                      const SizedBox(height: 40),
                      _buildLogoutButton(context),
                      const SizedBox(height: 100),
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

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 48),
          Text(
            'Account',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          // Placeholder to keep title centred
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ── Avatar ───────────────────────────────────────────────────────────────
  Widget _buildUserAvatar(
      BuildContext context, Map<String, dynamic> user, Color textColor) {
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

  // ── Account Summary ──────────────────────────────────────────────────────
  Widget _buildAccountSummary(
      BuildContext context, Color textColor, Color secondaryTextColor) {
    final auth = context.read<AuthProvider>();
    final isVerified = auth.isVerified;
    final user = auth.user;

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
            context,
            'Profile Status',
            isVerified ? 'Verified' : 'Unverified',
            isVerified ? LucideIcons.badgeCheck : LucideIcons.badgeAlert,
            isVerified ? AppTheme.success : AppTheme.warning,
          ),
          Container(
              width: 1,
              height: 40,
              color: secondaryTextColor.withValues(alpha: 0.1)),
          _buildSummaryItem(
            context,
            'Member Since',
            _formatDate(user?['created_at']),
            LucideIcons.userPlus,
            AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value,
      IconData icon, Color color) {
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

  // ── Preferences & Security section (now includes Edit Profile) ───────────
  Widget _buildPreferencesSection(BuildContext context,
      Map<String, dynamic> user, Color textColor, Color secondaryTextColor) {
    final isVerified = context.read<AuthProvider>().isVerified;
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
              // ── Edit Profile ──
              _buildQuickLinkTile(
                context,
                icon: LucideIcons.userCog,
                title: 'Edit Profile',
                subtitle: 'Your name, not your net worth — make it count.',
                onTap: () => _showEditProfileSheet(context, user),
                color: AppTheme.primary,
              ),
              if (!isVerified) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(height: 1, color: Colors.black12),
                ),
                _buildQuickLinkTile(
                  context,
                  icon: LucideIcons.shieldCheck,
                  title: 'Verify Account',
                  subtitle: 'Unlock badges and cloud sync.',
                  onTap: () => _showVerificationDialog(context),
                  color: AppTheme.warning,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLinkTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            AppTheme.getTextColor(context, isSecondary: true),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 16, color: color.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  // ── Help dialog ──────────────────────────────────────────────────────────

  // ── Logout / Clear data ──────────────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        final random = DateTime.now().millisecond % 10;
        final num1 = random + 5;
        final num2 = random + 3;
        final answer = num1 + num2;
        final answerController = TextEditingController();

        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Clear App Data',
                style: TextStyle(fontWeight: FontWeight.w900)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Are you sure? This will delete all local records. To confirm, solve this simple puzzle:'),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    '$num1 + $num2 = ?',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: answerController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Your answer',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (answerController.text == answer.toString()) {
                    final auth = context.read<AuthProvider>();
                    Navigator.pop(dialogContext);
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/landing', (route) => false);
                    }
                  } else {
                    answerController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 3),
                        content: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.danger.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.xCircle,
                                  color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  "Math is hard, isn't it? Try again!",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
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

  // ── Helpers ──────────────────────────────────────────────────────────────
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

// ══ Edit Profile Bottom Sheet ══════════════════════════════════════════════

class _EditProfileSheet extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;

  const _EditProfileSheet({
    required this.formKey,
    required this.nameController,
    required this.emailController,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  bool _isSaving = false;

  Future<void> _save() async {
    if (!widget.formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final auth = context.read<AuthProvider>();
    try {
      await auth.updateProfile(
        fullName: widget.nameController.text.trim(),
        email: widget.emailController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile. Please try again.'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppTheme.getTextColor(context);
    final secondaryColor = AppTheme.getTextColor(context, isSecondary: true);
    final sheetColor = isDark ? AppTheme.bgCardDark : Colors.white;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
        child: Form(
          key: widget.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(LucideIcons.userCog,
                        color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Glow-up your profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'First impressions matter — even in an app.',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Name field
              _buildLabel('Full Name', textColor),
              const SizedBox(height: 8),
              TextFormField(
                controller: widget.nameController,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Enter your full name',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child:
                        Icon(LucideIcons.user, color: secondaryColor, size: 18),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Name cannot be empty';
                  }
                  if (v.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Email field
              _buildLabel('Email Address', textColor),
              const SizedBox(height: 8),
              TextFormField(
                controller: widget.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child:
                        Icon(LucideIcons.mail, color: secondaryColor, size: 18),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email cannot be empty';
                  }
                  final emailRe = RegExp(
                      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
                  if (!emailRe.hasMatch(v.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Save / Cancel buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(
                            color:
                                isDark ? AppTheme.borderDark : AppTheme.border),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                            color: secondaryColor, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, Color textColor) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: 0.2,
      ),
    );
  }
}

// ══ Verification Bottom Sheet ══════════════════════════════════════════════

class _VerificationSheet extends StatefulWidget {
  const _VerificationSheet();

  @override
  State<_VerificationSheet> createState() => _VerificationSheetState();
}

class _VerificationSheetState extends State<_VerificationSheet>
    with SingleTickerProviderStateMixin {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isVerifying = false;
  int _timer = 60;
  Timer? _countdown;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Automatically send code when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerSendCode();
    });
  }

  Future<void> _triggerSendCode({bool force = false}) async {
    final auth = context.read<AuthProvider>();
    setState(() => _isVerifying = true);
    final success = await auth.sendVerificationCode(force: force);

    if (mounted) {
      setState(() => _isVerifying = false);
      if (success) {
        _startTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'Failed to send code.'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _startTimer() {
    setState(() => _timer = 60);
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timer == 0) {
        t.cancel();
      } else {
        setState(() => _timer--);
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _countdown?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    if (_otpController.text.length < 6) return;

    setState(() => _isVerifying = true);
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final success = await auth.verifyAccount(_otpController.text);
      if (!mounted) return;

      if (success) {
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Verification Successful! 🎉'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _isVerifying = false);
        _otpController.clear();
        messenger.showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'Invalid code. Please try again.'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Try again.'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildOtpBoxes(BuildContext context, String currentText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        final isFilled = index < currentText.length;
        final isActive = index == currentText.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primary.withValues(alpha: 0.1)
                : (isFilled
                    ? AppTheme.primary.withValues(alpha: 0.05)
                    : Colors.transparent),
            border: Border.all(
              color: isActive
                  ? AppTheme.primary
                  : (isFilled
                      ? AppTheme.primary.withValues(alpha: 0.5)
                      : AppTheme.getTextColor(context).withValues(alpha: 0.1)),
              width: isActive ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isFilled ? currentText[index] : '',
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppTheme.getTextColor(context);
    final secondaryColor = AppTheme.getTextColor(context, isSecondary: true);
    final sheetColor = isDark ? AppTheme.bgCardDark : Colors.white;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 32 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 32),

            // Animated Shield Icon
            ScaleTransition(
              scale: Tween(begin: 1.0, end: 1.05).animate(
                CurvedAnimation(
                    parent: _pulseController, curve: Curves.easeInOut),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.shieldCheck,
                    color: AppTheme.primary, size: 48),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Secure Your Account',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We\'ve sent a 6-digit verification code to your email. Enter it below to unlock cloud sync and premium features.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: secondaryColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),

            // OTP Input (Custom 6-Box UI)
            Stack(
              alignment: Alignment.center,
              children: [
                _buildOtpBoxes(context, _otpController.text),
                Positioned.fill(
                  child: TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    autofocus: true,
                    showCursor: false,
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                    ),
                    style: const TextStyle(color: Colors.transparent),
                    onChanged: (v) {
                      setState(() {});
                      if (v.length == 6) {
                        FocusScope.of(context).unfocus();
                        _verify();
                      }
                    },
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Enter 6 digits' : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Timer & Resend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _timer > 0
                      ? 'Resend code in ${_timer}s'
                      : 'Didn\'t get the code? ',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: secondaryColor,
                  ),
                ),
                if (_timer == 0)
                  TextButton(
                    onPressed: () => _triggerSendCode(force: true),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Resend',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 40),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isVerifying ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      side: BorderSide(
                          color:
                              isDark ? AppTheme.borderDark : AppTheme.border),
                    ),
                    child: Text(
                      'Later',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        color: secondaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(
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
                      onPressed: _isVerifying ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 3, color: Colors.white),
                            )
                          : Text(
                              'Verify Now',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
