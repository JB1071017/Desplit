import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'network_models.dart';
import 'world_atlas_service.dart';

class TrafficMapPainter extends CustomPainter {
  final double animationProgress;
  final bool isLightMode;
  final bool isGlobeMode;
  final List<MeshNode> nodes;

  TrafficMapPainter({
    required this.animationProgress,
    this.isLightMode = false,
    this.isGlobeMode = false,
    this.nodes = const [],
  });

  static Offset _getNodeGeo(MeshNode node, int index, int total) {
    if (node.isUser) {
      final tzHours = DateTime.now().timeZoneOffset.inMinutes / 60.0;
      if (tzHours >= 5.0 && tzHours <= 6.0) {
        return const Offset(77.59, 12.97); // India
      }
      final approxLon = (tzHours * 15.0).clamp(-180.0, 180.0);
      return Offset(approxLon, 37.77);
    }
    const peerCoords = [
      Offset(8.68, 50.11),    // Central Europe
      Offset(139.69, 35.68),  // East Asia
      Offset(-77.48, 39.04),  // US East
      Offset(103.82, 1.35),   // SE Asia
      Offset(-0.12, 51.50),   // Western Europe
      Offset(151.20, -33.86), // Oceania
    ];
    final idx = (index - 1).clamp(0, peerCoords.length - 1);
    return peerCoords[idx];
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    if (isGlobeMode) {
      _paintGlobeMap(canvas, size);
    } else {
      _paintFlatMap(canvas, size);
    }
  }

  // ===========================================================================
  // 1. EXACT FLAT WORLD MAP FORMATTED FROM countries-110m.json
  // ===========================================================================
  void _paintFlatMap(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background Cyber Grid (Parallels & Meridians)
    final gridPaint = Paint()
      ..color = isLightMode
          ? const Color(0x187C3AED)
          : const Color(0x1EA855F7)
      ..strokeWidth = 0.7;

    // Parallels (-60, -30, 0, 30, 60 degrees lat)
    final latDivisions = [-60.0, -30.0, 0.0, 30.0, 60.0];
    for (final lat in latDivisions) {
      final y = ((90.0 - lat) / 180.0) * h;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Meridians (-120, -60, 0, 60, 120 degrees lon)
    final lonDivisions = [-120.0, -60.0, 0.0, 60.0, 120.0];
    for (final lon in lonDivisions) {
      final x = ((lon + 180.0) / 360.0) * w;
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }

    // Landmass Paint
    final landPaint = Paint()
      ..color = isLightMode
          ? const Color(0xFFECE6F8)
          : const Color(0xFF16122E)
      ..style = PaintingStyle.fill;

    final landStroke = Paint()
      ..color = isLightMode
          ? const Color(0xFFD4C7F6)
          : const Color(0x3AA855F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final atlas = WorldAtlasService.instance;
    if (atlas.isLoaded && atlas.normalizedFlatPath != null) {
      canvas.save();
      canvas.scale(w, h);
      canvas.drawPath(atlas.normalizedFlatPath!, landPaint);
      canvas.drawPath(atlas.normalizedFlatPath!, landStroke);
      canvas.restore();
    } else {
      _drawFallbackContinents(canvas, size, landPaint, landStroke);
    }

    // Real Registered Mesh Nodes
    final effectiveNodes = nodes.isNotEmpty
        ? nodes
        : const [
            MeshNode(
              id: 'local_node',
              title: 'OPERATOR (YOU)',
              username: '@operator',
              gpu: 'Intel Iris Xe',
              contribution: '48.4 GFLOPS',
              latency: '0 ms',
              region: 'Local Tier 0',
              relativePos: Offset(0.5, 0.5),
              icon: Icons.memory_rounded,
              isUser: true,
            ),
          ];

    final List<Offset> realScreenHubs = [];
    for (int i = 0; i < effectiveNodes.length; i++) {
      final node = effectiveNodes[i];
      final geo = _getNodeGeo(node, i, effectiveNodes.length);
      final hub = _geoToFlat(geo, w, h);
      realScreenHubs.add(hub);

      final isUser = node.isUser;
      final color = isUser ? const Color(0xFF00F5A0) : const Color(0xFF38BDF8);

      final auraRadius = 4.5 + 2.5 * math.sin(animationProgress * math.pi * 2);
      canvas.drawCircle(
        hub,
        auraRadius + 2,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        hub,
        4.0,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        hub,
        1.8,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: node.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final bgRect = Rect.fromLTWH(hub.dx - tp.width / 2 - 4, hub.dy + 7, tp.width + 8, tp.height + 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(3)),
        Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.8),
      );
      tp.paint(canvas, Offset(hub.dx - tp.width / 2, hub.dy + 8));
    }

    // Connect real nodes with Great Circle routes ONLY if peers are present
    if (effectiveNodes.length > 1) {
      final userHub = realScreenHubs.first;
      for (int i = 1; i < realScreenHubs.length; i++) {
        _drawCurvedTrafficArc(
          canvas,
          userHub,
          realScreenHubs[i],
          const Color(0xFF00F5A0),
          (animationProgress + (i * 0.25)) % 1.0,
        );
      }
    }
  }

  // ===========================================================================
  // 2. EXACT 3D ROTATING GLOBE FORMATTED FROM countries-50m.json
  // ===========================================================================
  void _paintGlobeMap(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = math.min(size.width, size.height) * 0.44;

    // Smooth continuous rotation in radians
    final lonRotation = (animationProgress * 2 * math.pi) % (2 * math.pi);
    // Slight spherical tilt towards camera for 3D perspective
    const tilt = 0.26; // ~15 degrees tilt
    final cosTilt = math.cos(tilt);
    final sinTilt = math.sin(tilt);

    // 1. Outer Deep Space Glow Ring (Shader gradient, zero blur filter cost)
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isLightMode ? const Color(0xFF8B5CF6) : const Color(0xFFA855F7))
              .withValues(alpha: 0.28),
          (isLightMode ? const Color(0xFF8B5CF6) : const Color(0xFFA855F7))
              .withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius + 8))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 8, glowPaint);

    // 2. Base Shaded Sphere (Gradient representing spherical volume)
    final spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.95,
        colors: isLightMode
            ? [
                const Color(0xFFF3EEFF),
                const Color(0xFFE2D7FB),
                const Color(0xFFD4C5F7),
              ]
            : [
                const Color(0xFF1B1536),
                const Color(0xFF120E24),
                const Color(0xFF090714),
              ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, spherePaint);

    // Clip all interior drawings to the sphere disc
    canvas.save();
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(clipPath);

    // 3. Spherical Graticule Coordinate Rings
    final gridPaint = Paint()
      ..color = isLightMode
          ? const Color(0x187C3AED)
          : const Color(0x22A855F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    // Fast Latitude rings (-60, -30, 0, 30, 60)
    for (final latDeg in [-60.0, -30.0, 0.0, 30.0, 60.0]) {
      final latRad = latDeg * math.pi / 180.0;
      final latPath = Path();
      bool isFirst = true;

      for (int step = 0; step <= 24; step++) {
        final lonDeg = -180.0 + (step / 24.0) * 360.0;
        final lam = lonDeg * math.pi / 180.0 - lonRotation;
        final cosC = sinTilt * math.sin(latRad) + cosTilt * math.cos(latRad) * math.cos(lam);
        if (cosC > 0) {
          final px = center.dx + radius * math.cos(latRad) * math.sin(lam);
          final py = center.dy - radius * (cosTilt * math.sin(latRad) - sinTilt * math.cos(latRad) * math.cos(lam));
          if (isFirst) {
            latPath.moveTo(px, py);
            isFirst = false;
          } else {
            latPath.lineTo(px, py);
          }
        } else {
          isFirst = true;
        }
      }
      canvas.drawPath(latPath, gridPaint);
    }

    // Longitude meridian rings (every 45 degrees for efficiency)
    for (int m = 0; m < 8; m++) {
      final meridianLon = m * (math.pi / 4.0);
      final lam = meridianLon - lonRotation;
      final meridianPath = Path();
      bool isFirst = true;

      for (int step = 0; step <= 20; step++) {
        final latRad = -math.pi / 2.0 + (step / 20.0) * math.pi;
        final cosC = sinTilt * math.sin(latRad) + cosTilt * math.cos(latRad) * math.cos(lam);
        if (cosC > 0) {
          final px = center.dx + radius * math.cos(latRad) * math.sin(lam);
          final py = center.dy - radius * (cosTilt * math.sin(latRad) - sinTilt * math.cos(latRad) * math.cos(lam));
          if (isFirst) {
            meridianPath.moveTo(px, py);
            isFirst = false;
          } else {
            meridianPath.lineTo(px, py);
          }
        } else {
          isFirst = true;
        }
      }
      canvas.drawPath(meridianPath, gridPaint);
    }

    // 4. Draw Exact Landmasses and Country Borders from countries-110m.json
    final landPaint = Paint()
      ..color = isLightMode
          ? const Color(0xFFDDD2F8)
          : const Color(0xFF1E1742)
      ..style = PaintingStyle.fill;

    final landStroke = Paint()
      ..color = isLightMode
          ? const Color(0xFFBAA7ED)
          : const Color(0x60A855F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85;

    final atlas = WorldAtlasService.instance;
    final ringsToDraw = atlas.isLoaded ? atlas.globeRings : [];

    final combinedLandPath = Path();
    for (final ring in ringsToDraw) {
      bool hasVisible = false;
      bool isFirst = true;

      for (final pt in ring) {
        final lam = pt.dx * math.pi / 180.0 - lonRotation;
        final phi = pt.dy * math.pi / 180.0;
        final cosC = sinTilt * math.sin(phi) + cosTilt * math.cos(phi) * math.cos(lam);

        if (cosC > -0.05) {
          final px = center.dx + radius * math.cos(phi) * math.sin(lam);
          final py = center.dy - radius * (cosTilt * math.sin(phi) - sinTilt * math.cos(phi) * math.cos(lam));
          if (isFirst) {
            combinedLandPath.moveTo(px, py);
            isFirst = false;
          } else {
            combinedLandPath.lineTo(px, py);
          }
          hasVisible = true;
        } else {
          isFirst = true;
        }
      }

      if (hasVisible) {
        combinedLandPath.close();
      }
    }
    canvas.drawPath(combinedLandPath, landPaint);
    canvas.drawPath(combinedLandPath, landStroke);

    // 5. Projected 3D Live Real Mesh Nodes
    final effectiveNodes = nodes.isNotEmpty
        ? nodes
        : const [
            MeshNode(
              id: 'local_node',
              title: 'OPERATOR (YOU)',
              username: '@operator',
              gpu: 'Intel Iris Xe',
              contribution: '48.4 GFLOPS',
              latency: '0 ms',
              region: 'Local Tier 0',
              relativePos: Offset(0.5, 0.5),
              icon: Icons.memory_rounded,
              isUser: true,
            ),
          ];

    final Map<int, Offset> hubScreenPositions = {};
    for (int i = 0; i < effectiveNodes.length; i++) {
      final node = effectiveNodes[i];
      final geo = _getNodeGeo(node, i, effectiveNodes.length);
      final lam = geo.dx * math.pi / 180.0 - lonRotation;
      final phi = geo.dy * math.pi / 180.0;
      final cosC = sinTilt * math.sin(phi) + cosTilt * math.cos(phi) * math.cos(lam);

      if (cosC > 0.05) {
        final px = center.dx + radius * math.cos(phi) * math.sin(lam);
        final py = center.dy - radius * (cosTilt * math.sin(phi) - sinTilt * math.cos(phi) * math.cos(lam));
        final pos = Offset(px, py);
        hubScreenPositions[i] = pos;

        final isUser = node.isUser;
        final color = isUser ? const Color(0xFF00F5A0) : const Color(0xFF38BDF8);

        // Pulsing glow aura
        final auraRadius = 4.0 + 3.0 * math.sin(animationProgress * math.pi * 2);
        canvas.drawCircle(
          pos,
          auraRadius + 2,
          Paint()
            ..color = color.withValues(alpha: 0.25)
            ..style = PaintingStyle.fill,
        );
        // Solid Hub Pin
        canvas.drawCircle(
          pos,
          3.5,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          pos,
          1.5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill,
        );

        // Text Badge
        final tp = TextPainter(
          text: TextSpan(
            text: '${node.title}\n${isUser ? "OPERATOR • LISTENING" : node.latency}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final labelRect = Rect.fromLTWH(px + 7, py - 9, tp.width + 8, tp.height + 4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
          Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.85),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
          Paint()
            ..color = color.withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.7,
        );
        tp.paint(canvas, Offset(px + 11, py - 7));
      }
    }

    // Draw Great Circle Arcs between visible hubs
    void drawGlobeArc(Offset p1, Offset p2, Color color, double progress) {
      final midX = (p1.dx + p2.dx) / 2;
      final midY = (p1.dy + p2.dy) / 2;
      final toCenter = Offset(midX - center.dx, midY - center.dy);
      final dist = toCenter.distance;
      final outward = dist > 0 ? toCenter / dist * (radius * 0.18) : Offset.zero;
      final cp = Offset(midX + outward.dx, midY + outward.dy);

      final arcPath = Path()
        ..moveTo(p1.dx, p1.dy)
        ..quadraticBezierTo(cp.dx, cp.dy, p2.dx, p2.dy);

      canvas.drawPath(
        arcPath,
        Paint()
          ..color = color.withValues(alpha: 0.55)
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke,
      );

      // Packet
      final u = 1 - progress;
      final tt = progress * progress;
      final uu = u * u;
      final px = uu * p1.dx + 2 * u * progress * cp.dx + tt * p2.dx;
      final py = uu * p1.dy + 2 * u * progress * cp.dy + tt * p2.dy;
      canvas.drawCircle(
        Offset(px, py),
        2.8,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }

    // Draw real Great Circle Arcs ONLY between real connected nodes
    if (effectiveNodes.length > 1 && hubScreenPositions.containsKey(0)) {
      final pUser = hubScreenPositions[0]!;
      for (int i = 1; i < effectiveNodes.length; i++) {
        final pPeer = hubScreenPositions[i];
        if (pPeer != null) {
          drawGlobeArc(pUser, pPeer, const Color(0xFF00F5A0), (animationProgress + (i * 0.3)) % 1.0);
        }
      }
    }

    canvas.restore();

    // 6. Atmosphere Rim Ring
    final rimPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [
          const Color(0xFFA855F7).withValues(alpha: 0.5),
          const Color(0xFF7C3AED).withValues(alpha: 0.2),
          const Color(0xFFA855F7).withValues(alpha: 0.6),
          const Color(0xFFC084FC).withValues(alpha: 0.3),
          const Color(0xFFA855F7).withValues(alpha: 0.5),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, radius, rimPaint);
  }

  // Helper to convert geographic lon/lat into equirectangular flat map pixel position
  Offset _geoToFlat(Offset geo, double w, double h) {
    final x = ((geo.dx + 180.0) / 360.0) * w;
    final y = ((90.0 - geo.dy) / 180.0) * h;
    return Offset(x, y);
  }

  void _drawCurvedTrafficArc(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    double progress, {
    double heightOffset = -30.0,
  }) {
    final mid = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2 + heightOffset,
    );

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);

    final arcPaint = Paint()
      ..color = color.withValues(alpha: 0.50)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, arcPaint);

    // Glowing data packet moving along spline
    final u = 1 - progress;
    final tt = progress * progress;
    final uu = u * u;
    final x = uu * start.dx + 2 * u * progress * mid.dx + tt * end.dx;
    final y = uu * start.dy + 2 * u * progress * mid.dy + tt * end.dy;
    final packetPos = Offset(x, y);

    // Outer glow
    canvas.drawCircle(
      packetPos,
      4.5,
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill,
    );
    // Core dot
    canvas.drawCircle(
      packetPos,
      2.5,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  void _drawFallbackContinents(
      Canvas canvas, Size size, Paint fillPaint, Paint strokePaint) {
    final w = size.width;
    final h = size.height;
    // Simple basic fallback if json hasn't finished parsing
    final na = [
      Offset(w * 0.10, h * 0.18),
      Offset(w * 0.28, h * 0.18),
      Offset(w * 0.28, h * 0.45),
      Offset(w * 0.15, h * 0.40),
    ];
    _drawShape(canvas, fillPaint, strokePaint, na);
  }

  void _drawShape(
      Canvas canvas, Paint fillPaint, Paint strokePaint, List<Offset> points) {
    if (points.isEmpty) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant TrafficMapPainter oldDelegate) {
    return true;
  }
}
