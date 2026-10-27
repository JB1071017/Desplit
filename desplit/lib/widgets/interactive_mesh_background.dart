import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class InteractiveMeshBackground extends StatefulWidget {
  final Widget? child;
  final int particleCount;

  const InteractiveMeshBackground({
    super.key,
    this.child,
    this.particleCount = 80,
  });

  @override
  State<InteractiveMeshBackground> createState() =>
      _InteractiveMeshBackgroundState();
}

class _InteractiveMeshBackgroundState extends State<InteractiveMeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset? _mousePosition;
  Size _lastSize = Size.zero;
  final List<_MeshParticle> _particles = [];
  final Random _rng = Random(42);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _controller.addListener(_updatePhysics);
  }

  @override
  void dispose() {
    _controller.removeListener(_updatePhysics);
    _controller.dispose();
    super.dispose();
  }

  void _initParticles(Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    _lastSize = size;
    _particles.clear();

    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(
        _MeshParticle(
          x: _rng.nextDouble() * size.width,
          y: _rng.nextDouble() * size.height,
          vx: (_rng.nextDouble() - 0.5) * 0.7,
          vy: (_rng.nextDouble() - 0.5) * 0.7,
          baseRadius: 1.6 + _rng.nextDouble() * 1.6,
          phase: _rng.nextDouble() * 2 * pi,
        ),
      );
    }
  }

  void _updatePhysics() {
    if (_lastSize.width <= 0 || _lastSize.height <= 0) return;

    final double width = _lastSize.width;
    final double height = _lastSize.height;
    final Offset? mouse = _mousePosition;
    const double mouseRadius = 180.0;
    const double repulsionStrength = 2.8;

    for (final p in _particles) {
      // Natural drifting motion
      p.x += p.vx;
      p.y += p.vy;

      // Wrap around bounds smoothly
      if (p.x < -10) p.x = width + 10;
      if (p.x > width + 10) p.x = -10;
      if (p.y < -10) p.y = height + 10;
      if (p.y > height + 10) p.y = -10;

      // Mouse interactivity (Repulsion + Excitation Glow)
      if (mouse != null) {
        final double dx = p.x - mouse.dx;
        final double dy = p.y - mouse.dy;
        final double dist = sqrt(dx * dx + dy * dy);

        if (dist < mouseRadius && dist > 0.001) {
          // Repulsion force
          final double force = (1.0 - dist / mouseRadius) * repulsionStrength;
          p.x += (dx / dist) * force;
          p.y += (dy / dist) * force;

          // Target excitation
          final double targetExcitation = (1.0 - dist / mouseRadius);
          p.excitation += (targetExcitation - p.excitation) * 0.25;
        } else {
          // Decay excitation smoothly
          p.excitation *= 0.94;
        }
      } else {
        p.excitation *= 0.94;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final currentSize = Size(constraints.maxWidth, constraints.maxHeight);
        if (_particles.isEmpty || _lastSize != currentSize) {
          _initParticles(currentSize);
        }

        return MouseRegion(
          onHover: (event) {
            _mousePosition = event.localPosition;
          },
          onExit: (_) {
            _mousePosition = null;
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _MeshPainter(
                  particles: _particles,
                  mousePosition: _mousePosition,
                  time: _controller.value * 2 * pi,
                ),
                size: Size.infinite,
              ),
              if (widget.child != null) widget.child!,
            ],
          ),
        );
      },
    );
  }
}

class _MeshParticle {
  double x;
  double y;
  double vx;
  double vy;
  double baseRadius;
  double phase;
  double excitation = 0.0;

  _MeshParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.baseRadius,
    required this.phase,
  });
}

class _MeshPainter extends CustomPainter {
  final List<_MeshParticle> particles;
  final Offset? mousePosition;
  final double time;

  _MeshPainter({
    required this.particles,
    required this.mousePosition,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double maxConnectionDist = 125.0;
    const double maxMouseConnectDist = 170.0;

    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint nodePaint = Paint()..style = PaintingStyle.fill;
    final Paint glowPaint = Paint()..style = PaintingStyle.fill;

    // 1. Draw connections between mesh nodes
    final int count = particles.length;
    for (int i = 0; i < count; i++) {
      final p1 = particles[i];
      for (int j = i + 1; j < count; j++) {
        final p2 = particles[j];
        final double dx = p1.x - p2.x;
        final double dy = p1.y - p2.y;
        final double dist = sqrt(dx * dx + dy * dy);

        if (dist < maxConnectionDist) {
          final double normalizedDist = 1.0 - (dist / maxConnectionDist);
          final double maxExc = max(p1.excitation, p2.excitation);

          // Base subtle alpha + excitation boost
          final double alpha = (normalizedDist * 0.16 + maxExc * 0.40).clamp(0.0, 0.75);

          final Color lineColor = Color.lerp(
            AppColors.brandAccent.withValues(alpha: alpha),
            AppColors.accentHover.withValues(alpha: alpha),
            maxExc,
          )!;

          linePaint.color = lineColor;
          linePaint.strokeWidth = 0.75 + (maxExc * 0.85);

          canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), linePaint);
        }
      }
    }

    // 2. Draw active probe connections to mouse cursor
    if (mousePosition != null) {
      final mouse = mousePosition!;
      for (final p in particles) {
        final double dx = p.x - mouse.dx;
        final double dy = p.y - mouse.dy;
        final double dist = sqrt(dx * dx + dy * dy);

        if (dist < maxMouseConnectDist) {
          final double norm = 1.0 - (dist / maxMouseConnectDist);
          final double alpha = (norm * 0.45).clamp(0.0, 0.65);

          linePaint.color = AppColors.accentHover.withValues(alpha: alpha);
          linePaint.strokeWidth = 1.1;

          canvas.drawLine(mouse, Offset(p.x, p.y), linePaint);
        }
      }

      // Small cursor focal halo
      final Paint cursorGlow = Paint()
        ..color = AppColors.brandAccent.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawCircle(mouse, 22, cursorGlow);

      final Paint cursorDot = Paint()
        ..color = AppColors.accentHover.withValues(alpha: 0.75)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(mouse, 2.5, cursorDot);
    }

    // 3. Draw mesh node points
    for (final p in particles) {
      final double pulse = 0.85 + 0.15 * sin(time + p.phase);
      final double radius = p.baseRadius * pulse + (p.excitation * 1.5);

      // Node aura glow when excited or nearby
      if (p.excitation > 0.05) {
        glowPaint.color = AppColors.accentHover.withValues(
          alpha: (p.excitation * 0.35).clamp(0.0, 0.5),
        );
        glowPaint.maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          4.0 + p.excitation * 6.0,
        );
        canvas.drawCircle(Offset(p.x, p.y), radius * 2.6, glowPaint);
      }

      // Center node dot
      final Color nodeColor = Color.lerp(
        AppColors.textSecondary.withValues(alpha: 0.35),
        AppColors.textPrimary,
        (p.excitation * 1.2).clamp(0.0, 1.0),
      )!;

      nodePaint.color = nodeColor;
      canvas.drawCircle(Offset(p.x, p.y), radius, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) => true;
}
