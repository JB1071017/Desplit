import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'world_atlas_service.dart';

class TrafficMapPainter extends CustomPainter {
  final double animationProgress;
  final bool isLightMode;
  final bool isGlobeMode;

  TrafficMapPainter({
    required this.animationProgress,
    this.isLightMode = false,
    this.isGlobeMode = false,
  });

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
      // Draw the exact countries and borders from countries-110m.json
      canvas.save();
      canvas.scale(w, h);
      canvas.drawPath(atlas.normalizedFlatPath!, landPaint);
      canvas.drawPath(atlas.normalizedFlatPath!, landStroke);
      canvas.restore();
    } else {
      // Fallback while loading
      _drawFallbackContinents(canvas, size, landPaint, landStroke);
    }

    // Exact Geo Locations of Global Mesh Transit Hubs
    final hubUSEast = _geoToFlat(Offset(-77.48, 39.04), w, h); // Virginia
    final hubFrankfurt = _geoToFlat(Offset(8.68, 50.11), w, h); // Frankfurt
    final hubTokyo = _geoToFlat(Offset(139.69, 35.68), w, h); // Tokyo
    final hubUSWest = _geoToFlat(Offset(-122.08, 37.38), w, h); // Silicon Valley
    final hubMumbai = _geoToFlat(Offset(72.87, 19.07), w, h); // Mumbai
    final hubSydney = _geoToFlat(Offset(151.20, -33.86), w, h); // Sydney
    final hubSaoPaulo = _geoToFlat(Offset(-46.63, -23.55), w, h); // Sao Paulo
    final hubLondon = _geoToFlat(Offset(-0.12, 51.50), w, h); // London

    // Global Tensor Transit Arcs
    // 1. Virginia <-> Frankfurt
    _drawCurvedTrafficArc(
      canvas,
      hubUSEast,
      hubFrankfurt,
      isLightMode ? const Color(0xFF8B5CF6) : const Color(0xFFC084FC),
      animationProgress,
      heightOffset: -h * 0.18,
    );

    // 2. Frankfurt <-> Tokyo (Highlighted Amber Tensor Route)
    _drawCurvedTrafficArc(
      canvas,
      hubFrankfurt,
      hubTokyo,
      const Color(0xFFF97316),
      (animationProgress + 0.38) % 1.0,
      heightOffset: -h * 0.22,
    );

    // 3. Silicon Valley <-> Mumbai
    _drawCurvedTrafficArc(
      canvas,
      hubUSWest,
      hubMumbai,
      isLightMode ? const Color(0xFF7C3AED) : const Color(0xFFA855F7),
      (animationProgress + 0.72) % 1.0,
      heightOffset: -h * 0.26,
    );

    // 4. London <-> Sao Paulo
    _drawCurvedTrafficArc(
      canvas,
      hubLondon,
      hubSaoPaulo,
      isLightMode ? const Color(0xFF9333EA) : const Color(0xFFE879F9),
      (animationProgress + 0.54) % 1.0,
      heightOffset: -h * 0.12,
    );

    // Major Hub Pins
    final majorHubs = [
      hubUSEast,
      hubUSWest,
      hubFrankfurt,
      hubTokyo,
      hubMumbai,
      hubSydney,
      hubSaoPaulo,
      hubLondon,
    ];

    for (final hub in majorHubs) {
      canvas.drawCircle(
        hub,
        4.5,
        Paint()
          ..color = (isLightMode ? const Color(0xFF8B5CF6) : const Color(0xFFC084FC))
              .withValues(alpha: 0.35)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        hub,
        2.2,
        Paint()
          ..color = isLightMode ? const Color(0xFF7C3AED) : Colors.white
          ..style = PaintingStyle.fill,
      );
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

    // 5. Projected 3D Transit Arcs & City Hubs
    final hubs = <_GlobeHub>[
      _GlobeHub('Virginia', -77.48, 39.04, const Color(0xFFC084FC)),
      _GlobeHub('Frankfurt', 8.68, 50.11, const Color(0xFFFB923C)),
      _GlobeHub('Tokyo', 139.69, 35.68, const Color(0xFFF97316)),
      _GlobeHub('Mumbai', 72.87, 19.07, const Color(0xFF00F5A0)),
      _GlobeHub('London', -0.12, 51.50, const Color(0xFFA855F7)),
      _GlobeHub('Silicon Valley', -122.08, 37.38, const Color(0xFF38BDF8)),
      _GlobeHub('Sydney', 151.20, -33.86, const Color(0xFFA78BFA)),
    ];

    // Compute hub visibility and screen coordinates
    final hubScreenPositions = <String, Offset>{};
    for (final hub in hubs) {
      final lam = hub.lon * math.pi / 180.0 - lonRotation;
      final phi = hub.lat * math.pi / 180.0;
      final cosC = sinTilt * math.sin(phi) + cosTilt * math.cos(phi) * math.cos(lam);

      if (cosC > 0.08) {
        final px = center.dx + radius * math.cos(phi) * math.sin(lam);
        final py = center.dy - radius * (cosTilt * math.sin(phi) - sinTilt * math.cos(phi) * math.cos(lam));
        hubScreenPositions[hub.name] = Offset(px, py);

        // Pulsing glow aura
        final auraRadius = 3.5 + 2.0 * math.sin(animationProgress * math.pi * 2);
        canvas.drawCircle(
          Offset(px, py),
          auraRadius,
          Paint()
            ..color = hub.color.withValues(alpha: 0.35)
            ..style = PaintingStyle.fill,
        );
        // Solid Hub Pin
        canvas.drawCircle(
          Offset(px, py),
          2.2,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill,
        );
      }
    }

    // Draw Great Circle Arcs between visible hubs
    void drawGlobeArc(String from, String to, Color color, double progress) {
      final p1 = hubScreenPositions[from];
      final p2 = hubScreenPositions[to];
      if (p1 == null || p2 == null) return;

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

    drawGlobeArc('Frankfurt', 'Tokyo', const Color(0xFFF97316), (animationProgress + 0.38) % 1.0);
    drawGlobeArc('Virginia', 'Frankfurt', const Color(0xFFC084FC), animationProgress);
    drawGlobeArc('Frankfurt', 'Mumbai', const Color(0xFF00F5A0), (animationProgress + 0.72) % 1.0);

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

class _GlobeHub {
  final String name;
  final double lon;
  final double lat;
  final Color color;

  const _GlobeHub(this.name, this.lon, this.lat, this.color);
}
