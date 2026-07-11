import 'dart:math';
import 'package:flutter/material.dart';

class EcgPainter extends CustomPainter {
  final double phase;

  EcgPainter({required this.phase});

  double _ecgFormula(double xFraction) {
    double localX = (xFraction * 4) % 1.0; 
    
    if (localX > 0.1 && localX < 0.16) {
      return sin((localX - 0.1) / 0.06 * pi) * 0.12;
    } else if (localX >= 0.16 && localX < 0.20) {
      return 0.0;
    } else if (localX >= 0.20 && localX < 0.22) {
      return -((localX - 0.20) / 0.02) * 0.15;
    } else if (localX >= 0.22 && localX < 0.26) {
      return ((localX - 0.22) / 0.04) * 1.2 - 0.15;
    } else if (localX >= 0.26 && localX < 0.29) {
      return 1.05 - ((localX - 0.26) / 0.03) * 1.35;
    } else if (localX >= 0.29 && localX < 0.38) {
      return sin((localX - 0.29) / 0.09 * pi) * 0.25;
    }
    return 0.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    const gridSpacing = 15.0;
    for (double i = 0; i < size.width; i += gridSpacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += gridSpacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    final path = Path();
    final pointsCount = size.width.toInt();
    final centerY = size.height / 2;

    for (int i = 0; i < pointsCount; i++) {
      double x = i.toDouble();
      
      double fraction = (x / size.width) - phase;
      if (fraction < 0) fraction += 1.0;
      fraction = fraction % 1.0;

      double ecgValue = _ecgFormula(fraction);
      double y = centerY - (ecgValue * centerY * 0.7);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant EcgPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}
