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

/// variant01 ~ variantNN + 라벨 리스트
List<AvatarOptionItem> _variantsWithLabels(int n, List<String> labels) {
  assert(labels.length >= n, 'labels must have at least $n items');
  return List.generate(n, (i) {
    final v = 'variant${(i + 1).toString().padLeft(2, '0')}';
    return AvatarOptionItem(value: v, label: labels[i]);
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
      options: _variantsWithLabels(48, [
        '숏컷', '볼륨 숏', '귀여운 숏', '뾰족 숏', '레이어드 숏', '이모 밥',
        '세미 롱', '긴 생머리', '웨이브 롱', '컬 롱', '스트레이트', '세미 컬',
        '포니테일', '묶은 머리', '올림 머리', '땋은 머리', '반묶음', '측면 가르마',
        '앞머리 있음', '앞머리 없음', '뱅', '시스루 뱅', '자연스러운 숏', '보이쉬 컷',
        '롱 웨이브', '롱 스트레이트', '미디움 웨이브', '미디움 스트레이트', '숏 웨이브',
        '볼륨 롱', '플랫 롱', '레이어드 롱', '쉐기 컷', '울프 컷', '멀렛',
        '픽시 컷', '밥 컷', 'A라인', 'H라인', '내추럴 컬', '타이트 컬',
        '루즈 컬', '빅 컬', '스몰 컬', '웨이브 프린지', '스트레이트 프린지',
        '미디움 컬', '롱 컬',
      ]),
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
      options: _variantsWithLabels(24, [
        '둥근 눈', '가는 눈', '웃는 눈', '반짝 눈', '졸린 눈', '진지한 눈',
        '동그란 눈', '살짝 감은 눈', '크게 뜬 눈', '부드러운 눈', '날카로운 눈',
        '귀여운 눈', '시크한 눈', '밝은 눈', '어두운 눈', '쌍꺼풀 눈',
        '외꺼풀 눈', '내추럴 눈', '도톰 눈', '가는 눈썹 눈', '미소 눈',
        '찡그린 눈', '놀란 눈', '차분한 눈',
      ]),
    ),
    AvatarOptionCategory(
      apiKey: 'eyebrows',
      label: '눈썹',
      options: _variantsWithLabels(13, [
        '얇은 눈썹', '진한 눈썹', '굵은 눈썹', '자연 눈썹', '올라간 눈썹',
        '내려간 눈썹', '일자 눈썹', '활 눈썹', '부드러운 눈썹', '각진 눈썹',
        '짧은 눈썹', '긴 눈썹', '뾰족 눈썹',
      ]),
    ),
    AvatarOptionCategory(
      apiKey: 'nose',
      label: '코',
      options: _variantsWithLabels(6, [
        '둥근 코', '뾰족한 코', '작은 코', '커다란 코', '버튼 코', '직선 코',
      ]),
    ),
    AvatarOptionCategory(
      apiKey: 'mouth',
      label: '입',
      options: [
        ...List.generate(18, (i) => AvatarOptionItem(
            value: 'happy${(i + 1).toString().padLeft(2, '0')}',
            label: ['미소', '환한 웃음', '살짝 웃음', '넓은 웃음', '귀여운 웃음',
              '시크 웃음', '부드러운 미소', '밝은 웃음', '자연스러운 웃음',
              '도톰 입 웃음', '가는 입 웃음', '오므린 웃음', '벌린 웃음',
              '쑥스러운 웃음', '장난스러운 웃음', '따뜻한 웃음', '차분한 웃음', '활짝 웃음'][i])),
        ...List.generate(9, (i) => AvatarOptionItem(
            value: 'sad${(i + 1).toString().padLeft(2, '0')}',
            label: ['슬픈 입', '실망한 입', '찡그린 입', '내려간 입', '작은 슬픔',
              '진지한 입', '무표정 입', '걱정 입', '한숨 입'][i])),
      ],
    ),
    AvatarOptionCategory(
      apiKey: 'head',
      label: '얼굴형',
      options: _variantsWithLabels(4, [
        '둥근 얼굴', '갸름한 얼굴', '각진 얼굴', '타원형 얼굴',
      ]),
    ),
    AvatarOptionCategory(
      apiKey: 'glasses',
      label: '안경',
      allowNone: true,
      options: [
        const AvatarOptionItem(value: '', label: '없음'),
        ..._variantsWithLabels(5, [
          '둥근 안경', '사각 안경', '각진 안경', '무테 안경', '캣아이 안경',
        ]),
      ],
    ),
    AvatarOptionCategory(
      apiKey: 'earrings',
      label: '귀걸이',
      allowNone: true,
      options: [
        const AvatarOptionItem(value: '', label: '없음'),
        ..._variantsWithLabels(3, [
          '링 귀걸이', '드롭 귀걸이', '스터드 귀걸이',
        ]),
      ],
    ),
    AvatarOptionCategory(
      apiKey: 'beard',
      label: '수염',
      allowNone: true,
      options: [
        const AvatarOptionItem(value: '', label: '없음'),
        ..._variantsWithLabels(2, [
          '콧수염', '턱수염',
        ]),
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
