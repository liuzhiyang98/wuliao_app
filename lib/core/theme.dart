import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFFE96A8B);
  static const secondary = Color(0xFF7F77DD);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        scaffoldBackgroundColor: const Color(0xFFFDF6F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFDF6F8),
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
      );
}
