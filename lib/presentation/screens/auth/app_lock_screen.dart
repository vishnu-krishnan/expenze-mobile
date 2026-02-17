import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
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
      if (auth.useBiometrics) {
        _handleBiometric();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1B4B),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Logo/Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.lock,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome Back',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter PIN to unlock Expenze',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 40),
            // PIN Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: index < _pin.length
                        ? const Color(0xFF10B981)
                        : Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: _isError && _pin.isEmpty
                        ? Border.all(color: Colors.redAccent, width: 2)
                        : null,
                  ),
                );
              }),
            ),
            if (_isError)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  'Invalid PIN. Try again.',
                  style: GoogleFonts.inter(color: Colors.redAccent),
                ),
              ),
            const Spacer(),
            // Keypad
            _buildKeypad(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _buildKeyRow(['1', '2', '3']),
          const SizedBox(height: 20),
          _buildKeyRow(['4', '5', '6']),
          const SizedBox(height: 20),
          _buildKeyRow(['7', '8', '9']),
          const SizedBox(height: 20),
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
        width: 70,
        height: 70,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.useBiometrics) {
      return const SizedBox(width: 70, height: 70);
    }
    return InkWell(
      onTap: _handleBiometric,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 70,
        height: 70,
        alignment: Alignment.center,
        child: const Icon(
          LucideIcons.fingerprint,
          color: const Color(0xFF10B981),
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
        width: 70,
        height: 70,
        alignment: Alignment.center,
        child: const Icon(
          LucideIcons.delete,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
