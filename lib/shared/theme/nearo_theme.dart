import 'package:flutter/material.dart';

class NearoTheme {
      static ThemeData secret({Color? seedColor}) {
        final colorScheme = ColorScheme.fromSeed(
          seedColor: seedColor ?? primary,
          brightness: Brightness.dark,
          background: Colors.black,
        );
        return ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme.copyWith(
            primary: primary,
            secondary: secondary,
            background: Colors.black,
          ),
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            elevation: 0,
            centerTitle: true,
            foregroundColor: Colors.white,
          ),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
            headlineMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
            titleMedium: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
              height: 1.5,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: colorScheme.outline),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      }
    static ThemeData dark({Color? seedColor}) {
      final colorScheme = ColorScheme.fromSeed(
        seedColor: seedColor ?? primary,
        brightness: Brightness.dark,
        background: Colors.black,
      );
      return ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme.copyWith(
          primary: primary,
          secondary: secondary,
          background: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.2,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.2,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white70,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white70,
            height: 1.5,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: colorScheme.outline),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }
  static Color primary = const Color(0xFFEC4899);
  static const Color secondary = Color(0xFF00B894);
  static const Color background = Color(0xFFF7F7FB);
  static const Color textPrimary = Color(0xFF1B1B1F);
  static const Color textSecondary = Color(0xFF5F5F6E);

  // ─── Design 폴더 colorThemes.ts pink 테마 (Tailwind rose/pink 팔레트 그대로) ───
  static const Color designRose50 = Color(0xFFFFF1F2);
  static const Color designRose100 = Color(0xFFFFE4E6);
  static const Color designRose200 = Color(0xFFFECDD3);
  static const Color designRose300 = Color(0xFFFDA4AF);
  static const Color designRose400 = Color(0xFFFB7185);
  static const Color designRose500 = Color(0xFFF43F5E);
  static const Color designPink50 = Color(0xFFFDF2F8);
  static const Color designPink300 = Color(0xFFF9A8D4);
  static const Color designPink400 = Color(0xFFF472B6);
  static const Color designPink500 = Color(0xFFEC4899);

  /// gradient: from-rose-300 via-pink-300 to-rose-400
  static const LinearGradient designPinkGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [designRose300, designPink300, designRose400],
  );
  /// gradientAlt: from-rose-400 to-pink-400
  static const LinearGradient designPinkGradientAlt = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [designRose400, designPink400],
  );
  /// 앱바/버튼용: rose-400 ~ pink-500 (Design에서 자주 쓰는 2색)
  static const LinearGradient designPinkGradientBar = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [designRose500, designPink500],
  );

  /// Design ProfileDetailModal: from-rose-400 via-pink-400 to-rose-500 (시트/모달 헤더용)
  static const LinearGradient designPinkGradientSheet = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [designRose400, designPink400, designRose500],
  );

  /// Design colorThemes.ts pink bgGradient: from-rose-50 via-pink-50 to-rose-100
  /// Use for screens that use bg-gradient-to-br in Design (Ranking, Board, Community, Profile, Shop, MessageList, PostDetail, WritePost)
  static const LinearGradient designScreenBgGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      designRose50,
      designPink50,
      designRose100,
    ],
  );
  static const Color designScreenBgDark = Color(0xFF111827);

  /// 하단 탭(커뮤니티/메시지함/홈/My프로필/상점) 공통 배경. 흰색 → rose-50, 위→아래.
  /// HomeShellScreen 한 곳에서만 그려지며, 각 탭 화면은 투명 배경으로 이 위에 얹힌다.
  static const LinearGradient tabScreenBgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white, designRose50],
  );

  static ThemeData light({Color? seedColor}) {
    final base = seedColor ?? primary;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: base,
      brightness: Brightness.light,
      background: background,
    ).copyWith(primary: base);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: textPrimary,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          height: 1.2,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.5,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: colorScheme.outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
