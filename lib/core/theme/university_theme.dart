import 'package:flutter/material.dart';
import 'meetzy_design_tokens.dart';

/// 학교별 교색. DB(Environment.primaryColor) hex가 들어오면 코드 수정 없이 UI 색상만 반영.
/// 초기값: 세종대학교 Crimson.
class UniversityTheme {
  UniversityTheme._();

  /// 세종대학교 교색 (Crimson 계열)
  static const Color sejongCrimson = Color(0xFFA41E36);
  static const Color sejongCrimsonLight = Color(0xFFC41E3A);

  /// Environment.primaryColor(hex) 파싱. null/빈값이면 세종대 기본값.
  static Color primaryFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return sejongCrimson;
    final h = hex.startsWith('#') ? hex.substring(1) : hex;
    if (h.length != 6 && h.length != 8) return sejongCrimson;
    final r = int.tryParse(h.substring(0, 2), radix: 16);
    final g = int.tryParse(h.substring(2, 4), radix: 16);
    final b = int.tryParse(h.substring(4, 6), radix: 16);
    if (r == null || g == null || b == null) return sejongCrimson;
    final a = h.length == 8 ? int.tryParse(h.substring(6, 8), radix: 16) ?? 255 : 255;
    return Color.fromARGB(a, r, g, b);
  }

  /// last/colorThemes.ts pink 테마 → Flutter Color (세종대/기본)
  static Color get primary => sejongCrimson;
  static Color get primaryLight => const Color(0xFFFDA4AF); // rose-300
  static Color get primaryLighter => const Color(0xFFF9A8D4); // pink-300
  static Color get primaryDark => const Color(0xFFFB7185);   // rose-400
  static Color get bgGradientStart => const Color(0xFFFFF1F2); // rose-50
  static Color get bgGradientMid => const Color(0xFFFDF2F8);   // pink-50
  static Color get bgGradientEnd => const Color(0xFFFFE4E6);   // rose-100
  static Color get surface => Colors.white;
  static Color get onSurface => const Color(0xFF111827);       // gray-900
  static Color get onSurfaceVariant => const Color(0xFF6B7280); // gray-500

  /// Header gradient (left → right): theme gradient
  static LinearGradient headerGradient(Color primaryColor) {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        primaryColor.withOpacity(0.9),
        primaryColor,
      ],
    );
  }

  /// last colorThemes gradient (rose-300 → pink-300 → rose-400)
  static const LinearGradient designPinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFDA4AF),
      Color(0xFFF9A8D4),
      Color(0xFFFB7185),
    ],
  );

  /// Screen background gradient (last bgGradient)
  static const LinearGradient screenBgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF1F2),
      Color(0xFFFDF2F8),
      Color(0xFFFFE4E6),
    ],
  );

  /// FAB/Button primary color (theme에 따라 변경 가능)
  static Color fabColor(Color primaryColor) => primaryColor;
}
