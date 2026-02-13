import 'package:flutter/material.dart';
import 'package:nearo_app/ui/widgets/avatar_widget.dart';

class AvatarDemoScreen extends StatelessWidget {
  const AvatarDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 예시 데이터 (실제 사용 시 서버에서 받아온 값으로 대체)
    final avatarData = {
      'faceShape': 'round',
      'hairBack': 'short-back',
      'hairFront': 'bangs',
      'hairColor': 'black',
      'eyes': 'happy',
      'mouth': 'smile',
      'clothes': 'tshirt',
      'clothesColor': 'blue',
      'accessory': 'glasses',
      'skinColor': '#FFE0D2',
      'background': '#B0BEC5',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('아바타 조합 예시')),
      body: Center(
        child: AvatarWidget(
          faceShape: avatarData['faceShape']!,
          hairBack: avatarData['hairBack']!,
          hairFront: avatarData['hairFront']!,
          hairColor: avatarData['hairColor']!,
          eyes: avatarData['eyes']!,
          mouth: avatarData['mouth']!,
          clothes: avatarData['clothes']!,
          clothesColor: avatarData['clothesColor']!,
          accessory: avatarData['accessory']!,
          skinColor: avatarData['skinColor']!,
          background: avatarData['background']!,
        ),
      ),
    );
  }
}
