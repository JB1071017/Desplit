import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class WorldCountry {
  final String id;
  final String name;
  final List<List<Offset>> rings; // dx = lon (-180..180), dy = lat (-90..90)

  const WorldCountry({
    required this.id,
    required this.name,
    required this.rings,
  });
}

class WorldAtlasService extends ChangeNotifier {
  static final WorldAtlasService _instance = WorldAtlasService._internal();
  static WorldAtlasService get instance => _instance;

  WorldAtlasService._internal();

  static const String onlineUrl = 'https://cdn.jsdelivr.net/npm/world-atlas@2/countries-110m.json';
  static const String localAsset = 'assets/data/countries-110m.json';

  bool _isLoading = false;
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;

  List<WorldCountry> _countries = [];
  List<WorldCountry> get countries => _countries;

  Path? _normalizedFlatPath;
  Path? get normalizedFlatPath => _normalizedFlatPath;

  // Ultra-lightweight simplified rings for 60fps 3D orthographic sphere projection
  List<List<Offset>> _globeRings = [];
  List<List<Offset>> get globeRings => _globeRings;

  /// Loads the world atlas TopoJSON file from bundled 110m assets or online fallback
  Future<void> loadAtlas({bool forceOnline = false}) async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;

    try {
      String? jsonStr;

      // 1. Try bundled lightweight 110m asset first if not forcing online
      if (!forceOnline) {
        try {
          jsonStr = await rootBundle.loadString(localAsset);
        } catch (e) {
          debugPrint('Local asset $localAsset not found or failed, pinging online: $e');
        }
      }

      // 2. Online ping / fallback to https://cdn.jsdelivr.net/npm/world-atlas@2/countries-110m.json
      if (jsonStr == null || jsonStr.isEmpty) {
        debugPrint('WorldAtlasService: Pinging online source $onlineUrl');
        jsonStr = await _fetchOnlineAtlas(onlineUrl);
      }

      if (jsonStr != null && jsonStr.isNotEmpty) {
        await _parseAtlasJson(jsonStr);
      } else {
        debugPrint('WorldAtlasService: Could not retrieve atlas data from local or online.');
      }
    } catch (e, st) {
      debugPrint('Error loading WorldAtlasService: $e\n$st');
    } finally {
      _isLoading = false;
    }
  }

  /// Pings and fetches the world atlas JSON from online CDN
  Future<String?> _fetchOnlineAtlas(String url) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8);
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final content = await response.transform(utf8.decoder).join();
        client.close();
        return content;
      }
      client.close();
    } catch (e) {
      debugPrint('WorldAtlasService: Failed to ping online atlas: $e');
    }
    return null;
  }

  Future<void> _parseAtlasJson(String jsonStr) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      final transform = data['transform'] as Map<String, dynamic>?;
      if (transform == null) return;

      final scaleList = (transform['scale'] as List).cast<num>();
      final translateList = (transform['translate'] as List).cast<num>();
      final double sx = scaleList[0].toDouble();
      final double sy = scaleList[1].toDouble();
      final double tx = translateList[0].toDouble();
      final double ty = translateList[1].toDouble();

      final rawArcs = data['arcs'] as List;

      // 1. Decode all delta-encoded arcs into [lon, lat]
      final decodedArcs = List<List<Offset>>.generate(rawArcs.length, (i) {
        final arc = rawArcs[i] as List;
        final pts = <Offset>[];
        double curX = 0;
        double curY = 0;
        for (final item in arc) {
          final pt = item as List;
          curX += (pt[0] as num).toDouble();
          curY += (pt[1] as num).toDouble();
          final lon = curX * sx + tx;
          final lat = curY * sy + ty;
          pts.add(Offset(lon, lat));
        }
        return pts;
      });

      // 2. Decode countries geometries
      final objects = data['objects'] as Map<String, dynamic>?;
      if (objects == null) return;
      final countriesObj = objects['countries'] as Map<String, dynamic>?;
      if (countriesObj == null) return;
      final geometries = countriesObj['geometries'] as List;

      final parsedCountries = <WorldCountry>[];
      final flatPath = Path();
      final globeRingsList = <List<Offset>>[];

      for (final g in geometries) {
        final geom = g as Map<String, dynamic>;
        final type = geom['type'] as String;
        final id = geom['id']?.toString() ?? '';
        final props = geom['properties'] as Map<String, dynamic>?;
        final name = props?['name']?.toString() ?? 'Country $id';

        final countryRings = <List<Offset>>[];

        void addRing(List<dynamic> arcIndices) {
          final ring = <Offset>[];
          for (final a in arcIndices) {
            final arcIdx = (a as num).toInt();
            if (arcIdx >= 0) {
              final pts = decodedArcs[arcIdx];
              if (ring.isEmpty) {
                ring.addAll(pts);
              } else if (pts.isNotEmpty) {
                ring.addAll(pts.skip(1));
              }
            } else {
              final reversedPts = decodedArcs[~arcIdx].reversed.toList();
              if (ring.isEmpty) {
                ring.addAll(reversedPts);
              } else if (reversedPts.isNotEmpty) {
                ring.addAll(reversedPts.skip(1));
              }
            }
          }

          if (ring.length >= 3) {
            countryRings.add(ring);

            // Add to normalized 2D flat path: lon [-180..180] -> [0..1], lat [-90..90] -> [0..1]
            final firstLon = ring.first.dx.clamp(-180.0, 180.0);
            final firstLat = ring.first.dy.clamp(-90.0, 90.0);
            flatPath.moveTo(
              (firstLon + 180.0) / 360.0,
              (90.0 - firstLat) / 180.0,
            );

            for (int i = 1; i < ring.length; i++) {
              final lon = ring[i].dx.clamp(-180.0, 180.0);
              final lat = ring[i].dy.clamp(-90.0, 90.0);
              flatPath.lineTo(
                (lon + 180.0) / 360.0,
                (90.0 - lat) / 180.0,
              );
            }
            flatPath.close();

            // Calculate ring bounding box for 3D globe selection
            double minLon = 180, maxLon = -180, minLat = 90, maxLat = -90;
            for (final pt in ring) {
              if (pt.dx < minLon) minLon = pt.dx;
              if (pt.dx > maxLon) maxLon = pt.dx;
              if (pt.dy < minLat) minLat = pt.dy;
              if (pt.dy > maxLat) maxLat = pt.dy;
            }
            final bboxDiag = (maxLon - minLon).abs() + (maxLat - minLat).abs();

            // Only include primary landmass rings with visible span on globe (>6 degrees)
            if (bboxDiag > 6.0 && ring.length >= 4) {
              if (ring.length <= 8) {
                globeRingsList.add(ring);
              } else {
                // Downsample step=2 for silky smooth 60/120 FPS animation
                final simplified = <Offset>[];
                for (int i = 0; i < ring.length; i += 2) {
                  simplified.add(ring[i]);
                }
                if (simplified.last != ring.last) {
                  simplified.add(ring.last);
                }
                globeRingsList.add(simplified);
              }
            }
          }
        }

        if (type == 'Polygon') {
          final arcLists = geom['arcs'] as List;
          for (final r in arcLists) {
            addRing(r as List);
          }
        } else if (type == 'MultiPolygon') {
          final polyLists = geom['arcs'] as List;
          for (final poly in polyLists) {
            for (final r in (poly as List)) {
              addRing(r as List);
            }
          }
        }

        parsedCountries.add(WorldCountry(
          id: id,
          name: name,
          rings: countryRings,
        ));
      }

      _countries = parsedCountries;
      _normalizedFlatPath = flatPath;
      _globeRings = globeRingsList;
      _isLoaded = true;
      notifyListeners();
      debugPrint('WorldAtlasService: Successfully loaded ${_countries.length} countries and ${_globeRings.length} globe rings from countries-110m.json');
    } catch (e, st) {
      debugPrint('Error parsing TopoJSON in WorldAtlasService: $e\n$st');
    }
  }
}
