import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import 'profile_setup_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Theme-aligned Premium Background Gradient
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2D8272), // primaryDark
                  Color(0xFF79D2C1), // primary
                  Color(0xFF9CDDD1), // secondary
                  Colors.white,
                ],
                stops: [0.0, 0.4, 0.7, 1.0],
              ),
            ),
          ),

          // Decorative Abstract Circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // Brand Identity
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Image.asset(
                          'assets/images/expenze_logo.png',
                          width: 32,
                          height: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'EXPENZE',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 2),

                  // Professional & Friendly Copy
                  Text(
                    'Take control of your money with confidence.',
                    style: GoogleFonts.outfit(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'EXPENZE helps you understand your spending in a simple and stress-free way. No complicated setup. No unnecessary accounts. Just clear insights and full control from day one.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Feature Highlights (Refined Cards)
                  _buildFeatureRow(
                    icon: LucideIcons.shieldCheck,
                    title: 'Your Data, Your Choice',
                    desc:
                        'Your expenses are stored on your device by default. Optional Google Drive backup will be available, always under your control.',
                  ),
                  const SizedBox(height: 24),
                  _buildFeatureRow(
                    icon: LucideIcons.lock,
                    title: 'Secure and Protected',
                    desc:
                        'Lock your app with a PIN or biometric security to keep your financial information safe.',
                  ),
                  const SizedBox(height: 24),
                  _buildFeatureRow(
                    icon: LucideIcons.zap,
                    title: 'Start Instantly',
                    desc:
                        'No sign-up process. No waiting. Open the app and begin tracking right away.',
                  ),

                  const Spacer(flex: 2),

                  // CTA Button
                  _buildPrimaryButton(context),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileSetupPage(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Take Control Now',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.arrowRight, size: 20),
          ],
        ),
      ),
    );
  }
}
