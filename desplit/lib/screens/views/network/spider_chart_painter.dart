import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'network_models.dart';

class SpiderChartPainter extends CustomPainter {
  final List<RadarIndicator> indicators;
  final bool isLightMode;
  final double animationValue;

  SpiderChartPainter({
    required this.indicators,
    this.isLightMode = false,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || indicators.isEmpty) return;

    final center = Offset(size.width * 0.5, size.height * 0.5);
    final maxRadius = math.min(size.width, size.height) * 0.38;
    final int count = indicators.length;
    final angleStep = (2 * math.pi) / count;

    // 1. Draw concentric web polygons (4 levels: 25%, 50%, 75%, 100%)
    final gridPaint = Paint()
      ..color = isLightMode ? const Color(0x288B5CF6) : const Color(0x22A855F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int level = 1; level <= 4; level++) {
      final r = maxRadius * (level / 4.0);
      final webPath = Path();
      for (int i = 0; i < count; i++) {
        final angle = -math.pi / 2 + (i * angleStep);
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          webPath.moveTo(x, y);
        } else {
          webPath.lineTo(x, y);
        }
      }
      webPath.close();
      canvas.drawPath(webPath, gridPaint);
    }

    // 2. Draw radial axis lines
    final axisPaint = Paint()
      ..color = isLightMode ? const Color(0x208B5CF6) : const Color(0x18A855F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < count; i++) {
      final angle = -math.pi / 2 + (i * angleStep);
      final endX = center.dx + maxRadius * math.cos(angle);
      final endY = center.dy + maxRadius * math.sin(angle);
      canvas.drawLine(center, Offset(endX, endY), axisPaint);
    }

    // 3. Compute data polygon vertices
    final polygonPath = Path();
    final dataPoints = <Offset>[];

    for (int i = 0; i < count; i++) {
      final angle = -math.pi / 2 + (i * angleStep);
      final normalized = (indicators[i].value * animationValue).clamp(0.05, 1.0);
      final r = maxRadius * normalized;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      final pt = Offset(x, y);
      dataPoints.add(pt);

      if (i == 0) {
        polygonPath.moveTo(pt.dx, pt.dy);
      } else {
        polygonPath.lineTo(pt.dx, pt.dy);
      }
    }
    polygonPath.close();

    // 4. Fill data polygon with luminous glowing gradient
    final fillGradient = RadialGradient(
      center: Alignment.center,
      radius: 0.8,
      colors: isLightMode
          ? [
              const Color(0x558B5CF6),
              const Color(0x15A855F7),
            ]
          : [
              const Color(0x66C084FC),
              const Color(0x187C3AED),
            ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(
        Rect.fromCircle(center: center, radius: maxRadius),
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(polygonPath, fillPaint);

    // 5. Draw data polygon perimeter stroke
    final strokePaint = Paint()
      ..color = isLightMode ? const Color(0xFF8B5CF6) : const Color(0xFFC084FC)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(polygonPath, strokePaint);

    // 6. Draw glowing vertex dots
    for (final pt in dataPoints) {
      canvas.drawCircle(
        pt,
        3.5,
        Paint()
          ..color = isLightMode ? const Color(0xFF7C3AED) : const Color(0xFFEDE9FE)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        pt,
        6.0,
        Paint()
          ..color = isLightMode
              ? const Color(0x448B5CF6)
              : const Color(0x66C084FC)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SpiderChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isLightMode != isLightMode;
  }
}
