/// DiceBear lorelei 스타일의 편집 가능 옵션 정의.
/// 스키마(https://api.dicebear.com/9.x/lorelei/schema.json) 기반.

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

/// lorelei 전체 카테고리 (style 제외)
List<AvatarOptionCategory> getLoreleiCategories() {
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
      options: _variants(48, prefix: '헤어'),
    ),
    AvatarOptionCategory(
      apiKey: 'hairColor',
      label: '헤어색',
      allowNone: true,
      options: [
        const AvatarOptionItem(value: '', label: '기본'),
        const AvatarOptionItem(value: '000000', label: '검정'),
        const AvatarOptionItem(value: '4a312c', label: '갈색'),
        const AvatarOptionItem(value: '704214', label: '다크브라운'),
        const AvatarOptionItem(value: 'c0a080', label: '블론드'),
        const AvatarOptionItem(value: 'e6b87c', label: '골드'),
      ],
    ),
    AvatarOptionCategory(
      apiKey: 'eyes',
      label: '눈',
      options: _variants(24, prefix: '눈'),
    ),
    AvatarOptionCategory(
      apiKey: 'eyebrows',
      label: '눈썹',
      options: _variants(13, prefix: '눈썹'),
    ),
    AvatarOptionCategory(
      apiKey: 'nose',
      label: '코',
      options: _variants(6, prefix: '코'),
    ),
    AvatarOptionCategory(
      apiKey: 'mouth',
      label: '입',
      options: [
        ...List.generate(18, (i) => AvatarOptionItem(
            value: 'happy${(i + 1).toString().padLeft(2, '0')}',
            label: '웃음 ${i + 1}')),
        ...List.generate(9, (i) => AvatarOptionItem(
            value: 'sad${(i + 1).toString().padLeft(2, '0')}',
            label: '슬픔 ${i + 1}')),
      ],
    ),
    AvatarOptionCategory(
      apiKey: 'head',
      label: '얼굴형',
      options: _variants(4, prefix: '얼굴'),
    ),
    AvatarOptionCategory(
      apiKey: 'glasses',
      label: '안경',
      allowNone: true,
      options: [
        const AvatarOptionItem(value: '', label: '없음'),
        ..._variants(5, prefix: '안경'),
      ],
    ),
    AvatarOptionCategory(
      apiKey: 'earrings',
      label: '귀걸이',
      allowNone: true,
      options: [
        const AvatarOptionItem(value: '', label: '없음'),
        ..._variants(3, prefix: '귀걸이'),
      ],
    ),
    AvatarOptionCategory(
      apiKey: 'beard',
      label: '수염',
      allowNone: true,
      options: [
        const AvatarOptionItem(value: '', label: '없음'),
        ..._variants(2, prefix: '수염'),
      ],
    ),
    AvatarOptionCategory(
      apiKey: 'freckles',
      label: '주근깨',
      allowNone: true,
      options: [
        const AvatarOptionItem(value: '', label: '없음'),
        const AvatarOptionItem(value: 'variant01', label: '있음'),
      ],
    ),
    AvatarOptionCategory(
      apiKey: 'hairAccessories',
      label: '헤어 악세서리',
      allowNone: true,
      options: [
        const AvatarOptionItem(value: '', label: '없음'),
        const AvatarOptionItem(value: 'flowers', label: '꽃'),
      ],
    ),
  ];
}
