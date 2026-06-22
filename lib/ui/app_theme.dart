import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const seed = Color(0xFF2F6B2F);
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: seed),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF7F3E8),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF7F3E8), centerTitle: false),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.green.shade100),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(96, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}
