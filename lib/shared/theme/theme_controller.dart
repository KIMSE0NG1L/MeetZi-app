import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';

class ThemeController {
  /// Design 폴더 pink 테마 메인 색상 (colorThemes.ts pink-500)
  static Color get designPink => NearoTheme.designPink500;

  static const _keyThemeColorMode = 'theme_color_mode';
  static const _valuePink = 'pink';
  static const _valueSchool = 'school';

  /// 'pink' = 핑크색, 'school' = DB 교색(primaryColor)
  static final ValueNotifier<String> themeColorMode = ValueNotifier<String>(_valueSchool);

  /// 저장된 테마 색상 모드 로드. 앱/홈 진입 시 한 번 호출.
  static Future<void> loadThemeColorMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = prefs.getString(_keyThemeColorMode) ?? _valueSchool;
      themeColorMode.value = mode;
      if (mode == _valuePink) {
        setSeedColor(designPink);
      }
    } catch (_) {}
  }

  /// 핑크색 선택 시: seedColor를 Design 핑크로 설정 후 저장.
  static Future<void> setThemeColorModePink() async {
    themeColorMode.value = _valuePink;
    setSeedColor(designPink);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyThemeColorMode, _valuePink);
    } catch (_) {}
  }

  /// 교색 선택 시: seedColor는 호출측에서 DB primary로 설정. 모드만 저장.
  static Future<void> setThemeColorModeSchool(Color schoolPrimary) async {
    themeColorMode.value = _valueSchool;
    setSeedColor(schoolPrimary);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyThemeColorMode, _valueSchool);
    } catch (_) {}
  }

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
    final darker = Color.lerp(primary, Colors.black, 0.12)!;
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [lighter, primary, darker],
    );
  }

  /// 위와 동일 3색, 방향만 topLeft → bottomRight (프로필 시트·모달 헤더용)
  static LinearGradient gradientFromPrimaryDiagonal(Color primary) {
    final lighter = Color.lerp(primary, Colors.white, 0.22)!;
    final darker = Color.lerp(primary, Colors.black, 0.12)!;
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
