import 'package:flutter/material.dart';

class HairFrontPainter extends CustomPainter {
  final String hairStyle;
  final Color hairColor;

  HairFrontPainter({required this.hairStyle, required this.hairColor});

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
      ..strokeWidth = 3;
    final path = Path();
    switch (hairStyle) {
      case 'none':
        // 아무것도 그리지 않음
        break;
      case 'short-front':
        path.moveTo(centerX - 60, centerY - 100);
        path.quadraticBezierTo(centerX, centerY - 130, centerX + 60, centerY - 100);
        path.lineTo(centerX + 40, centerY - 60);
        path.quadraticBezierTo(centerX, centerY - 80, centerX - 40, centerY - 60);
        path.close();
        break;
      case 'bangs':
        path.moveTo(centerX - 50, centerY - 110);
        path.quadraticBezierTo(centerX, centerY - 140, centerX + 50, centerY - 110);
        path.lineTo(centerX + 30, centerY - 70);
        path.quadraticBezierTo(centerX, centerY - 90, centerX - 30, centerY - 70);
        path.close();
        break;
      case 'side-swept':
        path.moveTo(centerX - 60, centerY - 110);
        path.quadraticBezierTo(centerX + 40, centerY - 140, centerX + 60, centerY - 100);
        path.lineTo(centerX + 30, centerY - 60);
        path.quadraticBezierTo(centerX - 20, centerY - 80, centerX - 40, centerY - 60);
        path.close();
        break;
      case 'curtain':
        path.moveTo(centerX - 45, centerY - 110);
        path.quadraticBezierTo(centerX - 20, centerY - 140, centerX, centerY - 120);
        path.quadraticBezierTo(centerX + 20, centerY - 140, centerX + 45, centerY - 110);
        path.lineTo(centerX + 25, centerY - 70);
        path.quadraticBezierTo(centerX, centerY - 90, centerX - 25, centerY - 70);
        path.close();
        break;
      case 'center-part':
        path.moveTo(centerX - 30, centerY - 110);
        path.quadraticBezierTo(centerX, centerY - 140, centerX + 30, centerY - 110);
        path.lineTo(centerX + 15, centerY - 80);
        path.quadraticBezierTo(centerX, centerY - 100, centerX - 15, centerY - 80);
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
