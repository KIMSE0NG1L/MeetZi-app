import { useRef, useEffect } from 'react';
import {
  drawFaceBase,
  drawHairBack,
  drawEyes,
  drawMouth,
  drawHairFront,
  drawNeck,
  drawClothes,
  drawAccessory,
} from '../utils/avatarParts';

interface AvatarCanvasProps {
  skinTone: string;
  faceShape: string;
  hairBack: string;
  eyes: string;
  mouth: string;
  hairFront: string;
  clothes: string;
  accessory: string;
  hairColor: string;
  clothesColor: string;
}

export function AvatarCanvas({
  skinTone,
  faceShape,
  hairBack,
  eyes,
  mouth,
  hairFront,
  clothes,
  accessory,
  hairColor,
  clothesColor,
}: AvatarCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Clear canvas
    ctx.clearRect(0, 0, 512, 512);

    // Draw avatar layers in correct order - 목이 옷 아래로
    drawHairBack(ctx, hairBack, hairColor);
    drawNeck(ctx, skinTone);
    drawFaceBase(ctx, faceShape, skinTone);
    drawClothes(ctx, clothes, clothesColor);
    drawEyes(ctx, eyes);
    drawMouth(ctx, mouth);
    drawHairFront(ctx, hairFront, hairColor);
    drawAccessory(ctx, accessory);
  }, [
    skinTone,
    faceShape,
    hairBack,
    eyes,
    mouth,
    hairFront,
    clothes,
    accessory,
    hairColor,
    clothesColor,
  ]);

  return (
    <canvas
      ref={canvasRef}
      width={512}
      height={512}
      className="border-4 border-gray-800 rounded-lg bg-gray-100"
    />
  );
}