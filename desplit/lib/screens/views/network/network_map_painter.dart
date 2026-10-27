import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import 'network_models.dart';

/// Ultra-lightweight, high-performance static background painter for P2P Mesh Topology.
/// Paints cyber grid crosshairs, concentric latency orbit rings, and telemetry markers.
/// Completely eliminates heavy world map vector geometry for butter-smooth 120 FPS performance.
class NetworkMapBackgroundPainter extends CustomPainter {
  final bool isLightMode;

  NetworkMapBackgroundPainter({
    required this.isLightMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.5);

    final isPro = AppColors.isProfessional;
    final primaryAccent = isPro
        ? const Color(0xFF60CDFF)
        : (isLightMode ? const Color(0xFF7C3AED) : const Color(0xFFA855F7));

    // 1. Soft Central Radial Gradient Aura behind Operator Node
    final auraGradient = RadialGradient(
      center: Alignment.center,
      radius: 0.65,
      colors: [
        primaryAccent.withValues(alpha: isPro ? 0.08 : (isLightMode ? 0.05 : 0.10)),
        primaryAccent.withValues(alpha: 0.0),
      ],
    );
    final auraPaint = Paint()
      ..shader = auraGradient.createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), auraPaint);

    // 2. High-Tech Cyber Grid (Subtle Crosshairs & Micro Dots)
    final gridPaint = Paint()
      ..color = primaryAccent.withValues(alpha: isLightMode ? 0.05 : 0.07)
      ..strokeWidth = 0.75;

    const gridStep = 80.0;
    const crossSize = 3.5;

    for (double x = 40.0; x < w; x += gridStep) {
      for (double y = 40.0; y < h; y += gridStep) {
        // Draw miniature coordinate crosshair (+) at grid intersections
        canvas.drawLine(
          Offset(x - crossSize, y),
          Offset(x + crossSize, y),
          gridPaint,
        );
        canvas.drawLine(
          Offset(x, y - crossSize),
          Offset(x, y + crossSize),
          gridPaint,
        );
      }
    }

    // 3. Concentric Latency Orbit Rings (Mesh Tiers)
    final ringRadii = [
      h * 0.22, // Tier 1: Low Latency Cluster (~187px)
      h * 0.42, // Tier 2: Regional GPU Swarm (~357px)
      h * 0.62, // Tier 3: Global Edge Relay Mesh (~527px)
    ];

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < ringRadii.length; i++) {
      final r = ringRadii[i];
      final alphaVal = (0.16 - (i * 0.035)).clamp(0.06, 0.25);
      ringPaint.color = primaryAccent.withValues(alpha: alphaVal);
      _drawDashedCircle(canvas, center, r, ringPaint, dashCount: 72 + (i * 24));
    }

    // 4. Radial Sector Spokes (12 Clock Spoke Dividers radiating from Core)
    final spokePaint = Paint()
      ..color = primaryAccent.withValues(alpha: isLightMode ? 0.04 : 0.06)
      ..strokeWidth = 0.8;

    const int spokeCount = 12;
    final maxRadius = h * 0.66;
    for (int i = 0; i < spokeCount; i++) {
      final angle = i * (2 * math.pi / spokeCount);
      final spokeStart = Offset(
        center.dx + 48 * math.cos(angle),
        center.dy + 48 * math.sin(angle),
      );
      final spokeEnd = Offset(
        center.dx + maxRadius * math.cos(angle),
        center.dy + maxRadius * math.sin(angle),
      );
      canvas.drawLine(spokeStart, spokeEnd, spokePaint);
    }

    // 5. Tier Distance Labels on Orbit Rings
    _drawTierDistanceLabels(canvas, center, ringRadii, primaryAccent);

    // 6. Cyber Compass & Topology Telemetry Badges in Canvas Corners
    _drawCyberTelemetryCorners(canvas, size, primaryAccent);
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint, {
    int dashCount = 64,
  }) {
    final double dashAngle = (2 * math.pi) / dashCount;
    for (int i = 0; i < dashCount; i += 2) {
      final startAngle = i * dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle * 0.75,
        false,
        paint,
      );
    }
  }

  void _drawTierDistanceLabels(
    Canvas canvas,
    Offset center,
    List<double> radii,
    Color accentColor,
  ) {
    final tierNames = [
      'TIER 1 • CLUSTER (<25ms)',
      'TIER 2 • SWARM (<60ms)',
      'TIER 3 • GLOBAL RELAY (<150ms)',
    ];

    final textStyle = TextStyle(
      color: accentColor.withValues(alpha: isLightMode ? 0.45 : 0.35),
      fontSize: 9.0,
      fontFamily: 'Consolas',
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    );

    // Draw along the right horizontal axis (+35° angle)
    for (int i = 0; i < radii.length && i < tierNames.length; i++) {
      final r = radii[i];
      final angle = -math.pi / 7; // ~-25 degrees upward right
      final labelPos = Offset(
        center.dx + r * math.cos(angle) + 6,
        center.dy + r * math.sin(angle) - 6,
      );

      final textPainter = TextPainter(
        text: TextSpan(text: tierNames[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, labelPos);
    }
  }

  void _drawCyberTelemetryCorners(Canvas canvas, Size size, Color accentColor) {
    final tagStyle = TextStyle(
      color: accentColor.withValues(alpha: isLightMode ? 0.40 : 0.30),
      fontSize: 8.5,
      fontFamily: 'Consolas',
      fontWeight: FontWeight.w700,
      letterSpacing: 0.9,
    );

    // Top-Left Cyber Telemetry Tag
    final tlPainter = TextPainter(
      text: TextSpan(text: 'TOPOLOGY // P2P DECENTRALIZED MESH', style: tagStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tlPainter.paint(canvas, const Offset(18, 14));

    // Bottom-Left Protocol Info
    final blPainter = TextPainter(
      text: TextSpan(
        text: 'ROUTING: KADEMLIA DHT • RELAY: LIBP2P / QUIC • PEERS: 18 ACTIVE',
        style: tagStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    blPainter.paint(canvas, Offset(18, size.height - 24));
  }

  @override
  bool shouldRepaint(covariant NetworkMapBackgroundPainter oldDelegate) {
    return oldDelegate.isLightMode != isLightMode;
  }
}

/// Ultra-smooth, 60+ FPS animated painter for Mesh Links, Dynamic Packet Pulses,
/// and Interactive Node Halos.
class NetworkMapPainter extends CustomPainter {
  final List<MeshNode> nodes;
  final List<MeshLink> links;
  final double animationProgress; // 0.0 to 1.0 looping
  final String? hoveredNodeId;
  final bool isLightMode;

  NetworkMapPainter({
    required this.nodes,
    required this.links,
    required this.animationProgress,
    this.hoveredNodeId,
    this.isLightMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width * 0.5, size.height * 0.5);
    final isPro = AppColors.isProfessional;
    final primaryAccent = isPro
        ? const Color(0xFF60CDFF)
        : (isLightMode ? const Color(0xFF7C3AED) : const Color(0xFFA855F7));

    // Precompute absolute pixel positions of each node
    final nodePositions = <String, Offset>{};
    for (final node in nodes) {
      nodePositions[node.id] = Offset(
        node.relativePos.dx * size.width,
        node.relativePos.dy * size.height,
      );
    }

    // 1. Draw Mesh Conduits (Links) between Nodes
    for (final link in links) {
      final p1 = nodePositions[link.fromId];
      final p2 = nodePositions[link.toId];
      if (p1 == null || p2 == null) continue;

      final isHoverLinked = hoveredNodeId != null &&
          (link.fromId == hoveredNodeId || link.toId == hoveredNodeId);

      // Elegant Bezier Curvature: slight organic outward curve relative to center
      final midX = (p1.dx + p2.dx) / 2;
      final midY = (p1.dy + p2.dy) / 2;
      final vecToCenter = Offset(midX - center.dx, midY - center.dy);
      // Gentle curve factor
      final curveOffset = vecToCenter * 0.18;
      final cp = Offset(midX + curveOffset.dx, midY + curveOffset.dy);

      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..quadraticBezierTo(cp.dx, cp.dy, p2.dx, p2.dy);

      if (link.isHighlighted) {
        // High-Priority Active Tensor Route (Orange / Amber Glow)
        final orangeGlow = Paint()
          ..color = const Color(0xFFF97316).withValues(alpha: 0.40)
          ..strokeWidth = isHoverLinked ? 6.0 : 4.0
          ..style = PaintingStyle.stroke;
        canvas.drawPath(path, orangeGlow);

        final orangeCore = Paint()
          ..color = const Color(0xFFFB923C)
          ..strokeWidth = isHoverLinked ? 2.5 : 1.8
          ..style = PaintingStyle.stroke;
        canvas.drawPath(path, orangeCore);

        // Prominent glowing tensor packets traveling along this route
        _drawTravelingPacket(
          canvas,
          p1,
          cp,
          p2,
          (animationProgress * 1.6) % 1.0,
          const Color(0xFFFFF7ED),
          const Color(0xFFEA580C),
          6.5,
        );
        _drawTravelingPacket(
          canvas,
          p1,
          cp,
          p2,
          ((animationProgress * 1.6) + 0.5) % 1.0,
          const Color(0xFFFED7AA),
          const Color(0xFFF97316),
          4.5,
        );
      } else {
        // Standard Cyber Mesh Link
        Color linkColor;
        double strokeW;

        if (isHoverLinked) {
          linkColor = primaryAccent;
          strokeW = 2.2;
        } else if (hoveredNodeId != null) {
          // Dim unrelated links slightly to emphasize hovered node's mesh connections
          linkColor = primaryAccent.withValues(alpha: 0.12);
          strokeW = 0.8;
        } else {
          linkColor = primaryAccent.withValues(alpha: isLightMode ? 0.28 : 0.22);
          strokeW = 1.0;
        }

        final linkPaint = Paint()
          ..color = linkColor
          ..strokeWidth = strokeW
          ..style = PaintingStyle.stroke;

        canvas.drawPath(path, linkPaint);

        // Traveling cyber data packets
        final packetProgress =
            (animationProgress * link.packetSpeed + (p1.dx * 0.003)) % 1.0;
        _drawTravelingPacket(
          canvas,
          p1,
          cp,
          p2,
          packetProgress,
          isHoverLinked ? Colors.white : primaryAccent,
          isHoverLinked
              ? primaryAccent
              : primaryAccent.withValues(alpha: 0.4),
          isHoverLinked ? 4.2 : 3.0,
        );
      }
    }

    // 2. Node Vertex Halos & Pulsing Aura
    for (final node in nodes) {
      final pos = nodePositions[node.id];
      if (pos == null) continue;

      final isHovered = node.id == hoveredNodeId;

      if (node.isUser) {
        // Operator Center Core Pulsing Reactor
        final pulsePhase = (animationProgress * 2 * math.pi);
        final pulseRadius = 18.0 + 4.0 * math.sin(pulsePhase);

        canvas.drawCircle(
          pos,
          pulseRadius + 10,
          Paint()
            ..color = primaryAccent.withValues(alpha: 0.15 + 0.08 * math.sin(pulsePhase))
            ..style = PaintingStyle.fill,
        );

        canvas.drawCircle(
          pos,
          pulseRadius,
          Paint()
            ..color = primaryAccent.withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );

        canvas.drawCircle(
          pos,
          6.0,
          Paint()
            ..color = primaryAccent
            ..style = PaintingStyle.fill,
        );
      } else if (node.isSpecialRoute) {
        // Active Tensor Worker Node Halo
        final pulseRadius = 12.0 + 3.0 * math.sin(animationProgress * 2 * math.pi);
        canvas.drawCircle(
          pos,
          pulseRadius,
          Paint()
            ..color = const Color(0xFFF97316).withValues(alpha: 0.25)
            ..style = PaintingStyle.fill,
        );
      } else if (isHovered) {
        // Hovered Node Halo
        canvas.drawCircle(
          pos,
          16.0,
          Paint()
            ..color = primaryAccent.withValues(alpha: 0.35)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  void _drawTravelingPacket(
    Canvas canvas,
    Offset p1,
    Offset cp,
    Offset p2,
    double t,
    Color coreColor,
    Color glowColor,
    double radius,
  ) {
    // Quadratic Bezier interpolation formula: B(t) = (1-t)^2*p1 + 2(1-t)t*cp + t^2*p2
    final double u = 1 - t;
    final double tt = t * t;
    final double uu = u * u;
    final double x = uu * p1.dx + 2 * u * t * cp.dx + tt * p2.dx;
    final double y = uu * p1.dy + 2 * u * t * cp.dy + tt * p2.dy;
    final pos = Offset(x, y);

    // Glow aura
    canvas.drawCircle(
      pos,
      radius * 1.9,
      Paint()
        ..color = glowColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.fill,
    );

    // Core point
    canvas.drawCircle(
      pos,
      radius,
      Paint()
        ..color = coreColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant NetworkMapPainter oldDelegate) {
    return true;
  }
}
