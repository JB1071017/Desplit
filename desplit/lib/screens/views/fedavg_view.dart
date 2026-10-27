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

  // Table filtering & search
  String _nodeFilter = 'ALL'; // 'ALL', 'TRAINING', 'SYNCED', 'SYNCING', 'LAGGING'
  String _clusterFilter = 'ALL';
  String _searchQuery = '';
  String _sortBy = 'Speed'; // 'Speed', 'Progress', 'Weight', 'Ping', 'Name'
  bool _sortAscending = false;

  // Expandable row state
  String? _expandedNodeId;
  int? _hoveredRowIndex;

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

    setState(() {
      _currentRound = round;
      _isPaused = !isTraining;
      _isAggregating = isAggregating;
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
    setState(() {
      _activeViewIndex = 0;
      _nodeFilter = 'ALL';
      _clusterFilter = 'ALL';
      _expandedNodeId = nodeId;
    });
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
              // 1. Top Cyber Brand Navigation Bar (like Malext Sentry)
              _buildTopNavBar(isDark),

              const SizedBox(height: 16),

              // 2. Metric Summary Cards (4 Cards Grid, including Detection Pulse chart)
              _buildMetricCardsRow(isDark),

              const SizedBox(height: 14),

              // 3. Sliding Cyber Alert Banner
              _buildAlertBanner(isDark),

              const SizedBox(height: 16),

              // 4. View Specific Content
              if (_activeViewIndex == 0) ...[
                // Search, Filter & Toolbar (with segmented distribution progress bar)
                _buildSearchAndFilterToolbar(isDark),

                const SizedBox(height: 14),

                // Main High-Tech Data Table (matching Image 1 & Image 2)
                _buildSentryDataTable(isDark),
              ] else ...[
                // Full Diagnostics & Network View
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
  // 1. Top Navigation Bar (Malext Sentry style)
  // ---------------------------------------------------------------------------
  Widget _buildTopNavBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _borderColor,
          width: 1.0,
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          // Left: Brand Logo & Title with live pulsing indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: _isPaused
                      ? const Color(0xFFF59E0B)
                      : (_isAggregating ? const Color(0xFFA855F7) : const Color(0xFF00F5A0)),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isPaused
                              ? const Color(0xFFF59E0B)
                              : (_isAggregating ? const Color(0xFFA855F7) : const Color(0xFF00F5A0)))
                          .withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Welcome Back...',
                style: TextStyle(
                  color: Color(0xFF00F5A0),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _cardSurfaceLight,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _borderColor),
                ),
                child: Text(
                  'Llama 3 (8B)',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          // Center: View Navigation Pills
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(width: 6),
              _buildNavPill(
                title: 'PARAMETERS',
                badge: 'INT8',
                isActive: false,
                onTap: _openParametersDialog,
              ),
            ],
          ),

          // Right: Swarm Executive Training Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pause / Resume Button
              InkWell(
                onTap: _togglePauseTraining,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _isPaused
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                        : _cardSurfaceLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _isPaused
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                          : _borderColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        size: 13,
                        color: _isPaused ? const Color(0xFFF59E0B) : _textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isPaused ? 'RESUME' : 'PAUSE',
                        style: TextStyle(
                          color: _isPaused ? const Color(0xFFF59E0B) : _textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Trigger Aggregation Button
              InkWell(
                onTap: _isAggregating ? null : _triggerManualAggregation,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00F5A0), Color(0xFF00D287)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F5A0).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isAggregating
                          ? const SizedBox(
                              width: 11,
                              height: 11,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.black),
                            )
                          : const Icon(Icons.merge_type_rounded, size: 12, color: Colors.black),
                      const SizedBox(width: 5),
                      Text(
                        _isAggregating ? 'AGGREGATING...' : 'SYNC ROUND',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
                      subtext: 'Trimmed-Mean INT8',
                      icon: Icons.sync_rounded,
                      accentColor: const Color(0xFF38BDF8),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'GLOBAL LOSS',
                      value: '0.141',
                      subtext: '94.8% Acc • 0.988 cos',
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
                subtext: 'Trimmed-Mean INT8 • Next in 18s',
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
                value: '0.141',
                subtext: 'Accuracy 94.8% • 0.988 cos sim',
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
                '833 it/s sync • peak 1,480/s',
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
                painter: _SwarmPulseHistogramPainter(),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('R1: SETUP', style: TextStyle(color: _textMuted, fontSize: 8.5, fontFamily: 'monospace')),
              Text('R2: TENSORS', style: TextStyle(color: _textMuted, fontSize: 8.5, fontFamily: 'monospace')),
              Text('R3: BYZ-VERIFIED', style: TextStyle(color: _textMuted, fontSize: 8.5, fontFamily: 'monospace')),
              const Text('R4: ACTIVE SYNC', style: TextStyle(color: Color(0xFF00F5A0), fontSize: 8.5, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
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
  // 4. Search, Filter & Action Toolbar (EXACTLY matching Image 2)
  // ---------------------------------------------------------------------------
  Widget _buildSearchAndFilterToolbar(bool isDark) {
    final trainingCount = _workers.where((w) => w.status == 'Training' && !w.isExcluded).length;
    final syncedCount = _workers.where((w) => w.status == 'Synced' && !w.isExcluded).length;
    final syncingCount = _workers.where((w) => w.status == 'Syncing' && !w.isExcluded).length;
    final laggingCount = _workers.where((w) => w.status == 'Lagging' && !w.isExcluded).length;
    final excludedCount = _workers.where((w) => w.isExcluded).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main toolbar row
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            // Left: Cluster filter dropdown pill (like "MALEXT RESEARCH 0" in Image 2)
            PopupMenuButton<String>(
              initialValue: _clusterFilter,
              onSelected: (val) => setState(() => _clusterFilter = val),
              color: _cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: _borderColor),
              ),
              itemBuilder: (ctx) {
                final distinctClusters = {'ALL', ..._workers.map((w) => w.cluster.split('•').first.trim()).toSet()};
                return distinctClusters.map((c) {
                  final label = c == 'ALL' ? 'All Clusters (${distinctClusters.length - 1})' : c;
                  return PopupMenuItem(
                    value: c,
                    child: Text(label, style: TextStyle(color: _textPrimary, fontSize: 12)),
                  );
                }).toList();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _cardSurfaceLight,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: _borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hub_outlined, size: 13, color: Color(0xFF00F5A0)),
                    const SizedBox(width: 7),
                    Text(
                      _clusterFilter == 'ALL' ? 'ALL CLUSTERS' : _clusterFilter.toUpperCase(),
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_drop_down_rounded, size: 16, color: _textMuted),
                  ],
                ),
              ),
            ),

            // Center: Search Bar with Ctrl+K shortcut badge (Image 2 style)
            Container(
              width: 380,
              height: 34,
              decoration: BoxDecoration(
                color: _cardSurfaceLight,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: _borderColor),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Icon(Icons.search_rounded, size: 15, color: _textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search by node name, ID, hardware, or cluster...',
                        hintStyle: TextStyle(
                          color: _textMuted,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.close_rounded, size: 14, color: _textMuted),
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: _cardSurfaceHover,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _borderColor, width: 0.8),
                    ),
                    child: Text(
                      'Ctrl+K',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 9,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Quick Status Filter Chips
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusFilterChip('ALL', 'ALL', null),
                const SizedBox(width: 5),
                _buildStatusFilterChip('TRAINING', 'TRAINING', const Color(0xFF38BDF8)),
                const SizedBox(width: 5),
                _buildStatusFilterChip('SYNCED', 'SYNCED', const Color(0xFF00F5A0)),
                const SizedBox(width: 5),
                _buildStatusFilterChip('SYNCING', 'SYNCING', const Color(0xFFA855F7)),
                const SizedBox(width: 5),
                _buildStatusFilterChip('LAGGING', 'LAGGING', const Color(0xFFF59E0B)),
              ],
            ),

            // Right: Sort By Dropdown & Export Button
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sort By Button
                PopupMenuButton<String>(
                  initialValue: _sortBy,
                  onSelected: (val) {
                    setState(() {
                      if (_sortBy == val) {
                        _sortAscending = !_sortAscending;
                      } else {
                        _sortBy = val;
                        _sortAscending = false;
                      }
                    });
                  },
                  color: _cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: _borderColor),
                  ),
                  itemBuilder: (ctx) => [
                    PopupMenuItem(value: 'Speed', child: Text('Sort by Speed (it/s)', style: TextStyle(color: _textPrimary, fontSize: 12))),
                    PopupMenuItem(value: 'Progress', child: Text('Sort by Progress', style: TextStyle(color: _textPrimary, fontSize: 12))),
                    PopupMenuItem(value: 'Weight', child: Text('Sort by Weight Score', style: TextStyle(color: _textPrimary, fontSize: 12))),
                    PopupMenuItem(value: 'Ping', child: Text('Sort by Network Ping', style: TextStyle(color: _textPrimary, fontSize: 12))),
                    PopupMenuItem(value: 'Name', child: Text('Sort by Node Name', style: TextStyle(color: _textPrimary, fontSize: 12))),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: _cardSurfaceLight,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sort_rounded, size: 13, color: _textMuted),
                        const SizedBox(width: 6),
                        Text(
                          'SORT: ${_sortBy.toUpperCase()} ${_sortAscending ? '▲' : '▼'}',
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Export CSV Button
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Swarm telemetry exported to /logs/fedavg_round_4_telemetry.csv'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Color(0xFF00F5A0),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(7),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: _cardSurfaceLight,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: _borderColor),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download_rounded, size: 13, color: Color(0xFF00F5A0)),
                        SizedBox(width: 5),
                        Text(
                          'EXPORT CSV',
                          style: TextStyle(
                            color: Color(0xFF00F5A0),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Thin Multi-Colored Segmented Distribution Progress Bar (Image 2 style)
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 4,
            child: Row(
              children: [
                if (trainingCount > 0)
                  Expanded(
                    flex: trainingCount,
                    child: Container(color: const Color(0xFF38BDF8)),
                  ),
                if (syncedCount > 0)
                  Expanded(
                    flex: syncedCount,
                    child: Container(color: const Color(0xFF00F5A0)),
                  ),
                if (syncingCount > 0)
                  Expanded(
                    flex: syncingCount,
                    child: Container(color: const Color(0xFFA855F7)),
                  ),
                if (laggingCount > 0)
                  Expanded(
                    flex: laggingCount,
                    child: Container(color: const Color(0xFFF59E0B)),
                  ),
                if (excludedCount > 0)
                  Expanded(
                    flex: excludedCount,
                    child: Container(color: const Color(0xFFEF4444)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilterChip(String label, String value, Color? dotColor) {
    final isSelected = _nodeFilter == value;

    return InkWell(
      onTap: () => setState(() => _nodeFilter = value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _cardSurfaceHover : _cardSurfaceLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.brandAccent.withValues(alpha: 0.7) : _borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _textPrimary : _textSecondary,
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

  // ---------------------------------------------------------------------------
  // 5. High-Tech Sentry Data Table (Image 1 & Image 2)
  // ---------------------------------------------------------------------------
  Widget _buildSentryDataTable(bool isDark) {
    final workers = _filteredWorkers;

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _borderColor,
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          // Table Header Row (matching Image 1 & 2 columns)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: _cardSurfaceLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(9),
                topRight: Radius.circular(9),
              ),
              border: Border(
                bottom: BorderSide(color: _borderColor, width: 1.0),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '#',
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'NAME',
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'CLUSTER / ROLE',
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'HARDWARE & ID',
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'STATUS',
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'SOURCE / SPEED',
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'PROGRESS & TIME',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 24),
              ],
            ),
          ),

          if (workers.isEmpty)
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
                          _nodeFilter = 'ALL';
                          _clusterFilter = 'ALL';
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                      child: const Text('Reset All Filters', style: TextStyle(color: Color(0xFF00F5A0))),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: workers.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFF141A29),
              ),
              itemBuilder: (context, index) {
                final worker = workers[index];
                final isExpanded = _expandedNodeId == worker.id;
                final isHovered = _hoveredRowIndex == index;

                return _buildSentryTableRow(
                  worker: worker,
                  index: index,
                  isExpanded: isExpanded,
                  isHovered: isHovered,
                  isDark: isDark,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSentryTableRow({
    required _SwarmWorkerItem worker,
    required int index,
    required bool isExpanded,
    required bool isHovered,
    required bool isDark,
  }) {
    // Determine status color matching Image 1
    Color statusTextColor;
    String statusLabel = worker.status;
    if (worker.isExcluded) {
      statusTextColor = const Color(0xFFEF4444);
      statusLabel = 'Excluded';
    } else {
      switch (worker.status) {
        case 'Training':
          statusTextColor = const Color(0xFF38BDF8); // Cyan
          break;
        case 'Synced':
          statusTextColor = const Color(0xFF00F5A0); // Emerald
          break;
        case 'Syncing':
          statusTextColor = const Color(0xFFA855F7); // Purple
          break;
        case 'Lagging':
          statusTextColor = const Color(0xFFF59E0B); // Amber / Orange
          break;
        default:
          statusTextColor = const Color(0xFF94A3B8);
      }
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRowIndex = index),
      onExit: (_) => setState(() => _hoveredRowIndex = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: isExpanded
              ? _cardSurfaceLight
              : (isHovered ? _cardSurfaceHover : _cardBg),
          border: Border(
            left: BorderSide(
              color: isExpanded
                  ? const Color(0xFF00F5A0)
                  : (isHovered ? const Color(0xFF38BDF8) : Colors.transparent),
              width: 3.0,
            ),
          ),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _expandedNodeId = isExpanded ? null : worker.id;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Col 1: #
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isHovered ? const Color(0xFF00F5A0) : _textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),

                    // Col 2: NAME (bold title + host badge)
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        worker.name,
                                        style: TextStyle(
                                          color: worker.isExcluded ? _textMuted : _textPrimary,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (worker.role.contains('Host')) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(3),
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
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  worker.localEpoch,
                                  style: TextStyle(
                                    color: _textMuted,
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Col 3: CLUSTER / ROLE
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Icon(worker.icon, size: 14, color: worker.iconColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              worker.cluster,
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Col 4: HARDWARE & ID (Monospace ID with link icon matching Image 1)
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${worker.id} • ${worker.hardware}',
                                  style: TextStyle(
                                    color: _textSecondary,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${worker.tflops} • ${worker.vram}',
                                  style: TextStyle(
                                    color: _textMuted,
                                    fontSize: 9.5,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.open_in_new_rounded, size: 12, color: _textMuted),
                        ],
                      ),
                    ),

                    // Col 5: STATUS (Colored cyber text matching Image 1)
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusTextColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),

                    // Col 6: SOURCE / SPEED (Sleek bordered pill button matching Image 1)
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _cardSurfaceLight,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _borderColor,
                              width: 0.9,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt_rounded, size: 11, color: Color(0xFF00F5A0)),
                              const SizedBox(width: 4),
                              Text(
                                '${worker.speedItSec.toStringAsFixed(1)} it/s',
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Col 7: PROGRESS & TIME
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${(worker.progress * 100).toInt()}%',
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                worker.timeLeft,
                                style: TextStyle(
                                  color: _textMuted,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: SizedBox(
                              width: 100,
                              height: 3.5,
                              child: LinearProgressIndicator(
                                value: worker.progress,
                                backgroundColor: _isLight ? const Color(0xFFE2E8F0) : const Color(0x33FFFFFF),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  worker.progress >= 1.0 ? const Color(0xFF00F5A0) : const Color(0xFF38BDF8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Chevron >
                    SizedBox(
                      width: 24,
                      child: Center(
                        child: AnimatedRotation(
                          turns: isExpanded ? 0.25 : 0.0,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: _textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expandable High-Tech Detail Drawer
            if (isExpanded)
              _buildExpandedNodeDrawer(worker, isDark),
          ],
        ),
      ),
    );
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
                    label: 'Accuracy (94.8%)',
                    isSelected: _showAccuracyCurve,
                    activeColor: accuracyColor,
                    onTap: () => setState(() => _showAccuracyCurve = !_showAccuracyCurve),
                    isDark: isDark,
                  ),
                  _buildCurveToggleChip(
                    label: 'Loss (0.141)',
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
                'PEAK INGRESS',
                '2.41 GB/s',
                const Color(0xFF38BDF8),
              ),
              _buildMiniTelemetryBadge(
                'GLOBAL ACCURACY',
                '94.8% (+1.2%)',
                const Color(0xFF00F5A0),
              ),
              _buildMiniTelemetryBadge(
                'CONVERGENCE LOSS',
                '0.141 (-0.024)',
                const Color(0xFFF59E0B),
              ),
              _buildMiniTelemetryBadge(
                'QUORUM SYNC',
                '8/8 Active Nodes',
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
          _buildMetricTile('Aggregate Weight Delta', '4.46 GB INT8', isDark),
          const SizedBox(height: 10),
          _buildMetricTile('Trimmed-Mean Outlier Cutoff', '10% Top / 10% Bottom', isDark),
          const SizedBox(height: 10),
          _buildMetricTile('Byzantine Audit Status', '100% Verified Clean', isDark),
          const SizedBox(height: 10),
          _buildMetricTile('Avg Inter-Node P2P RTT', '82.4 ms', isDark),
          const SizedBox(height: 10),
          _buildMetricTile('Compression Ratio', '4.1x (76% Bandwidth Saved)', isDark),
          const SizedBox(height: 10),
          _buildMetricTile('Estimated Round Finish', '18 Seconds Left', isDark),
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
              if (_workers.length <= 1) {
                final w = _workers.isNotEmpty ? _workers[0] : null;
                final speedStr = w != null ? '${w.speedItSec.toStringAsFixed(1)} it/s' : 'Idle';
                final deltaStr = w != null ? w.deltaSize : '256 MB INT8';
                streams.add(_buildStreamItem('Host CPU/GPU ➔ Shard Cache', deltaStr, speedStr, const Color(0xFF00F5A0)));
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
// Pulse Histogram Custom Painter (EXACTLY like Image 2 "DETECTION PULSE")
// -----------------------------------------------------------------------------
class _SwarmPulseHistogramPainter extends CustomPainter {
  // 26 bar heights representing throughput pulses
  static const List<double> _pulseBars = [
    0.18, 0.25, 0.22, 0.32, 0.28, 0.45, 0.40, 0.35, 0.52, 0.48,
    0.62, 0.55, 0.48, 0.68, 0.75, 0.58, 0.50, 0.70, 0.85, 0.65,
    0.95, 0.88, 1.00, 0.78, 0.68, 0.82
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final double w = size.width;
    final double h = size.height;
    final int count = _pulseBars.length;
    final double barWidth = (w / count) - 2.5;

    final basePaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final double normalized = _pulseBars[i];
      final double barH = (normalized * h).clamp(4.0, h);
      final double x = i * (barWidth + 2.5);
      final double y = h - barH;

      // Color gradation matching Image 2: older bars muted blue-gray, peak and recent bars cyan/emerald
      Color barColor;
      if (i == 22) {
        // Peak bar
        barColor = const Color(0xFF00F5A0);
      } else if (i >= 20) {
        barColor = const Color(0xFF38BDF8);
      } else if (i >= 14) {
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

      // Subtle glow atop the peak bar
      if (i == 22) {
        final glowPaint = Paint()
          ..color = const Color(0xFF00F5A0).withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(x + barWidth / 2, y), 3, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// Realtime Transfer Speed Graph Painter
// -----------------------------------------------------------------------------
class _SleekTransferSpeedPainter extends CustomPainter {
  final bool isDark;
  final bool isDownload;
  final bool showThroughput;
  final bool showAccuracy;
  final bool showLoss;

  _SleekTransferSpeedPainter({
    required this.isDark,
    required this.isDownload,
    this.showThroughput = true,
    this.showAccuracy = true,
    this.showLoss = true,
  });

  static const List<double> _downloadTelemetryPoints = [
    0.38, 0.45, 0.36, 0.58, 0.50, 0.68, 0.61, 0.54, 0.76, 0.71,
    0.85, 0.72, 0.65, 0.82, 0.90, 0.75, 0.68, 0.86, 0.79, 0.93,
    0.84, 0.77, 0.95, 0.89, 0.82, 0.91, 0.85, 0.80, 0.87,
  ];

  static const List<double> _uploadTelemetryPoints = [
    0.28, 0.36, 0.26, 0.48, 0.40, 0.62, 0.54, 0.46, 0.68, 0.57,
    0.78, 0.65, 0.57, 0.74, 0.83, 0.69, 0.62, 0.76, 0.85, 0.72,
    0.80, 0.67, 0.89, 0.75, 0.70, 0.84, 0.73, 0.66, 0.78,
  ];

  static const List<double> _accuracyTelemetryPoints = [
    0.62, 0.64, 0.65, 0.68, 0.69, 0.72, 0.71, 0.74, 0.76, 0.78,
    0.79, 0.81, 0.80, 0.83, 0.85, 0.86, 0.85, 0.88, 0.89, 0.90,
    0.91, 0.90, 0.92, 0.93, 0.93, 0.94, 0.94, 0.95, 0.948,
  ];

  static const List<double> _lossTelemetryPoints = [
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

    final int count = 29;

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
      final points = isDownload ? _downloadTelemetryPoints : _uploadTelemetryPoints;
      final List<Offset> coords = [];

      for (int i = 0; i < count; i++) {
        final val = points[i];
        final x = graphLeft + (i / (count - 1)) * graphWidth;
        final y = graphBottom - (val * usableHeight);
        coords.add(Offset(x, y));
      }

      final path = Path()..moveTo(coords.first.dx, coords.first.dy);
      for (int i = 1; i < coords.length; i++) {
        path.lineTo(coords[i].dx, coords[i].dy);
      }

      // Gradient fill
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

    // Accuracy Curve
    if (showAccuracy) {
      final List<Offset> accCoords = [];
      for (int i = 0; i < count; i++) {
        final val = _accuracyTelemetryPoints[i];
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

    // Loss Curve
    if (showLoss) {
      final List<Offset> lossCoords = [];
      for (int i = 0; i < count; i++) {
        final val = _lossTelemetryPoints[i];
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

  @override
  bool shouldRepaint(covariant _SleekTransferSpeedPainter old) {
    return old.isDownload != isDownload ||
        old.showThroughput != showThroughput ||
        old.showAccuracy != showAccuracy ||
        old.showLoss != showLoss;
  }
}
