// Avatar Parts Data and Drawing Functions

export const SKIN_TONES = [
  '#FFE0D2',
  '#F0C4AA',
  '#D6A480',
  '#B27E5C',
  '#764E3A',
];

export const FACE_SHAPES = [
  { id: 'round', name: '둥근형' },
  { id: 'long', name: '긴형' },
  { id: 'slim', name: '슬림형' },
  { id: 'angular', name: '각진형' },
  { id: 'soft-square', name: '부드러운 사각형' },
];

export const HAIR_BACK = [
  { id: 'none', name: '없음' },
  { id: 'short-back', name: '짧은 머리' },
  { id: 'medium-back', name: '중간 머리' },
  { id: 'long-back', name: '긴 머리' },
  { id: 'wavy-back', name: '웨이브' },
  { id: 'bun-back', name: '묶은 머리' },
  { id: 'ponytail-back', name: '포니테일' },
  { id: 'bob-back', name: '단발' },
  { id: 'pixie-back', name: '픽시컷' },
  { id: 'curly-back', name: '곱슬' },
  { id: 'slick-back', name: '올백' },
];

export const EYES = [
  { id: 'normal', name: '보통' },
  { id: 'happy', name: '웃는 눈' },
  { id: 'sleepy', name: '졸린 눈' },
  { id: 'fox', name: '여우눈' },
  { id: 'wink', name: '윙크' },
  { id: 'sanpakgan', name: '삼백안' },
];

export const MOUTHS = [
  { id: 'neutral', name: '무표정' },
  { id: 'smile', name: '미소' },
  { id: 'pout', name: '삐죽' },
];

export const HAIR_FRONT = [
  { id: 'bangs', name: '일자 앞머리' },
  { id: 'side-swept', name: '옆으로 넘긴' },
  { id: 'choppy', name: '시스루' },
  { id: 'wispy', name: '가벼운' },
  { id: 'no-bangs', name: '앞머리 없음' },
  { id: 'short-bangs', name: '짧은 앞머리' },
  { id: 'messy', name: '흐트러진' },
];

export const CLOTHES = [
  { id: 'tshirt', name: '티셔츠' },
  { id: 'hoodie', name: '후드티' },
  { id: 'shirt', name: '셔츠' },
  { id: 'sweater', name: '스웨터' },
  { id: 'vneck', name: 'V넥' },
  { id: 'polo', name: '폴로' },
  { id: 'jacket', name: '재킷' },
  { id: 'cardigan', name: '가디건' },
  { id: 'blazer', name: '블레이저' },
  { id: 'tank', name: '민소매' },
];

export const ACCESSORIES = [
  { id: 'none', name: '없음' },
  { id: 'glasses', name: '안경' },
  { id: 'sunglasses', name: '선글라스' },
  { id: 'round-glasses', name: '동그란 안경' },
  { id: 'earrings', name: '귀걸이' },
];

export const HAIR_COLORS = [
  '#91969B',
  '#E6DCC3',
  '#73192D',
  '#1E375F',
  '#5C301C',
  '#000000',
];

export const CLOTHES_COLORS = [
  '#546E7A',
  '#78909C',
  '#90A4AE',
  '#B0BEC5',
  '#CFD8DC',
  '#607D8B',
];

// Drawing Functions
export function drawFaceBase(
  ctx: CanvasRenderingContext2D,
  faceShape: string,
  skinTone: string
) {
  const centerX = 256;
  const centerY = 256;
  
  // 귀를 먼저 그리기 (얼굴 뒤로)
  drawEars(ctx, skinTone);
  
  ctx.fillStyle = skinTone;
  ctx.strokeStyle = '#3E2723';
  ctx.lineWidth = 4;

  ctx.beginPath();
  
  switch (faceShape) {
    case 'round':
      // 애니메이션 스타일 - 둥근 얼굴에 뾰족한 턱 (약간 크게)
      ctx.moveTo(centerX, centerY - 120);
      // 왼쪽 상단 (둥근 이마)
      ctx.bezierCurveTo(
        centerX - 72, centerY - 120,
        centerX - 90, centerY - 93,
        centerX - 93, centerY - 55
      );
      // 왼쪽 중간 (둥근 뺨 - 덜 빵빵함)
      ctx.bezierCurveTo(
        centerX - 96, centerY - 11,
        centerX - 96, centerY + 33,
        centerX - 88, centerY + 66
      );
      // 왼쪽 아래 (턱으로 좁아짐)
      ctx.bezierCurveTo(
        centerX - 75, centerY + 93,
        centerX - 46, centerY + 110,
        centerX - 20, centerY + 118
      );
      // 뾰족한 턱
      ctx.bezierCurveTo(
        centerX - 8, centerY + 123,
        centerX + 8, centerY + 123,
        centerX + 20, centerY + 118
      );
      // 오른쪽 아래
      ctx.bezierCurveTo(
        centerX + 46, centerY + 110,
        centerX + 75, centerY + 93,
        centerX + 88, centerY + 66
      );
      // 오른쪽 중간 (둥근 뺨 - 덜 빵빵함)
      ctx.bezierCurveTo(
        centerX + 96, centerY + 33,
        centerX + 96, centerY - 11,
        centerX + 93, centerY - 55
      );
      // 오른쪽 상단 (둥근 이마)
      ctx.bezierCurveTo(
        centerX + 90, centerY - 93,
        centerX + 72, centerY - 120,
        centerX, centerY - 120
      );
      ctx.closePath();
      break;
    case 'long':
      // 애니메이션 스타일 - 긴형
      ctx.moveTo(centerX, centerY - 125);
      ctx.bezierCurveTo(
        centerX - 70, centerY - 125,
        centerX - 88, centerY - 95,
        centerX - 92, centerY - 55
      );
      ctx.bezierCurveTo(
        centerX - 95, centerY - 10,
        centerX - 95, centerY + 35,
        centerX - 88, centerY + 70
      );
      ctx.bezierCurveTo(
        centerX - 75, centerY + 95,
        centerX - 45, centerY + 110,
        centerX - 18, centerY + 120
      );
      ctx.bezierCurveTo(
        centerX - 7, centerY + 125,
        centerX + 7, centerY + 125,
        centerX + 18, centerY + 120
      );
      ctx.bezierCurveTo(
        centerX + 45, centerY + 110,
        centerX + 75, centerY + 95,
        centerX + 88, centerY + 70
      );
      ctx.bezierCurveTo(
        centerX + 95, centerY + 35,
        centerX + 95, centerY - 10,
        centerX + 92, centerY - 55
      );
      ctx.bezierCurveTo(
        centerX + 88, centerY - 95,
        centerX + 70, centerY - 125,
        centerX, centerY - 125
      );
      ctx.closePath();
      break;
    case 'slim':
      // 애니메이션 스타일 - 슬림형
      ctx.moveTo(centerX, centerY - 115);
      ctx.bezierCurveTo(
        centerX - 68, centerY - 115,
        centerX - 85, centerY - 88,
        centerX - 88, centerY - 50
      );
      ctx.bezierCurveTo(
        centerX - 90, centerY - 8,
        centerX - 90, centerY + 32,
        centerX - 83, centerY + 65
      );
      ctx.bezierCurveTo(
        centerX - 70, centerY + 88,
        centerX - 42, centerY + 102,
        centerX - 16, centerY + 110
      );
      ctx.bezierCurveTo(
        centerX - 6, centerY + 114,
        centerX + 6, centerY + 114,
        centerX + 16, centerY + 110
      );
      ctx.bezierCurveTo(
        centerX + 42, centerY + 102,
        centerX + 70, centerY + 88,
        centerX + 83, centerY + 65
      );
      ctx.bezierCurveTo(
        centerX + 90, centerY + 32,
        centerX + 90, centerY - 8,
        centerX + 88, centerY - 50
      );
      ctx.bezierCurveTo(
        centerX + 85, centerY - 88,
        centerX + 68, centerY - 115,
        centerX, centerY - 115
      );
      ctx.closePath();
      break;
    case 'angular':
      // 애니메이션 스타일 - 각진형
      ctx.moveTo(centerX, centerY - 110);
      ctx.bezierCurveTo(
        centerX - 65, centerY - 113,
        centerX - 88, centerY - 95,
        centerX - 98, centerY - 60
      );
      ctx.bezierCurveTo(
        centerX - 105, centerY - 20,
        centerX - 105, centerY + 25,
        centerX - 98, centerY + 60
      );
      ctx.bezierCurveTo(
        centerX - 85, centerY + 85,
        centerX - 55, centerY + 100,
        centerX - 22, centerY + 110
      );
      ctx.bezierCurveTo(
        centerX - 9, centerY + 114,
        centerX + 9, centerY + 114,
        centerX + 22, centerY + 110
      );
      ctx.bezierCurveTo(
        centerX + 55, centerY + 100,
        centerX + 85, centerY + 85,
        centerX + 98, centerY + 60
      );
      ctx.bezierCurveTo(
        centerX + 105, centerY + 25,
        centerX + 105, centerY - 20,
        centerX + 98, centerY - 60
      );
      ctx.bezierCurveTo(
        centerX + 88, centerY - 95,
        centerX + 65, centerY - 113,
        centerX, centerY - 110
      );
      ctx.closePath();
      break;
    case 'soft-square':
      // 애니메이션 스타일 - 부드러운 사각형
      ctx.moveTo(centerX, centerY - 108);
      ctx.bezierCurveTo(
        centerX - 70, centerY - 112,
        centerX - 92, centerY - 90,
        centerX - 98, centerY - 50
      );
      ctx.bezierCurveTo(
        centerX - 102, centerY - 8,
        centerX - 102, centerY + 30,
        centerX - 95, centerY + 62
      );
      ctx.bezierCurveTo(
        centerX - 82, centerY + 87,
        centerX - 52, centerY + 102,
        centerX - 20, centerY + 110
      );
      ctx.bezierCurveTo(
        centerX - 8, centerY + 113,
        centerX + 8, centerY + 113,
        centerX + 20, centerY + 110
      );
      ctx.bezierCurveTo(
        centerX + 52, centerY + 102,
        centerX + 82, centerY + 87,
        centerX + 95, centerY + 62
      );
      ctx.bezierCurveTo(
        centerX + 102, centerY + 30,
        centerX + 102, centerY - 8,
        centerX + 98, centerY - 50
      );
      ctx.bezierCurveTo(
        centerX + 92, centerY - 90,
        centerX + 70, centerY - 112,
        centerX, centerY - 108
      );
      ctx.closePath();
      break;
    default:
      // 기본 애니메이션 스타일
      ctx.moveTo(centerX, centerY - 110);
      ctx.bezierCurveTo(
        centerX - 75, centerY - 110,
        centerX - 95, centerY - 85,
        centerX - 100, centerY - 50
      );
      ctx.bezierCurveTo(
        centerX - 103, centerY - 10,
        centerX - 103, centerY + 30,
        centerX - 95, centerY + 60
      );
      ctx.bezierCurveTo(
        centerX - 80, centerY + 85,
        centerX - 50, centerY + 100,
        centerX - 20, centerY + 108
      );
      ctx.bezierCurveTo(
        centerX - 8, centerY + 112,
        centerX + 8, centerY + 112,
        centerX + 20, centerY + 108
      );
      ctx.bezierCurveTo(
        centerX + 50, centerY + 100,
        centerX + 80, centerY + 85,
        centerX + 95, centerY + 60
      );
      ctx.bezierCurveTo(
        centerX + 103, centerY + 30,
        centerX + 103, centerY - 10,
        centerX + 100, centerY - 50
      );
      ctx.bezierCurveTo(
        centerX + 95, centerY - 85,
        centerX + 75, centerY - 110,
        centerX, centerY - 110
      );
      ctx.closePath();
  }
  
  ctx.fill();
  ctx.stroke();
  
  // 홍조 그리기
  drawBlush(ctx);
  
  // 위쪽 눈꺼풀을 피부색으로 눈 위에 그리기
  drawEyelids(ctx, skinTone);
}

// 귀 그리기 함수
function drawEars(ctx: CanvasRenderingContext2D, skinTone: string) {
  const centerX = 256;
  const centerY = 256;
  
  ctx.fillStyle = skinTone;
  ctx.strokeStyle = '#3E2723';
  ctx.lineWidth = 3;
  
  // 왼쪽 귀
  ctx.beginPath();
  ctx.ellipse(centerX - 98, centerY + 5, 18, 28, -0.2, 0, Math.PI * 2);
  ctx.fill();
  ctx.stroke();
  
  // 왼쪽 귀 안쪽
  ctx.fillStyle = adjustBrightness(skinTone, -15);
  ctx.beginPath();
  ctx.ellipse(centerX - 98, centerY + 5, 8, 14, -0.2, 0, Math.PI * 2);
  ctx.fill();
  
  // 오른쪽 귀
  ctx.fillStyle = skinTone;
  ctx.beginPath();
  ctx.ellipse(centerX + 98, centerY + 5, 18, 28, 0.2, 0, Math.PI * 2);
  ctx.fill();
  ctx.stroke();
  
  // 오른쪽 귀 안쪽
  ctx.fillStyle = adjustBrightness(skinTone, -15);
  ctx.beginPath();
  ctx.ellipse(centerX + 98, centerY + 5, 8, 14, 0.2, 0, Math.PI * 2);
  ctx.fill();
}

// 홍조 그리기 함수
function drawBlush(ctx: CanvasRenderingContext2D) {
  const centerX = 256;
  const centerY = 256;
  
  ctx.fillStyle = 'rgba(255, 150, 150, 0.3)';
  
  // 왼쪽 볼 홍조
  ctx.beginPath();
  ctx.ellipse(centerX - 55, centerY + 25, 22, 15, 0, 0, Math.PI * 2);
  ctx.fill();
  
  // 오른쪽 볼 홍조
  ctx.beginPath();
  ctx.ellipse(centerX + 55, centerY + 25, 22, 15, 0, 0, Math.PI * 2);
  ctx.fill();
}

// 색상 밝기 조정 함수
function adjustBrightness(color: string, amount: number): string {
  const hex = color.replace('#', '');
  const r = Math.max(0, Math.min(255, parseInt(hex.substr(0, 2), 16) + amount));
  const g = Math.max(0, Math.min(255, parseInt(hex.substr(2, 2), 16) + amount));
  const b = Math.max(0, Math.min(255, parseInt(hex.substr(4, 2), 16) + amount));
  return `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`;
}

export function drawHairBack(
  ctx: CanvasRenderingContext2D,
  hairStyle: string,
  hairColor: string
) {
  const centerX = 256;
  const centerY = 256;
  
  ctx.fillStyle = hairColor;
  ctx.strokeStyle = '#000000';
  ctx.lineWidth = 4;

  switch (hairStyle) {
    case 'none':
      // 뒷머리 없음 - 아무것도 그리지 않음
      break;
    case 'short-back':
      ctx.beginPath();
      ctx.ellipse(centerX, centerY - 80, 100, 65, 0, 0, Math.PI, true);
      ctx.lineTo(centerX + 100, centerY + 15);
      ctx.lineTo(centerX - 100, centerY + 15);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      break;
    case 'medium-back':
      ctx.beginPath();
      ctx.ellipse(centerX, centerY - 80, 105, 80, 0, 0, Math.PI, true);
      ctx.lineTo(centerX + 105, centerY + 50);
      ctx.lineTo(centerX - 105, centerY + 50);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      break;
    case 'long-back':
      ctx.beginPath();
      ctx.ellipse(centerX, centerY - 80, 108, 85, 0, 0, Math.PI, true);
      ctx.lineTo(centerX + 108, centerY + 130);
      ctx.lineTo(centerX - 108, centerY + 130);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      break;
    case 'wavy-back':
      ctx.beginPath();
      ctx.ellipse(centerX, centerY - 80, 110, 82, 0, 0, Math.PI, true);
      ctx.lineTo(centerX + 110, centerY + 90);
      ctx.lineTo(centerX - 110, centerY + 90);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      break;
    case 'bun-back':
      ctx.beginPath();
      ctx.ellipse(centerX, centerY - 80, 105, 70, 0, 0, Math.PI, true);
      ctx.lineTo(centerX + 105, centerY + 20);
      ctx.lineTo(centerX - 105, centerY + 20);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      // Bun
      ctx.beginPath();
      ctx.arc(centerX, centerY - 170, 40, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
      break;
    case 'ponytail-back':
      ctx.beginPath();
      ctx.ellipse(centerX, centerY - 80, 105, 70, 0, 0, Math.PI, true);
      ctx.lineTo(centerX + 105, centerY + 20);
      ctx.lineTo(centerX - 105, centerY + 20);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      // Ponytail - 옆으로 빠지게
      ctx.beginPath();
      ctx.moveTo(centerX - 20, centerY - 20);
      ctx.quadraticCurveTo(centerX - 60, centerY + 20, centerX - 80, centerY + 80);
      ctx.quadraticCurveTo(centerX - 85, centerY + 120, centerX - 75, centerY + 160);
      ctx.lineTo(centerX - 65, centerY + 160);
      ctx.quadraticCurveTo(centerX - 75, centerY + 120, centerX - 70, centerY + 80);
      ctx.quadraticCurveTo(centerX - 50, centerY + 20, centerX - 10, centerY - 20);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      break;
    case 'bob-back':
      ctx.beginPath();
      ctx.ellipse(centerX, centerY - 80, 105, 80, 0, 0, Math.PI, true);
      ctx.lineTo(centerX + 105, centerY + 65);
      ctx.lineTo(centerX - 105, centerY + 65);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      break;
    case 'pixie-back':
      ctx.beginPath();
      ctx.ellipse(centerX, centerY - 80, 98, 60, 0, 0, Math.PI, true);
      ctx.lineTo(centerX + 98, centerY + 5);
      ctx.lineTo(centerX - 98, centerY + 5);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      break;
    case 'curly-back':
      ctx.beginPath();
      ctx.ellipse(centerX, centerY - 80, 115, 95, 0, 0, Math.PI, true);
      ctx.lineTo(centerX + 115, centerY + 95);
      ctx.lineTo(centerX - 115, centerY + 95);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      break;
    case 'slick-back':
      ctx.beginPath();
      ctx.ellipse(centerX, centerY - 80, 103, 68, 0, 0, Math.PI, true);
      ctx.lineTo(centerX + 103, centerY + 25);
      ctx.lineTo(centerX - 103, centerY + 25);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      break;
  }
}

export function drawEyes(
  ctx: CanvasRenderingContext2D,
  eyeStyle: string
) {
  const centerX = 256;
  const centerY = 256;
  const eyeY = centerY - 5; // -15에서 -5로 변경 (10px 아래로)
  
  ctx.strokeStyle = '#3E2723';
  ctx.lineWidth = 3;

  switch (eyeStyle) {
    case 'normal':
      // 애니메이션 스타일 - 기본 눈
      drawAnimeEye(ctx, centerX - 45, eyeY, 1, 1);
      drawAnimeEye(ctx, centerX + 45, eyeY, 1, 1);
      break;
    case 'happy':
      // 웃는 눈 - ^^ 모양
      ctx.lineWidth = 4;
      ctx.lineCap = 'round';
      
      // 왼쪽 눈 ^
      ctx.beginPath();
      ctx.moveTo(centerX - 65, eyeY);
      ctx.quadraticCurveTo(centerX - 45, eyeY - 15, centerX - 25, eyeY);
      ctx.stroke();
      
      // 오른쪽 눈 ^
      ctx.beginPath();
      ctx.moveTo(centerX + 25, eyeY);
      ctx.quadraticCurveTo(centerX + 45, eyeY - 15, centerX + 65, eyeY);
      ctx.stroke();
      break;
    case 'sleepy':
      // 졸린 눈 - -- 모양
      ctx.lineWidth = 3;
      ctx.lineCap = 'round';
      
      // 왼쪽 눈 -
      ctx.beginPath();
      ctx.moveTo(centerX - 65, eyeY);
      ctx.lineTo(centerX - 25, eyeY);
      ctx.stroke();
      
      // 오른쪽 눈 -
      ctx.beginPath();
      ctx.moveTo(centerX + 25, eyeY);
      ctx.lineTo(centerX + 65, eyeY);
      ctx.stroke();
      break;
    case 'fox':
      // 여우눈 - 흰자와 홍채가 위쪽으로
      drawFoxEye(ctx, centerX - 45, eyeY);
      drawFoxEye(ctx, centerX + 45, eyeY);
      break;
    case 'focused':
      // 집중한 눈 - 좀 더 날카롭게
      drawAnimeEye(ctx, centerX - 45, eyeY, 0.9, 1);
      drawAnimeEye(ctx, centerX + 45, eyeY, 0.9, 1);
      // 눈썹을 더 가깝게
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.moveTo(centerX - 65, eyeY - 35);
      ctx.quadraticCurveTo(centerX - 45, eyeY - 32, centerX - 25, eyeY - 35);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(centerX + 25, eyeY - 35);
      ctx.quadraticCurveTo(centerX + 45, eyeY - 32, centerX + 65, eyeY - 35);
      ctx.stroke();
      break;
    case 'wink':
      // 왼쪽 눈은 보통 눈
      drawAnimeEye(ctx, centerX - 45, eyeY, 1, 1);
      
      // 오른쪽 눈은 웃는 눈 ^
      ctx.lineWidth = 4;
      ctx.lineCap = 'round';
      ctx.beginPath();
      ctx.moveTo(centerX + 25, eyeY);
      ctx.quadraticCurveTo(centerX + 45, eyeY - 15, centerX + 65, eyeY);
      ctx.stroke();
      
      // 왼쪽 눈썹만
      ctx.lineWidth = 3;
      ctx.strokeStyle = '#3E2723';
      ctx.lineCap = 'round';
      ctx.beginPath();
      ctx.moveTo(centerX - 70, eyeY - 40);
      ctx.quadraticCurveTo(centerX - 45, eyeY - 42, centerX - 20, eyeY - 38);
      ctx.stroke();
      break;
    case 'sanpakgan':
      // 삼백안 - 홍채가 위쪽으로, 아래 흰자 많이 보임
      drawSanpakganEye(ctx, centerX - 45, eyeY);
      drawSanpakganEye(ctx, centerX + 45, eyeY);
      break;
    case 'narrow':
      // 좁은 눈
      drawAnimeEye(ctx, centerX - 45, eyeY + 3, 0.8, 0.6);
      drawAnimeEye(ctx, centerX + 45, eyeY + 3, 0.8, 0.6);
      break;
  }
  
  // 눈썹 그리기 (집중한 눈, 웃는 눈, 졸린 눈 제외)
  if (eyeStyle !== 'focused' && eyeStyle !== 'happy' && eyeStyle !== 'sleepy') {
    ctx.lineWidth = 3;
    ctx.strokeStyle = '#3E2723';
    ctx.lineCap = 'round';
    
    // 왼쪽 눈썹
    ctx.beginPath();
    ctx.moveTo(centerX - 70, eyeY - 40);
    ctx.quadraticCurveTo(centerX - 45, eyeY - 42, centerX - 20, eyeY - 38);
    ctx.stroke();
    
    // 오른쪽 눈썹
    ctx.beginPath();
    ctx.moveTo(centerX + 20, eyeY - 38);
    ctx.quadraticCurveTo(centerX + 45, eyeY - 42, centerX + 70, eyeY - 40);
    ctx.stroke();
  }
}

// 애니메이션 스타일 눈 그리기 함수
function drawAnimeEye(
  ctx: CanvasRenderingContext2D, 
  x: number, 
  y: number, 
  scaleX: number = 1, 
  scaleY: number = 1
) {
  ctx.save();
  ctx.translate(x, y);
  ctx.scale(scaleX, scaleY);
  
  // 먼저 눈꺼풀 아래 부분만 그리기 (위쪽은 나중에 덮음)
  ctx.fillStyle = '#FFFFFF';
  ctx.strokeStyle = '#3E2723';
  ctx.lineWidth = 3;
  
  ctx.beginPath();
  ctx.ellipse(0, 0, 22, 26, 0, 0, Math.PI * 2);
  ctx.fill();
  ctx.stroke();
  
  // 홍채 (갈색 그라데이션)
  const gradient = ctx.createRadialGradient(0, 2, 0, 0, 2, 14);
  gradient.addColorStop(0, '#D4A574');
  gradient.addColorStop(0.5, '#8D6E63');
  gradient.addColorStop(1, '#6D4C41');
  
  ctx.fillStyle = gradient;
  ctx.beginPath();
  ctx.ellipse(0, 2, 14, 16, 0, 0, Math.PI * 2);
  ctx.fill();
  
  // 동공
  ctx.fillStyle = '#1A1A1A';
  ctx.beginPath();
  ctx.ellipse(0, 3, 6, 8, 0, 0, Math.PI * 2);
  ctx.fill();
  
  // 하이라이트 (�� 것)
  ctx.fillStyle = 'rgba(255, 255, 255, 0.9)';
  ctx.beginPath();
  ctx.ellipse(-6, -6, 6, 8, -0.3, 0, Math.PI * 2);
  ctx.fill();
  
  // 하이라이트 (작은 것)
  ctx.fillStyle = 'rgba(255, 255, 255, 0.7)';
  ctx.beginPath();
  ctx.arc(5, 8, 3, 0, Math.PI * 2);
  ctx.fill();
  
  // 아래쪽 눈꺼풀 라인
  ctx.strokeStyle = '#3E2723';
  ctx.lineWidth = 2.5;
  ctx.lineCap = 'round';
  ctx.beginPath();
  ctx.arc(0, 2, 23, Math.PI * 0.15, Math.PI * 0.85);
  ctx.stroke();
  
  ctx.restore();
}

// 삼백안 눈 그리기 함수
function drawSanpakganEye(
  ctx: CanvasRenderingContext2D, 
  x: number, 
  y: number
) {
  ctx.save();
  ctx.translate(x, y);
  
  // 클리핑 영역 설정 - 반달 모양만 보이도록
  ctx.beginPath();
  ctx.arc(0, 0, 22, 0, Math.PI);
  ctx.clip();
  
  // 흰자위 - 반달 모양 (위쪽이 잘림)
  ctx.fillStyle = '#FFFFFF';
  ctx.beginPath();
  ctx.arc(0, 0, 22, 0, Math.PI);
  ctx.closePath();
  ctx.fill();
  
  // 홍채 (갈색 그라데이션) - y=0에 배치해서 정확히 절반만 보이게
  const gradient = ctx.createRadialGradient(0, 0, 0, 0, 0, 14);
  gradient.addColorStop(0, '#D4A574');
  gradient.addColorStop(0.5, '#8D6E63');
  gradient.addColorStop(1, '#6D4C41');
  
  ctx.fillStyle = gradient;
  ctx.beginPath();
  ctx.arc(0, 0, 14, 0, Math.PI * 2);
  ctx.fill();
  
  // 동공 - 홍채 중심에
  ctx.fillStyle = '#1A1A1A';
  ctx.beginPath();
  ctx.arc(0, 2, 6, 0, Math.PI * 2);
  ctx.fill();
  
  // 하이라이트 (큰 것) - 보이는 아래쪽 부분에
  ctx.fillStyle = 'rgba(255, 255, 255, 0.9)';
  ctx.beginPath();
  ctx.ellipse(-5, 5, 5, 7, -0.3, 0, Math.PI * 2);
  ctx.fill();
  
  // 하이라이트 (작은 것)
  ctx.fillStyle = 'rgba(255, 255, 255, 0.7)';
  ctx.beginPath();
  ctx.arc(5, 8, 3, 0, Math.PI * 2);
  ctx.fill();
  
  ctx.restore();
  
  // 외곽선 - 클리핑 없이 그리기
  ctx.save();
  ctx.translate(x, y);
  ctx.strokeStyle = '#3E2723';
  ctx.lineWidth = 3;
  ctx.beginPath();
  ctx.arc(0, 0, 22, 0, Math.PI);
  ctx.stroke();
  
  // 위쪽 직선 라인 (눈꺼풀)
  ctx.lineCap = 'round';
  ctx.beginPath();
  ctx.moveTo(-22, 0);
  ctx.lineTo(22, 0);
  ctx.stroke();
  
  ctx.restore();
}

// 여우눈 그리기 함수 - 삼백안을 위아래로 뒤집음
function drawFoxEye(
  ctx: CanvasRenderingContext2D, 
  x: number, 
  y: number
) {
  ctx.save();
  ctx.translate(x, y);
  
  // 클리핑 영역 설정 - 반달 모양만 보이도록 (아래쪽이 잘림)
  ctx.beginPath();
  ctx.arc(0, 0, 22, Math.PI, 0);
  ctx.clip();
  
  // 흰자위 - 반달 모양 (아래쪽이 잘림)
  ctx.fillStyle = '#FFFFFF';
  ctx.beginPath();
  ctx.arc(0, 0, 22, Math.PI, 0);
  ctx.closePath();
  ctx.fill();
  
  // 홍채 (갈색 그라데이션) - 아래로 더 많이 내림
  const gradient = ctx.createRadialGradient(0, 7, 0, 0, 7, 14);
  gradient.addColorStop(0, '#D4A574');
  gradient.addColorStop(0.5, '#8D6E63');
  gradient.addColorStop(1, '#6D4C41');
  
  ctx.fillStyle = gradient;
  ctx.beginPath();
  ctx.arc(0, 7, 14, 0, Math.PI * 2);
  ctx.fill();
  
  // 동공 - 홍채 중심에 (아래로)
  ctx.fillStyle = '#1A1A1A';
  ctx.beginPath();
  ctx.arc(0, 5, 6, 0, Math.PI * 2);
  ctx.fill();
  
  // 하이라이트 (큰 것) - 보이는 위쪽 부분에
  ctx.fillStyle = 'rgba(255, 255, 255, 0.9)';
  ctx.beginPath();
  ctx.ellipse(-5, 2, 5, 7, -0.3, 0, Math.PI * 2);
  ctx.fill();
  
  // 하이라이트 (작은 것)
  ctx.fillStyle = 'rgba(255, 255, 255, 0.7)';
  ctx.beginPath();
  ctx.arc(5, -1, 3, 0, Math.PI * 2);
  ctx.fill();
  
  ctx.restore();
  
  // 외곽선 - 클리핑 없이 그리기
  ctx.save();
  ctx.translate(x, y);
  ctx.strokeStyle = '#3E2723';
  ctx.lineWidth = 3;
  ctx.beginPath();
  ctx.arc(0, 0, 22, Math.PI, 0);
  ctx.stroke();
  
  // 아래쪽 직선 라인 (눈꺼풀)
  ctx.lineCap = 'round';
  ctx.beginPath();
  ctx.moveTo(-22, 0);
  ctx.lineTo(22, 0);
  ctx.stroke();
  
  ctx.restore();
}

export function drawMouth(
  ctx: CanvasRenderingContext2D,
  mouthStyle: string
) {
  const centerX = 256;
  const centerY = 256;
  const mouthY = centerY + 65; // +50에서 +65로 변경 (15px 아래로)
  
  ctx.strokeStyle = '#3E2723';
  ctx.lineWidth = 3;
  ctx.lineCap = 'round';

  switch (mouthStyle) {
    case 'neutral':
      ctx.beginPath();
      ctx.moveTo(centerX - 20, mouthY);
      ctx.lineTo(centerX + 20, mouthY);
      ctx.stroke();
      break;
    case 'smile':
      // 입꼬리 낮춤 - 더 은은한 미소
      ctx.beginPath();
      ctx.arc(centerX, mouthY + 2, 18, 0.3, Math.PI - 0.3); // 반지름 줄이고 각도 조정
      ctx.stroke();
      break;
    case 'pout':
      ctx.fillStyle = '#FFB6C1';
      ctx.beginPath();
      ctx.ellipse(centerX, mouthY, 12, 8, 0, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
      break;
  }
}

export function drawHairFront(
  ctx: CanvasRenderingContext2D,
  hairStyle: string,
  hairColor: string
) {
  const centerX = 256;
  const centerY = 256;
  
  ctx.fillStyle = hairColor;
  ctx.strokeStyle = '#000000';
  ctx.lineWidth = 1;

  switch (hairStyle) {
    case 'bangs':
      ctx.beginPath();
      ctx.arc(centerX, centerY - 50, 100, Math.PI, 0); // -30에서 -50으로 상승
      ctx.lineTo(centerX + 100, centerY - 70);
      // 자연스러운 앞머리 끝단
      ctx.quadraticCurveTo(centerX + 80, centerY - 35, centerX + 70, centerY - 30);
      ctx.quadraticCurveTo(centerX + 50, centerY - 35, centerX + 40, centerY - 28);
      ctx.quadraticCurveTo(centerX + 20, centerY - 32, centerX, centerY - 30);
      ctx.quadraticCurveTo(centerX - 20, centerY - 32, centerX - 40, centerY - 28);
      ctx.quadraticCurveTo(centerX - 50, centerY - 35, centerX - 70, centerY - 30);
      ctx.quadraticCurveTo(centerX - 80, centerY - 35, centerX - 100, centerY - 70);
      ctx.closePath();
      ctx.fill();
      // 양옆과 아래만 외곽선
      ctx.beginPath();
      ctx.moveTo(centerX - 100, centerY - 70);
      ctx.quadraticCurveTo(centerX - 80, centerY - 35, centerX - 70, centerY - 30);
      ctx.quadraticCurveTo(centerX - 50, centerY - 35, centerX - 40, centerY - 28);
      ctx.quadraticCurveTo(centerX - 20, centerY - 32, centerX, centerY - 30);
      ctx.quadraticCurveTo(centerX + 20, centerY - 32, centerX + 40, centerY - 28);
      ctx.quadraticCurveTo(centerX + 50, centerY - 35, centerX + 70, centerY - 30);
      ctx.quadraticCurveTo(centerX + 80, centerY - 35, centerX + 100, centerY - 70);
      ctx.stroke();
      break;
    case 'side-swept':
      ctx.beginPath();
      ctx.arc(centerX, centerY - 50, 100, Math.PI, 0); // -30에서 -50으로 상승
      ctx.lineTo(centerX + 100, centerY - 70);
      ctx.quadraticCurveTo(centerX + 85, centerY - 50, centerX + 70, centerY - 45);
      ctx.quadraticCurveTo(centerX + 40, centerY - 70, centerX, centerY - 80);
      ctx.quadraticCurveTo(centerX - 50, centerY - 90, centerX - 100, centerY - 80);
      ctx.closePath();
      ctx.fill();
      // 양옆과 아래만 외곽선
      ctx.beginPath();
      ctx.moveTo(centerX - 100, centerY - 80);
      ctx.quadraticCurveTo(centerX - 50, centerY - 90, centerX, centerY - 80);
      ctx.quadraticCurveTo(centerX + 40, centerY - 70, centerX + 70, centerY - 45);
      ctx.quadraticCurveTo(centerX + 85, centerY - 50, centerX + 100, centerY - 70);
      ctx.stroke();
      break;
    case 'choppy':
      ctx.beginPath();
      ctx.arc(centerX, centerY - 50, 100, Math.PI, 0); // -30에서 -50으로 상승
      ctx.lineTo(centerX + 100, centerY - 70);
      // 자연스러운 시스루 뱅
      const choppyPoints = [
        { x: 90, y: -45 },
        { x: 70, y: -40 },
        { x: 50, y: -37 },
        { x: 30, y: -40 },
        { x: 10, y: -35 },
        { x: -10, y: -38 },
        { x: -30, y: -35 },
        { x: -50, y: -40 },
        { x: -70, y: -38 },
        { x: -90, y: -42 },
      ];
      for (const point of choppyPoints) {
        ctx.lineTo(centerX + point.x, centerY + point.y);
      }
      ctx.lineTo(centerX - 100, centerY - 70);
      ctx.closePath();
      ctx.fill();
      // 양옆과 아래만 외곽선
      ctx.beginPath();
      ctx.moveTo(centerX - 100, centerY - 70); // -60에서 -70으로 상승
      ctx.lineTo(centerX - 90, centerY - 42);
      ctx.lineTo(centerX - 70, centerY - 38);
      ctx.lineTo(centerX - 50, centerY - 40);
      ctx.lineTo(centerX - 30, centerY - 35);
      ctx.lineTo(centerX - 10, centerY - 38);
      ctx.lineTo(centerX + 10, centerY - 35);
      ctx.lineTo(centerX + 30, centerY - 40);
      ctx.lineTo(centerX + 50, centerY - 37);
      ctx.lineTo(centerX + 70, centerY - 40);
      ctx.lineTo(centerX + 90, centerY - 45);
      ctx.lineTo(centerX + 100, centerY - 70); // -60에서 -70으로 상승
      ctx.stroke();
      break;
    case 'wispy':
      ctx.beginPath();
      ctx.arc(centerX, centerY - 52, 95, Math.PI, 0); // -32에서 -52로 상승
      ctx.lineTo(centerX + 95, centerY - 65);
      ctx.lineTo(centerX + 85, centerY - 45);
      ctx.quadraticCurveTo(centerX + 70, centerY - 48, centerX + 50, centerY - 40);
      ctx.quadraticCurveTo(centerX + 40, centerY - 43, centerX + 20, centerY - 38);
      ctx.quadraticCurveTo(centerX + 10, centerY - 45, centerX - 10, centerY - 40);
      ctx.quadraticCurveTo(centerX - 20, centerY - 48, centerX - 40, centerY - 42);
      ctx.quadraticCurveTo(centerX - 50, centerY - 50, centerX - 70, centerY - 45);
      ctx.quadraticCurveTo(centerX - 80, centerY - 50, centerX - 95, centerY - 65);
      ctx.closePath();
      ctx.fill();
      // 양옆과 아래만 외곽선
      ctx.beginPath();
      ctx.moveTo(centerX - 95, centerY - 65);
      ctx.quadraticCurveTo(centerX - 80, centerY - 50, centerX - 70, centerY - 45);
      ctx.quadraticCurveTo(centerX - 50, centerY - 50, centerX - 40, centerY - 42);
      ctx.quadraticCurveTo(centerX - 20, centerY - 48, centerX - 10, centerY - 40);
      ctx.quadraticCurveTo(centerX + 10, centerY - 45, centerX + 20, centerY - 38);
      ctx.quadraticCurveTo(centerX + 40, centerY - 43, centerX + 50, centerY - 40);
      ctx.quadraticCurveTo(centerX + 70, centerY - 48, centerX + 85, centerY - 45);
      ctx.lineTo(centerX + 95, centerY - 65);
      ctx.stroke();
      break;
    case 'no-bangs':
      // No front hair
      break;
    case 'short-bangs':
      ctx.beginPath();
      ctx.arc(centerX, centerY - 50, 100, Math.PI, 0); // -30에서 -50으로 상승
      ctx.lineTo(centerX + 100, centerY - 70);
      ctx.quadraticCurveTo(centerX + 70, centerY - 60, centerX + 50, centerY - 62);
      ctx.quadraticCurveTo(centerX + 30, centerY - 65, centerX, centerY - 62);
      ctx.quadraticCurveTo(centerX - 30, centerY - 65, centerX - 50, centerY - 62);
      ctx.quadraticCurveTo(centerX - 70, centerY - 60, centerX - 100, centerY - 70);
      ctx.closePath();
      ctx.fill();
      // 양옆과 아래만 외곽선
      ctx.beginPath();
      ctx.moveTo(centerX - 100, centerY - 70);
      ctx.quadraticCurveTo(centerX - 70, centerY - 60, centerX - 50, centerY - 62);
      ctx.quadraticCurveTo(centerX - 30, centerY - 65, centerX, centerY - 62);
      ctx.quadraticCurveTo(centerX + 30, centerY - 65, centerX + 50, centerY - 62);
      ctx.quadraticCurveTo(centerX + 70, centerY - 60, centerX + 100, centerY - 70);
      ctx.stroke();
      break;
    case 'messy':
      ctx.beginPath();
      ctx.arc(centerX, centerY - 55, 95, Math.PI, 0); // -35에서 -55로 상승
      ctx.lineTo(centerX + 95, centerY - 105);
      // 흐트러진 머리 - 불규칙한 패턴
      const messyPoints = [
        { x: 90, y: -98 },
        { x: 80, y: -70 },
        { x: 70, y: -65 },
        { x: 60, y: -75 },
        { x: 50, y: -68 },
        { x: 40, y: -78 },
        { x: 30, y: -70 },
        { x: 20, y: -80 },
        { x: 10, y: -72 },
        { x: 0, y: -82 },
        { x: -10, y: -75 },
        { x: -20, y: -85 },
        { x: -30, y: -78 },
        { x: -40, y: -88 },
        { x: -50, y: -80 },
        { x: -60, y: -90 },
        { x: -70, y: -85 },
        { x: -75, y: -95 },
        { x: -85, y: -100 },
      ];
      
      for (const point of messyPoints) {
        ctx.lineTo(centerX + point.x, centerY + point.y);
      }
      
      ctx.lineTo(centerX - 95, centerY - 105);
      ctx.closePath();
      ctx.fill();
      // 양옆과 아래만 외곽선
      ctx.beginPath();
      ctx.moveTo(centerX - 95, centerY - 105);
      ctx.lineTo(centerX - 85, centerY - 100);
      ctx.lineTo(centerX - 75, centerY - 95);
      ctx.lineTo(centerX - 70, centerY - 85);
      ctx.lineTo(centerX - 60, centerY - 90);
      ctx.lineTo(centerX - 50, centerY - 80);
      ctx.lineTo(centerX - 40, centerY - 88);
      ctx.lineTo(centerX - 30, centerY - 78);
      ctx.lineTo(centerX - 20, centerY - 85);
      ctx.lineTo(centerX - 10, centerY - 75);
      ctx.lineTo(centerX, centerY - 82);
      ctx.lineTo(centerX + 10, centerY - 72);
      ctx.lineTo(centerX + 20, centerY - 80);
      ctx.lineTo(centerX + 30, centerY - 70);
      ctx.lineTo(centerX + 40, centerY - 78);
      ctx.lineTo(centerX + 50, centerY - 68);
      ctx.lineTo(centerX + 60, centerY - 75);
      ctx.lineTo(centerX + 70, centerY - 65);
      ctx.lineTo(centerX + 80, centerY - 70);
      ctx.lineTo(centerX + 90, centerY - 98);
      ctx.lineTo(centerX + 95, centerY - 105);
      ctx.stroke();
      break;
  }
}

// 목 그리기 함수
export function drawNeck(
  ctx: CanvasRenderingContext2D,
  skinTone: string
) {
  const centerX = 256;
  const centerY = 256;
  
  ctx.fillStyle = skinTone;
  ctx.strokeStyle = '#3E2723';
  ctx.lineWidth = 3;
  
  // 목 - 턱에서 어깨까지 (길이를 늘림)
  ctx.beginPath();
  ctx.moveTo(centerX - 30, centerY + 90); // 턱 바로 아래
  ctx.lineTo(centerX - 40, centerY + 150); // 어깨 아래까지
  ctx.lineTo(centerX + 40, centerY + 150); // 어깨 아래까지
  ctx.lineTo(centerX + 30, centerY + 90); // 턱 바로 아래
  ctx.closePath();
  ctx.fill();
  ctx.stroke();
}

export function drawClothes(
  ctx: CanvasRenderingContext2D,
  clothesStyle: string,
  clothesColor: string
) {
  const centerX = 256;
  const centerY = 256;
  
  ctx.fillStyle = clothesColor;
  ctx.strokeStyle = '#3E2723';
  ctx.lineWidth = 4;

  const neckY = centerY + 130;

  switch (clothesStyle) {
    case 'tshirt':
      ctx.beginPath();
      ctx.moveTo(centerX - 70, neckY);
      ctx.lineTo(centerX - 100, neckY + 30);
      ctx.lineTo(centerX - 100, neckY + 120);
      ctx.lineTo(centerX + 100, neckY + 120);
      ctx.lineTo(centerX + 100, neckY + 30);
      ctx.lineTo(centerX + 70, neckY);
      // Neck
      ctx.lineTo(centerX + 30, neckY);
      ctx.lineTo(centerX + 30, neckY + 15);
      ctx.lineTo(centerX - 30, neckY + 15);
      ctx.lineTo(centerX - 30, neckY);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      break;
    case 'hoodie':
      // Hood
      ctx.beginPath();
      ctx.arc(centerX, centerY - 120, 130, 0.9, Math.PI - 0.9);
      ctx.stroke();
      // Body
      ctx.beginPath();
      ctx.moveTo(centerX - 70, neckY);
      ctx.lineTo(centerX - 105, neckY + 30);
      ctx.lineTo(centerX - 105, neckY + 120);
      ctx.lineTo(centerX + 105, neckY + 120);
      ctx.lineTo(centerX + 105, neckY + 30);
      ctx.lineTo(centerX + 70, neckY);
      ctx.lineTo(centerX + 30, neckY);
      ctx.lineTo(centerX + 30, neckY + 15);
      ctx.lineTo(centerX - 30, neckY + 15);
      ctx.lineTo(centerX - 30, neckY);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      // Zipper
      ctx.beginPath();
      ctx.moveTo(centerX, neckY + 15);
      ctx.lineTo(centerX, neckY + 80);
      ctx.stroke();
      break;
    case 'shirt':
      ctx.fillStyle = '#FFFFFF';
      ctx.beginPath();
      ctx.moveTo(centerX - 70, neckY);
      ctx.lineTo(centerX - 100, neckY + 30);
      ctx.lineTo(centerX - 100, neckY + 120);
      ctx.lineTo(centerX + 100, neckY + 120);
      ctx.lineTo(centerX + 100, neckY + 30);
      ctx.lineTo(centerX + 70, neckY);
      // Collar
      ctx.lineTo(centerX + 50, neckY - 10);
      ctx.lineTo(centerX + 30, neckY);
      ctx.lineTo(centerX + 30, neckY + 15);
      ctx.lineTo(centerX - 30, neckY + 15);
      ctx.lineTo(centerX - 30, neckY);
      ctx.lineTo(centerX - 50, neckY - 10);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      // Buttons
      for (let i = 0; i < 4; i++) {
        ctx.beginPath();
        ctx.arc(centerX, neckY + 25 + i * 20, 3, 0, Math.PI * 2);
        ctx.stroke();
      }
      break;
    case 'sweater':
      ctx.beginPath();
      ctx.moveTo(centerX - 70, neckY);
      ctx.lineTo(centerX - 105, neckY + 30);
      ctx.lineTo(centerX - 105, neckY + 120);
      ctx.lineTo(centerX + 105, neckY + 120);
      ctx.lineTo(centerX + 105, neckY + 30);
      ctx.lineTo(centerX + 70, neckY);
      // Round neck
      ctx.arc(centerX, neckY, 40, 0, Math.PI);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      break;
    case 'vneck':
      ctx.beginPath();
      ctx.moveTo(centerX - 70, neckY);
      ctx.lineTo(centerX - 100, neckY + 30);
      ctx.lineTo(centerX - 100, neckY + 120);
      ctx.lineTo(centerX + 100, neckY + 120);
      ctx.lineTo(centerX + 100, neckY + 30);
      ctx.lineTo(centerX + 70, neckY);
      // V-neck
      ctx.lineTo(centerX + 30, neckY);
      ctx.lineTo(centerX, neckY + 30);
      ctx.lineTo(centerX - 30, neckY);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      break;
    case 'polo':
      ctx.beginPath();
      ctx.moveTo(centerX - 70, neckY);
      ctx.lineTo(centerX - 100, neckY + 30);
      ctx.lineTo(centerX - 100, neckY + 120);
      ctx.lineTo(centerX + 100, neckY + 120);
      ctx.lineTo(centerX + 100, neckY + 30);
      ctx.lineTo(centerX + 70, neckY);
      // Collar
      ctx.lineTo(centerX + 50, neckY - 15);
      ctx.lineTo(centerX + 30, neckY);
      ctx.lineTo(centerX + 30, neckY + 15);
      ctx.lineTo(centerX - 30, neckY + 15);
      ctx.lineTo(centerX - 30, neckY);
      ctx.lineTo(centerX - 50, neckY - 15);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      // Buttons
      ctx.beginPath();
      ctx.arc(centerX, neckY + 25, 3, 0, Math.PI * 2);
      ctx.stroke();
      ctx.beginPath();
      ctx.arc(centerX, neckY + 40, 3, 0, Math.PI * 2);
      ctx.stroke();
      break;
    case 'jacket':
      ctx.beginPath();
      ctx.moveTo(centerX - 70, neckY);
      ctx.lineTo(centerX - 110, neckY + 30);
      ctx.lineTo(centerX - 110, neckY + 120);
      ctx.lineTo(centerX + 110, neckY + 120);
      ctx.lineTo(centerX + 110, neckY + 30);
      ctx.lineTo(centerX + 70, neckY);
      ctx.lineTo(centerX + 50, neckY - 10);
      ctx.lineTo(centerX + 35, neckY);
      ctx.lineTo(centerX + 35, neckY + 15);
      ctx.lineTo(centerX - 35, neckY + 15);
      ctx.lineTo(centerX - 35, neckY);
      ctx.lineTo(centerX - 50, neckY - 10);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      // Zipper
      ctx.beginPath();
      ctx.moveTo(centerX, neckY + 15);
      ctx.lineTo(centerX, neckY + 100);
      ctx.stroke();
      break;
    case 'cardigan':
      ctx.beginPath();
      ctx.moveTo(centerX - 70, neckY);
      ctx.lineTo(centerX - 105, neckY + 30);
      ctx.lineTo(centerX - 105, neckY + 120);
      ctx.lineTo(centerX + 105, neckY + 120);
      ctx.lineTo(centerX + 105, neckY + 30);
      ctx.lineTo(centerX + 70, neckY);
      ctx.arc(centerX, neckY, 40, 0, Math.PI);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      // Buttons
      for (let i = 0; i < 5; i++) {
        ctx.beginPath();
        ctx.arc(centerX, neckY + 15 + i * 20, 3, 0, Math.PI * 2);
        ctx.stroke();
      }
      break;
    case 'blazer':
      ctx.beginPath();
      ctx.moveTo(centerX - 70, neckY);
      ctx.lineTo(centerX - 110, neckY + 30);
      ctx.lineTo(centerX - 110, neckY + 120);
      ctx.lineTo(centerX + 110, neckY + 120);
      ctx.lineTo(centerX + 110, neckY + 30);
      ctx.lineTo(centerX + 70, neckY);
      // Lapel
      ctx.lineTo(centerX + 55, neckY - 20);
      ctx.lineTo(centerX + 35, neckY);
      ctx.lineTo(centerX + 35, neckY + 15);
      ctx.lineTo(centerX - 35, neckY + 15);
      ctx.lineTo(centerX - 35, neckY);
      ctx.lineTo(centerX - 55, neckY - 20);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      break;
    case 'tank':
      ctx.beginPath();
      ctx.moveTo(centerX - 50, neckY);
      ctx.lineTo(centerX - 80, neckY + 30);
      ctx.lineTo(centerX - 80, neckY + 120);
      ctx.lineTo(centerX + 80, neckY + 120);
      ctx.lineTo(centerX + 80, neckY + 30);
      ctx.lineTo(centerX + 50, neckY);
      ctx.arc(centerX, neckY, 30, 0, Math.PI);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
      break;
  }
}

export function drawAccessory(
  ctx: CanvasRenderingContext2D,
  accessoryStyle: string
) {
  const centerX = 256;
  const centerY = 256;
  
  ctx.strokeStyle = '#3E2723';
  ctx.lineWidth = 3;

  switch (accessoryStyle) {
    case 'none':
      break;
    case 'glasses':
      ctx.fillStyle = 'rgba(255, 255, 255, 0.3)';
      // Left lens - 눈 위치에 맞게 아래로
      ctx.beginPath();
      ctx.roundRect(centerX - 75, centerY - 15, 50, 38, 6);
      ctx.fill();
      ctx.stroke();
      // Right lens - 눈 위치에 맞게 아래로
      ctx.beginPath();
      ctx.roundRect(centerX + 25, centerY - 15, 50, 38, 6);
      ctx.fill();
      ctx.stroke();
      // Bridge
      ctx.beginPath();
      ctx.moveTo(centerX - 25, centerY + 5);
      ctx.lineTo(centerX + 25, centerY + 5);
      ctx.stroke();
      // Temples - 위에서 아래로
      ctx.beginPath();
      ctx.moveTo(centerX - 75, centerY - 10);
      ctx.lineTo(centerX - 95, centerY - 15);
      ctx.lineTo(centerX - 100, centerY + 10);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(centerX + 75, centerY - 10);
      ctx.lineTo(centerX + 95, centerY - 15);
      ctx.lineTo(centerX + 100, centerY + 10);
      ctx.stroke();
      break;
    case 'sunglasses':
      ctx.fillStyle = 'rgba(0, 0, 0, 0.7)';
      // Left lens - 눈 위치에 맞게 아래로
      ctx.beginPath();
      ctx.roundRect(centerX - 75, centerY - 15, 50, 38, 6);
      ctx.fill();
      ctx.stroke();
      // Right lens - 눈 위치에 맞게 아래로
      ctx.beginPath();
      ctx.roundRect(centerX + 25, centerY - 15, 50, 38, 6);
      ctx.fill();
      ctx.stroke();
      // Bridge
      ctx.beginPath();
      ctx.moveTo(centerX - 25, centerY + 5);
      ctx.lineTo(centerX + 25, centerY + 5);
      ctx.stroke();
      // Temples - 위에서 아래로
      ctx.beginPath();
      ctx.moveTo(centerX - 75, centerY - 10);
      ctx.lineTo(centerX - 95, centerY - 15);
      ctx.lineTo(centerX - 100, centerY + 10);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(centerX + 75, centerY - 10);
      ctx.lineTo(centerX + 95, centerY - 15);
      ctx.lineTo(centerX + 100, centerY + 10);
      ctx.stroke();
      break;
    case 'round-glasses':
      ctx.fillStyle = 'rgba(255, 255, 255, 0.3)';
      // Left lens - 동그란 안경 (더 크게, 중앙으로)
      ctx.beginPath();
      ctx.arc(centerX - 38, centerY + 2, 30, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
      // Right lens - 동그란 안경 (더 크게, 중앙으로)
      ctx.beginPath();
      ctx.arc(centerX + 38, centerY + 2, 30, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
      // Bridge
      ctx.beginPath();
      ctx.moveTo(centerX - 8, centerY + 2);
      ctx.lineTo(centerX + 8, centerY + 2);
      ctx.stroke();
      // Temples - 위에서 아래로
      ctx.beginPath();
      ctx.moveTo(centerX - 68, centerY + 2);
      ctx.lineTo(centerX - 95, centerY - 10);
      ctx.lineTo(centerX - 100, centerY + 10);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(centerX + 68, centerY + 2);
      ctx.lineTo(centerX + 95, centerY - 10);
      ctx.lineTo(centerX + 100, centerY + 10);
      ctx.stroke();
      break;
    case 'earrings':
      ctx.fillStyle = '#FFD700';
      ctx.beginPath();
      ctx.arc(centerX - 95, centerY + 20, 5, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
      ctx.beginPath();
      ctx.arc(centerX + 95, centerY + 20, 5, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
      break;
  }
}

// 눈꺼풀 그리기 함수
function drawEyelids(
  ctx: CanvasRenderingContext2D,
  skinTone: string
) {
  const centerX = 256;
  const centerY = 256;
  const eyeY = centerY - 15;
  
  ctx.fillStyle = skinTone;
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';
  
  // 왼쪽 눈꺼풀 - 피부색으로 눈 위를 덮음
  ctx.beginPath();
  ctx.arc(centerX - 45, eyeY - 2, 24, Math.PI, 0, true);
  ctx.lineTo(centerX - 45 + 24, eyeY - 28);
  ctx.lineTo(centerX - 45 - 24, eyeY - 28);
  ctx.closePath();
  ctx.fill();
  
  // 오른쪽 눈꺼풀 - 피부색으로 눈 위를 덮음
  ctx.beginPath();
  ctx.arc(centerX + 45, eyeY - 2, 24, Math.PI, 0, true);
  ctx.lineTo(centerX + 45 + 24, eyeY - 28);
  ctx.lineTo(centerX + 45 - 24, eyeY - 28);
  ctx.closePath();
  ctx.fill();
}