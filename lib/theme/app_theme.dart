import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF3D2B1F);
  static const Color secondary = Color(0xFF2D4B2D);
  static const Color tertiary = Color(0xFF1A1A1A);
  static const Color neutral = Color(0xFFF5F1E6);
  static const Color neutralSoft = Color(0xFFF9F6EE);
  static const Color neutralStrong = Color(0xFFE4DDCB);
  static const Color outline = Color(0xFFD8D0C0);
  static const Color primaryHighlight = Color(0xFFC48E63);
  static const Color error = Color(0xFFD62020);

  static const List<Color> primaryScale = <Color>[
    Color(0xFF100A06),
    Color(0xFF1A120D),
    Color(0xFF271C15),
    Color(0xFF36271E),
    Color(0xFF49362A),
    Color(0xFF6C5649),
    Color(0xFF91796A),
    Color(0xFFBEA493),
    Color(0xFFE8D0C2),
    Color(0xFFF7E7DD),
  ];

  static const List<Color> secondaryScale = <Color>[
    Color(0xFF031104),
    Color(0xFF0A1E0D),
    Color(0xFF133017),
    Color(0xFF1E4120),
    Color(0xFF2D4B2D),
    Color(0xFF476547),
    Color(0xFF668066),
    Color(0xFF91AA91),
    Color(0xFFBED4BE),
    Color(0xFFE5F2E5),
  ];

  static const List<Color> tertiaryScale = <Color>[
    Color(0xFF000000),
    Color(0xFF111111),
    Color(0xFF1A1A1A),
    Color(0xFF2B2B2B),
    Color(0xFF444444),
    Color(0xFF666666),
    Color(0xFF8A8A8A),
    Color(0xFFB2B2B2),
    Color(0xFFD9D9D9),
    Color(0xFFF2F2F2),
  ];

  static const List<Color> neutralScale = <Color>[
    Color(0xFF1E1D18),
    Color(0xFF36342D),
    Color(0xFF545149),
    Color(0xFF75716A),
    Color(0xFF97928A),
    Color(0xFFB8B1A6),
    Color(0xFFD1C8BA),
    Color(0xFFE4DDCF),
    Color(0xFFF5F1E6),
    Color(0xFFFFFCF6),
  ];
}

abstract final class AppTheme {
  static ThemeData get lightTheme {
    final ThemeData baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ).copyWith(
            primary: AppColors.primary,
            onPrimary: AppColors.neutral,
            secondary: AppColors.secondary,
            onSecondary: AppColors.neutral,
            tertiary: AppColors.tertiary,
            onTertiary: AppColors.neutral,
            surface: AppColors.neutral,
            onSurface: AppColors.tertiary,
            error: AppColors.error,
            onError: Colors.white,
            outline: AppColors.outline,
          ),
      scaffoldBackgroundColor: AppColors.tertiary,
      canvasColor: AppColors.neutral,
    );

    final TextTheme textTheme =
        GoogleFonts.newsreaderTextTheme(baseTheme.textTheme).copyWith(
          displayLarge: GoogleFonts.newsreader(
            fontSize: 88,
            height: 0.95,
            fontWeight: FontWeight.w400,
            color: AppColors.tertiary,
          ),
          displayMedium: GoogleFonts.newsreader(
            fontSize: 64,
            height: 0.98,
            fontWeight: FontWeight.w400,
            color: AppColors.tertiary,
          ),
          headlineLarge: GoogleFonts.newsreader(
            fontSize: 38,
            height: 1.02,
            fontWeight: FontWeight.w500,
            color: AppColors.tertiary,
          ),
          headlineMedium: GoogleFonts.newsreader(
            fontSize: 30,
            height: 1.05,
            fontWeight: FontWeight.w500,
            color: AppColors.tertiary,
          ),
          titleLarge: GoogleFonts.newsreader(
            fontSize: 24,
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: AppColors.tertiary,
          ),
          titleMedium: GoogleFonts.newsreader(
            fontSize: 20,
            height: 1.1,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
          bodyLarge: GoogleFonts.newsreader(
            fontSize: 22,
            height: 1.25,
            fontWeight: FontWeight.w400,
            color: AppColors.primary,
          ),
          bodyMedium: GoogleFonts.newsreader(
            fontSize: 18,
            height: 1.35,
            fontWeight: FontWeight.w400,
            color: AppColors.primary,
          ),
          labelLarge: GoogleFonts.newsreader(
            fontSize: 18,
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
          labelMedium: GoogleFonts.newsreader(
            fontSize: 15,
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
          labelSmall: GoogleFonts.newsreader(
            fontSize: 13,
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        );

    const BorderRadius buttonRadius = BorderRadius.zero;

    return baseTheme.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.neutral,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.newsreader(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: AppColors.neutral,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.primary, size: 22),
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        color: AppColors.neutralSoft,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: AppColors.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutralSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.primary.withOpacity(0.68),
        ),
        prefixIconColor: AppColors.primary.withOpacity(0.7),
        border: OutlineInputBorder(
          borderRadius: buttonRadius,
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: buttonRadius,
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: buttonRadius,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.neutral,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.outline),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.neutral,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
        ),
      ),
      chipTheme: baseTheme.chipTheme.copyWith(
        backgroundColor: AppColors.primary,
        selectedColor: AppColors.secondary,
        disabledColor: AppColors.neutralStrong,
        labelStyle: textTheme.labelMedium?.copyWith(color: AppColors.neutral),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: buttonRadius),
      ),
    );
  }
}
