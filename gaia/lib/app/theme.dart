import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gaia/values/values.dart';

const _lightFillColor = AppColors.black;

final Color _lightFocusColor = AppColors.black.withOpacity(0.12);

const _extraBold = FontWeight.w900;
const _bold = FontWeight.w700;
const _semiBold = FontWeight.w600;
const _medium = FontWeight.w500;
const _regular = FontWeight.w400;
// static const _light = FontWeight.w300;

final _textTheme = TextTheme(
  displayLarge: GoogleFonts.inter(
    fontWeight: _extraBold,
    fontSize: 72.0,
    color: AppColors.gray,
  ),
  displayMedium: GoogleFonts.inter(
    fontWeight: _extraBold,
    fontSize: 48.0,
    color: AppColors.gray,
  ),
  displaySmall: GoogleFonts.inter(
    fontWeight: _extraBold,
    fontSize: 40.0,
    color: AppColors.gray,
  ),
  headlineMedium: GoogleFonts.inter(
    fontWeight: _extraBold,
    fontSize: 28.0,
    color: AppColors.gray,
  ),
  headlineSmall: GoogleFonts.inter(
    fontWeight: _semiBold,
    fontSize: 24.0,
    color: AppColors.gray,
  ),
  titleLarge: GoogleFonts.inter(
    fontWeight: _medium,
    fontSize: 20.0,
    color: AppColors.gray,
  ),
  titleMedium: GoogleFonts.inter(
    fontWeight: _bold,
    fontSize: 18.0,
    color: AppColors.gray,
  ),
  titleSmall: GoogleFonts.inter(
    fontWeight: _medium,
    fontSize: 18.0,
    color: AppColors.gray,
  ),
  bodyLarge: GoogleFonts.inter(
    fontWeight: _regular,
    fontSize: 16.0,
    color: AppColors.gray,
  ),
  bodyMedium: GoogleFonts.inter(
    fontWeight: _regular,
    fontSize: 14.0,
    color: AppColors.gray,
  ),
);

// lead text styles
final lead1 = GoogleFonts.inter(
  fontWeight: _regular,
  fontSize: 18.0,
  color: AppColors.gray,
);

final lead2 = GoogleFonts.inter(
  fontWeight: _medium,
  fontSize: 14.0,
  color: AppColors.gray,
);

// label text styles
final largeLabel = GoogleFonts.inter(
  fontWeight: _semiBold,
  fontSize: 20.0,
  color: AppColors.black,
);

final mediumLabel = GoogleFonts.inter(
  fontWeight: _semiBold,
  fontSize: 14.0,
  color: AppColors.gray,
);

final smallLabel = GoogleFonts.inter(
  fontWeight: _semiBold,
  fontSize: 12.0,
  color: AppColors.gray,
);

ThemeData themeData(ColorScheme colorScheme, Color focusColor) {
  return ThemeData(
    colorScheme: colorScheme,
    textTheme: _textTheme,
    canvasColor: colorScheme.surface,
    scaffoldBackgroundColor: colorScheme.surface,
    highlightColor: Colors.transparent,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    focusColor: AppColors.purple,
  );
}

ColorScheme _lightColorScheme = ColorScheme(
  primary: AppColors.purple,
  primaryContainer: AppColors.purple.shade800,
  secondary: AppColors.turquoise,
  secondaryContainer: AppColors.turquoise.shade800,
  surface: AppColors.white,
  

  error: _lightFillColor,
  onError: _lightFillColor,
  onPrimary: _lightFillColor,
  onSecondary: AppColors.white,
  onSurface: AppColors.gray,
  brightness: Brightness.light,
);

ThemeData lightThemeData = themeData(_lightColorScheme, _lightFocusColor);