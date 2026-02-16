import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // User Preferred Palette
  static const Color primary = Color(0xFF79D2C1);
  static const Color primaryDark =
      Color(0xFF2D6C84); // Deep Blue/Teal for headings
  static const Color secondary = Color(0xFF9CDDD1);
  static const Color accent = Color(0xFF2D6C84);
  static const Color info = Color(0xFFC7ECE6);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Background colors
  static const Color bgPrimary = Colors.white;
  static const Color bgSecondary = Color(0xFFC7ECE6);
  static const Color bgCard = Colors.white;

  // Text colors
  static const Color textPrimary =
      Color(0xFF2D6C84); // Using heading color for primary text
  static const Color textSecondary = Color(0xFF475569);
  static const Color textLight = Color(0xFF94A3B8);

  // Border & Depth
  static const Color border = Color(0xFFC7ECE6);
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: primary.withOpacity(0.1),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Dark Theme Palette (Refined for the new scheme)
  static const Color bgPrimaryDark = Color(0xFF0F172A);
  static const Color bgSecondaryDark = Color(0xFF1E293B);
  static const Color bgCardDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Background patterns
  static BoxDecoration get backgroundDecoration => BoxDecoration(
        color: bgPrimary,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withOpacity(0.1),
            bgPrimary,
            bgPrimary,
            info.withOpacity(0.2),
          ],
        ),
      );

  static BoxDecoration get darkBackgroundDecoration => BoxDecoration(
        color: bgPrimaryDark,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryDark.withOpacity(0.15),
            bgPrimaryDark,
            bgPrimaryDark,
            primary.withOpacity(0.05),
          ],
        ),
      );

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primary,
    scaffoldBackgroundColor: Colors.white,
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
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ).copyWith(inherit: true),
    ),
    cardTheme: CardTheme(
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
    textTheme: GoogleFonts.outfitTextTheme(
      ThemeData.dark().textTheme,
    ).copyWith(
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
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimaryDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(
        color: textPrimaryDark,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ).copyWith(inherit: true),
    ),
    cardTheme: CardTheme(
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
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16)
            .copyWith(inherit: true),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );

  static InputDecoration inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(icon, color: textSecondary, size: 20),
      ),
      hintStyle: GoogleFonts.outfit(color: textLight, fontSize: 16),
    );
  }

  static ButtonStyle get primaryButtonStyle =>
      lightTheme.elevatedButtonTheme.style!;
}
