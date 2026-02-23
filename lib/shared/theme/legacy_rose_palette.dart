import 'package:flutter/material.dart';

/// 원래 앱에서 쓰던 핑크/로즈 팔레트.
/// 학교별 primaryColor로 테마를 쓰기 전 기본 색상이었고, 나중에 참고용으로 보관.
class LegacyRosePalette {
  LegacyRosePalette._();

  /// 메인 로즈 (기존 버튼·강조색)
  static const Color rose500 = Color(0xFFF43F5E);

  /// 조금 더 연한 로즈 (그라데이션·채팅 버블 등)
  static const Color rose400 = Color(0xFFFB7185);

  /// 핑크 (그라데이션 보조)
  static const Color pink500 = Color(0xFFEC4899);
  static const Color pink400 = Color(0xFFF472B6);

  /// 연한 배경/태그용
  static const Color rose50 = Color(0xFFFFF1F2);
  static const Color rose300 = Color(0xFFFDA4AF);

  /// 기본 2색 그라데이션 (헤더·버튼용)
  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [rose400, rose500],
  );

  /// 3색 그라데이션 (프로필 모달 헤더 등)
  static const LinearGradient gradientWide = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [rose400, pink400, rose500],
  );
}
