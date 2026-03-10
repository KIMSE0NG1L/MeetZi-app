import 'package:flutter/material.dart';
import 'meetzy_design_tokens.dart';

/// Pretendard 기본 적용. assets에 Pretendard 폰트 추가 시 fontFamily 사용.
/// last/theme.css: font-size 16px, font-weight 400/500.
class AppTextStyles {
  AppTextStyles._();

  static const String _fontFamily = 'Pretendard';

  static TextStyle _base({double? fontSize, FontWeight? fontWeight, Color? color}) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontSize: fontSize ?? MeetzyDesignTokens.textBase,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      height: 1.5,
    );
  }

  /// h1: text-2xl font-bold (Header "MeetZy")
  static TextStyle headerTitle([Color? color]) => _base(
        fontSize: MeetzyDesignTokens.text2xl,
        fontWeight: FontWeight.w700,
        color: color,
      );

  /// Header 부제 (세종대)
  static TextStyle headerSubtitle([Color? color]) => _base(
        fontSize: MeetzyDesignTokens.textSm,
        fontWeight: FontWeight.w500,
        color: color,
      );

  /// Stats bar 닉네임: text-base font-bold
  static TextStyle statsNickname([Color? color]) => _base(
        fontSize: MeetzyDesignTokens.textBase,
        fontWeight: FontWeight.w700,
        color: color,
      );

  /// Ticket chip 라벨: text-[9px] font-semibold
  static TextStyle ticketLabel([Color? color]) => _base(
        fontSize: MeetzyDesignTokens.ticketLabelFontSize,
        fontWeight: FontWeight.w600,
        color: color,
      );

  /// Ticket chip 숫자: text-xs font-bold
  static TextStyle ticketValue([Color? color]) => _base(
        fontSize: MeetzyDesignTokens.ticketValueFontSize,
        fontWeight: FontWeight.w700,
        color: color,
      );

  /// Card nickname: text-sm font-bold
  static TextStyle cardNickname([Color? color]) => _base(
        fontSize: MeetzyDesignTokens.cardNicknameFontSize,
        fontWeight: FontWeight.w700,
        color: color,
      );

  /// Card tag: text-xs font-medium
  static TextStyle cardTag([Color? color]) => _base(
        fontSize: MeetzyDesignTokens.cardTagFontSize,
        fontWeight: FontWeight.w500,
        color: color,
      );

  /// NEW badge
  static TextStyle badge([Color? color]) => _base(
        fontSize: MeetzyDesignTokens.badgeFontSize,
        fontWeight: FontWeight.w700,
        color: color ?? Colors.white,
      );

  /// Bottom nav label: text-[10px]
  static TextStyle bottomNavLabel([Color? color]) => _base(
        fontSize: MeetzyDesignTokens.bottomNavLabelSize,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle bottomNavLabelActive([Color? color]) => _base(
        fontSize: MeetzyDesignTokens.bottomNavLabelSize,
        fontWeight: FontWeight.w700,
        color: color,
      );

  /// FAB "등록"
  static TextStyle fab([Color? color]) => _base(
        fontSize: MeetzyDesignTokens.fabFontSize,
        fontWeight: MeetzyDesignTokens.fabFontWeight,
        color: color ?? Colors.white,
      );
}
