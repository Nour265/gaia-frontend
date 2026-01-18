import 'package:flutter/material.dart';

// This class contains all the visual styling of the application.
// It defines colors, background, fonts, and general UI appearance.
// Keeping this in one file makes it easy to change the design globally.
class AppTheme {
  // We define a method that returns a ThemeData object.
  // ThemeData is Flutter’s way of describing the look and feel of the app.
  static ThemeData light() {
    return ThemeData(
      // We use Material 3 because it gives a more modern UI design.
      useMaterial3: true,

      // Primary color of the application.
      // This will be used for buttons, progress bars, highlights, etc.
      primaryColor: const Color(0xFF1F4FD8), // Medical blue

      // Background color for all screens.
      scaffoldBackgroundColor: const Color(0xFFF5F8FF), // Light clean background

      // Default font family for the whole app.
      // You can later replace this with Inter or Roboto.
      fontFamily: 'Roboto',

      // Text styling configuration.
      textTheme: const TextTheme(
        // Large titles (like page titles)
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),

        // Normal body text
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFF64748B),
        ),
      ),

      // AppBar (top bar) styling
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B),
        ),
        iconTheme: IconThemeData(
          color: Color(0xFF1E293B),
        ),
      ),

      // Card styling (used later for wizard steps and result boxes)
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Button styling for all ElevatedButtons in the app
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F4FD8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Input field styling (TextField, TextFormField)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
