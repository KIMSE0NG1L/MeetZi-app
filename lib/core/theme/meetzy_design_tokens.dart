import 'package:flutter/material.dart';

/// last 폴더(MeetZyBoard, MaleBoard) 수치 1:1 매핑.
/// Tailwind: 1 unit = 4px. rounded-2xl=16, rounded-3xl=24, gap-4=16, px-5=20, pt-14=56, p-4=16.
class MeetzyDesignTokens {
  MeetzyDesignTokens._();

  // ─── Spacing (Tailwind → px) ───
  static const double space1 = 4;   // gap-1, p-1
  static const double space2 = 8;   // gap-2, p-2
  static const double space3 = 12;  // gap-3
  static const double space4 = 16;  // gap-4, p-4
  static const double space5 = 20;  // px-5
  static const double space6 = 24;  // py-6, mb-6
  static const double space10 = 40; // mb-10 (Splash)
  static const double bottomFab = 72; // 등록 버튼 하단에서의 거리 (작을수록 아래로)

  // ─── Border radius (last 폴더 그대로) ───
  static const double radiusLg = 10;   // --radius 0.625rem
  static const double radiusXl = 12;   // rounded-xl
  static const double radius2xl = 16; // rounded-2xl (Stats bar, Nav item)
  static const double radius3xl = 24;  // rounded-3xl (Card outer)
  static const double radiusCardInner = 22; // rounded-[22px]
  static const double radiusFull = 999;     // rounded-full (FAB, badge)
  static const double cardBorderWidth = 3;    // p-[3px] gradient border

  // ─── Header ───
  static const EdgeInsets headerPadding = EdgeInsets.only(left: 20, right: 20, top: 56, bottom: 20); // px-5 pt-14 pb-5

  // ─── Main content ───
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 24); // px-5 py-6

  // ─── Stats bar (내 프로필 + 열람권/등록권/매칭권) ───
  static const double statsBarRadius = 16; // rounded-2xl
  static const EdgeInsets statsBarPadding = EdgeInsets.all(16); // p-4
  static const double statsBarAvatarSize = 48; // w-12 h-12
  static const double statsBarGap = 12; // gap-3
  static const List<BoxShadow> statsBarShadow = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 15, offset: Offset(0, 4)),
  ];

  // ─── Ticket chips (열람권/등록권/매칭권) ───
  static const EdgeInsets ticketChipPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 8); // px-3 py-2
  static const double ticketChipRadius = 12; // rounded-xl
  static const double ticketChipGap = 8;     // gap-2
  static const double ticketLabelFontSize = 9;
  static const double ticketValueFontSize = 12;

  // ─── Profile card grid ───
  static const int gridCrossAxisCount = 3;
  static const double gridGap = 16; // gap-4
  static const double gridBottomSpace = 96; // h-24
  /// 카드 높이/너비 비율. 작을수록 카드가 높아짐 (오버플로우 방지).
  /// 0.50 이하로 두어 96px 폭에서도 셀 높이 ≥192px 되도록 함.
  static const double gridChildAspectRatio = 0.50;

  // ─── Profile card (last MeetZyBoard card) ───
  static const double cardOuterRadius = 24;   // rounded-3xl
  static const double cardInnerRadius = 22;   // rounded-[22px]
  static const EdgeInsets cardInnerPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  static const List<BoxShadow> cardOuterShadow = [
    BoxShadow(color: Color(0x33000000), blurRadius: 25, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x26000000), blurRadius: 10, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> cardInnerShadow = [
    BoxShadow(color: Color(0x80FFFFFF), blurRadius: 2, offset: Offset(0, 1), spreadRadius: 0),
  ];
  static const double cardAvatarSize = 90;   // 아바타 원 (바깥 링과 맞춤)
  static const double cardAvatarRingWidth = 3;
  static const double cardAvatarRingOffset = 0; // 링과 아바타 원 딱 맞게 (간격 없음)
  static const double cardAvatarMarginBottom = 12; // mb-3
  static const double cardNicknameFontSize = 16;  // text-base (예전 사이즈)
  static const double cardNicknameMarginBottom = 6; // mb-1.5
  static const EdgeInsets cardTagPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 6); // px-3 py-1.5
  static const double cardTagFontSize = 12;   // text-xs
  static const double cardTagMaxWidth = 60;   // max-w-[60px] (1줄일 때)
  /// 이상형 등 태그 2줄 허용 시 최대 너비 (카드 여백 활용)
  static const double cardTagMaxWidthTwoLines = 88;
  static const double cardTagGap = 6;        // gap-1.5
  // NEW badge
  static const double badgeTop = 4;   // top-1
  static const double badgeRight = 4; // right-1
  static const EdgeInsets badgePadding = EdgeInsets.symmetric(horizontal: 8, vertical: 2); // px-2 py-0.5
  static const double badgeFontSize = 10;
  static const List<BoxShadow> badgeShadow = [
    BoxShadow(color: Color(0x8010B981), blurRadius: 15, offset: Offset(0, 4)),
  ];

  // ─── FAB (등록 버튼) ───
  static const EdgeInsets fabPadding = EdgeInsets.symmetric(horizontal: 32, vertical: 16); // px-8 py-4
  static const double fabIconSize = 20; // w-5 h-5
  static const double fabFontSize = 16;
  static const FontWeight fabFontWeight = FontWeight.w700;

  // ─── Bottom nav ───
  static const EdgeInsets bottomNavPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 8); // px-3 py-2
  static const double bottomNavItemPadding = 10; // py-2.5
  static const double bottomNavIconSize = 20;    // w-5 h-5
  static const double bottomNavLabelSize = 10;  // text-[10px]
  static const double bottomNavGap = 4;         // gap-1

  // ─── Typography (last theme.css + Tailwind) ───
  static const double text2xl = 24;
  static const double textBase = 16;
  static const double textSm = 14;
  static const double textXs = 12;
}
