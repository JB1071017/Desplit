import 'package:flutter/material.dart';

/// Custom painter for Windows Task Manager grid charts with the
/// sleek purple gradient waveform theme from Image 2.
class TaskManagerChartPainter extends CustomPainter {
  final List<double> dataPoints; // Values from 0.0 to 1.0 (or percentage)
  final double maxValue;
  final Color strokeColor;
  final Color fillStartColor;
  final Color fillEndColor;
  final Color gridColor;
  final double? hoverNormalizedX; // 0.0 to 1.0
  final bool showGrid;
  final int gridRows;
  final int gridCols;

  TaskManagerChartPainter({
    required this.dataPoints,
    this.maxValue = 100.0,
    this.strokeColor = const Color(0xFFC084FC),
    this.fillStartColor = const Color(0x66A855F7),
    this.fillEndColor = const Color(0x057C3AED),
    this.gridColor = const Color(0x22A855F7),
    this.hoverNormalizedX,
    this.showGrid = true,
    this.gridRows = 4,
    this.gridCols = 10,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Draw Task Manager background grid lines
    if (showGrid) {
      final gridPaint = Paint()
        ..color = gridColor
        ..strokeWidth = 1.0;

      // Horizontal grid lines
      final rowStep = size.height / gridRows;
      for (int i = 0; i <= gridRows; i++) {
        final y = (i * rowStep).clamp(0.0, size.height);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }

      // Vertical grid lines
      final colStep = size.width / gridCols;
      for (int i = 0; i <= gridCols; i++) {
        final x = (i * colStep).clamp(0.0, size.width);
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
    }

    if (dataPoints.isEmpty) return;

    // 2. Compute coordinate points
    final points = <Offset>[];
    final count = dataPoints.length;
    final stepX = count > 1 ? size.width / (count - 1) : size.width;

    final safeMax = maxValue > 0 ? maxValue : 1.0;
    for (int i = 0; i < count; i++) {
      final normalizedY = (dataPoints[i] / safeMax).clamp(0.0, 1.0);
      final x = i * stepX;
      final y = size.height - (normalizedY * size.height);
      points.add(Offset(x, y));
    }

    // 3. Build smooth path using cubic Bezier curves
    final path = Path();
    final fillPath = Path();

    path.moveTo(points.first.dx, points.first.dy);
    fillPath.moveTo(points.first.dx, size.height);
    fillPath.lineTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cx = p0.dx + (p1.dx - p0.dx) / 2;
      path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
      fillPath.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    // 4. Fill gradient area (Image 2's purple mountain glow)
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [fillStartColor, fillEndColor],
    );
    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // 5. Draw the luminous waveform stroke
    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    // 6. Optional hover guide line & pinpoint circle (from Image 2 tooltip)
    if (hoverNormalizedX != null) {
      final hoverX = (hoverNormalizedX! * size.width).clamp(0.0, size.width);
      final guidePaint = Paint()
        ..color = strokeColor.withValues(alpha: 0.6)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(hoverX, 0), Offset(hoverX, size.height), guidePaint);

      // Find interpolated Y value at hoverX
      final index = ((hoverX / size.width) * (count - 1)).clamp(0, count - 1).toInt();
      final targetPoint = points[index];

      // Outer glow circle
      canvas.drawCircle(
        targetPoint,
        6.0,
        Paint()
          ..color = strokeColor.withValues(alpha: 0.4)
          ..style = PaintingStyle.fill,
      );

      // Inner white pin dot
      canvas.drawCircle(
        targetPoint,
        3.0,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TaskManagerChartPainter oldDelegate) {
    return true;
  }
}
