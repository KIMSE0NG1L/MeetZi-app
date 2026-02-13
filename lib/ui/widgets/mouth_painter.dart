import 'package:flutter/material.dart';

class MouthPainter extends CustomPainter {
  final String mouth;

  MouthPainter({required this.mouth});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final paint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    switch (mouth) {
      case 'smile':
        canvas.drawArc(
          Rect.fromCenter(center: Offset(centerX, centerY + 60), width: 40, height: 20),
          0, 3.14159, false, paint,
        );
        break;
      case 'open':
        paint.style = PaintingStyle.fill;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(centerX, centerY + 62), width: 32, height: 18), paint,
        );
        break;
      case 'sad':
        canvas.drawArc(
          Rect.fromCenter(center: Offset(centerX, centerY + 68), width: 40, height: 20),
          3.14159, 3.14159, false, paint,
        );
        break;
      case 'neutral':
        canvas.drawLine(
          Offset(centerX - 18, centerY + 62),
          Offset(centerX + 18, centerY + 62), paint,
        );
        break;
      case 'grin':
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 5;
        canvas.drawArc(
          Rect.fromCenter(center: Offset(centerX, centerY + 60), width: 48, height: 24),
          0, 3.14159, false, paint,
        );
        break;
      case 'surprised':
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 4;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(centerX, centerY + 62), width: 18, height: 18), paint,
        );
        break;
      case 'tongue':
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 4;
        canvas.drawArc(
          Rect.fromCenter(center: Offset(centerX, centerY + 62), width: 32, height: 18),
          0, 3.14159, false, paint,
        );
        final tonguePaint = Paint()
          ..color = Colors.pinkAccent
          ..style = PaintingStyle.fill;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(centerX, centerY + 70), width: 16, height: 10), tonguePaint,
        );
        break;
      default:
        // 아무것도 그리지 않음
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
