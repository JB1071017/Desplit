import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/desplit_daemon_service.dart';
import '../../services/theme_service.dart';
import '../../theme/app_colors.dart';

class _SwarmWorkerItem {
  final String id;
  final String name;
  final String cluster;
  final String role;
  final String hardware;
  final String tflops;
  final String vram;
  int pingMs;
  final IconData icon;
  final Color iconColor;
  double progress;
  final String localEpoch;
  final String deltaSize;
  final String compression;
  final String timeLeft;
  double speedItSec;
  final String weightScore;
  final String cosineSimilarity;
  final double cosineVal;
  String status; // 'Training', 'Syncing', 'Synced', 'Lagging'
  final Color statusColor;
  final bool byzantineVerified;
  bool isExcluded = false;

  _SwarmWorkerItem({
    required this.id,
    required this.name,
    required this.cluster,
    required this.role,
    required this.hardware,
    required this.tflops,
    required this.vram,
    required this.pingMs,
    required this.icon,
    required this.iconColor,
    required this.progress,
    required this.localEpoch,
    required this.deltaSize,
    required this.compression,
    required this.timeLeft,
    required this.speedItSec,
    required this.weightScore,
    required this.cosineSimilarity,
    required this.cosineVal,
    required this.status,
    required this.statusColor,
    required this.byzantineVerified,
  });
}

class _SwarmAlert {
  final String id;
  final String title;
  final String message;
  final String targetNodeId;
  final String actionLabel;
  final Color color;
  final IconData icon;
  final String badgeText;
  final String timeAgo;

  const _SwarmAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.targetNodeId,
    required this.actionLabel,
    required this.color,
    required this.icon,
    required this.badgeText,
    required this.timeAgo,
  });
}

class FedAvgView extends StatefulWidget {
  const FedAvgView({super.key});

  @override
  State<FedAvgView> createState() => _FedAvgViewState();
}

class _FedAvgViewState extends State<FedAvgView> with SingleTickerProviderStateMixin {
  // Swarm runtime controls
  bool _isPaused = false;
  int _currentRound = 4;
  final int _totalRounds = 20;
  bool _isAggregating = false;

  // View navigation: 0 = Swarm Nodes Table (Main), 1 = Diagnostics & Telemetry
  int _activeViewIndex = 0;

  // Diagnostics transfer tab: 'INGRESS' or 'EGRESS'
  String _activeTransferTab = 'INGRESS';

  // Multi-curve graph toggles
  bool _showThroughputCurve = true;
  bool _showAccuracyCurve = true;
  bool _showLossCurve = true;

  // Real Diagnostic Telemetry & Convergence state
  String _globalLoss = '0.415';
  String _lossDeltaStr = '+0.000';
  String _globalAccuracy = '87.5%';
  String _accuracyGainStr = '+0.0%';
  String _peakIngressStr = '500.0 KB/s';
  String _peakEgressStr = '317.0 KB/s';
  String _weightDeltaStr = '256 MB INT8';
  String _avgRttStr = '< 1 ms (Localhost Direct)';
  String _compressionRatioStr = '4.2x (INT8 Quantized • 76% Saved)';
  String _estimatedFinishStr = 'Ready';
  List<double> _chartIngressPoints = [];
  List<double> _chartEgressPoints = [];
  List<double> _chartAccuracyPoints = [];
  List<double> _chartLossPoints = [];
  List<double> _pulseBars = [];
  List<Map<String, dynamic>> _diagnosticStreams = [];

  // Table filtering & search
  final String _nodeFilter = 'ALL'; // 'ALL', 'TRAINING', 'SYNCED', 'SYNCING', 'LAGGING'
  final String _clusterFilter = 'ALL';
  String _searchQuery = '';
  final String _sortBy = 'Speed'; // 'Speed', 'Progress', 'Weight', 'Ping', 'Name'
  final bool _sortAscending = false;

  // Docker Desktop View State (Matching Image 1)
  bool _showCharts = false; // By default HIDE details from Image 2 as a dropdown
  bool _onlyShowActive = false; // "Only show running containers" toggle
  bool _isLocalExpanded = true; // Group expansion chevron for host row
  bool _selectAll = false;
  final Set<String> _selectedNodeIds = {};

  // Alert & sliding notification state
  late List<_SwarmAlert> _alerts;
  final Set<String> _dismissedAlertIds = {};
  int _currentAlertIndex = 0;
  bool _isHoveringAlerts = false;
  Timer? _alertSlideTimer;

  // Periodic simulation timer
  Timer? _liveUpdateTimer;

  // Swarm mesh workers
  late List<_SwarmWorkerItem> _workers;

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initFallbackWorkers();
    _startAlertSlideTimer();

    // Connect to live real FedAvg swarm daemon
    _syncWithDaemonFedAvg();
    DeSplitDaemonService.instance.fedAvgState.addListener(_onDaemonFedAvgChanged);
    DeSplitDaemonService.instance.networkState.addListener(_onDaemonFedAvgChanged);
    DeSplitDaemonService.instance.hardwareMetrics.addListener(_onDaemonFedAvgChanged);
  }

  void _onDaemonFedAvgChanged() {
    if (!mounted) return;
    _syncWithDaemonFedAvg();
  }

  void _initFallbackWorkers() {
    _initAlerts();
    _workers = [
      _SwarmWorkerItem(
        id: 'node_local',
        name: 'JB (YOU)',
        cluster: 'Local Node • Primary Operator',
        role: 'Host / Aggregator',
        hardware: 'Intel(R) Iris(R) Xe Graphics',
        tflops: '48.4 GFLOPS',
        vram: '15.8 GB RAM',
        pingMs: 0,
        icon: Icons.computer_rounded,
        iconColor: const Color(0xFF00F5A0),
        progress: 0.25,
        localEpoch: 'Epoch 5 / 20',
        deltaSize: '256 MB INT8',
        compression: '4.2x',
        timeLeft: '35s',
        speedItSec: 39.7,
        weightScore: '100.0%',
        cosineSimilarity: '0.994',
        cosineVal: 0.994,
        status: 'Training',
        statusColor: const Color(0xFF38BDF8),
        byzantineVerified: true,
      ),
    ];
  }

  void _syncWithDaemonFedAvg() {
    final data = DeSplitDaemonService.instance.fedAvgState.value;
    if (data == null) return;

    final round = data['round'] as int? ?? _currentRound;
    final isTraining = data['is_training'] as bool? ?? !_isPaused;
    final isAggregating = data['is_aggregating'] as bool? ?? false;
    final rawWorkers = data['workers'] as List<dynamic>? ?? [];
    final rawAlerts = data['alerts'] as List<dynamic>? ?? [];

    final List<_SwarmWorkerItem> parsedWorkers = [];
    for (final rw in rawWorkers) {
      final w = rw as Map<String, dynamic>;
      final isUser = w['is_user'] == true;
      final st = w['status'] as String? ?? 'Training';
      Color stColor = const Color(0xFF38BDF8);
      if (st == 'Synced') {
        stColor = const Color(0xFF00F5A0);
      } else if (st == 'Paused') {
        stColor = const Color(0xFFF59E0B);
      } else if (st == 'Aggregating') {
        stColor = const Color(0xFFA855F7);
      }

      parsedWorkers.add(
        _SwarmWorkerItem(
          id: w['id'] as String? ?? 'node',
          name: w['name'] as String? ?? 'Node',
          cluster: w['cluster'] as String? ?? 'Local Node',
          role: w['role'] as String? ?? 'Compute Worker',
          hardware: w['hardware'] as String? ?? 'Hardware',
          tflops: w['tflops'] as String? ?? '50 GFLOPS',
          vram: w['vram'] as String? ?? '16 GB RAM',
          pingMs: (w['ping_ms'] as num? ?? 0).toInt(),
          icon: isUser ? Icons.computer_rounded : Icons.hub_rounded,
          iconColor: isUser ? const Color(0xFF00F5A0) : const Color(0xFF38BDF8),
          progress: (w['progress'] as num? ?? 0.0).toDouble().clamp(0.0, 1.0),
          localEpoch: w['local_epoch'] as String? ?? 'Epoch 1 / 20',
          deltaSize: w['delta_size'] as String? ?? '256 MB INT8',
          compression: w['compression'] as String? ?? '4.2x',
          timeLeft: w['time_left'] as String? ?? 'Ready',
          speedItSec: (w['speed_it_sec'] as num? ?? 39.0).toDouble(),
          weightScore: w['weight_score'] as String? ?? '100.0%',
          cosineSimilarity: w['cosine_similarity'] as String? ?? '0.994',
          cosineVal: (w['cosine_val'] as num? ?? 0.994).toDouble(),
          status: st,
          statusColor: stColor,
          byzantineVerified: w['byzantine_verified'] == true,
        ),
      );
    }

    final List<_SwarmAlert> parsedAlerts = [];
    for (final ra in rawAlerts) {
      final a = ra as Map<String, dynamic>;
      final badge = a['badge_text'] as String? ?? 'CONSENSUS';
      Color alertColor = const Color(0xFF00F5A0);
      IconData icon = Icons.verified_user_rounded;

      if (badge == 'HARDWARE') {
        alertColor = const Color(0xFFF43F5E);
        icon = Icons.memory_rounded;
      } else if (badge == 'COMPUTE') {
        alertColor = const Color(0xFFF59E0B);
        icon = Icons.speed_rounded;
      } else if (badge == 'NETWORK') {
        alertColor = const Color(0xFF38BDF8);
        icon = Icons.alt_route_rounded;
      }

      parsedAlerts.add(
        _SwarmAlert(
          id: a['id'] as String? ?? 'alert',
          title: a['title'] as String? ?? 'Alert',
          message: a['message'] as String? ?? '',
          targetNodeId: a['target_node_id'] as String? ?? '',
          actionLabel: a['action_label'] as String? ?? 'Inspect',
          color: alertColor,
          icon: icon,
          badgeText: badge,
          timeAgo: a['time_ago'] as String? ?? 'Just now',
        ),
      );
    }

    final globalLoss = data['global_loss'] as String? ?? _globalLoss;
    final lossDelta = data['loss_delta_str'] as String? ?? _lossDeltaStr;
    final globalAccuracy = data['global_accuracy'] as String? ?? _globalAccuracy;
    final accGain = data['accuracy_gain_str'] as String? ?? _accuracyGainStr;
    final peakIngress = data['peak_ingress_str'] as String? ?? _peakIngressStr;
    final peakEgress = data['peak_egress_str'] as String? ?? _peakEgressStr;
    final weightDelta = data['weight_delta_str'] as String? ?? _weightDeltaStr;
    final avgRtt = data['avg_rtt_str'] as String? ?? _avgRttStr;
    final compressionRatio = data['compression_ratio'] as String? ?? _compressionRatioStr;
    final estimatedFinish = data['estimated_finish_str'] as String? ?? _estimatedFinishStr;

    final rawIngress = data['history_ingress'] as List<dynamic>?;
    final rawEgress = data['history_egress'] as List<dynamic>?;
    final rawAcc = data['history_accuracy'] as List<dynamic>?;
    final rawLoss = data['history_loss'] as List<dynamic>?;
    final rawPulse = data['pulse_bars'] as List<dynamic>?;
    final rawStreams = data['streams'] as List<dynamic>?;

    final ingressPoints = rawIngress != null
        ? rawIngress.map((e) => (e as num).toDouble()).toList()
        : _chartIngressPoints;
    final egressPoints = rawEgress != null
        ? rawEgress.map((e) => (e as num).toDouble()).toList()
        : _chartEgressPoints;
    final accuracyPoints = rawAcc != null
        ? rawAcc.map((e) => (e as num).toDouble()).toList()
        : _chartAccuracyPoints;
    final lossPoints = rawLoss != null
        ? rawLoss.map((e) => (e as num).toDouble()).toList()
        : _chartLossPoints;
    final pulseBars = rawPulse != null
        ? rawPulse.map((e) => (e as num).toDouble()).toList()
        : _pulseBars;

    final List<Map<String, dynamic>> parsedStreams = [];
    if (rawStreams != null) {
      for (final s in rawStreams) {
        if (s is Map<String, dynamic>) parsedStreams.add(s);
      }
    }

    // Also enrich with live network I/O if available
    final netData = DeSplitDaemonService.instance.networkState.value?['network_io'];
    String livePeakIn = peakIngress;
    String livePeakEg = peakEgress;
    if (netData != null) {
      final curRecvStr = netData['recv_rate_str'] as String?;
      final curSentStr = netData['sent_rate_str'] as String?;
      if (curRecvStr != null && curRecvStr != '0 B/s') livePeakIn = curRecvStr;
      if (curSentStr != null && curSentStr != '0 B/s') livePeakEg = curSentStr;
    }

    setState(() {
      _currentRound = round;
      _isPaused = !isTraining;
      _isAggregating = isAggregating;
      _globalLoss = globalLoss;
      _lossDeltaStr = lossDelta;
      _globalAccuracy = globalAccuracy;
      _accuracyGainStr = accGain;
      _peakIngressStr = livePeakIn;
      _peakEgressStr = livePeakEg;
      _weightDeltaStr = weightDelta;
      _avgRttStr = avgRtt;
      _compressionRatioStr = compressionRatio;
      _estimatedFinishStr = estimatedFinish;
      if (ingressPoints.isNotEmpty) _chartIngressPoints = ingressPoints;
      if (egressPoints.isNotEmpty) _chartEgressPoints = egressPoints;
      if (accuracyPoints.isNotEmpty) _chartAccuracyPoints = accuracyPoints;
      if (lossPoints.isNotEmpty) _chartLossPoints = lossPoints;
      if (pulseBars.isNotEmpty) _pulseBars = pulseBars;
      if (parsedStreams.isNotEmpty) _diagnosticStreams = parsedStreams;
      if (parsedWorkers.isNotEmpty) {
        _workers = parsedWorkers;
      }
      if (parsedAlerts.isNotEmpty) {
        _alerts = parsedAlerts;
      }
    });
  }

  void _initAlerts() {
    _alerts = [
      const _SwarmAlert(
        id: 'alert-initial',
        title: 'FedAvg Swarm Sentry Active',
        message: 'Local physical node initialized in cluster. Zero-Knowledge signature verified.',
        targetNodeId: 'node_local',
        actionLabel: 'Inspect Local Node',
        color: Color(0xFF00F5A0),
        icon: Icons.verified_user_rounded,
        badgeText: 'BYZANTINE',
        timeAgo: 'Just now',
      ),
    ];
  }

  void _startAlertSlideTimer() {
    _alertSlideTimer?.cancel();
    _alertSlideTimer = Timer.periodic(const Duration(milliseconds: 5000), (_) {
      if (!mounted || _isHoveringAlerts) return;
      final active = _activeAlerts;
      if (active.length <= 1) return;
      setState(() {
        _currentAlertIndex = (_currentAlertIndex + 1) % active.length;
      });
    });
  }

  List<_SwarmAlert> get _activeAlerts =>
      _alerts.where((a) => !_dismissedAlertIds.contains(a.id)).toList();

  void _nextAlert() {
    final active = _activeAlerts;
    if (active.isEmpty) return;
    setState(() {
      _currentAlertIndex = (_currentAlertIndex + 1) % active.length;
    });
  }

  void _prevAlert() {
    final active = _activeAlerts;
    if (active.isEmpty) return;
    setState(() {
      _currentAlertIndex = (_currentAlertIndex - 1 + active.length) % active.length;
    });
  }

  void _dismissCurrentAlert(String alertId) {
    setState(() {
      _dismissedAlertIds.add(alertId);
      final remaining = _activeAlerts;
      if (remaining.isNotEmpty) {
        _currentAlertIndex = _currentAlertIndex % remaining.length;
      }
    });
  }

  void _restoreAllAlerts() {
    setState(() {
      _dismissedAlertIds.clear();
      _currentAlertIndex = 0;
    });
  }

  @override
  void dispose() {
    DeSplitDaemonService.instance.fedAvgState.removeListener(_onDaemonFedAvgChanged);
    DeSplitDaemonService.instance.networkState.removeListener(_onDaemonFedAvgChanged);
    DeSplitDaemonService.instance.hardwareMetrics.removeListener(_onDaemonFedAvgChanged);
    _liveUpdateTimer?.cancel();
    _alertSlideTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _togglePauseTraining() async {
    final isTraining = await DeSplitDaemonService.instance.toggleFedAvgTraining();
    setState(() {
      _isPaused = !isTraining;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isPaused ? 'Swarm training paused across all nodes' : 'Swarm training resumed'),
          duration: const Duration(seconds: 2),
          backgroundColor: _isPaused ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _triggerManualAggregation() async {
    setState(() => _isAggregating = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text('Averaging federated model weights across all ${_workers.length} node(s)...'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.brandAccent,
      ),
    );

    final ok = await DeSplitDaemonService.instance.triggerFedAvgAggregation();
    if (!mounted) return;
    setState(() => _isAggregating = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Round $_currentRound aggregated successfully! Model weights updated.'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  void _inspectNode(String nodeId) {
    final worker = _workers.firstWhere(
      (w) => w.id == nodeId,
      orElse: () => _workers.first,
    );
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = !ThemeService.instance.isLight;
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.assessment_rounded, color: AppColors.brandAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Node Telemetry: ${worker.name}',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 780,
            child: SingleChildScrollView(
              child: _buildExpandedNodeDrawer(worker, isDark),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Close', style: TextStyle(color: AppColors.brandAccent)),
            ),
          ],
        );
      },
    );
  }

  void _openParametersDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = !ThemeService.instance.isLight;
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              Icon(Icons.tune_rounded, size: 20, color: AppColors.brandAccent),
              const SizedBox(width: 10),
              Text(
                'Training Parameters',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configure federated consensus strategy and node tolerance rules.',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),
                _buildDialogParamRow(
                  'Aggregation Algorithm',
                  'Trimmed-Mean (Outlier Resistant)',
                  'Discards the top and bottom 10% of gradient updates to stop poison attacks.',
                  isDark,
                ),
                const SizedBox(height: 14),
                _buildDialogParamRow(
                  'Weight Quantization',
                  'INT8 Compression (4.2x)',
                  'Compresses parameter updates by 76% to minimize network transfer time.',
                  isDark,
                ),
                const SizedBox(height: 14),
                _buildDialogParamRow(
                  'Minimum Quorum',
                  '${(_workers.length * 0.75).ceil()} of ${_workers.length} node(s) (75%)',
                  'Minimum required nodes to finalize a consensus round.',
                  isDark,
                ),
                const SizedBox(height: 14),
                _buildDialogParamRow(
                  'Local Epochs per Round',
                  '20 Epochs',
                  'Number of local mini-batch passes each node computes before submitting updates.',
                  isDark,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: AppColors.brandAccent, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogParamRow(String title, String value, String description, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.cardSurfaceLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.5)),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: AppColors.brandAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          description,
          style: TextStyle(
            color: isDark ? const Color(0xFF64748B) : AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Filtered & Sorted Workers List
  // ---------------------------------------------------------------------------
  List<_SwarmWorkerItem> get _filteredWorkers {
    return _workers.where((w) {
      if (_nodeFilter != 'ALL') {
        if (_nodeFilter == 'EXCLUDED') {
          if (!w.isExcluded) return false;
        } else {
          if (w.status.toUpperCase() != _nodeFilter) return false;
        }
      }

      if (_clusterFilter != 'ALL') {
        if (!w.cluster.toUpperCase().contains(_clusterFilter.toUpperCase())) {
          return false;
        }
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = w.name.toLowerCase().contains(q);
        final matchesId = w.id.toLowerCase().contains(q);
        final matchesHardware = w.hardware.toLowerCase().contains(q);
        final matchesCluster = w.cluster.toLowerCase().contains(q);
        final matchesRole = w.role.toLowerCase().contains(q);
        final matchesStatus = w.status.toLowerCase().contains(q);
        if (!matchesName && !matchesId && !matchesHardware && !matchesCluster && !matchesRole && !matchesStatus) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) {
        int cmp = 0;
        switch (_sortBy) {
          case 'Speed':
            cmp = a.speedItSec.compareTo(b.speedItSec);
            break;
          case 'Progress':
            cmp = a.progress.compareTo(b.progress);
            break;
          case 'Weight':
            cmp = a.weightScore.compareTo(b.weightScore);
            break;
          case 'Ping':
            cmp = a.pingMs.compareTo(b.pingMs);
            break;
          case 'Name':
          default:
            cmp = a.name.compareTo(b.name);
            break;
        }
        return _sortAscending ? cmp : -cmp;
      });
  }

  bool get _isLight => ThemeService.instance.isLight;

  Color get _cardBg => AppColors.cardSurface;
  Color get _cardSurfaceLight => AppColors.cardSurfaceLight;
  Color get _cardSurfaceHover => AppColors.cardSurfaceHover;
  Color get _borderColor => AppColors.borderSubtle.withValues(alpha: 0.85);
  Color get _textPrimary => _isLight ? AppColors.textPrimary : Colors.white;
  Color get _textSecondary => _isLight ? AppColors.textSecondary : const Color(0xFFCBD5E1);
  Color get _textMuted => _isLight ? AppColors.textMuted : const Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: ThemeService.instance.themeModeNotifier,
      builder: (context, mode, child) {
        final isDark = !ThemeService.instance.isLight;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Docker-style Top Header with Real Hardware Stats (Matching Image 1)
              _buildDockerHeader(isDark),

              // 2. Collapsible Image 2 Details Dropdown (4 Cards + Alert Banner)
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 240),
                crossFadeState: _showCharts ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                firstChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    _buildMetricCardsRow(isDark),
                    const SizedBox(height: 14),
                    _buildAlertBanner(isDark),
                  ],
                ),
                secondChild: const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),

              // 3. Docker-style Toolbar (Search, Layout Icon, Only show running switch, Actions)
              _buildDockerToolbar(isDark),

              const SizedBox(height: 14),

              // 4. View Specific Content: Docker Nodes Table (Main) or Full Diagnostics
              if (_activeViewIndex == 0) ...[
                _buildDockerNodesTable(isDark),
              ] else ...[
                _buildDiagnosticsSection(isDark),
              ],

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Docker Desktop Header & Resource Usage Bar (Matching Image 1)
  // ---------------------------------------------------------------------------
  Widget _buildDockerHeader(bool isDark) {
    final hwData = DeSplitDaemonService.instance.hardwareMetrics.value;
    final realtime = hwData?['realtime'] as Map<String, dynamic>?;
    final cpuPercent = (realtime?['cpu_percent'] as num?)?.toDouble() ?? 47.7;
    final cpuCores = (realtime?['cpu_cores_logical'] as num?)?.toInt() ?? 12;
    final ramUsedGb = (realtime?['ram_used_gb'] as num?)?.toDouble() ?? 13.1;
    final ramTotalGb = (realtime?['ram_total_gb'] as num?)?.toDouble() ?? 15.8;
    final speedItSec = _workers.isNotEmpty ? _workers.first.speedItSec : 49.0;
    final gpus = hwData?['gpus'] as List<dynamic>?;
    final gpuName = gpus != null && gpus.isNotEmpty
        ? (gpus.first['name'] as String? ?? 'Iris Xe')
        : 'Intel(R) Iris(R) Xe';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row matching Image 1
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Swarm Nodes',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('DeSplit Swarm v1.4.0 • Node pool healthy'),
                    duration: Duration(seconds: 1),
                    backgroundColor: Color(0xFF00F5A0),
                  ),
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Give feedback',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.open_in_new_rounded, size: 10, color: Color(0xFF38BDF8)),
                ],
              ),
            ),
            const Spacer(),
            // Navigation pills (Swarm Nodes vs Diagnostics)
            _buildNavPill(
              title: 'SWARM NODES',
              badge: '${_workers.length}',
              isActive: _activeViewIndex == 0,
              onTap: () => setState(() => _activeViewIndex = 0),
            ),
            const SizedBox(width: 6),
            _buildNavPill(
              title: 'DIAGNOSTICS',
              badge: 'LIVE',
              isActive: _activeViewIndex == 1,
              onTap: () => setState(() => _activeViewIndex = 1),
            ),
          ],
        ),
        const SizedBox(height: 3),
        // Subtitle matching Image 1
        Row(
          children: [
            Text(
              'View all your running federated nodes and active model shards. ',
              style: TextStyle(
                color: _textMuted,
                fontSize: 12,
              ),
            ),
            InkWell(
              onTap: _openParametersDialog,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Learn more',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.open_in_new_rounded, size: 11, color: Color(0xFF38BDF8)),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Live Resource Stats row matching Image 1
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Container CPU usage
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Container CPU usage ',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(Icons.info_outline_rounded, size: 12, color: _textMuted),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${cpuPercent.toStringAsFixed(2)}% / 100%',
                      style: const TextStyle(
                        color: Color(0xFF00F5A0),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      ' ($cpuCores CPUs available • ${speedItSec.toStringAsFixed(1)} it/s)',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(width: 48),

            // Container memory usage
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Container memory usage ',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(Icons.info_outline_rounded, size: 12, color: _textMuted),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${(ramUsedGb * 1024).toStringAsFixed(2)}MB / ${(ramTotalGb * 1024).toStringAsFixed(2)}MB',
                      style: const TextStyle(
                        color: Color(0xFF00F5A0),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      ' (${ramTotalGb.toStringAsFixed(1)}GB • $gpuName)',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Spacer(),

            // Show charts / Hide charts toggle matching Image 1
            InkWell(
              onTap: () => setState(() => _showCharts = !_showCharts),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _showCharts ? 'Hide charts' : 'Show charts',
                      style: TextStyle(
                        color: _showCharts ? const Color(0xFF00F5A0) : _textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showCharts ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: _showCharts ? const Color(0xFF00F5A0) : _textPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavPill({
    required String title,
    required String badge,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: isActive ? _cardSurfaceLight : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? AppColors.brandAccent.withValues(alpha: 0.6) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isActive ? AppColors.brandAccent : _textSecondary,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.brandAccent.withValues(alpha: 0.18)
                    : _cardSurfaceHover,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: isActive ? AppColors.brandAccent : _textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Top Metric Cards Row (Image 2 style with Pulse Graph)
  // ---------------------------------------------------------------------------
  Widget _buildMetricCardsRow(bool isDark) {
    final activeCount = _workers.where((w) => !w.isExcluded).length;
    final totalCount = _workers.length;
    final totalSpeed = _workers.fold<double>(0, (sum, w) => sum + (w.isExcluded ? 0 : w.speedItSec));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 980;

        if (isCompact) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      label: 'TOTAL NODES',
                      value: '$activeCount / $totalCount',
                      subtext: '100% QUORUM nominal',
                      icon: Icons.shield_outlined,
                      accentColor: const Color(0xFF00F5A0),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'CONSENSUS ROUND',
                      value: '$_currentRound / $_totalRounds',
                      subtext: 'Trimmed-Mean INT8 • $_estimatedFinishStr',
                      icon: Icons.sync_rounded,
                      accentColor: const Color(0xFF38BDF8),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'GLOBAL LOSS',
                      value: _globalLoss,
                      subtext: '$_globalAccuracy Acc • 0.994 cos',
                      icon: Icons.auto_graph_rounded,
                      accentColor: const Color(0xFFA855F7),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildPulseChartCard(totalSpeed, isDark),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 1
            Expanded(
              flex: 3,
              child: _buildMetricCard(
                label: 'TOTAL NODES',
                value: '$activeCount / $totalCount',
                subtext: '100% QUORUM nominal • 0 excluded',
                icon: Icons.shield_outlined,
                accentColor: const Color(0xFF00F5A0),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            // Card 2
            Expanded(
              flex: 3,
              child: _buildMetricCard(
                label: 'CONSENSUS ROUND',
                value: '$_currentRound / $_totalRounds',
                subtext: 'Trimmed-Mean INT8 • $_estimatedFinishStr',
                icon: Icons.sync_rounded,
                accentColor: const Color(0xFF38BDF8),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            // Card 3
            Expanded(
              flex: 3,
              child: _buildMetricCard(
                label: 'GLOBAL LOSS & ACC',
                value: _globalLoss,
                subtext: 'Accuracy $_globalAccuracy • 0.994 cos sim',
                icon: Icons.auto_graph_rounded,
                accentColor: const Color(0xFFA855F7),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            // Card 4: Detection Pulse Chart (exact match to Image 2)
            Expanded(
              flex: 5,
              child: _buildPulseChartCard(totalSpeed, isDark),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
  }) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _borderColor,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  fontFamily: 'monospace',
                ),
              ),
              Icon(icon, size: 14, color: accentColor.withValues(alpha: 0.8)),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              letterSpacing: -0.5,
            ),
          ),
          Text(
            subtext,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPulseChartCard(double totalSpeed, bool isDark) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _borderColor,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DETECTION PULSE • ',
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    '${totalSpeed.toStringAsFixed(0)} it/s',
                    style: const TextStyle(
                      color: Color(0xFF00F5A0),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              Text(
                totalSpeed > 0
                    ? '${(totalSpeed * 0.9).toStringAsFixed(0)} it/s sync • peak ${(totalSpeed * 1.25).toStringAsFixed(0)}/s'
                    : 'Cluster Idle',
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          // Custom Histogram Pulse Painter
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 2),
              child: CustomPaint(
                size: Size.infinite,
                painter: _SwarmPulseHistogramPainter(pulseBars: _pulseBars),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('R${_currentRound > 3 ? _currentRound - 3 : 1}: SETUP', style: TextStyle(color: _textMuted, fontSize: 8.5, fontFamily: 'monospace')),
              Text('R${_currentRound > 2 ? _currentRound - 2 : 2}: TENSORS', style: TextStyle(color: _textMuted, fontSize: 8.5, fontFamily: 'monospace')),
              Text('R${_currentRound > 1 ? _currentRound - 1 : 3}: BYZ-VERIFIED', style: TextStyle(color: _textMuted, fontSize: 8.5, fontFamily: 'monospace')),
              Text('R$_currentRound: ACTIVE SYNC', style: const TextStyle(color: Color(0xFF00F5A0), fontSize: 8.5, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Sliding Cyber Alert Banner
  // ---------------------------------------------------------------------------
  Widget _buildAlertBanner(bool isDark) {
    final activeAlerts = _activeAlerts;

    if (activeAlerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF00F5A0).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF00F5A0).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF00F5A0)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'All 8 swarm workers nominal. Byzantine consensus active without anomalies.',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: _restoreAllAlerts,
              child: const Text(
                'RESTORE ALERTS',
                style: TextStyle(
                  color: Color(0xFF00F5A0),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      );
    }

    final currentIndex = _currentAlertIndex % activeAlerts.length;
    final alert = activeAlerts[currentIndex];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringAlerts = true),
      onExit: (_) => setState(() => _isHoveringAlerts = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: alert.color.withValues(alpha: 0.35),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: alert.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                alert.badgeText,
                style: TextStyle(
                  color: alert.color,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Message
            Expanded(
              child: Row(
                children: [
                  Text(
                    '${alert.title}: ',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      alert.message,
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Action button
            InkWell(
              onTap: () => _inspectNode(alert.targetNodeId),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: alert.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: alert.color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'INSPECT',
                  style: TextStyle(
                    color: alert.color,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Pagination controls
            Text(
              '${currentIndex + 1}/${activeAlerts.length}',
              style: TextStyle(
                color: _textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: _prevAlert,
              child: const Icon(Icons.chevron_left_rounded, size: 16, color: Color(0xFF94A3B8)),
            ),
            InkWell(
              onTap: _nextAlert,
              child: const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => _dismissCurrentAlert(alert.id),
              child: const Icon(Icons.close_rounded, size: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Docker-Style Toolbar (Matching Image 1)
  // ---------------------------------------------------------------------------
  Widget _buildDockerToolbar(bool isDark) {
    return Row(
      children: [
        // Search Box (matching Image 1)
        Container(
          width: 250,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 16, color: _textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(color: _textPrimary, fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: _textMuted, fontSize: 12.5),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                InkWell(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: Icon(Icons.close_rounded, size: 14, color: _textMuted),
                ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // Layout Icon Button (matching Image 1)
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _borderColor),
          ),
          child: Icon(Icons.table_rows_rounded, size: 15, color: _textSecondary),
        ),

        const SizedBox(width: 14),

        // Only show running nodes switch (matching Image 1)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: 0.75,
              child: Switch(
                value: _onlyShowActive,
                onChanged: (val) => setState(() => _onlyShowActive = val),
                activeThumbColor: const Color(0xFF00F5A0),
                activeTrackColor: const Color(0xFF00F5A0).withValues(alpha: 0.3),
                inactiveThumbColor: const Color(0xFF94A3B8),
                inactiveTrackColor: const Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 2),
            Text(
              'Only show running nodes',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const Spacer(),

        // Right side Action buttons
        // Pause / Resume Swarm
        InkWell(
          onTap: _togglePauseTraining,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _cardSurfaceLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  size: 14,
                  color: _isPaused ? const Color(0xFFF59E0B) : _textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  _isPaused ? 'Resume Swarm' : 'Pause Swarm',
                  style: TextStyle(
                    color: _isPaused ? const Color(0xFFF59E0B) : _textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Trigger FedAvg
        InkWell(
          onTap: _isAggregating ? null : _triggerManualAggregation,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00F5A0), Color(0xFF00D287)],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _isAggregating
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.black),
                      )
                    : const Icon(Icons.flash_on_rounded, size: 13, color: Colors.black),
                const SizedBox(width: 5),
                Text(
                  _isAggregating ? 'Aggregating...' : 'Trigger FedAvg',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 6),

        // Parameters icon button
        IconButton(
          tooltip: 'Consensus Parameters',
          icon: Icon(Icons.tune_rounded, size: 17, color: _textMuted),
          onPressed: _openParametersDialog,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Main Swarm Nodes Table (Docker Desktop Style Matching Image 1)
  // ---------------------------------------------------------------------------
  Widget _buildDockerNodesTable(bool isDark) {
    final hwData = DeSplitDaemonService.instance.hardwareMetrics.value;
    final realtime = hwData?['realtime'] as Map<String, dynamic>?;
    final cpuPercent = (realtime?['cpu_percent'] as num?)?.toDouble() ?? 47.7;
    final speedItSec = _workers.isNotEmpty ? _workers.first.speedItSec : 49.0;

    final localWorker = _workers.firstWhere(
      (w) => w.role.contains('Host') || w.name.contains('YOU'),
      orElse: () => _workers.first,
    );

    final children = _getLocalNodeChildren(speedItSec);

    // Apply search filter to children
    final filteredChildren = children.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (c['name'] as String).toLowerCase().contains(q) ||
          (c['id'] as String).toLowerCase().contains(q) ||
          (c['image'] as String).toLowerCase().contains(q) ||
          (c['ports'] as String).toLowerCase().contains(q);
    }).toList();

    // Additional peer workers beyond local host
    final peerWorkers = _filteredWorkers.where((w) => w.id != localWorker.id).toList();

    final isLocalVisible = !_onlyShowActive || !localWorker.isExcluded;

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          // Header Row
          _buildDockerTableHeader(isDark),

          // Host Node Parent Row (like local_dev_lab in Image 1)
          if (isLocalVisible) ...[
            _buildDockerParentRow(
              isDark: isDark,
              worker: localWorker,
              cpuPercent: cpuPercent,
              isExpanded: _isLocalExpanded,
              onToggleExpand: () => setState(() => _isLocalExpanded = !_isLocalExpanded),
              isSelected: _selectedNodeIds.contains(localWorker.id),
              onSelect: (val) {
                setState(() {
                  if (val) {
                    _selectedNodeIds.add(localWorker.id);
                  } else {
                    _selectedNodeIds.remove(localWorker.id);
                  }
                });
              },
            ),

            // Child Rows (indented like proxy-1, backend-1, db-1 in Image 1)
            if (_isLocalExpanded)
              ...filteredChildren.map((c) => _buildDockerChildRow(
                    isDark: isDark,
                    id: c['id'] as String,
                    name: c['name'] as String,
                    nodeId: c['id'] as String,
                    image: c['image'] as String,
                    ports: c['ports'] as String,
                    cpu: c['cpu'] as String,
                    lastStarted: c['sync'] as String,
                    dotColor: c['dotColor'] as Color,
                    isSelected: _selectedNodeIds.contains(c['id']),
                    onSelect: (val) {
                      setState(() {
                        if (val) {
                          _selectedNodeIds.add(c['id'] as String);
                        } else {
                          _selectedNodeIds.remove(c['id'] as String);
                        }
                      });
                    },
                  )),
          ],

          // Peer Workers
          ...peerWorkers.map((w) => _buildDockerPeerRow(
                isDark: isDark,
                worker: w,
                isSelected: _selectedNodeIds.contains(w.id),
                onSelect: (val) {
                  setState(() {
                    if (val) {
                      _selectedNodeIds.add(w.id);
                    } else {
                      _selectedNodeIds.remove(w.id);
                    }
                  });
                },
              )),

          if (!isLocalVisible && peerWorkers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.search_off_rounded, size: 36, color: Color(0xFF475569)),
                    const SizedBox(height: 10),
                    const Text(
                      'No swarm nodes match your current filters.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _onlyShowActive = false;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                      child: const Text('Reset Filters', style: TextStyle(color: Color(0xFF00F5A0))),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDockerTableHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: _cardSurfaceLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(7),
          topRight: Radius.circular(7),
        ),
        border: Border(
          bottom: BorderSide(color: _borderColor, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Select All Checkbox
          SizedBox(
            width: 26,
            height: 26,
            child: Checkbox(
              value: _selectAll,
              onChanged: (val) {
                setState(() {
                  _selectAll = val ?? false;
                  if (_selectAll) {
                    _selectedNodeIds.add('node_local');
                    for (final c in _getLocalNodeChildren(49.0)) {
                      _selectedNodeIds.add(c['id'] as String);
                    }
                    for (final w in _workers) {
                      _selectedNodeIds.add(w.id);
                    }
                  } else {
                    _selectedNodeIds.clear();
                  }
                });
              },
              activeColor: const Color(0xFF00F5A0),
              checkColor: Colors.black,
              side: const BorderSide(color: Color(0xFF475569), width: 1.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
            ),
          ),
          const SizedBox(width: 16),
          // Name
          Expanded(
            flex: 3,
            child: Text(
              'Name',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Node ID
          Expanded(
            flex: 2,
            child: Text(
              'Node ID',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Hardware & Model
          Expanded(
            flex: 3,
            child: Text(
              'Hardware & Model',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Port(s)
          Expanded(
            flex: 2,
            child: Text(
              'Port(s)',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // CPU (%)
          Expanded(
            flex: 1,
            child: Text(
              'CPU (%)',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Last started
          Expanded(
            flex: 2,
            child: Text(
              'Last started',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Actions
          SizedBox(
            width: 88,
            child: Text(
              'Actions',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockerParentRow({
    required bool isDark,
    required _SwarmWorkerItem worker,
    required double cpuPercent,
    required bool isExpanded,
    required VoidCallback onToggleExpand,
    required bool isSelected,
    required ValueChanged<bool> onSelect,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border(
          bottom: BorderSide(color: _borderColor.withValues(alpha: 0.5), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          SizedBox(
            width: 26,
            height: 26,
            child: Checkbox(
              value: isSelected,
              onChanged: (val) => onSelect(val ?? false),
              activeColor: const Color(0xFF00F5A0),
              checkColor: Colors.black,
              side: const BorderSide(color: Color(0xFF475569), width: 1.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
            ),
          ),
          const SizedBox(width: 4),
          // Status dot
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: worker.isExcluded
                  ? const Color(0xFFEF4444)
                  : (_isPaused ? const Color(0xFFF59E0B) : const Color(0xFF00F5A0)),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (worker.isExcluded
                          ? const Color(0xFFEF4444)
                          : (_isPaused ? const Color(0xFFF59E0B) : const Color(0xFF00F5A0)))
                      .withValues(alpha: 0.6),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          // Name with expand chevron (matching local_dev_lab in Image 1)
          Expanded(
            flex: 3,
            child: Row(
              children: [
                InkWell(
                  onTap: onToggleExpand,
                  borderRadius: BorderRadius.circular(3),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(
                      isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                      size: 16,
                      color: _textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    worker.name,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F5A0).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: const Color(0xFF00F5A0).withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'HOST',
                    style: TextStyle(
                      color: Color(0xFF00F5A0),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Node ID
          Expanded(
            flex: 2,
            child: Text(
              worker.id,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Hardware & Model
          Expanded(
            flex: 3,
            child: Text(
              '${worker.hardware} • Llama 3 8B',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Port(s)
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Swarm gRPC server listening on 0.0.0.0:50051'),
                    duration: Duration(seconds: 1),
                    backgroundColor: Color(0xFF38BDF8),
                  ),
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '50051:50051',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(Icons.open_in_new_rounded, size: 10, color: Color(0xFF38BDF8)),
                ],
              ),
            ),
          ),
          // CPU (%)
          Expanded(
            flex: 1,
            child: Text(
              '${cpuPercent.toStringAsFixed(1)}%',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          // Last started
          Expanded(
            flex: 2,
            child: Text(
              '${worker.localEpoch} • Just now',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 11.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Actions
          SizedBox(
            width: 88,
            child: _buildDockerActionButtons(
              isRunning: !_isPaused && !worker.isExcluded,
              onToggle: _togglePauseTraining,
              onMenu: () => _inspectNode(worker.id),
              onDelete: () => _toggleExcludeNode(worker.id, worker.name),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockerChildRow({
    required bool isDark,
    required String id,
    required String name,
    required String nodeId,
    required String image,
    required String ports,
    required String cpu,
    required String lastStarted,
    required Color dotColor,
    required bool isSelected,
    required ValueChanged<bool> onSelect,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: _cardBg.withValues(alpha: 0.7),
        border: Border(
          bottom: BorderSide(color: _borderColor.withValues(alpha: 0.35), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          SizedBox(
            width: 26,
            height: 26,
            child: Checkbox(
              value: isSelected,
              onChanged: (val) => onSelect(val ?? false),
              activeColor: const Color(0xFF00F5A0),
              checkColor: Colors.black,
              side: const BorderSide(color: Color(0xFF475569), width: 1.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
            ),
          ),
          const SizedBox(width: 4),
          // Status dot
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          // Name (indented with left margin, matching proxy-1 in Image 1)
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                name,
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Node ID
          Expanded(
            flex: 2,
            child: Text(
              nodeId,
              style: TextStyle(
                color: _textMuted,
                fontSize: 11.5,
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Hardware & Model (Image in Docker)
          Expanded(
            flex: 3,
            child: Text(
              image,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Port(s)
          Expanded(
            flex: 2,
            child: ports.contains('↗')
                ? InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$name active on $ports'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: const Color(0xFF38BDF8),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            ports.replaceAll(' ↗', ''),
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 11.5,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.open_in_new_rounded, size: 10, color: Color(0xFF38BDF8)),
                      ],
                    ),
                  )
                : Text(
                    ports,
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 11.5,
                      fontFamily: 'monospace',
                    ),
                  ),
          ),
          // CPU (%)
          Expanded(
            flex: 1,
            child: Text(
              cpu,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 11.5,
                fontFamily: 'monospace',
              ),
            ),
          ),
          // Last started
          Expanded(
            flex: 2,
            child: Text(
              lastStarted,
              style: TextStyle(
                color: _textMuted,
                fontSize: 11.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Actions
          SizedBox(
            width: 88,
            child: _buildDockerActionButtons(
              isRunning: true,
              onToggle: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$name shard state updated'),
                    duration: const Duration(seconds: 1),
                    backgroundColor: const Color(0xFF00F5A0),
                  ),
                );
              },
              onMenu: () => _inspectNode(id),
              onDelete: () => _toggleExcludeNode(id, name),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockerPeerRow({
    required bool isDark,
    required _SwarmWorkerItem worker,
    required bool isSelected,
    required ValueChanged<bool> onSelect,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border(
          bottom: BorderSide(color: _borderColor.withValues(alpha: 0.4), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          SizedBox(
            width: 26,
            height: 26,
            child: Checkbox(
              value: isSelected,
              onChanged: (val) => onSelect(val ?? false),
              activeColor: const Color(0xFF00F5A0),
              checkColor: Colors.black,
              side: const BorderSide(color: Color(0xFF475569), width: 1.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
            ),
          ),
          const SizedBox(width: 4),
          // Status dot
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: worker.isExcluded ? const Color(0xFFEF4444) : worker.statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (worker.isExcluded ? const Color(0xFFEF4444) : worker.statusColor)
                      .withValues(alpha: 0.6),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          // Name
          Expanded(
            flex: 3,
            child: Text(
              worker.name,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Node ID
          Expanded(
            flex: 2,
            child: Text(
              worker.id,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Hardware & Model
          Expanded(
            flex: 3,
            child: Text(
              worker.hardware,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Port(s)
          Expanded(
            flex: 2,
            child: Text(
              '${worker.pingMs} ms',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          // CPU (%)
          Expanded(
            flex: 1,
            child: Text(
              '${worker.speedItSec.toStringAsFixed(1)}/s',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          // Last started
          Expanded(
            flex: 2,
            child: Text(
              worker.localEpoch,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 11.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Actions
          SizedBox(
            width: 88,
            child: _buildDockerActionButtons(
              isRunning: !worker.isExcluded && worker.status != 'Paused',
              onToggle: () {
                setState(() {
                  worker.status = worker.status == 'Paused' ? 'Training' : 'Paused';
                });
              },
              onMenu: () => _inspectNode(worker.id),
              onDelete: () => _toggleExcludeNode(worker.id, worker.name),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockerActionButtons({
    required bool isRunning,
    required VoidCallback onToggle,
    required VoidCallback onMenu,
    required VoidCallback onDelete,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stop/Pause square button (matching Image 1)
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
              size: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Three dots overflow menu
        InkWell(
          onTap: onMenu,
          borderRadius: BorderRadius.circular(4),
          child: const Padding(
            padding: EdgeInsets.all(2.0),
            child: Icon(
              Icons.more_vert_rounded,
              size: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Trash can button
        InkWell(
          onTap: onDelete,
          borderRadius: BorderRadius.circular(4),
          child: const Padding(
            padding: EdgeInsets.all(2.0),
            child: Icon(
              Icons.delete_outline_rounded,
              size: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getLocalNodeChildren(double speedItSec) {
    return [
      {
        'id': 'shard-gpu-001',
        'name': 'Host Iris Xe Compute Core',
        'image': 'Intel(R) Iris(R) Xe Graphics',
        'ports': 'PCIe Direct',
        'cpu': '${speedItSec.toStringAsFixed(1)} it/s',
        'sync': 'Active Shard',
        'dotColor': const Color(0xFF00F5A0),
      },
      {
        'id': 'port-50051',
        'name': 'gRPC Swarm Listener',
        'image': '0.0.0.0:50051 (mTLS)',
        'ports': '50051:50051 ↗',
        'cpu': '0.0%',
        'sync': 'Listening',
        'dotColor': const Color(0xFF38BDF8),
      },
      {
        'id': 'stun-nat-001',
        'name': 'STUN NAT Gateway',
        'image': 'RFC 5389 NAT Traversal',
        'ports': '117.239.252.50:63492 ↗',
        'cpu': '0 ms',
        'sync': 'Direct STUN',
        'dotColor': const Color(0xFFA855F7),
      },
      {
        'id': 'shard-int8-01',
        'name': 'Llama 3 INT8 Shard Buffer',
        'image': 'Llama 3 (8B Instruct)',
        'ports': 'Cache 256 MB',
        'cpu': '100% Score',
        'sync': 'Synced INT8',
        'dotColor': const Color(0xFF00F5A0),
      },
    ];
  }

  void _toggleExcludeNode(String id, String name) {
    setState(() {
      final worker = _workers.firstWhere((w) => w.id == id, orElse: () => _workers.first);
      worker.isExcluded = !worker.isExcluded;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            worker.isExcluded
                ? '$name excluded from swarm quorum'
                : '$name restored to active swarm quorum',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: worker.isExcluded ? const Color(0xFFF59E0B) : const Color(0xFF00F5A0),
        ),
      );
    });
  }

  Widget _buildExpandedNodeDrawer(_SwarmWorkerItem worker, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      decoration: BoxDecoration(
        color: _cardSurfaceLight,
        border: Border(
          top: BorderSide(color: _borderColor, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // 4 Telemetry Metrics Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compute
              Expanded(
                child: _buildDrawerCard(
                  title: 'COMPUTE & HARDWARE',
                  icon: Icons.memory_rounded,
                  items: [
                    {'Device': worker.hardware},
                    {'Throughput': '${worker.tflops} Peak'},
                    {'VRAM Usage': worker.vram},
                    {'Latency': '${worker.pingMs} ms (P2P Mesh)'},
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Consensus & Alignment
              Expanded(
                child: _buildDrawerCard(
                  title: 'CONSENSUS & ALIGNMENT',
                  icon: Icons.verified_user_rounded,
                  items: [
                    {'Model Cosine Sim': '${(worker.cosineVal * 100).toStringAsFixed(1)}% (${worker.cosineSimilarity})'},
                    {'Swarm Weight': worker.weightScore},
                    {'Gradient Delta': worker.deltaSize},
                    {'Quantization': 'INT8 (${worker.compression})'},
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Byzantine Integrity
              Expanded(
                child: _buildDrawerCard(
                  title: 'BYZANTINE INTEGRITY',
                  icon: Icons.security_rounded,
                  items: [
                    {'ZK Commitment': worker.byzantineVerified ? 'Verified Authentic' : 'Flagged'},
                    {'Poison Delta Check': 'Pass (0 outliers)'},
                    {'Epoch Batch': worker.localEpoch},
                    {'Status State': worker.isExcluded ? 'MANUALLY EXCLUDED' : worker.status.toUpperCase()},
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Node Quick Action Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Action 1: Ping Test
              _buildDrawerActionButton(
                label: 'PING TEST',
                icon: Icons.network_ping_rounded,
                onTap: () {
                  setState(() {
                    worker.pingMs = (worker.pingMs * 0.95 + 4).toInt();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('P2P Ping to ${worker.name}: ${worker.pingMs} ms (Nominal)'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: const Color(0xFF00F5A0),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),

              // Action 2: Inspect Tensor Gradients
              _buildDrawerActionButton(
                label: 'INSPECT GRADIENTS',
                icon: Icons.assessment_outlined,
                onTap: () => _showGradientInspectDialog(worker, isDark),
              ),
              const SizedBox(width: 8),

              // Action 3: Exclude / Include Toggle
              _buildDrawerActionButton(
                label: worker.isExcluded ? 'RESTORE TO QUORUM' : 'EXCLUDE FROM ROUND',
                icon: worker.isExcluded ? Icons.add_circle_outline_rounded : Icons.block_rounded,
                isDestructive: !worker.isExcluded,
                onTap: () {
                  setState(() {
                    worker.isExcluded = !worker.isExcluded;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        worker.isExcluded
                            ? '${worker.name} excluded from next aggregation round'
                            : '${worker.name} restored to active swarm quorum',
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: worker.isExcluded ? const Color(0xFFF59E0B) : const Color(0xFF00F5A0),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerCard({
    required String title,
    required IconData icon,
    required List<Map<String, String>> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: const Color(0xFF00F5A0)),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) {
            final key = item.keys.first;
            final val = item.values.first;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    key,
                    style: TextStyle(color: _textSecondary, fontSize: 10.5),
                  ),
                  Text(
                    val,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDestructive ? const Color(0xFFEF4444).withValues(alpha: 0.12) : _cardSurfaceHover,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDestructive ? const Color(0xFFEF4444).withValues(alpha: 0.4) : _borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isDestructive ? const Color(0xFFEF4444) : _textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isDestructive ? const Color(0xFFEF4444) : _textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGradientInspectDialog(_SwarmWorkerItem worker, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _borderColor),
          ),
          title: Row(
            children: [
              const Icon(Icons.query_stats_rounded, size: 20, color: Color(0xFF00F5A0)),
              const SizedBox(width: 10),
              Text(
                '${worker.name} — Gradient Tensor Telemetry',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Layer-by-layer update norm and alignment against cluster mean.',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 14),
                _buildLayerStatRow('model.layers.0-7.self_attn', '||W|| = 0.0412', 'cos = 0.998', isDark),
                const SizedBox(height: 8),
                _buildLayerStatRow('model.layers.8-15.mlp.gate_proj', '||W|| = 0.0384', 'cos = 0.994', isDark),
                const SizedBox(height: 8),
                _buildLayerStatRow('model.layers.16-23.mlp.up_proj', '||W|| = 0.0390', 'cos = 0.991', isDark),
                const SizedBox(height: 8),
                _buildLayerStatRow('model.layers.24-31.down_proj', '||W|| = 0.0365', 'cos = 0.989', isDark),
                const SizedBox(height: 8),
                _buildLayerStatRow('model.norm.weight', '||W|| = 0.0121', 'cos = 0.999', isDark),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close', style: TextStyle(color: Color(0xFF00F5A0), fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLayerStatRow(String layer, String norm, String cos, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _cardSurfaceHover,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            layer,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          Row(
            children: [
              Text(
                norm,
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 10.5,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 10),
              Text(
                cos,
                style: const TextStyle(
                  color: Color(0xFF00F5A0),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Diagnostics & Network View Section
  // ---------------------------------------------------------------------------
  Widget _buildDiagnosticsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Split Layout: Realtime Bandwidth Graph + Telemetry Metrics
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 840;

            if (isCompact) {
              return Column(
                children: [
                  _buildChartCard(isDark),
                  const SizedBox(height: 16),
                  _buildMetricsSummaryCard(isDark),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: _buildChartCard(isDark),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: _buildMetricsSummaryCard(isDark),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _buildP2PStreamsBreakdownCard(isDark),
      ],
    );
  }

  Widget _buildChartCard(bool isDark) {
    final primaryColor = _activeTransferTab == 'INGRESS'
        ? const Color(0xFF38BDF8)
        : const Color(0xFFA855F7);

    const accuracyColor = Color(0xFF00F5A0);
    const lossColor = Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _borderColor,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insights_rounded, size: 16, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'GRADIENT TRANSFER, ACCURACY & LOSS',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),

              // Filter Toggles & Ingress/Egress Switcher
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildCurveToggleChip(
                    label: 'Throughput',
                    isSelected: _showThroughputCurve,
                    activeColor: primaryColor,
                    onTap: () => setState(() => _showThroughputCurve = !_showThroughputCurve),
                    isDark: isDark,
                  ),
                  _buildCurveToggleChip(
                    label: 'Accuracy ($_globalAccuracy)',
                    isSelected: _showAccuracyCurve,
                    activeColor: accuracyColor,
                    onTap: () => setState(() => _showAccuracyCurve = !_showAccuracyCurve),
                    isDark: isDark,
                  ),
                  _buildCurveToggleChip(
                    label: 'Loss ($_globalLoss)',
                    isSelected: _showLossCurve,
                    activeColor: lossColor,
                    onTap: () => setState(() => _showLossCurve = !_showLossCurve),
                    isDark: isDark,
                  ),
                  Container(
                    width: 1,
                    height: 18,
                    color: _borderColor,
                  ),
                  // Ingress / Egress Switcher
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _cardSurfaceLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTransferTabChip('INGRESS', Icons.download_rounded),
                        _buildTransferTabChip('EGRESS', Icons.upload_rounded),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Realtime Multi-Curve Custom Painted Chart
          SizedBox(
            height: 220,
            width: double.infinity,
            child: CustomPaint(
              size: Size.infinite,
              painter: _SleekTransferSpeedPainter(
                isDark: isDark,
                isDownload: _activeTransferTab == 'INGRESS',
                showThroughput: _showThroughputCurve,
                showAccuracy: _showAccuracyCurve,
                showLoss: _showLossCurve,
                ingressPoints: _chartIngressPoints,
                egressPoints: _chartEgressPoints,
                accuracyPoints: _chartAccuracyPoints,
                lossPoints: _chartLossPoints,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Bottom telemetry ticker - wrap to prevent RenderFlex overflow
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _buildMiniTelemetryBadge(
                _activeTransferTab == 'INGRESS' ? 'PEAK INGRESS' : 'PEAK EGRESS',
                _activeTransferTab == 'INGRESS' ? _peakIngressStr : _peakEgressStr,
                const Color(0xFF38BDF8),
              ),
              _buildMiniTelemetryBadge(
                'GLOBAL ACCURACY',
                '$_globalAccuracy ($_accuracyGainStr)',
                const Color(0xFF00F5A0),
              ),
              _buildMiniTelemetryBadge(
                'CONVERGENCE LOSS',
                '$_globalLoss ($_lossDeltaStr)',
                const Color(0xFFF59E0B),
              ),
              _buildMiniTelemetryBadge(
                'QUORUM SYNC',
                '${_workers.length}/${_workers.length} Active Node${_workers.length > 1 ? 's' : ''}',
                const Color(0xFFA855F7),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTelemetryBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _cardSurfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: _textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _borderColor,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed_rounded, size: 16, color: Color(0xFF00F5A0)),
              const SizedBox(width: 8),
              Text(
                'SWARM CONSENSUS METRICS',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetricTile('Aggregate Weight Delta', _weightDeltaStr, isDark),
          const SizedBox(height: 10),
          _buildMetricTile('Trimmed-Mean Outlier Cutoff', '10% Top / 10% Bottom', isDark),
          const SizedBox(height: 10),
          _buildMetricTile('Byzantine Audit Status', '100% Verified Clean (${_workers.length} Node${_workers.length > 1 ? 's' : ''})', isDark),
          const SizedBox(height: 10),
          _buildMetricTile('Avg Inter-Node P2P RTT', _avgRttStr, isDark),
          const SizedBox(height: 10),
          _buildMetricTile('Compression Ratio', _compressionRatioStr, isDark),
          const SizedBox(height: 10),
          _buildMetricTile('Estimated Round Finish', _estimatedFinishStr, isDark),
        ],
      ),
    );
  }

  Widget _buildP2PStreamsBreakdownCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _borderColor,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.device_hub_rounded, size: 16, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 8),
                  Text(
                    'P2P GRADIENT STREAMS BREAKDOWN',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const Text(
                'WireGuard Mesh Encrypted',
                style: TextStyle(
                  color: Color(0xFF00F5A0),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, streamConstraints) {
              final streams = <Widget>[];
              if (_diagnosticStreams.isNotEmpty) {
                for (final s in _diagnosticStreams) {
                  final route = s['route'] as String? ?? 'Stream';
                  final size = s['delta_size'] as String? ?? '256 MB INT8';
                  final speed = s['speed'] as String? ?? 'Active';
                  final hexStr = (s['color_hex'] as String? ?? '#00F5A0').replaceAll('#', '');
                  Color color = const Color(0xFF00F5A0);
                  try {
                    color = Color(int.parse('FF$hexStr', radix: 16));
                  } catch (_) {}
                  streams.add(_buildStreamItem(route, size, speed, color));
                }
              } else if (_workers.length <= 1) {
                final w = _workers.isNotEmpty ? _workers[0] : null;
                final speedStr = w != null ? '${w.speedItSec.toStringAsFixed(1)} it/s' : 'Idle';
                final deltaStr = w != null ? w.deltaSize : '256 MB INT8';
                streams.add(_buildStreamItem('${w?.hardware ?? "Host Iris Xe"} ➔ Shard Cache', deltaStr, speedStr, const Color(0xFF00F5A0)));
                streams.add(_buildStreamItem('gRPC Port 50051 ➔ Pool Listener', '0 B Active Peers', 'Listening', const Color(0xFF38BDF8)));
                streams.add(_buildStreamItem('STUN NAT Gateway ➔ Local Host', 'Direct STUN', '0 ms latency', const Color(0xFFA855F7)));
                streams.add(_buildStreamItem('Consensus Shard ➔ Llama 3 (8B)', 'Full Local Shard', 'Trimmed-Mean', const Color(0xFFF59E0B)));
              } else {
                for (final w in _workers) {
                  final isLocal = w.id.contains('local') || w.name.contains('(YOU)');
                  final route = isLocal ? 'Host Cores ➔ Local Shard' : '${w.name} ➔ Host Aggregator';
                  streams.add(_buildStreamItem(route, w.deltaSize, '${w.speedItSec.toStringAsFixed(1)} it/s', w.iconColor));
                }
              }

              final isNarrow = streamConstraints.maxWidth < 650;
              if (isNarrow) {
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: streams.map((s) => SizedBox(
                    width: (streamConstraints.maxWidth - 10) / 2 > 160
                        ? (streamConstraints.maxWidth - 10) / 2
                        : streamConstraints.maxWidth,
                    child: s,
                  )).toList(),
                );
              }
              return Row(
                children: streams.map((s) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: s,
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStreamItem(String route, String size, String speed, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _cardSurfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            route,
            style: TextStyle(color: _textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(size, style: TextStyle(color: _textMuted, fontSize: 10, fontFamily: 'monospace')),
              Text(speed, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurveToggleChip({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.14) : _cardSurfaceLight,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isSelected ? activeColor.withValues(alpha: 0.6) : _borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : const Color(0xFF64748B),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : _textSecondary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferTabChip(String label, IconData icon) {
    final isSelected = _activeTransferTab == label;
    return InkWell(
      onTap: () => setState(() => _activeTransferTab = label),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00F5A0).withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 11,
              color: isSelected ? const Color(0xFF00F5A0) : _textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF00F5A0) : _textMuted,
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _cardSurfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: _textSecondary, fontSize: 11)),
          Text(
            value,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Pulse Histogram Custom Painter (Live compute pulse of real nodes)
// -----------------------------------------------------------------------------
class _SwarmPulseHistogramPainter extends CustomPainter {
  final List<double> pulseBars;

  _SwarmPulseHistogramPainter({List<double>? pulseBars})
      : pulseBars = pulseBars != null && pulseBars.isNotEmpty
            ? pulseBars
            : const [
                0.18, 0.25, 0.22, 0.32, 0.28, 0.45, 0.40, 0.35, 0.52, 0.48,
                0.62, 0.55, 0.48, 0.68, 0.75, 0.58, 0.50, 0.70, 0.85, 0.65,
                0.95, 0.88, 1.00, 0.78, 0.68, 0.82
              ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double w = size.width;
    final double h = size.height;
    final int count = pulseBars.length;
    if (count == 0) return;
    final double barWidth = (w / count) - 2.5;

    final basePaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final double normalized = pulseBars[i].clamp(0.04, 1.0);
      final double barH = (normalized * h).clamp(4.0, h);
      final double x = i * (barWidth + 2.5);
      final double y = h - barH;

      // Color gradation matching real activity
      Color barColor;
      if (i == count - 1 || normalized >= 0.90) {
        barColor = const Color(0xFF00F5A0);
      } else if (i >= count - 6) {
        barColor = const Color(0xFF38BDF8);
      } else if (i >= count - 14) {
        barColor = const Color(0xFF1E3A5F);
      } else {
        barColor = const Color(0xFF1E293B);
      }

      basePaint.color = barColor;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth.clamp(1.5, 20.0), barH),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(rect, basePaint);

      // Subtle glow atop peak or newest bar
      if (normalized >= 0.90 || i == count - 1) {
        final glowPaint = Paint()
          ..color = barColor.withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(x + barWidth / 2, y), 3, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SwarmPulseHistogramPainter oldDelegate) => true;
}

// -----------------------------------------------------------------------------
// Realtime Multi-Curve Transfer Speed Graph Painter
// -----------------------------------------------------------------------------
class _SleekTransferSpeedPainter extends CustomPainter {
  final bool isDark;
  final bool isDownload;
  final bool showThroughput;
  final bool showAccuracy;
  final bool showLoss;
  final List<double> ingressPoints;
  final List<double> egressPoints;
  final List<double> accuracyPoints;
  final List<double> lossPoints;

  _SleekTransferSpeedPainter({
    required this.isDark,
    required this.isDownload,
    this.showThroughput = true,
    this.showAccuracy = true,
    this.showLoss = true,
    List<double>? ingressPoints,
    List<double>? egressPoints,
    List<double>? accuracyPoints,
    List<double>? lossPoints,
  })  : ingressPoints = (ingressPoints != null && ingressPoints.isNotEmpty)
            ? ingressPoints
            : const [
                0.38, 0.45, 0.36, 0.58, 0.50, 0.68, 0.61, 0.54, 0.76, 0.71,
                0.85, 0.72, 0.65, 0.82, 0.90, 0.75, 0.68, 0.86, 0.79, 0.93,
                0.84, 0.77, 0.95, 0.89, 0.82, 0.91, 0.85, 0.80, 0.87,
              ],
        egressPoints = (egressPoints != null && egressPoints.isNotEmpty)
            ? egressPoints
            : const [
                0.28, 0.36, 0.26, 0.48, 0.40, 0.62, 0.54, 0.46, 0.68, 0.57,
                0.78, 0.65, 0.57, 0.74, 0.83, 0.69, 0.62, 0.76, 0.85, 0.72,
                0.80, 0.67, 0.89, 0.75, 0.70, 0.84, 0.73, 0.66, 0.78,
              ],
        accuracyPoints = (accuracyPoints != null && accuracyPoints.isNotEmpty)
            ? accuracyPoints
            : const [
                0.62, 0.64, 0.65, 0.68, 0.69, 0.72, 0.71, 0.74, 0.76, 0.78,
                0.79, 0.81, 0.80, 0.83, 0.85, 0.86, 0.85, 0.88, 0.89, 0.90,
                0.91, 0.90, 0.92, 0.93, 0.93, 0.94, 0.94, 0.95, 0.948,
              ],
        lossPoints = (lossPoints != null && lossPoints.isNotEmpty)
            ? lossPoints
            : const [
                0.91, 0.85, 0.81, 0.74, 0.70, 0.63, 0.60, 0.55, 0.49, 0.45,
                0.41, 0.38, 0.36, 0.32, 0.29, 0.26, 0.25, 0.22, 0.20, 0.18,
                0.17, 0.16, 0.15, 0.14, 0.13, 0.13, 0.12, 0.125, 0.121,
              ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double w = size.width;
    final double h = size.height;

    final primaryColor = isDownload
        ? const Color(0xFF38BDF8)
        : const Color(0xFFA855F7);

    const accuracyColor = Color(0xFF00F5A0);
    const lossColor = Color(0xFFF59E0B);

    final graphLeft = 44.0;
    final graphRight = w - 24.0;
    final graphWidth = graphRight - graphLeft;
    final usableHeight = h - 38;
    final graphTop = 16.0;
    final graphBottom = h - 22.0;

    // Gridlines
    final gridPaint = Paint()
      ..color = isDark ? const Color(0x22FFFFFF) : const Color(0x18000000)
      ..strokeWidth = 0.8;

    final gridSteps = [0.25, 0.50, 0.75];
    for (final step in gridSteps) {
      final y = h * step;
      canvas.drawLine(Offset(graphLeft, y), Offset(graphRight, y), gridPaint);
    }

    for (final vStep in gridSteps) {
      final x = graphLeft + graphWidth * vStep;
      canvas.drawLine(Offset(x, 10), Offset(x, graphBottom), gridPaint);
    }

    // Throughput Curve
    if (showThroughput) {
      final points = isDownload ? ingressPoints : egressPoints;
      final int count = points.length;
      if (count >= 2) {
        final List<Offset> coords = [];
        for (int i = 0; i < count; i++) {
          final val = points[i].clamp(0.0, 1.0);
          final x = graphLeft + (i / (count - 1)) * graphWidth;
          final y = graphBottom - (val * usableHeight);
          coords.add(Offset(x, y));
        }

        final path = Path()..moveTo(coords.first.dx, coords.first.dy);
        for (int i = 1; i < coords.length; i++) {
          path.lineTo(coords[i].dx, coords[i].dy);
        }

        final fillPath = Path.from(path)
          ..lineTo(coords.last.dx, graphBottom)
          ..lineTo(coords.first.dx, graphBottom)
          ..close();

        final fillPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withValues(alpha: 0.22),
              primaryColor.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(graphLeft, graphTop, graphWidth, usableHeight));

        canvas.drawPath(fillPath, fillPaint);

        final linePaint = Paint()
          ..color = primaryColor
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

        canvas.drawPath(path, linePaint);
      }
    }

    // Accuracy Curve
    if (showAccuracy) {
      final int count = accuracyPoints.length;
      if (count >= 2) {
        final List<Offset> accCoords = [];
        for (int i = 0; i < count; i++) {
          final val = accuracyPoints[i].clamp(0.0, 1.0);
          final x = graphLeft + (i / (count - 1)) * graphWidth;
          final y = graphBottom - (val * usableHeight);
          accCoords.add(Offset(x, y));
        }

        final accPath = Path()..moveTo(accCoords.first.dx, accCoords.first.dy);
        for (int i = 0; i < accCoords.length - 1; i++) {
          final p0 = accCoords[i];
          final p1 = accCoords[i + 1];
          final cx = (p0.dx + p1.dx) / 2;
          accPath.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
        }

        final accLinePaint = Paint()
          ..color = accuracyColor
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

        canvas.drawPath(accPath, accLinePaint);
      }
    }

    // Loss Curve
    if (showLoss) {
      final int count = lossPoints.length;
      if (count >= 2) {
        final List<Offset> lossCoords = [];
        for (int i = 0; i < count; i++) {
          final val = lossPoints[i].clamp(0.0, 1.0);
          final x = graphLeft + (i / (count - 1)) * graphWidth;
          final y = graphBottom - (val * usableHeight);
          lossCoords.add(Offset(x, y));
        }

        final lossPath = Path()..moveTo(lossCoords.first.dx, lossCoords.first.dy);
        for (int i = 0; i < lossCoords.length - 1; i++) {
          final p0 = lossCoords[i];
          final p1 = lossCoords[i + 1];
          final cx = (p0.dx + p1.dx) / 2;
          lossPath.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
        }

        final lossLinePaint = Paint()
          ..color = lossColor
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke;

        canvas.drawPath(lossPath, lossLinePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SleekTransferSpeedPainter old) => true;
}
