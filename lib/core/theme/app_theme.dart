import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary blues
  static const Color primary = Color(0xFF1A6BCC);
  static const Color primaryDark = Color(0xFF0F4A99);
  static const Color primaryLight = Color(0xFF4A90D9);
  static const Color primaryLighter = Color(0xFFDBEAFA);

  // Hero gradient — deep blue to medium blue
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0F3D8C), Color(0xFF1A6BCC), Color(0xFF3D8FE0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A6BCC), Color(0xFF3D8FE0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFEBF4FF), Color(0xFFF5F9FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient featuredCard1 = LinearGradient(
    colors: [Color(0xFF0F3D8C), Color(0xFF1A6BCC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient featuredCard2 = LinearGradient(
    colors: [Color(0xFF0E7490), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient featuredCard3 = LinearGradient(
    colors: [Color(0xFF1D4ED8), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Backgrounds — warm white tones
  static const Color background = Color(0xFFF5F8FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEFF4FB);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Accent
  static const Color accent = Color(0xFF1A6BCC);
  static const Color accentDark = Color(0xFF0F4A99);

  // Secondary
  static const Color secondary = Color(0xFF3D8FE0);

  // Text
  static const Color textPrimary = Color(0xFF0D1B2A);
  static const Color textSecondary = Color(0xFF4A6080);
  static const Color textMuted = Color(0xFF8FA8C0);

  // Status
  static const Color success = Color(0xFF059669);
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0284C7);

  // Club category colors
  static const Color technical = Color(0xFF1A6BCC);
  static const Color cultural = Color(0xFFDB2777);
  static const Color sports = Color(0xFF059669);
  static const Color finance = Color(0xFFD97706);
  static const Color literary = Color(0xFF7C3AED);
}

class AppShadows {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: const Color(0xFF1A6BCC).withValues(alpha: 0.07),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: const Color(0xFF1A6BCC).withValues(alpha: 0.22),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: -2,
        ),
      ];

  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.light,
          surface: AppColors.surface,
          primary: AppColors.accent,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.interTextTheme().copyWith(
          displayLarge: GoogleFonts.inter(
            fontSize: 32, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary, letterSpacing: -0.5,
          ),
          displayMedium: GoogleFonts.inter(
            fontSize: 26, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary, letterSpacing: -0.3,
          ),
          headlineLarge: GoogleFonts.inter(
            fontSize: 22, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          headlineMedium: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          titleLarge: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          titleMedium: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600,
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
            fontSize: 14, fontWeight: FontWeight.w600,
            color: AppColors.surface,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardBg,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
          hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceVariant,
          selectedColor: AppColors.accent.withValues(alpha: 0.15),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.black.withValues(alpha: 0.06),
          thickness: 1,
          space: 0,
        ),
      );

      static ThemeData get dark => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.dark,
        surface: const Color(0xFF1A1A2E),
        primary: AppColors.accent,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F0E1A),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
        displayMedium: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3),
        headlineLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
        headlineMedium: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        titleMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: const Color(0xFFE0E0E0)),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFFB0B0C0)),
        bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: const Color(0xFF808090)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F0E1A),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1A2E),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF252540),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2A45))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF606080)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1A1A2E),
        selectedItemColor: AppColors.accent,
        unselectedItemColor: Color(0xFF606080),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF2A2A45), thickness: 1, space: 0),
    );
}

class AppRadius {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
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