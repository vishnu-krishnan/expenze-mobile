import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'profile_setup_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1), // Indigo
              Color(0xFF4F46E5), // Darker Indigo
              Color(0xFF1E1B4B), // Very Dark Indigo
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                // Logo or Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    LucideIcons.wallet,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Master Your\nFinances.',
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'A private, secure, and beautiful way to track your daily expenses without account friction.',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                // Features
                _buildFeatureRow(
                    LucideIcons.shieldCheck, '100% Private & Local'),
                const SizedBox(height: 16),
                _buildFeatureRow(LucideIcons.fingerprint, 'Biometric App Lock'),
                const SizedBox(height: 16),
                _buildFeatureRow(LucideIcons.zap, 'Zero Sign-Up Required'),
                const SizedBox(height: 60),
                // Get Started Button
                SPrimaryButton(
                  text: 'Get Started',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileSetupPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF10B981), size: 24),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class SPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const SPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF4F46E5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
