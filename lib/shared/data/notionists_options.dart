/// DiceBear notionists 스타일의 모든 편집 가능 옵션 정의.
/// 스키마(https://api.dicebear.com/9.x/notionists/schema.json) 기반으로
/// 확장 가능한 구조로 두었으며, 향후 자체 레이어 시스템으로 교체해도
/// [AvatarOptionCategory] / [AvatarOptionItem] 구조를 재사용할 수 있음.

/// 단일 옵션 값 (value = API query param 값, label = 표시명)
class AvatarOptionItem {
  const AvatarOptionItem({required this.value, required this.label});
  final String value;
  final String label;
}

/// 카테고리: 탭 하나에 대응 (apiKey = DiceBear 쿼리 키)
class AvatarOptionCategory {
  const AvatarOptionCategory({
    required this.apiKey,
    required this.label,
    required this.options,
    this.allowNone = false,
  });
  final String apiKey;
  final String label;
  final List<AvatarOptionItem> options;
  /// true면 "없음"(value: '') 선택 가능
  final bool allowNone;
}

/// variant01 ~ variantNN 생성
List<AvatarOptionItem> _variants(int n, {String prefix = ''}) {
  return List.generate(n, (i) {
    final v = 'variant${(i + 1).toString().padLeft(2, '0')}';
    return AvatarOptionItem(value: v, label: prefix.isEmpty ? v : '$prefix ${i + 1}');
  });
}

/// notionists 전체 카테고리 (style 제외, 선택형 옵션만)
List<AvatarOptionCategory> getNotionistsCategories() {
  return [
    AvatarOptionCategory(
      apiKey: 'backgroundColor',
      label: '배경색',
      allowNone: true,
      options: [
        const AvatarOptionItem(value: '', label: '기본'),
        const AvatarOptionItem(value: 'transparent', label: '투명'),
        const AvatarOptionItem(value: 'b6e3f4', label: '하늘'),
        const AvatarOptionItem(value: 'c0aede', label: '보라'),
        const AvatarOptionItem(value: 'd1d4f9', label: '라벤더'),
        const AvatarOptionItem(value: 'ffd5dc', label: '핑크'),
        const AvatarOptionItem(value: 'ffdfbf', label: '피치'),
      ],
    ),
    AvatarOptionCategory(
      apiKey: 'backgroundType',
      label: '배경 타입',
      options: [
        const AvatarOptionItem(value: 'solid', label: '단색'),
        const AvatarOptionItem(value: 'gradientLinear', label: '그라데이션'),
      ],
    ),
    AvatarOptionCategory(
      apiKey: 'hair',
      label: '헤어',
      options: [
        const AvatarOptionItem(value: 'hat', label: '모자'),
        ..._variants(63, prefix: '헤어'),
      ],
    ),
    AvatarOptionCategory(
      apiKey: 'eyes',
      label: '눈',
      options: _variants(5, prefix: '눈'),
    ),
    AvatarOptionCategory(
      apiKey: 'brows',
      label: '눈썹',
      options: _variants(13, prefix: '눈썹'),
    ),
    AvatarOptionCategory(
      apiKey: 'nose',
      label: '코',
      options: _variants(20, prefix: '코'),
    ),
    AvatarOptionCategory(
      apiKey: 'lips',
      label: '입',
      options: _variants(30, prefix: '입'),
    ),
    AvatarOptionCategory(
      apiKey: 'glasses',
      label: '안경',
      allowNone: true,
      options: [
        const AvatarOptionItem(value: '', label: '없음'),
        ..._variants(11, prefix: '안경'),
      ],
    ),
    AvatarOptionCategory(
      apiKey: 'beard',
      label: '수염',
      allowNone: true,
      options: [
        const AvatarOptionItem(value: '', label: '없음'),
        ..._variants(12, prefix: '수염'),
      ],
    ),
    AvatarOptionCategory(
      apiKey: 'body',
      label: '옷',
      options: _variants(25, prefix: '옷'),
    ),
    AvatarOptionCategory(
      apiKey: 'bodyIcon',
      label: '옷 아이콘',
      allowNone: true,
      options: [
        const AvatarOptionItem(value: '', label: '없음'),
        const AvatarOptionItem(value: 'electric', label: '전기'),
        const AvatarOptionItem(value: 'galaxy', label: '은하'),
        const AvatarOptionItem(value: 'saturn', label: '토성'),
      ],
    ),
    AvatarOptionCategory(
      apiKey: 'gesture',
      label: '제스처',
      options: [
        const AvatarOptionItem(value: 'hand', label: '손'),
        const AvatarOptionItem(value: 'handPhone', label: '손+폰'),
        const AvatarOptionItem(value: 'ok', label: 'OK'),
        const AvatarOptionItem(value: 'okLongArm', label: 'OK 롱암'),
        const AvatarOptionItem(value: 'point', label: '포인트'),
        const AvatarOptionItem(value: 'pointLongArm', label: '포인트 롱암'),
        const AvatarOptionItem(value: 'waveLongArm', label: '손 흔들기'),
        const AvatarOptionItem(value: 'waveLongArms', label: '손 흔들기 양손'),
        const AvatarOptionItem(value: 'waveOkLongArms', label: '손 흔들기+OK'),
        const AvatarOptionItem(value: 'wavePointLongArms', label: '손 흔들기+포인트'),
      ],
    ),
  ];
}
