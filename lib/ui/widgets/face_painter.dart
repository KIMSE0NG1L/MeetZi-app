import 'package:flutter/material.dart';

class FacePainter extends CustomPainter {
  final String faceShape;
  final Color skinTone;

  FacePainter({required this.faceShape, required this.skinTone});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final paint = Paint()
      ..color = skinTone
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final path = Path();
    switch (faceShape) {
      case 'round':
        path.moveTo(centerX, centerY - 120);
        path.cubicTo(centerX - 72, centerY - 120, centerX - 90, centerY - 93, centerX - 93, centerY - 55);
        path.cubicTo(centerX - 96, centerY - 11, centerX - 96, centerY + 33, centerX - 88, centerY + 66);
        path.cubicTo(centerX - 75, centerY + 93, centerX - 46, centerY + 110, centerX - 20, centerY + 118);
        path.cubicTo(centerX - 8, centerY + 123, centerX + 8, centerY + 123, centerX + 20, centerY + 118);
        path.cubicTo(centerX + 46, centerY + 110, centerX + 75, centerY + 93, centerX + 88, centerY + 66);
        path.cubicTo(centerX + 96, centerY + 33, centerX + 96, centerY - 11, centerX + 93, centerY - 55);
        path.cubicTo(centerX + 90, centerY - 93, centerX + 72, centerY - 120, centerX, centerY - 120);
        path.close();
        break;
      case 'long':
        path.moveTo(centerX, centerY - 125);
        path.cubicTo(centerX - 70, centerY - 125, centerX - 88, centerY - 95, centerX - 92, centerY - 55);
        path.cubicTo(centerX - 95, centerY - 10, centerX - 95, centerY + 35, centerX - 88, centerY + 70);
        path.cubicTo(centerX - 75, centerY + 95, centerX - 45, centerY + 110, centerX - 18, centerY + 120);
        path.cubicTo(centerX - 7, centerY + 125, centerX + 7, centerY + 125, centerX + 18, centerY + 120);
        path.cubicTo(centerX + 45, centerY + 110, centerX + 75, centerY + 95, centerX + 88, centerY + 70);
        path.cubicTo(centerX + 95, centerY + 35, centerX + 95, centerY - 10, centerX + 92, centerY - 55);
        path.cubicTo(centerX + 88, centerY - 95, centerX + 70, centerY - 125, centerX, centerY - 125);
        path.close();
        break;
      case 'slim':
        path.moveTo(centerX, centerY - 115);
        path.cubicTo(centerX - 68, centerY - 115, centerX - 85, centerY - 88, centerX - 88, centerY - 50);
        path.cubicTo(centerX - 90, centerY - 8, centerX - 90, centerY + 32, centerX - 83, centerY + 65);
        path.cubicTo(centerX - 70, centerY + 88, centerX - 42, centerY + 102, centerX - 16, centerY + 110);
        path.cubicTo(centerX - 6, centerY + 114, centerX + 6, centerY + 114, centerX + 16, centerY + 110);
        path.cubicTo(centerX + 42, centerY + 102, centerX + 70, centerY + 88, centerX + 83, centerY + 65);
        path.cubicTo(centerX + 90, centerY + 32, centerX + 90, centerY - 8, centerX + 88, centerY - 50);
        path.cubicTo(centerX + 85, centerY - 88, centerX + 68, centerY - 115, centerX, centerY - 115);
        path.close();
        break;
      case 'angular':
        path.moveTo(centerX, centerY - 110);
        path.cubicTo(centerX - 65, centerY - 113, centerX - 88, centerY - 95, centerX - 98, centerY - 60);
        path.cubicTo(centerX - 105, centerY - 20, centerX - 105, centerY + 25, centerX - 98, centerY + 60);
        path.cubicTo(centerX - 85, centerY + 85, centerX - 55, centerY + 100, centerX - 22, centerY + 110);
        path.cubicTo(centerX - 9, centerY + 114, centerX + 9, centerY + 114, centerX + 22, centerY + 110);
        path.cubicTo(centerX + 55, centerY + 100, centerX + 85, centerY + 85, centerX + 98, centerY + 60);
        path.cubicTo(centerX + 105, centerY + 25, centerX + 105, centerY - 20, centerX + 98, centerY - 60);
        path.cubicTo(centerX + 88, centerY - 95, centerX + 65, centerY - 113, centerX, centerY - 110);
        path.close();
        break;
      case 'soft-square':
        path.moveTo(centerX, centerY - 108);
        path.cubicTo(centerX - 70, centerY - 112, centerX - 92, centerY - 90, centerX - 98, centerY - 50);
        path.cubicTo(centerX - 102, centerY - 8, centerX - 102, centerY + 30, centerX - 95, centerY + 62);
        path.cubicTo(centerX - 82, centerY + 87, centerX - 52, centerY + 102, centerX - 20, centerY + 110);
        path.cubicTo(centerX - 8, centerY + 113, centerX + 8, centerY + 113, centerX + 20, centerY + 110);
        path.cubicTo(centerX + 52, centerY + 102, centerX + 82, centerY + 87, centerX + 95, centerY + 62);
        path.cubicTo(centerX + 102, centerY + 30, centerX + 102, centerY - 8, centerX + 98, centerY - 50);
        path.cubicTo(centerX + 92, centerY - 90, centerX + 70, centerY - 112, centerX, centerY - 108);
        path.close();
        break;
      default:
        return;
    }
    canvas.drawPath(path, paint);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
