import 'package:flutter/material.dart';

class AccessoryPainter extends CustomPainter {
  final String accessory;

  AccessoryPainter({required this.accessory});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final paint = Paint()
      ..color = Colors.blueGrey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    switch (accessory) {
      case 'glasses':
        canvas.drawCircle(Offset(centerX - 30, centerY + 10), 16, paint);
        canvas.drawCircle(Offset(centerX + 30, centerY + 10), 16, paint);
        canvas.drawLine(Offset(centerX - 14, centerY + 10), Offset(centerX + 14, centerY + 10), paint);
        break;
      case 'sunglasses':
        final sunglassPaint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(centerX - 30, centerY + 10), width: 32, height: 18), sunglassPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(centerX + 30, centerY + 10), width: 32, height: 18), sunglassPaint,
        );
        canvas.drawLine(Offset(centerX - 14, centerY + 10), Offset(centerX + 14, centerY + 10), paint);
        break;
      case 'earring':
        final earringPaint = Paint()
          ..color = Colors.amber
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(centerX - 55, centerY + 60), 7, earringPaint);
        canvas.drawCircle(Offset(centerX + 55, centerY + 60), 7, earringPaint);
        break;
      case 'hat':
        final hatPaint = Paint()
          ..color = Colors.brown
          ..style = PaintingStyle.fill;
        canvas.drawArc(
          Rect.fromCenter(center: Offset(centerX, centerY - 80), width: 120, height: 40),
          3.14159, 3.14159, false, hatPaint,
        );
        canvas.drawRect(
          Rect.fromCenter(center: Offset(centerX, centerY - 100), width: 60, height: 30), hatPaint,
        );
        break;
      case 'ribbon':
        final ribbonPaint = Paint()
          ..color = Colors.pink
          ..style = PaintingStyle.fill;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(centerX, centerY - 90), width: 40, height: 18), ribbonPaint,
        );
        canvas.drawCircle(Offset(centerX - 20, centerY - 90), 10, ribbonPaint);
        canvas.drawCircle(Offset(centerX + 20, centerY - 90), 10, ribbonPaint);
        break;
      case 'none':
        // 아무것도 그리지 않음
        break;
      default:
        // 아무것도 그리지 않음
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
