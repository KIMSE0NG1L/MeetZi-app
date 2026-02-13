import 'package:flutter/material.dart';

class EyesPainter extends CustomPainter {
  final String eyes;

  EyesPainter({required this.eyes});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    switch (eyes) {
      case 'happy':
        canvas.drawArc(
          Rect.fromCenter(center: Offset(centerX - 40, centerY + 10), width: 32, height: 16),
          0, 3.14159, false, paint,
        );
        canvas.drawArc(
          Rect.fromCenter(center: Offset(centerX + 40, centerY + 10), width: 32, height: 16),
          0, 3.14159, false, paint,
        );
        break;
      case 'normal':
        canvas.drawOval(
          Rect.fromCenter(center: Offset(centerX - 40, centerY + 10), width: 22, height: 14), paint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(centerX + 40, centerY + 10), width: 22, height: 14), paint,
        );
        break;
      case 'smile':
        canvas.drawArc(
          Rect.fromCenter(center: Offset(centerX - 40, centerY + 10), width: 28, height: 12),
          0.2, 2.7, false, paint,
        );
        canvas.drawArc(
          Rect.fromCenter(center: Offset(centerX + 40, centerY + 10), width: 28, height: 12),
          0.2, 2.7, false, paint,
        );
        break;
      case 'wink':
        canvas.drawLine(
          Offset(centerX - 40 - 10, centerY + 10),
          Offset(centerX - 40 + 10, centerY + 10), paint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(centerX + 40, centerY + 10), width: 22, height: 14), paint,
        );
        break;
      case 'big':
        canvas.drawOval(
          Rect.fromCenter(center: Offset(centerX - 40, centerY + 10), width: 30, height: 20), paint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(centerX + 40, centerY + 10), width: 30, height: 20), paint,
        );
        break;
      case 'sleepy':
        canvas.drawArc(
          Rect.fromCenter(center: Offset(centerX - 40, centerY + 14), width: 28, height: 10),
          0, 3.14159, false, paint,
        );
        canvas.drawArc(
          Rect.fromCenter(center: Offset(centerX + 40, centerY + 14), width: 28, height: 10),
          0, 3.14159, false, paint,
        );
        break;
      case 'angry':
        final pathLeft = Path();
        pathLeft.moveTo(centerX - 50, centerY + 5);
        pathLeft.lineTo(centerX - 30, centerY + 15);
        pathLeft.arcTo(
          Rect.fromCenter(center: Offset(centerX - 40, centerY + 15), width: 22, height: 14),
          0, 3.14159, false,
        );
        canvas.drawPath(pathLeft, paint);
        final pathRight = Path();
        pathRight.moveTo(centerX + 30, centerY + 15);
        pathRight.lineTo(centerX + 50, centerY + 5);
        pathRight.arcTo(
          Rect.fromCenter(center: Offset(centerX + 40, centerY + 15), width: 22, height: 14),
          0, 3.14159, false,
        );
        canvas.drawPath(pathRight, paint);
        break;
      case 'star':
        final starPaint = Paint()
          ..color = Colors.yellow
          ..style = PaintingStyle.fill;
        for (final dx in [-40.0, 40.0]) {
          final path = Path();
          final cx = centerX + dx;
          final cy = centerY + 10;
          for (int i = 0; i < 5; i++) {
            final angle = (i * 144) * 3.14159 / 180;
            final x = cx + 8 * Math.cos(angle);
            final y = cy + 8 * Math.sin(angle);
            if (i == 0) {
              path.moveTo(x, y);
            } else {
              path.lineTo(x, y);
            }
          }
          path.close();
          canvas.drawPath(path, starPaint);
        }
        break;
      default:
        // 아무것도 그리지 않음
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
