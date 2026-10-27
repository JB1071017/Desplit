import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class NodeBadge {
  final String id;
  final String title;
  final String category;
  final String dateEarned;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;
  final String description;

  const NodeBadge({
    required this.id,
    required this.title,
    required this.category,
    required this.dateEarned,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
    required this.description,
  });
}

class BadgeHexagonPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final bool isGlowing;

  BadgeHexagonPainter({
    required this.primaryColor,
    required this.secondaryColor,
    this.isGlowing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Draw Hexagon path
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (60 * i - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Fill gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor.withValues(alpha: 0.25),
          secondaryColor.withValues(alpha: 0.10),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Border stroke
    final borderPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryColor, secondaryColor],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, borderPaint);

    // Inner glowing sphere / ball (as seen in the user's uploaded image with 50 Days Badge)
    final innerCenter = Offset(center.dx + 4, center.dy);
    final sphereRadius = radius * 0.44;

    final sphereGlowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(innerCenter, sphereRadius, sphereGlowPaint);

    final spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          Colors.white.withValues(alpha: 0.8),
          primaryColor,
          primaryColor.withValues(alpha: 0.8),
        ],
      ).createShader(Rect.fromCircle(center: innerCenter, radius: sphereRadius));
    canvas.drawCircle(innerCenter, sphereRadius, spherePaint);
  }

  @override
  bool shouldRepaint(covariant BadgeHexagonPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.isGlowing != isGlowing;
  }
}

class BadgeCardWidget extends StatefulWidget {
  final NodeBadge badge;
  final bool isSelected;
  final VoidCallback? onTap;

  const BadgeCardWidget({
    super.key,
    required this.badge,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<BadgeCardWidget> createState() => _BadgeCardWidgetState();
}

class _BadgeCardWidgetState extends State<BadgeCardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final badge = widget.badge;

    return Tooltip(
      message: '${badge.title}\n${badge.description}\nEarned: ${badge.dateEarned}',
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.isProfessional
            ? const Color(0xFF191C21)
            : (AppColors.isLight
                ? const Color(0xFF1E1B4B)
                : const Color(0xFF131026)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badge.primaryColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
          ),
        ],
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 11.5,
        height: 1.4,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isHovered
                  ? badge.primaryColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered
                    ? badge.primaryColor.withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            child: SizedBox(
              width: 58,
              height: 58,
              child: CustomPaint(
                painter: BadgeHexagonPainter(
                  primaryColor: badge.primaryColor,
                  secondaryColor: badge.secondaryColor,
                  isGlowing: _isHovered,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Icon(
                      badge.icon,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
