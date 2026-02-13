import 'package:flutter/material.dart';

class ClothesPainter extends CustomPainter {
  final String clothes;
  final Color clothesColor;

  ClothesPainter({required this.clothes, required this.clothesColor});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final paint = Paint()
      ..color = clothesColor
      ..style = PaintingStyle.fill;

    switch (clothes) {
      case 'tshirt':
        final path = Path();
        path.moveTo(centerX - 60, centerY + 120);
        path.lineTo(centerX - 40, centerY + 180);
        path.lineTo(centerX + 40, centerY + 180);
        path.lineTo(centerX + 60, centerY + 120);
        path.close();
        canvas.drawPath(path, paint);
        break;
      case 'hoodie':
        final path = Path();
        path.moveTo(centerX - 65, centerY + 120);
        path.lineTo(centerX - 50, centerY + 185);
        path.lineTo(centerX + 50, centerY + 185);
        path.lineTo(centerX + 65, centerY + 120);
        path.quadraticBezierTo(centerX, centerY + 100, centerX - 65, centerY + 120);
        path.close();
        canvas.drawPath(path, paint);
        final hoodPaint = Paint()
          ..color = clothesColor.withOpacity(0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6;
        canvas.drawArc(
          Rect.fromCenter(center: Offset(centerX, centerY + 110), width: 80, height: 40),
          3.14159, 3.14159, false, hoodPaint,
        );
        break;
      case 'shirt':
        final path = Path();
        path.moveTo(centerX - 55, centerY + 120);
        path.lineTo(centerX - 35, centerY + 180);
        path.lineTo(centerX + 35, centerY + 180);
        path.lineTo(centerX + 55, centerY + 120);
        path.close();
        canvas.drawPath(path, paint);
        final collarPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawLine(
          Offset(centerX - 10, centerY + 120),
          Offset(centerX, centerY + 140), collarPaint,
        );
        canvas.drawLine(
          Offset(centerX + 10, centerY + 120),
          Offset(centerX, centerY + 140), collarPaint,
        );
        break;
      case 'sweater':
        final path = Path();
        path.moveTo(centerX - 62, centerY + 120);
        path.lineTo(centerX - 45, centerY + 185);
        path.lineTo(centerX + 45, centerY + 185);
        path.lineTo(centerX + 62, centerY + 120);
        path.close();
        canvas.drawPath(path, paint);
        final stripePaint = Paint()
          ..color = clothesColor.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6;
        for (int i = 1; i <= 2; i++) {
          canvas.drawLine(
            Offset(centerX - 40, centerY + 120 + i * 20),
            Offset(centerX + 40, centerY + 120 + i * 20), stripePaint,
          );
        }
        break;
      case 'dress':
        final path = Path();
        path.moveTo(centerX - 40, centerY + 120);
        path.lineTo(centerX - 60, centerY + 180);
        path.lineTo(centerX + 60, centerY + 180);
        path.lineTo(centerX + 40, centerY + 120);
        path.close();
        canvas.drawPath(path, paint);
        break;
      case 'jacket':
        final path = Path();
        path.moveTo(centerX - 60, centerY + 120);
        path.lineTo(centerX - 50, centerY + 180);
        path.lineTo(centerX + 50, centerY + 180);
        path.lineTo(centerX + 60, centerY + 120);
        path.close();
        canvas.drawPath(path, paint);
        final zipPaint = Paint()
          ..color = Colors.grey
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawLine(
          Offset(centerX, centerY + 120),
          Offset(centerX, centerY + 180), zipPaint,
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
