import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // User Preferred Palette - cleaner, more vibrant
  static const Color primary = Color(0xFF0D9488); // Teal 600
  static const Color primaryDark = Color(0xFF0F766E); // Teal 700
  static const Color primaryLight = Color(0xFFCCFBF1); // Teal 100
  static const Color secondary = Color(0xFF0EA5E9); // Sky 500
  static const Color accent = Color(0xFF0D9488);
  static const Color info = Color(0xFFE0F2F1);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFD97706);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerDark = Color(0xFFB91C1C);

  // System UI Styles
  static final SystemUiOverlayStyle headerOverlayStyle = SystemUiOverlayStyle.light.copyWith(
    statusBarColor: Colors.transparent,
    systemStatusBarContrastEnforced: false,
  );

  // Background colors - cleaner neutrals
  static const Color bgPrimary = Colors.white; // Pure Elite White
  static const Color bgSecondary = Color(0xFFF8FAFC); // Slate 50
  static const Color bgCard = Colors.white;

  // Text Colors - High contrast
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textLight = Color(0xFF94A3B8); // Slate 400

  // Dark Theme constants
  static const Color bgPrimaryDark = Color(0xFF020617); // Slate 950
  static const Color bgSecondaryDark = Color(0xFF0F172A); // Slate 900
  static const Color bgCardDark = Color(0xFF1E293B); // Slate 800
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderDark = Color(0xFF334155); // Slate 700
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static BoxDecoration glassDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.white.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
          color: (isDark ? borderDark : border).withValues(alpha: 0.3)),
    );
  }

  // Background patterns - softer gradients
  static BoxDecoration get backgroundDecoration => const BoxDecoration(
        color: bgPrimary,
      );

  static BoxDecoration headerDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: Theme.of(context).brightness == Brightness.dark
            ? [
                const Color(0xFF134E4A), // Elite Teal 900 at top
                bgPrimaryDark, // Dissolve
              ]
            : [
                const Color(
                    0xFF134E4A), // Dark Teal 900 at top (Notification area)
                const Color(0xFF0F766E), // Strong Teal accent
                bgPrimary, // Dissolve
              ],
        stops: Theme.of(context).brightness == Brightness.dark
            ? const [0.0, 1.0]
            : const [0.0, 0.4, 1.0],
      ),
    );
  }

  static BoxDecoration get darkBackgroundDecoration => const BoxDecoration(
        color: bgPrimaryDark,
      );

  // Helper method to get theme-aware text colors
  static Color getTextColor(BuildContext context, {bool isSecondary = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isSecondary) {
      return isDark ? textSecondaryDark : textSecondary;
    }
    return isDark ? textPrimaryDark : textPrimary;
  }

  // Color Utility: Desaturate a color to make it look less "popped" and more premium
  static Color desaturate(Color color, {double amount = 0.5}) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withSaturation((hsl.saturation * (1 - amount).clamp(0.0, 1.0))).toColor();
  }

  // Liquid Glass Utility: Create a transparent, blurred container
  static BoxDecoration liquidGlassDecoration(BuildContext context, {List<Color>? colors}) {
    final baseColors = colors ?? [
      Colors.white.withValues(alpha: 0.1),
      Colors.white.withValues(alpha: 0.05),
    ];

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: baseColors.map((c) => c.withValues(alpha: 0.4)).toList(),
      ),
      borderRadius: BorderRadius.circular(32),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.15),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 30,
          offset: const Offset(0, 16),
        ),
      ],
    );
  }

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primary,
    scaffoldBackgroundColor: bgPrimary,
    fontFamily: GoogleFonts.outfit().fontFamily,
    textTheme: GoogleFonts.outfitTextTheme().copyWith(
      displayLarge:
          GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.bold)
              .copyWith(inherit: true),
      displayMedium:
          GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.bold)
              .copyWith(inherit: true),
      bodyLarge:
          GoogleFonts.outfit(color: textSecondary).copyWith(inherit: true),
      bodyMedium:
          GoogleFonts.outfit(color: textSecondary).copyWith(inherit: true),
      labelLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600)
          .copyWith(inherit: true),
    ),
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: secondary,
      error: danger,
      surface: bgCard,
      onSurface: textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleTextStyle: GoogleFonts.outfit(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ).copyWith(inherit: true),
    ),
    cardTheme: CardThemeData(
      color: bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16)
            .copyWith(inherit: true),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primary,
    scaffoldBackgroundColor: bgPrimaryDark,
    fontFamily: GoogleFonts.outfit().fontFamily,
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.outfit(
              color: textPrimaryDark, fontWeight: FontWeight.bold)
          .copyWith(inherit: true),
      displayMedium: GoogleFonts.outfit(
              color: textPrimaryDark, fontWeight: FontWeight.bold)
          .copyWith(inherit: true),
      bodyLarge:
          GoogleFonts.outfit(color: textSecondaryDark).copyWith(inherit: true),
      bodyMedium:
          GoogleFonts.outfit(color: textSecondaryDark).copyWith(inherit: true),
      labelLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600)
          .copyWith(inherit: true),
    ),
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: accent,
      error: danger,
      surface: bgCardDark,
      onSurface: textPrimaryDark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimaryDark,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleTextStyle: GoogleFonts.outfit(
        color: textPrimaryDark,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ).copyWith(inherit: true),
    ),
    cardTheme: CardThemeData(
      color: bgCardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: borderDark, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgCardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16)
            .copyWith(inherit: true),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );

  static InputDecoration inputDecoration(String hint, IconData? icon,
      {BuildContext? context}) {
    final color = context != null
        ? getTextColor(context, isSecondary: true)
        : textSecondary;
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Icon(icon, color: color, size: 20),
            ),
      hintStyle: GoogleFonts.outfit(color: textLight, fontSize: 16),
    );
  }

  static ButtonStyle get primaryButtonStyle =>
      lightTheme.elevatedButtonTheme.style!;
}
