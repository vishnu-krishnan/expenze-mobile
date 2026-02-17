import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _pin = '';
  bool _isError = false;

  void _onKeyPress(String value) {
    if (_pin.length < 4) {
      setState(() {
        _pin += value;
        _isError = false;
      });

      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _isError = false;
      });
    }
  }

  void _verifyPin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.verifyPin(_pin);

    if (success) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } else {
      setState(() {
        _pin = '';
        _isError = true;
      });

      // Haptic feedback could be added here
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _isError = false);
      });
    }
  }

  void _handleBiometric() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.authenticateWithBiometrics();
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      // Automatically trigger biometrics if enabled
      if (auth.useBiometrics) {
        _handleBiometric();
      }
    });
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
        child: Stack(
          children: [
            // Subtle background glow
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Security Icon with Glow
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.1),
                          blurRadius: 40,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/expenze_logo.png',
                      width: 56,
                      height: 56,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'EXPENZE',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.getTextColor(context),
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Enter 4-digit PIN to unlock',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppTheme.getTextColor(context, isSecondary: true),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Modern PIN Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isActive = index < _pin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _isError
                              ? Colors.redAccent.withOpacity(0.4)
                              : isActive
                                  ? AppTheme.primary
                                  : Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isError
                                ? Colors.redAccent
                                : isActive
                                    ? AppTheme.primary
                                    : Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: isActive && !_isError
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.4),
                                    blurRadius: 10,
                                  )
                                ]
                              : [],
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // Error Text
                  SizedBox(
                    height: 20,
                    child: _isError
                        ? Text(
                            'Incorrect PIN. Please try again.',
                            style: GoogleFonts.inter(
                              color: Colors.redAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),

                  const Spacer(flex: 3),

                  // Keypad
                  _buildKeypad(),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        children: [
          _buildKeyRow(['1', '2', '3']),
          const SizedBox(height: 24),
          _buildKeyRow(['4', '5', '6']),
          const SizedBox(height: 24),
          _buildKeyRow(['7', '8', '9']),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBiometricButton(),
              _buildKeyButton('0'),
              _buildBackspaceButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((key) => _buildKeyButton(key)).toList(),
    );
  }

  Widget _buildKeyButton(String value) {
    return InkWell(
      onTap: () => _onKeyPress(value),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 74,
        height: 74,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.getTextColor(context).withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextColor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    // Even if not "enabled" in settings, if the user requested it and it's available, show it.
    // However, usually we should respect the setting.
    // The user said: "if fingerprint is available and turned on the phone, implement the fingerprint lock"
    return InkWell(
      onTap: _handleBiometric,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 74,
        height: 74,
        alignment: Alignment.center,
        child: Icon(
          LucideIcons.fingerprint,
          color: auth.useBiometrics
              ? AppTheme.primary
              : AppTheme.getTextColor(context, isSecondary: true)
                  .withOpacity(0.3),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return InkWell(
      onTap: _onBackspace,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 74,
        height: 74,
        alignment: Alignment.center,
        child: Icon(
          LucideIcons.delete,
          color: AppTheme.getTextColor(context, isSecondary: true),
          size: 28,
        ),
      ),
    );
  }
}
