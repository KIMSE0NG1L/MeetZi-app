import 'package:flutter/material.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';

class ThemeController {
  /// DB primaryColor(hex, e.g. "#003380") → Color. null/empty면 null.
  static Color? parsePrimaryColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    String s = hex.trim().replaceFirst('#', '');
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return null;
    final v = int.tryParse(s, radix: 16);
    return v != null ? Color(v) : null;
  }

  /// 테마 primary와 어울리도록 밝은·기본·어두운 톤을 쓴 그라데이션 (헤더·버튼 등)
  static LinearGradient gradientFromPrimary(Color primary) {
    final lighter = Color.lerp(primary, Colors.white, 0.22)!;
    final darker = Color.lerp(primary, Colors.grey.shade200, 0.12)!;
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [lighter, primary, darker],
    );
  }

  /// 위와 동일 3색, 방향만 topLeft → bottomRight (프로필 시트·모달 헤더용)
  static LinearGradient gradientFromPrimaryDiagonal(Color primary) {
    final lighter = Color.lerp(primary, Colors.white, 0.22)!;
    final darker = Color.lerp(primary, Colors.grey.shade200, 0.12)!;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [lighter, primary, darker],
    );
  }
    static final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);
    static final ValueNotifier<bool> secretMode = ValueNotifier<bool>(false);

    static void setThemeMode(ThemeMode mode) {
      if (themeMode.value == mode) return;
      themeMode.value = mode;
    }

    static void setSecretMode(bool enabled) {
      if (secretMode.value == enabled) return;
      secretMode.value = enabled;
    }
  static final ValueNotifier<Color> seedColor =
      ValueNotifier<Color>(NearoTheme.primary);

  static void setSeedColor(Color color) {
    if (seedColor.value == color) return;
    seedColor.value = color;
    NearoTheme.primary = color;
  }
}
