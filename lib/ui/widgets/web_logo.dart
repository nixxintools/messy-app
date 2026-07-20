import 'dart:math';

import 'package:flutter/material.dart';

import '../../app.dart';

/// The yellow mesh-web logo, drawn to match docs/wireframes.html.
class WebLogo extends StatelessWidget {
  const WebLogo({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _WebPainter());
  }
}

class _WebPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = messyYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width / 24;
    final c = size.center(Offset.zero);
    final r = size.width / 2 - paint.strokeWidth;
    for (final f in const [0.3, 0.65, 1.0]) {
      canvas.drawCircle(c, r * f, paint);
    }
    for (var i = 0; i < 4; i++) {
      final a = i * pi / 4;
      canvas.drawLine(
        c - Offset(cos(a), sin(a)) * r,
        c + Offset(cos(a), sin(a)) * r,
        paint,
      );
    }
    canvas.drawCircle(c, size.width / 18, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
