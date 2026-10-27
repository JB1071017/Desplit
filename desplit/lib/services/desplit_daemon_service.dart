import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../screens/views/network/network_models.dart';

/// Singleton service connecting the Flutter UI to the local DeSplit Engine Daemon (http://127.0.0.1:8240).
class DeSplitDaemonService {
  static final DeSplitDaemonService instance = DeSplitDaemonService._internal();

  DeSplitDaemonService._internal();

  static const String daemonBaseUrl = 'http://127.0.0.1:8240';

  final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 2);

  Timer? _metricsTimer;
  Timer? _clusterTimer;

  final ValueNotifier<bool> isDaemonConnected = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isNodeOnline = ValueNotifier<bool>(true);
  final ValueNotifier<Map<String, dynamic>?> hardwareMetrics =
      ValueNotifier<Map<String, dynamic>?>(null);
  final ValueNotifier<Map<String, dynamic>?> clusterState =
      ValueNotifier<Map<String, dynamic>?>(null);
  final ValueNotifier<List<MeshNode>> meshNodes =
      ValueNotifier<List<MeshNode>>([]);

  bool _isInitialized = false;

  void init() {
    if (_isInitialized) return;
    _isInitialized = true;

    // Initial fetch
    _fetchStatus();
    _fetchHardware();
    _fetchCluster();

    // High frequency metrics polling (every 1.5 seconds)
    _metricsTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _fetchHardware();
    });

    // Cluster state polling (every 3 seconds)
    _clusterTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchStatus();
      _fetchCluster();
    });
  }

  void dispose() {
    _metricsTimer?.cancel();
    _clusterTimer?.cancel();
  }

  Future<void> _fetchStatus() async {
    try {
      final uri = Uri.parse('$daemonBaseUrl/api/v1/status');
      final request = await _httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        isDaemonConnected.value = true;
        isNodeOnline.value = data['is_online'] ?? true;
      } else {
        isDaemonConnected.value = false;
      }
    } catch (_) {
      isDaemonConnected.value = false;
    }
  }

  Future<void> _fetchHardware() async {
    try {
      final uri = Uri.parse('$daemonBaseUrl/api/v1/hardware');
      final request = await _httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        hardwareMetrics.value = data;
        isDaemonConnected.value = true;
      }
    } catch (_) {
      // Keep existing cache if temporarily unavailable
    }
  }

  Future<void> _fetchCluster() async {
    try {
      final uri = Uri.parse('$daemonBaseUrl/api/v1/cluster');
      final request = await _httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        clusterState.value = data;
        isDaemonConnected.value = true;
        _updateMeshNodes(data);
      }
    } catch (_) {
      // Keep existing cache
    }
  }

  /// Toggle Master Power Switch in Daemon
  Future<bool> togglePool(bool online) async {
    isNodeOnline.value = online;
    try {
      final uri = Uri.parse('$daemonBaseUrl/api/v1/pool/toggle');
      final request = await _httpClient.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'online': online}));
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final newOnline = data['is_online'] as bool? ?? online;
        isNodeOnline.value = newOnline;
        await _fetchCluster();
        return newOnline;
      }
    } catch (e) {
      debugPrint('Error toggling daemon pool: $e');
    }
    return online;
  }

  /// Convert backend cluster state into dynamic MeshNodes for the NetworkView
  void _updateMeshNodes(Map<String, dynamic> data) {
    final rawNodes = data['nodes'] as List<dynamic>? ?? [];
    if (rawNodes.isEmpty) return;

    final List<MeshNode> list = [];

    // Coordinates for surrounding peers
    final peerPositions = [
      const Offset(0.39, 0.35),
      const Offset(0.61, 0.35),
      const Offset(0.36, 0.50),
      const Offset(0.64, 0.50),
      const Offset(0.42, 0.65),
      const Offset(0.58, 0.65),
      const Offset(0.28, 0.42),
      const Offset(0.72, 0.42),
    ];

    int peerIdx = 0;
    for (final n in rawNodes) {
      final node = n as Map<String, dynamic>;
      final nodeId = node['node_id'] as String? ?? '';
      final hostname = node['hostname'] as String? ?? 'Node';
      final isUser = hostname.contains('(YOU)');
      final hw = node['hardware'] as Map<String, dynamic>? ?? {};
      final gpus = hw['gpus'] as List<dynamic>? ?? [];
      final cpu = hw['cpu'] as Map<String, dynamic>? ?? {};
      final ram = hw['ram'] as Map<String, dynamic>? ?? {};
      final ep = node['endpoint'] as Map<String, dynamic>? ?? {};
      final bench = hw['benchmark'] as Map<String, dynamic>? ?? {};

      String gpuName = 'CPU Cluster';
      String contribution = '';

      final totalVramMb = (hw['total_vram_mb'] as num? ?? 0).toInt();
      final totalRamGb = ((ram['total_ram_mb'] as num? ?? 0) / 1024).toStringAsFixed(1);
      final cores = cpu['logical_cores'] ?? 12;
      final gflops = (bench['gpu_gflops'] as num? ?? 0.0) + (bench['cpu_gflops'] as num? ?? 0.0);
      final perfStr = gflops >= 1000
          ? '${(gflops / 1000).toStringAsFixed(1)} TFLOPS'
          : '${gflops.toStringAsFixed(1)} GFLOPS';

      if (gpus.isNotEmpty) {
        final g0 = gpus[0] as Map<String, dynamic>;
        gpuName = g0['name'] as String? ?? 'GPU';
        if (totalVramMb >= 1024) {
          final vramGb = (totalVramMb / 1024).toStringAsFixed(1);
          contribution = '$perfStr • $vramGb GB VRAM';
        } else {
          contribution = '$perfStr • $cores Cores • $totalRamGb GB RAM';
        }
      } else {
        contribution = '$perfStr • $cores Cores • $totalRamGb GB RAM';
      }

      final pubIp = ep['public_ip'] as String? ?? '127.0.0.1';
      final latency = isUser ? '0 ms' : '${12 + (peerIdx * 7)} ms';

      Offset pos;
      if (isUser) {
        pos = const Offset(0.50, 0.50);
      } else {
        pos = peerPositions[peerIdx % peerPositions.length];
        peerIdx++;
      }

      list.add(
        MeshNode(
          id: nodeId,
          title: isUser ? 'OPERATOR (YOU)' : hostname.toUpperCase(),
          username: '@${nodeId.replaceAll("node_", "")}',
          gpu: gpuName,
          contribution: contribution,
          latency: latency,
          region: isUser ? 'Local Node (Tier 0)' : '$hostname ($pubIp)',
          relativePos: pos,
          icon: isUser
              ? Icons.memory_rounded
              : (gpus.isNotEmpty ? Icons.dns_rounded : Icons.computer_rounded),
          isUser: isUser,
          isSpecialRoute: peerIdx == 1,
        ),
      );
    }

    meshNodes.value = list;
  }
}
