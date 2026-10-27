import 'package:flutter/material.dart';

class GoogleIcon extends StatelessWidget {
  final double size;

  const GoogleIcon({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = w / 2;

    final Paint blue = Paint()..color = const Color(0xFF4285F4);
    final Paint green = Paint()..color = const Color(0xFF34A853);
    final Paint yellow = Paint()..color = const Color(0xFFFBBC05);
    final Paint red = Paint()..color = const Color(0xFFEA4335);

    // Blue horizontal bar and arc
    final Path bluePath = Path()
      ..moveTo(cx, cy - r * 0.22)
      ..lineTo(cx + r * 0.95, cy - r * 0.22)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -0.2,
        1.5,
        false,
      )
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(bluePath, blue);

    // Green arc (bottom)
    final Path greenPath = Path()
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        0.8,
        1.6,
        false,
      )
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(greenPath, green);

    // Yellow arc (left-bottom)
    final Path yellowPath = Path()
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        2.4,
        1.2,
        false,
      )
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(yellowPath, yellow);

    // Red arc (top)
    final Path redPath = Path()
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        3.6,
        1.6,
        false,
      )
      ..lineTo(cx, cy)
      ..close();
    canvas.drawPath(redPath, red);

    // Inner cutout circle to make the "G" ring
    final Paint innerCut = Paint()..color = const Color(0xFF151329);
    canvas.drawCircle(Offset(cx, cy), r * 0.54, innerCut);

    // Clean up inner right notch for "G"
    final Paint whiteBar = Paint()..color = const Color(0xFF4285F4);
    final Rect barRect = Rect.fromLTRB(
      cx,
      cy - r * 0.18,
      cx + r * 0.94,
      cy + r * 0.18,
    );
    canvas.drawRect(barRect, whiteBar);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GithubIcon extends StatelessWidget {
  final double size;
  final Color color;

  const GithubIcon({
    super.key,
    this.size = 18,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GithubLogoPainter(color: color),
    );
  }
}

class _GithubLogoPainter extends CustomPainter {
  final Color color;

  _GithubLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    // Standard GitHub Octocat silhouette path
    final Path path = Path();
    path.moveTo(12.0, 2.0);
    path.cubicTo(6.48, 2.0, 2.0, 6.48, 2.0, 12.0);
    path.cubicTo(2.0, 16.42, 4.87, 20.17, 8.84, 21.5);
    path.cubicTo(9.34, 21.58, 9.5, 21.27, 9.5, 21.0);
    path.cubicTo(9.5, 20.77, 9.5, 20.14, 9.5, 19.31);
    path.cubicTo(6.73, 19.91, 6.14, 17.97, 6.14, 17.97);
    path.cubicTo(5.68, 16.81, 5.03, 16.5, 5.03, 16.5);
    path.cubicTo(4.12, 15.88, 5.1, 15.9, 5.1, 15.9);
    path.cubicTo(6.1, 15.97, 6.63, 16.93, 6.63, 16.93);
    path.cubicTo(7.52, 18.45, 8.97, 18.02, 9.54, 17.76);
    path.cubicTo(9.63, 17.11, 9.89, 16.67, 10.17, 16.42);
    path.cubicTo(7.95, 16.17, 5.62, 15.31, 5.62, 11.5);
    path.cubicTo(5.62, 10.41, 6.01, 9.51, 6.65, 8.81);
    path.cubicTo(6.55, 8.56, 6.21, 7.54, 6.75, 6.15);
    path.cubicTo(6.75, 6.15, 7.59, 5.88, 9.5, 7.17);
    path.cubicTo(10.3, 6.95, 11.15, 6.84, 12.0, 6.84);
    path.cubicTo(12.85, 6.84, 13.7, 6.95, 14.5, 7.17);
    path.cubicTo(16.41, 5.88, 17.25, 6.15, 17.25, 6.15);
    path.cubicTo(17.79, 7.54, 17.45, 8.56, 17.35, 8.81);
    path.cubicTo(17.99, 9.51, 18.38, 10.41, 18.38, 11.5);
    path.cubicTo(18.38, 15.32, 16.04, 16.16, 13.81, 16.41);
    path.cubicTo(14.17, 16.72, 14.5, 17.33, 14.5, 18.26);
    path.cubicTo(14.5, 19.6, 14.5, 20.68, 14.5, 21.0);
    path.cubicTo(14.5, 21.28, 14.66, 21.6, 15.17, 21.5);
    path.cubicTo(19.14, 20.16, 22.0, 16.42, 22.0, 12.0);
    path.cubicTo(22.0, 6.48, 17.52, 2.0, 12.0, 2.0);
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GithubLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}
