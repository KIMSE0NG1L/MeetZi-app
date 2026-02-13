import { Shuffle, Download } from 'lucide-react';

interface PartsCategory {
  id: string;
  name: string;
}

interface PartsSelectorProps {
  category: string;
  selectedPart: string;
  parts: PartsCategory[];
  onSelect: (partId: string) => void;
  label: string;
}

export function PartsSelector({
  category,
  selectedPart,
  parts,
  onSelect,
  label,
}: PartsSelectorProps) {
  return (
    <div className="mb-6">
      <h3 className="font-medium mb-2 text-gray-800">{label}</h3>
      <div className="grid grid-cols-3 gap-2">
        {parts.map((part) => (
          <button
            key={part.id}
            onClick={() => onSelect(part.id)}
            className={`
              py-2 px-3 rounded-lg border-2 text-sm transition-all
              ${
                selectedPart === part.id
                  ? 'border-gray-800 bg-gray-800 text-white'
                  : 'border-gray-300 bg-white text-gray-700 hover:border-gray-400'
              }
            `}
          >
            {part.name}
          </button>
        ))}
      </div>
    </div>
  );
}

interface ColorSelectorProps {
  label: string;
  colors: string[];
  selectedColor: string;
  onSelect: (color: string) => void;
}

export function ColorSelector({
  label,
  colors,
  selectedColor,
  onSelect,
}: ColorSelectorProps) {
  return (
    <div className="mb-6">
      <h3 className="font-medium mb-2 text-gray-800">{label}</h3>
      <div className="flex gap-2 flex-wrap">
        {colors.map((color) => (
          <button
            key={color}
            onClick={() => onSelect(color)}
            className={`
              w-10 h-10 rounded-full border-3 transition-all
              ${
                selectedColor === color
                  ? 'border-gray-800 scale-110'
                  : 'border-gray-300 hover:scale-105'
              }
            `}
            style={{ backgroundColor: color }}
          />
        ))}
      </div>
    </div>
  );
}

interface ActionButtonsProps {
  onRandomize: () => void;
  onDownload: () => void;
}

export function ActionButtons({ onRandomize, onDownload }: ActionButtonsProps) {
  return (
    <div className="flex gap-3">
      <button
        onClick={onRandomize}
        className="flex-1 flex items-center justify-center gap-2 py-3 px-4 bg-gray-700 hover:bg-gray-800 text-white rounded-lg transition-colors"
      >
        <Shuffle className="w-5 h-5" />
        <span>랜덤 생성</span>
      </button>
      <button
        onClick={onDownload}
        className="flex-1 flex items-center justify-center gap-2 py-3 px-4 bg-gray-800 hover:bg-gray-900 text-white rounded-lg transition-colors"
      >
        <Download className="w-5 h-5" />
        <span>PNG 다운로드</span>
      </button>
    </div>
  );
}
