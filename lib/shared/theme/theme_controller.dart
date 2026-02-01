import 'package:flutter/material.dart';
import 'package:nearo_app/shared/theme/nearo_theme.dart';

class ThemeController {
  static final ValueNotifier<Color> seedColor =
      ValueNotifier<Color>(NearoTheme.primary);

  static void setSeedColor(Color color) {
    if (seedColor.value == color) return;
    seedColor.value = color;
    NearoTheme.primary = color;
  }
}
