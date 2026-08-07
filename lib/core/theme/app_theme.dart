import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ClubSync — Neubrutalist theme
/// Thick black outlines, hard offset shadows (no blur), warm cream
/// background, vivid orange accent, chunky rounded display type.
class AppColors {
  // Core accent — vivid orange
  static const Color primary = Color(0xFFFF5A1F);
  static const Color primaryDark = Color(0xFFCC4210);
  static const Color primaryLight = Color(0xFFFF8A4C);
  static const Color primaryLighter = Color(0xFFFFE1CF);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFFFB35C), Color(0xFFFF5A1F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF7A33), Color(0xFFFF5A1F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFF1E6), Color(0xFFFFE1CF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient featuredCard1 = LinearGradient(
    colors: [Color(0xFF1A1A1A), Color(0xFF3A3A3A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient featuredCard2 = LinearGradient(
    colors: [Color(0xFF0E7490), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient featuredCard3 = LinearGradient(
    colors: [Color(0xFFFF5A1F), Color(0xFFFFB35C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Backgrounds — warm cream tones
  static const Color background = Color(0xFFF3F1EC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEDEBE4);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Ink — used for borders + primary text (near-black)
  static const Color ink = Color(0xFF16151A);

  // Accent (kept as alias so existing references still work)
  static const Color accent = primary;
  static const Color accentDark = primaryDark;

  // Secondary
  static const Color secondary = Color(0xFFFFB35C);

  // Text
  static const Color textPrimary = Color(0xFF16151A);
  static const Color textSecondary = Color(0xFF55534E);
  static const Color textMuted = Color(0xFF938F84);

  // Status
  static const Color success = Color(0xFF1F9254);
  static const Color successBg = Color(0xFFD8F5E3);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFEF0D9);
  static const Color error = Color(0xFFE0332A);
  static const Color errorBg = Color(0xFFFCDCDA);
  static const Color info = Color(0xFF1D6FCC);

  // Club category colors
  static const Color technical = Color(0xFF1D6FCC);
  static const Color cultural = Color(0xFFDB2777);
  static const Color sports = Color(0xFF1F9254);
  static const Color finance = Color(0xFFD97706);
  static const Color literary = Color(0xFF7C3AED);
}

/// Hard, offset, blur-free "sticker" shadows — the signature of this style.
class AppShadows {
  static List<BoxShadow> get card => const [
        BoxShadow(color: AppColors.ink, offset: Offset(4, 4), blurRadius: 0),
      ];

  static List<BoxShadow> get small => const [
        BoxShadow(color: AppColors.ink, offset: Offset(2, 2), blurRadius: 0),
      ];

  static List<BoxShadow> get elevated => const [
        BoxShadow(color: AppColors.ink, offset: Offset(6, 6), blurRadius: 0),
      ];

  // Kept for any remaining call sites expecting a soft shadow.
  static List<BoxShadow> get subtle => const [
        BoxShadow(color: AppColors.ink, offset: Offset(2, 2), blurRadius: 0),
      ];
}

/// Standard black outline used on cards/buttons/chips.
class AppBorders {
  static Border get thick => Border.all(color: AppColors.ink, width: 2.5);
  static Border get thin => Border.all(color: AppColors.ink, width: 1.5);
}

class AppTheme {
  static TextTheme get _textTheme => TextTheme(
        displayLarge: GoogleFonts.fredoka(
          fontSize: 34, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary, letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.fredoka(
          fontSize: 27, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary, letterSpacing: -0.3,
        ),
        headlineLarge: GoogleFonts.fredoka(
          fontSize: 23, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.fredoka(
          fontSize: 19, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.fredoka(
          fontSize: 17, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          surface: AppColors.surface,
          primary: AppColors.primary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: _textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: AppColors.ink),
          titleTextStyle: GoogleFonts.fredoka(
            fontSize: 20, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardBg,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.ink, width: 2.5),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.ink, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.ink, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2.5),
          ),
          hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.ink, width: 2.5),
            ),
            textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surface,
          selectedColor: AppColors.primary.withValues(alpha: 0.16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
            side: const BorderSide(color: AppColors.ink, width: 1.5),
          ),
          labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.ink,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.ink,
          thickness: 1,
          space: 0,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          surface: const Color(0xFF1C1B22),
          primary: AppColors.primary,
        ),
        scaffoldBackgroundColor: const Color(0xFF121116),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.fredoka(fontSize: 34, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: -0.5),
          displayMedium: GoogleFonts.fredoka(fontSize: 27, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: -0.3),
          headlineLarge: GoogleFonts.fredoka(fontSize: 23, fontWeight: FontWeight.w600, color: Colors.white),
          headlineMedium: GoogleFonts.fredoka(fontSize: 19, fontWeight: FontWeight.w600, color: Colors.white),
          titleLarge: GoogleFonts.fredoka(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
          titleMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
          bodyLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: const Color(0xFFE7E5E0)),
          bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFFB8B5AD)),
          bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: const Color(0xFF8A8780)),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF121116),
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1C1B22),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF242330),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white, width: 2)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF3A3945), width: 2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2.5)),
          hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6E6C76)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1C1B22),
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Color(0xFF6E6C76),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFF3A3945), thickness: 1, space: 0),
      );
}

class AppRadius {
  static const double xs = 8;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 22;
  static const double xxl = 28;
  static const double full = 999;
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}