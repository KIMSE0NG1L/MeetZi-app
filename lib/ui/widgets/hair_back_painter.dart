import 'package:flutter/material.dart';

class HairBackPainter extends CustomPainter {
  final String hairStyle;
  final Color hairColor;

  HairBackPainter({required this.hairStyle, required this.hairColor});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final paint = Paint()
      ..color = hairColor
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final path = Path();
    switch (hairStyle) {
      case 'none':
        // 아무것도 그리지 않음
        break;
      case 'short-back':
        path.addArc(
          Rect.fromCenter(center: Offset(centerX, centerY - 80), width: 200, height: 130),
          3.14159, 3.14159,
        );
        path.lineTo(centerX + 100, centerY + 15);
        path.lineTo(centerX - 100, centerY + 15);
        path.close();
        break;
      case 'medium-back':
        path.addArc(
          Rect.fromCenter(center: Offset(centerX, centerY - 80), width: 210, height: 160),
          3.14159, 3.14159,
        );
        path.lineTo(centerX + 105, centerY + 50);
        path.lineTo(centerX - 105, centerY + 50);
        path.close();
        break;
      case 'long-back':
        path.addArc(
          Rect.fromCenter(center: Offset(centerX, centerY - 80), width: 216, height: 170),
          3.14159, 3.14159,
        );
        path.lineTo(centerX + 108, centerY + 130);
        path.lineTo(centerX - 108, centerY + 130);
        path.close();
        break;
      case 'wavy-back':
        path.addArc(
          Rect.fromCenter(center: Offset(centerX, centerY - 80), width: 220, height: 164),
          3.14159, 3.14159,
        );
        path.lineTo(centerX + 110, centerY + 90);
        path.lineTo(centerX - 110, centerY + 90);
        path.close();
        break;
      case 'bun-back':
        path.addArc(
          Rect.fromCenter(center: Offset(centerX, centerY - 80), width: 210, height: 140),
          3.14159, 3.14159,
        );
        path.lineTo(centerX + 105, centerY + 20);
        path.lineTo(centerX - 105, centerY + 20);
        path.close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, border);
        // 번(머리 똥) 추가
        canvas.drawCircle(Offset(centerX, centerY - 170), 40, paint);
        canvas.drawCircle(Offset(centerX, centerY - 170), 40, border);
        return;
      case 'ponytail-back':
        path.addArc(
          Rect.fromCenter(center: Offset(centerX, centerY - 80), width: 210, height: 140),
          3.14159, 3.14159,
        );
        path.lineTo(centerX + 105, centerY + 20);
        path.lineTo(centerX - 105, centerY + 20);
        path.close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, border);
        // 포니테일(왼쪽 아래로)
        final ponytail = Path();
        ponytail.moveTo(centerX - 20, centerY - 20);
        ponytail.quadraticBezierTo(centerX - 60, centerY + 20, centerX - 80, centerY + 80);
        ponytail.quadraticBezierTo(centerX - 85, centerY + 120, centerX - 75, centerY + 160);
        ponytail.lineTo(centerX - 65, centerY + 160);
        ponytail.quadraticBezierTo(centerX - 75, centerY + 120, centerX - 70, centerY + 80);
        ponytail.quadraticBezierTo(centerX - 50, centerY + 20, centerX - 10, centerY - 20);
        ponytail.close();
        canvas.drawPath(ponytail, paint);
        canvas.drawPath(ponytail, border);
        return;
      case 'bob-back':
        path.addArc(
          Rect.fromCenter(center: Offset(centerX, centerY - 80), width: 210, height: 160),
          3.14159, 3.14159,
        );
        path.lineTo(centerX + 105, centerY + 65);
        path.lineTo(centerX - 105, centerY + 65);
        path.close();
        break;
      case 'pixie-back':
        path.addArc(
          Rect.fromCenter(center: Offset(centerX, centerY - 80), width: 196, height: 120),
          3.14159, 3.14159,
        );
        path.lineTo(centerX + 98, centerY + 5);
        path.lineTo(centerX - 98, centerY + 5);
        path.close();
        break;
      case 'curly-back':
        path.addArc(
          Rect.fromCenter(center: Offset(centerX, centerY - 80), width: 230, height: 190),
          3.14159, 3.14159,
        );
        path.lineTo(centerX + 115, centerY + 95);
        path.lineTo(centerX - 115, centerY + 95);
        path.close();
        break;
      case 'slick-back':
        path.addArc(
          Rect.fromCenter(center: Offset(centerX, centerY - 80), width: 206, height: 136),
          3.14159, 3.14159,
        );
        path.lineTo(centerX + 103, centerY + 25);
        path.lineTo(centerX - 103, centerY + 25);
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
