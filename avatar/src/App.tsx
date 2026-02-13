import { useState, useRef } from 'react';
import { AvatarCanvas } from './components/AvatarCanvas';
import { PartsSelector, ColorSelector, ActionButtons } from './components/PartsSelector';
import {
  SKIN_TONES,
  FACE_SHAPES,
  HAIR_BACK,
  EYES,
  MOUTHS,
  HAIR_FRONT,
  CLOTHES,
  ACCESSORIES,
  HAIR_COLORS,
  CLOTHES_COLORS,
} from './utils/avatarParts';

export default function App() {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  const [skinTone, setSkinTone] = useState(SKIN_TONES[0]);
  const [faceShape, setFaceShape] = useState(FACE_SHAPES[0].id);
  const [hairBack, setHairBack] = useState(HAIR_BACK[0].id);
  const [eyes, setEyes] = useState(EYES[0].id);
  const [mouth, setMouth] = useState(MOUTHS[0].id);
  const [hairFront, setHairFront] = useState(HAIR_FRONT[0].id);
  const [clothes, setClothes] = useState(CLOTHES[0].id);
  const [accessory, setAccessory] = useState(ACCESSORIES[0].id);
  const [hairColor, setHairColor] = useState(HAIR_COLORS[0]);
  const [clothesColor, setClothesColor] = useState(CLOTHES_COLORS[0]);

  const randomize = () => {
    setSkinTone(SKIN_TONES[Math.floor(Math.random() * SKIN_TONES.length)]);
    setFaceShape(FACE_SHAPES[Math.floor(Math.random() * FACE_SHAPES.length)].id);
    setHairBack(HAIR_BACK[Math.floor(Math.random() * HAIR_BACK.length)].id);
    setEyes(EYES[Math.floor(Math.random() * EYES.length)].id);
    setMouth(MOUTHS[Math.floor(Math.random() * MOUTHS.length)].id);
    setHairFront(HAIR_FRONT[Math.floor(Math.random() * HAIR_FRONT.length)].id);
    setClothes(CLOTHES[Math.floor(Math.random() * CLOTHES.length)].id);
    setAccessory(ACCESSORIES[Math.floor(Math.random() * ACCESSORIES.length)].id);
    setHairColor(HAIR_COLORS[Math.floor(Math.random() * HAIR_COLORS.length)]);
    setClothesColor(CLOTHES_COLORS[Math.floor(Math.random() * CLOTHES_COLORS.length)]);
  };

  const downloadPNG = () => {
    const canvas = document.querySelector('canvas');
    if (!canvas) return;

    canvas.toBlob((blob) => {
      if (!blob) return;
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `avatar-${Date.now()}.png`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    });
  };

  return (
    <div className="min-h-screen bg-gray-50 p-4 md:p-8">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-3xl mb-8 text-gray-900">2D 아바타 생성 시스템</h1>
        
        <div className="flex flex-col lg:flex-row gap-8">
          {/* Canvas Preview */}
          <div className="flex-shrink-0 flex flex-col items-center gap-4">
            <AvatarCanvas
              skinTone={skinTone}
              faceShape={faceShape}
              hairBack={hairBack}
              eyes={eyes}
              mouth={mouth}
              hairFront={hairFront}
              clothes={clothes}
              accessory={accessory}
              hairColor={hairColor}
              clothesColor={clothesColor}
            />
            <div className="w-full max-w-md">
              <ActionButtons onRandomize={randomize} onDownload={downloadPNG} />
            </div>
          </div>

          {/* Parts Selectors */}
          <div className="flex-1 bg-white rounded-lg p-6 shadow-sm overflow-y-auto max-h-[calc(100vh-12rem)]">
            <ColorSelector
              label="피부톤"
              colors={SKIN_TONES}
              selectedColor={skinTone}
              onSelect={setSkinTone}
            />

            <PartsSelector
              category="faceShape"
              selectedPart={faceShape}
              parts={FACE_SHAPES}
              onSelect={setFaceShape}
              label="얼굴형"
            />

            <ColorSelector
              label="머리 색상"
              colors={HAIR_COLORS}
              selectedColor={hairColor}
              onSelect={setHairColor}
            />

            <PartsSelector
              category="hairBack"
              selectedPart={hairBack}
              parts={HAIR_BACK}
              onSelect={setHairBack}
              label="뒷머리"
            />

            <PartsSelector
              category="hairFront"
              selectedPart={hairFront}
              parts={HAIR_FRONT}
              onSelect={setHairFront}
              label="앞머리"
            />

            <PartsSelector
              category="eyes"
              selectedPart={eyes}
              parts={EYES}
              onSelect={setEyes}
              label="눈"
            />

            <PartsSelector
              category="mouth"
              selectedPart={mouth}
              parts={MOUTHS}
              onSelect={setMouth}
              label="입"
            />

            <ColorSelector
              label="옷 색상"
              colors={CLOTHES_COLORS}
              selectedColor={clothesColor}
              onSelect={setClothesColor}
            />

            <PartsSelector
              category="clothes"
              selectedPart={clothes}
              parts={CLOTHES}
              onSelect={setClothes}
              label="의상"
            />

            <PartsSelector
              category="accessory"
              selectedPart={accessory}
              parts={ACCESSORIES}
              onSelect={setAccessory}
              label="액세서리"
            />
          </div>
        </div>
      </div>
    </div>
  );
}
