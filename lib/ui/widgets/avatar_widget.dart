import 'package:flutter/material.dart';
import 'face_painter.dart';
import 'hair_back_painter.dart';
import 'hair_front_painter.dart';
import 'eyes_painter.dart';
import 'mouth_painter.dart';
import 'clothes_painter.dart';
import 'accessory_painter.dart';

class AvatarWidget extends StatelessWidget {
  final String faceShape;
  final String hairBack;
  final String hairFront;
  final String hairColor;
  final String eyes;
  final String mouth;
  final String clothes;
  final String clothesColor;
  final String accessory;
  final String skinColor;

  const AvatarWidget({
    super.key,
    required this.faceShape,
    required this.hairBack,
    required this.hairFront,
    required this.hairColor,
    required this.eyes,
    required this.mouth,
    required this.clothes,
    required this.clothesColor,
    required this.accessory,
    required this.skinColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 256,
      height: 256,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(256, 256),
            painter: HairBackPainter(hairStyle: hairBack, hairColor: Colors.brown),
          ),
          CustomPaint(
            size: const Size(256, 256),
            painter: HairFrontPainter(hairStyle: hairFront, hairColor: Colors.brown),
          ),
          CustomPaint(
            size: const Size(256, 256),
            painter: FacePainter(faceShape: faceShape, skinTone: Color(int.parse(skinColor.replaceFirst('#', '0xff')))),
          ),
          CustomPaint(
            size: const Size(256, 256),
            painter: ClothesPainter(clothes: clothes, clothesColor: Colors.blue),
          ),
          CustomPaint(
            size: const Size(256, 256),
            painter: EyesPainter(eyes: eyes),
          ),
          CustomPaint(
            size: const Size(256, 256),
            painter: MouthPainter(mouth: mouth),
          ),
          CustomPaint(
            size: const Size(256, 256),
            painter: AccessoryPainter(accessory: accessory),
          ),
        ],
      ),
    );
  }
}
