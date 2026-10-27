import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Ambient glowing violet gradient background inspired by Proton VPN's
/// signature atmospheric lighting, tuned with light violet gradients for
/// optimal contrast, readability, and zero CPU/GPU overhead.
class AmbientVioletBackground extends StatelessWidget {
  final Widget child;
  final bool showGrid;

  const AmbientVioletBackground({
    super.key,
    required this.child,
    this.showGrid = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Deep canvas base
        Container(
          color: AppColors.canvasBackground,
        ),

        // 2. Atmospheric Upper-Center Radial Glow (Proton style violet aurora for dark/light themes)
        if (!AppColors.isProfessional)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.45),
                  radius: 1.20,
                  colors: [
                    AppColors.auraCenter.withValues(alpha: 0.42),
                    AppColors.auraMid.withValues(alpha: 0.22),
                    AppColors.isLight
                        ? const Color(0x058B5CF6)
                        : const Color(0x103B1A6E),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.40, 0.75, 1.0],
                ),
              ),
            ),
          ),

        // 3. Subtle secondary bottom-left ambient fill
        if (!AppColors.isProfessional)
          Positioned(
            left: -150,
            bottom: -150,
            width: 500,
            height: 500,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.brandAccent.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

        // 4. Subtle cyber topology grid (cached static paint)
        if (showGrid && !AppColors.isProfessional)
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: const _StaticTopologyGridPainter(),
              ),
            ),
          ),

        // 5. Main content
        child,
      ],
    );
  }
}

class _StaticTopologyGridPainter extends CustomPainter {
  const _StaticTopologyGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.accentLight.withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw subtle coordinate grid lines
    const double step = 64.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Draw faint concentric topological circles near center-top
    final center = Offset(size.width * 0.55, size.height * 0.42);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      final double radius = i * 90.0;
      ringPaint.color = AppColors.accentLight.withValues(
        alpha: (0.04 - (i * 0.01)).clamp(0.01, 0.05),
      );
      canvas.drawCircle(center, radius, ringPaint);
    }

    // Small glowing anchor dots at grid intersections
    final dotPaint = Paint()
      ..color = AppColors.accentNeon.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    for (double x = step * 2; x < size.width; x += step * 3) {
      for (double y = step * 2; y < size.height; y += step * 3) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
