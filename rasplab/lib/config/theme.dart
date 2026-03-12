import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF82AAFF),
    secondary: Color(0xFFC3E88D),
    surface: Color(0xFF1E1E2E),
    error: Color(0xFFF38BA8),
  ),
  scaffoldBackgroundColor: const Color(0xFF1E1E2E),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF181825),
    foregroundColor: Color(0xFFCDD6F4),
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF313244),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF313244),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide.none,
    ),
    hintStyle: const TextStyle(color: Color(0xFF6C7086)),
  ),
  textTheme: GoogleFonts.notoSansKrTextTheme(
    ThemeData.dark().textTheme,
  ).apply(
    bodyColor: const Color(0xFFCDD6F4),
    displayColor: const Color(0xFFCDD6F4),
  ),
);

// 채팅 버블 색상
const Color kUserBubbleColor = Color(0xFF45475A);
const Color kAiBubbleColor   = Color(0xFF313244);

// 코드블록 배경
const Color kCodeBlockColor  = Color(0xFF181825);

// 실행 결과 색상
const Color kSuccessColor    = Color(0xFFA6E3A1);
const Color kErrorColor      = Color(0xFFF38BA8);
const Color kRunningColor    = Color(0xFF89B4FA);
