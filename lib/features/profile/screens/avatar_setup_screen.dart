import 'package:flutter/material.dart';
import 'package:nearo_app/ui/widgets/avatar_widget.dart';

/// 아바타 파츠 선택 및 실시간 미리보기, 등록 화면
class AvatarSetupScreen extends StatefulWidget {
  const AvatarSetupScreen({super.key});

  @override
  State<AvatarSetupScreen> createState() => _AvatarSetupScreenState();
}

class _AvatarSetupScreenState extends State<AvatarSetupScreen> {
  // 파츠별 선택값 (초기값은 임의)
  String faceShape = 'round';
  String hairBack = 'short-back';
  String hairFront = 'bangs';
  String hairColor = 'black';
  String eyes = 'happy';
  String mouth = 'smile';
  String clothes = 'tshirt';
  String clothesColor = 'blue';
  String accessory = 'none';
  String skinColor = '#FFE0D2';
  String background = '#B0BEC5';

  // TODO: 서버에 등록하는 함수 구현 필요
  Future<void> _registerAvatar() async {
    // 서버에 POST 요청 등 구현
    // 성공 시 홈으로 이동
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _onPartChanged(String part, String value) {
    setState(() {
      switch (part) {
        case 'faceShape': faceShape = value; break;
        case 'hairBack': hairBack = value; break;
        case 'hairFront': hairFront = value; break;
        case 'hairColor': hairColor = value; break;
        case 'eyes': eyes = value; break;
        case 'mouth': mouth = value; break;
        case 'clothes': clothes = value; break;
        case 'clothesColor': clothesColor = value; break;
        case 'accessory': accessory = value; break;
        case 'skinColor': skinColor = value; break;
        case 'background': background = value; break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('아바타 만들기')),
      body: Column(
        children: [
          const SizedBox(height: 24),
          AvatarWidget(
            faceShape: faceShape,
            hairBack: hairBack,
            hairFront: hairFront,
            hairColor: hairColor,
            eyes: eyes,
            mouth: mouth,
            clothes: clothes,
            clothesColor: clothesColor,
            accessory: accessory,
            skinColor: skinColor,
          ),
          const SizedBox(height: 24),
          // 파츠별 선택 UI (예시: 버튼)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => _onPartChanged('faceShape', 'round'),
                child: const Text('둥근 얼굴'),
              ),
              ElevatedButton(
                onPressed: () => _onPartChanged('faceShape', 'long'),
                child: const Text('긴 얼굴'),
              ),
              // ...다른 파츠도 추가

              // 앞머리 파츠 선택 버튼
              ElevatedButton(
                onPressed: () => _onPartChanged('hairFront', 'bangs'),
                child: const Text('앞머리: 뱅'),
              ),
              ElevatedButton(
                onPressed: () => _onPartChanged('hairFront', 'short-front'),
                child: const Text('앞머리: 짧은'),
              ),
              ElevatedButton(
                onPressed: () => _onPartChanged('hairFront', 'side-swept'),
                child: const Text('앞머리: 사이드'),
              ),
              ElevatedButton(
                onPressed: () => _onPartChanged('hairFront', 'curtain'),
                child: const Text('앞머리: 커튼'),
              ),
              ElevatedButton(
                onPressed: () => _onPartChanged('hairFront', 'center-part'),
                child: const Text('앞머리: 가운데'),
              ),
              ElevatedButton(
                onPressed: () => _onPartChanged('hairFront', 'none'),
                child: const Text('앞머리 없음'),
              ),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _registerAvatar,
              child: const Text('아바타 등록하고 홈으로'),
            ),
          ),
        ],
      ),
    );
  }
}
