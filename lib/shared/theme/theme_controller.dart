import 'package:flutter/material.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';

class ThemeController {
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
