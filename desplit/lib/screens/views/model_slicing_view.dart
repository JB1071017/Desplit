import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/desplit_daemon_service.dart';
import '../../services/theme_service.dart';
import '../../theme/app_colors.dart';
import 'network/world_atlas_service.dart';

class _PipelineStage {
  final int stageNumber;
  final String nodeName;
  final String location;
  final String hardware;
  final String layerRange;
  final String layerDescription;
  final double allocatedMemoryGb;
  final double weightMemoryGb;
  final double activationMemoryGb;
  final double totalVramGb;
  final int stageLatencyMs;
  final int forwardMs;
  final int backwardMs;
  final int quicLatencyMs;
  final int bubbleMs;
  final int gpuLoadPercent;
  final int tempCelsius;
  final int powerWatts;
  final bool hasWarning;
  final String status;

  const _PipelineStage({
    required this.stageNumber,
    required this.nodeName,
    required this.location,
    required this.hardware,
    required this.layerRange,
    required this.layerDescription,
    required this.allocatedMemoryGb,
    required this.weightMemoryGb,
    required this.activationMemoryGb,
    required this.totalVramGb,
    required this.stageLatencyMs,
    required this.forwardMs,
    required this.backwardMs,
    required this.quicLatencyMs,
    required this.bubbleMs,
    required this.gpuLoadPercent,
    required this.tempCelsius,
    required this.powerWatts,
    this.hasWarning = false,
    this.status = 'Running',
  });
}

class ModelSlicingView extends StatefulWidget {
  final bool isOnline;
  final VoidCallback? onToggleOnline;

  const ModelSlicingView({
    super.key,
    this.isOnline = true,
    this.onToggleOnline,
  });

  @override
  State<ModelSlicingView> createState() => _ModelSlicingViewState();
}

class _ModelSlicingViewState extends State<ModelSlicingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  bool _isPaused = false;
  String _mapProjection = '3D_GLOBE'; // '3D_GLOBE' or '3D_ORBITAL'
  int? _hoveredStageIndex;
  int _selectedStageIndex = 0; // Default: Stage 1 selected

  int get _safeSelectedStageIndex =>
      _selectedStageIndex.clamp(0, (_stages.length - 1).clamp(0, 9999));

  List<_PipelineStage> get _stages {
    final liveNodes = DeSplitDaemonService.instance.meshNodes.value;
    if (liveNodes.isEmpty) {
      return const [
        _PipelineStage(
          stageNumber: 1,
          nodeName: 'OPERATOR (YOU)',
          location: 'Local Host • Tier 0',
          hardware: 'Intel(R) Iris(R) Xe • 12 Cores / 16 GB RAM',
          layerRange: 'Layers 1–32 (Consolidated Pipeline)',
          layerDescription:
              'Local pipeline execution ready across pooled CPU/GPU compute cores',
          allocatedMemoryGb: 3.2,
          weightMemoryGb: 2.8,
          activationMemoryGb: 0.4,
          totalVramGb: 16.0,
          stageLatencyMs: 18,
          forwardMs: 6,
          backwardMs: 12,
          quicLatencyMs: 0,
          bubbleMs: 1,
          gpuLoadPercent: 14,
          tempCelsius: 48,
          powerWatts: 28,
          hasWarning: false,
          status: 'Ready',
        ),
      ];
    }

    return List.generate(liveNodes.length, (idx) {
      final node = liveNodes[idx];
      final isLocal = node.isUser;
      const totalLayers = 32;
      final stageCount = liveNodes.length;
      final layersPerStage = (totalLayers / stageCount).ceil();
      final startLayer = idx * layersPerStage + 1;
      final endLayer = ((idx + 1) * layersPerStage).clamp(1, totalLayers);

      return _PipelineStage(
        stageNumber: idx + 1,
        nodeName: node.title,
        location: node.region,
        hardware: node.gpu,
        layerRange: 'Layers $startLayer–$endLayer',
        layerDescription: isLocal
            ? 'Input Embeddings & Attention Blocks on local operator'
            : 'Distributed Attention & SwiGLU MLP Blocks over P2P mesh',
        allocatedMemoryGb: 3.2,
        weightMemoryGb: 2.5,
        activationMemoryGb: 0.7,
        totalVramGb: 16.0,
        stageLatencyMs: 24 + (idx * 6),
        forwardMs: 8,
        backwardMs: 16,
        quicLatencyMs: isLocal ? 0 : 12,
        bubbleMs: 2,
        gpuLoadPercent: 22,
        tempCelsius: 50,
        powerWatts: 35,
        hasWarning: false,
        status: 'Online',
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    WorldAtlasService.instance.loadAtlas();
    DeSplitDaemonService.instance.meshNodes.addListener(_onDaemonNodesChanged);
  }

  void _onDaemonNodesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DeSplitDaemonService.instance.meshNodes.removeListener(_onDaemonNodesChanged);
    _animController.dispose();
    super.dispose();
  }

  void _openPlanModal() {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = !ThemeService.instance.isLight;
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.tune_rounded, size: 20, color: AppColors.brandAccent),
              const SizedBox(width: 10),
              Text(
                'Pipeline Execution Plan',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
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
                  '32 layers partitioned across 4 stages. All memory allocations validated.',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPlanRow('Stage 1 (Host)', 'Layers 1–8', '4.2 GB weights + 1.6 GB activations', isDark),
                const SizedBox(height: 8),
                _buildPlanRow('Stage 2 (Node-SG)', 'Layers 9–16', '4.2 GB weights + 1.2 GB activations', isDark),
                const SizedBox(height: 8),
                _buildPlanRow('Stage 3 (Node-IN)', 'Layers 17–24', '4.2 GB weights + 1.4 GB activations', isDark),
                const SizedBox(height: 8),
                _buildPlanRow('Stage 4 (Node-DE)', 'Layers 25–32', '4.2 GB weights + 1.0 GB activations', isDark),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Plan validated: 7.2 GB memory headroom available across the swarm.',
                          style: TextStyle(
                            color: isDark ? const Color(0xFFCBD5E1) : AppColors.textPrimary,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

  Widget _buildPlanRow(String stage, String layers, String details, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stage,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                details,
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textMuted,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.brandAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              layers,
              style: TextStyle(
                color: AppColors.brandAccent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRestartRun() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Restart Pipeline Run?'),
          content: const Text(
            'This will clear activation buffers and restart token execution from Stage 1. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Pipeline execution restarted from Stage 1'),
                    backgroundColor: AppColors.brandAccent,
                  ),
                );
              },
              child: const Text('Restart', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: ThemeService.instance.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode != AppThemeMode.light;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header with Title, State & Controls
              _buildTopHeader(isDark),

              const SizedBox(height: 12),

              // 2. Single Cohesive Summary Strip: Local VRAM | Swarm Memory | Step Latency
              _buildUnifiedSummaryStrip(isDark),

              const SizedBox(height: 16),

              // 3. Main Workspace: LayoutBuilder providing Wide (side-by-side) or Compact layout
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 940;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Execution Pipeline + Integrated Memory Bar + 3D Globe
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPipelineStagesRow(isDark),
                              const SizedBox(height: 12),
                              _buildIntegratedMemoryBar(isDark),
                              const SizedBox(height: 14),
                              _buildGlobeContainer(isDark),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Right Column: Contextual Stage Details Panel
                        Expanded(
                          flex: 4,
                          child: _buildStageDetailsPanel(_stages[_safeSelectedStageIndex], isDark),
                        ),
                      ],
                    );
                  }

                  // Narrow / Compact Window Layout
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPipelineStagesRow(isDark),
                      const SizedBox(height: 12),
                      _buildIntegratedMemoryBar(isDark),
                      const SizedBox(height: 14),
                      _buildStageDetailsPanel(_stages[_safeSelectedStageIndex], isDark),
                      const SizedBox(height: 14),
                      _buildGlobeContainer(isDark),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Top Header Row
  // ---------------------------------------------------------------------------
  Widget _buildTopHeader(bool isDark) {
    String stateLabel;
    Color stateColor;
    if (!widget.isOnline) {
      stateLabel = 'OFFLINE';
      stateColor = const Color(0xFF94A3B8);
    } else if (_isPaused) {
      stateLabel = 'PAUSED';
      stateColor = const Color(0xFFF59E0B);
    } else {
      stateLabel = 'RUNNING';
      stateColor = const Color(0xFF10B981);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title & Model Info
        Row(
          children: [
            Text(
              'Model Pipeline',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'Llama-3-8B · 4 nodes',
                style: TextStyle(
                  color: AppColors.brandAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: stateColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: stateColor.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5.5,
                    height: 5.5,
                    decoration: BoxDecoration(color: stateColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    stateLabel,
                    style: TextStyle(
                      color: stateColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Controls
        Row(
          children: [
            // Plan modal
            InkWell(
              onTap: _openPlanModal,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.7)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 13, color: isDark ? const Color(0xFFCBD5E1) : AppColors.textPrimary),
                    const SizedBox(width: 5),
                    Text(
                      'Plan',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFCBD5E1) : AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Restart Button
            InkWell(
              onTap: _confirmRestartRun,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.7)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 13, color: isDark ? const Color(0xFF94A3B8) : AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Restart',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Pause / Resume Toggle
            InkWell(
              onTap: () => setState(() => _isPaused = !_isPaused),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: _isPaused ? AppColors.brandAccent : AppColors.cardSurfaceLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isPaused ? AppColors.brandAccent : AppColors.borderSubtle,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      size: 14,
                      color: _isPaused ? Colors.white : (isDark ? Colors.white : AppColors.textPrimary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isPaused ? 'Resume' : 'Pause',
                      style: TextStyle(
                        color: _isPaused ? Colors.white : (isDark ? Colors.white : AppColors.textPrimary),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
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

  // ---------------------------------------------------------------------------
  // 2. Single Unified Summary Strip (Replaces separate competing metric cards)
  // ---------------------------------------------------------------------------
  Widget _buildUnifiedSummaryStrip(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.6),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // 1. Local GPU Memory
          Expanded(
            child: _buildSummaryMetricItem(
              label: 'Local GPU Memory',
              value: '5.8 / 8.0 GB',
              subtext: '72% utilized (Layers 1–8)',
              progress: 0.72,
              accentColor: AppColors.brandAccent,
              isDark: isDark,
            ),
          ),

          _buildVerticalDivider(),

          // 2. Swarm Memory
          Expanded(
            child: _buildSummaryMetricItem(
              label: 'Swarm Memory',
              value: '16.8 / 24.0 GB',
              subtext: '70% allocated (7.2 GB headroom)',
              progress: 0.70,
              accentColor: const Color(0xFF10B981),
              isDark: isDark,
            ),
          ),

          _buildVerticalDivider(),

          // 3. Step Latency
          Expanded(
            child: _buildSummaryMetricItem(
              label: 'Step Latency',
              value: '161 ms',
              subtext: '84 tokens/s (148ms compute + 13ms bubble)',
              accentColor: const Color(0xFF38BDF8),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 32,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: AppColors.borderSubtle.withValues(alpha: 0.5),
    );
  }

  Widget _buildSummaryMetricItem({
    required String label,
    required String value,
    required String subtext,
    double? progress,
    required Color accentColor,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (progress != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Container(
              height: 3.5,
              color: AppColors.progressTrack,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(color: accentColor),
              ),
            ),
          ),
          const SizedBox(height: 3),
        ],
        Text(
          subtext,
          style: TextStyle(
            color: isDark ? const Color(0xFF64748B) : AppColors.textMuted,
            fontSize: 9.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Pipeline Stages Connected Row
  // ---------------------------------------------------------------------------
  Widget _buildPipelineStagesRow(bool isDark) {
    return Row(
      children: List.generate(_stages.length * 2 - 1, (i) {
        if (i.isOdd) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 13,
              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
            ),
          );
        }

        final stageIndex = i ~/ 2;
        final stage = _stages[stageIndex];
        final isSelected = _selectedStageIndex == stageIndex;
        final isHovered = _hoveredStageIndex == stageIndex;

        return Expanded(
          child: MouseRegion(
            onEnter: (_) => setState(() => _hoveredStageIndex = stageIndex),
            onExit: (_) => setState(() => _hoveredStageIndex = null),
            child: GestureDetector(
              onTap: () => setState(() => _selectedStageIndex = stageIndex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                          ? (AppColors.isProfessional ? const Color(0xFF262B34) : const Color(0xFF1E293B))
                          : const Color(0xFFF1F5F9))
                      : (isHovered ? AppColors.cardSurfaceHover : AppColors.cardSurface),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brandAccent
                        : (isHovered
                            ? AppColors.brandAccent.withValues(alpha: 0.4)
                            : AppColors.borderSubtle.withValues(alpha: 0.6)),
                    width: isSelected ? 1.4 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Stage ${stage.stageNumber}',
                          style: TextStyle(
                            color: isSelected ? AppColors.brandAccent : (isDark ? Colors.white : AppColors.textPrimary),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: stage.hasWarning ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stage.nodeName,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      stage.layerRange,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${stage.allocatedMemoryGb} GB',
                          style: TextStyle(
                            color: isDark ? const Color(0xFFCBD5E1) : AppColors.textPrimary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (stage.hasWarning)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              '72%',
                              style: TextStyle(color: Color(0xFFF59E0B), fontSize: 8.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Integrated Memory Allocation Bar (Reconciled from per-node live data)
  // ---------------------------------------------------------------------------
  Widget _buildIntegratedMemoryBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Memory Allocation (16.8 GB model / 24.0 GB pool · 7.2 GB buffer)',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                'Plan Feasible',
                style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 18,
              child: Row(
                children: [
                  _buildMemorySlice('S1: 4.2 GB', 42, AppColors.brandAccent),
                  const SizedBox(width: 1),
                  _buildMemorySlice('S2: 4.2 GB', 42, const Color(0xFF38BDF8)),
                  const SizedBox(width: 1),
                  _buildMemorySlice('S3: 4.2 GB', 42, const Color(0xFF00F5A0)),
                  const SizedBox(width: 1),
                  _buildMemorySlice('S4: 4.2 GB', 42, const Color(0xFFA855F7)),
                  const SizedBox(width: 1),
                  Expanded(
                    flex: 72,
                    child: Container(
                      color: AppColors.cardSurfaceLight,
                      child: Center(
                        child: Text(
                          'Buffer 7.2 GB',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemorySlice(String label, int flex, Color color) {
    return Expanded(
      flex: flex,
      child: Container(
        color: color.withValues(alpha: 0.85),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. 3D Globe Section (Shown ONLY when widget.isOnline == true!)
  // ---------------------------------------------------------------------------
  Widget _buildGlobeContainer(bool isDark) {
    if (!widget.isOnline) {
      // Mesh is disconnected: Do NOT show the globe, show clean message
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded, size: 32, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
            const SizedBox(height: 8),
            Text(
              'Mesh Disconnected — 3D Tensor Flow Paused',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Node is offline. Turn on the master switch in the top window bar to connect to the swarm mesh.',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: widget.onToggleOnline,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.brandAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.power_settings_new_rounded, size: 13, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'Connect Node to Mesh',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Node is ONLINE: Render the 3D globe!
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Global Tensor Flow',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LIVE 3D',
                        style: TextStyle(color: Color(0xFF00F5A0), fontSize: 8.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildProjectionToggle('3D GLOBE', _mapProjection == '3D_GLOBE', () {
                      setState(() => _mapProjection = '3D_GLOBE');
                    }, isDark),
                    const SizedBox(width: 5),
                    _buildProjectionToggle('ORBITAL', _mapProjection == '3D_ORBITAL', () {
                      setState(() => _mapProjection = '3D_ORBITAL');
                    }, isDark),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: AppColors.borderSubtle.withValues(alpha: 0.5), height: 1),
          SizedBox(
            height: 310,
            width: double.infinity,
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _PipelineGlobePainter3D(
                      animationProgress: _animController.value,
                      isLightMode: !isDark && !AppColors.isProfessional,
                      isGlobeMode: _mapProjection == '3D_GLOBE',
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectionToggle(String title, bool isSelected, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandAccent.withValues(alpha: 0.20) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AppColors.brandAccent : AppColors.borderSubtle.withValues(alpha: 0.6),
            width: 0.7,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.brandAccent : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
            fontSize: 9.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Contextual Stage Details Panel (Displays next to or below pipeline)
  // ---------------------------------------------------------------------------
  Widget _buildStageDetailsPanel(_PipelineStage stage, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.brandAccent.withValues(alpha: 0.35), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.layers_rounded, size: 15, color: AppColors.brandAccent),
                  const SizedBox(width: 6),
                  Text(
                    'Stage ${stage.stageNumber} — ${stage.nodeName}',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.cardSurfaceLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  stage.location,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Hardware Diagnostics
          _buildDetailGroup(
            title: 'HARDWARE & TELEMETRY',
            isDark: isDark,
            rows: [
              _buildMetricLine('Hardware Model', stage.hardware, isDark),
              _buildMetricLine('GPU Core Load', '${stage.gpuLoadPercent}%', isDark),
              _buildMetricLine('Temperature / Power', '${stage.tempCelsius}°C • ${stage.powerWatts}W', isDark),
            ],
          ),

          const SizedBox(height: 8),

          // Memory Breakdown
          _buildDetailGroup(
            title: 'VRAM MEMORY BREAKDOWN',
            isDark: isDark,
            rows: [
              _buildMetricLine('Model Weights', '${stage.weightMemoryGb} GB', isDark),
              _buildMetricLine('Activation Buffer', '${stage.activationMemoryGb} GB', isDark),
              _buildMetricLine('Physical VRAM', '${stage.allocatedMemoryGb} / ${stage.totalVramGb} GB', isDark),
            ],
          ),

          const SizedBox(height: 8),

          // Execution & Schedule Latency
          _buildDetailGroup(
            title: 'STAGE LATENCY & SCHEDULE',
            isDark: isDark,
            rows: [
              _buildMetricLine('Forward Pass', '${stage.forwardMs} ms', isDark),
              _buildMetricLine('Backward Pass', '${stage.backwardMs} ms', isDark),
              _buildMetricLine('QUIC Mesh Overhead', '${stage.quicLatencyMs} ms (${stage.bubbleMs}ms bubble)', isDark),
            ],
          ),

          const SizedBox(height: 8),

          // Layer Operations
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.cardSurfaceLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.layerRange,
                  style: TextStyle(
                    color: AppColors.brandAccent,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stage.layerDescription,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailGroup({
    required String title,
    required bool isDark,
    required List<Widget> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 5),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildMetricLine(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textMuted,
              fontSize: 10.5,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PURE 3D PIPELINE GLOBE PAINTER (Smooth Spherical & Orbital Great-Circle Flow)
// =============================================================================
class _PipelineGlobePainter3D extends CustomPainter {
  final double animationProgress;
  final bool isLightMode;
  final bool isGlobeMode;

  _PipelineGlobePainter3D({
    required this.animationProgress,
    required this.isLightMode,
    required this.isGlobeMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width * 0.5, size.height * 0.5);

    if (isGlobeMode) {
      _paint3DSphericalGlobe(canvas, size, center);
    } else {
      _paint3DOrbitalRing(canvas, size, center);
    }
  }

  void _paint3DSphericalGlobe(Canvas canvas, Size size, Offset center) {
    final radius = math.min(size.width, size.height) * 0.38;

    final lonRotation = (animationProgress * 2 * math.pi) % (2 * math.pi);
    const tilt = 0.22;
    final cosTilt = math.cos(tilt);
    final sinTilt = math.sin(tilt);

    // 1. Atmospheric Glow
    final glowColor = AppColors.brandAccent;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor.withValues(alpha: 0.20),
          glowColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius + 10))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 10, glowPaint);

    // 2. Base Shaded Sphere
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
                const Color(0xFF1E242C),
                const Color(0xFF171A21),
                const Color(0xFF111419),
              ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, spherePaint);

    // Clip to sphere disc
    canvas.save();
    final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(clipPath);

    // 3. Latitude & Longitude Graticule
    final gridPaint = Paint()
      ..color = AppColors.borderSubtle.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

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

    // 4. Continents
    final atlas = WorldAtlasService.instance;
    final ringsToDraw = atlas.isLoaded ? atlas.globeRings : [];

    final landPaint = Paint()
      ..color = isLightMode ? const Color(0xFFDDD2F8) : const Color(0xFF232A34)
      ..style = PaintingStyle.fill;
    final landStroke = Paint()
      ..color = AppColors.brandAccent.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

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

    // 5. 3D Pipeline Nodes
    final pipelineNodes = [
      _GlobeNode('STAGE 1: THIS PC', -122.4, 37.7, 'L 1-8 • 5.8 GB', AppColors.brandAccent),
      _GlobeNode('STAGE 2: NODE-SG', 103.82, 1.35, 'L 9-16 • 5.4 GB', const Color(0xFF38BDF8)),
      _GlobeNode('STAGE 3: NODE-IN', 77.59, 12.97, 'L 17-24 • 5.6 GB', const Color(0xFF00F5A0)),
      _GlobeNode('STAGE 4: NODE-DE', 8.68, 50.11, 'L 25-32 • 5.2 GB', const Color(0xFFA855F7)),
    ];

    final nodeScreenPositions = <int, Offset>{};
    final nodeVisibility = <int, bool>{};

    for (int i = 0; i < pipelineNodes.length; i++) {
      final node = pipelineNodes[i];
      final lam = node.lon * math.pi / 180.0 - lonRotation;
      final phi = node.lat * math.pi / 180.0;
      final cosC = sinTilt * math.sin(phi) + cosTilt * math.cos(phi) * math.cos(lam);

      final isVisible = cosC > 0.05;
      nodeVisibility[i] = isVisible;

      final px = center.dx + radius * math.cos(phi) * math.sin(lam);
      final py = center.dy - radius * (cosTilt * math.sin(phi) - sinTilt * math.cos(phi) * math.cos(lam));
      nodeScreenPositions[i] = Offset(px, py);
    }

    // 6. Draw 3D Curved Great-Circle Tensor Routes Between Consecutive Nodes
    for (int i = 0; i < pipelineNodes.length; i++) {
      final nextIdx = (i + 1) % pipelineNodes.length;
      final p1 = nodeScreenPositions[i]!;
      final p2 = nodeScreenPositions[nextIdx]!;
      final isBothVisible = (nodeVisibility[i] ?? false) || (nodeVisibility[nextIdx] ?? false);

      if (isBothVisible) {
        final nodeA = pipelineNodes[i];

        final arcPath = Path();
        arcPath.moveTo(p1.dx, p1.dy);

        final midX = (p1.dx + p2.dx) / 2;
        final midY = (p1.dy + p2.dy) / 2;
        final vecToCenter = Offset(midX - center.dx, midY - center.dy);
        final cp = Offset(midX + vecToCenter.dx * 0.25, midY + vecToCenter.dy * 0.25);

        arcPath.quadraticBezierTo(cp.dx, cp.dy, p2.dx, p2.dy);

        final arcPaint = Paint()
          ..color = nodeA.color.withValues(alpha: 0.40)
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke;
        canvas.drawPath(arcPath, arcPaint);

        // Traveling packet bead
        final t = (animationProgress * 1.5 + (i * 0.25)) % 1.0;
        final u = 1 - t;
        final bx = u * u * p1.dx + 2 * u * t * cp.dx + t * t * p2.dx;
        final by = u * u * p1.dy + 2 * u * t * cp.dy + t * t * p2.dy;

        canvas.drawCircle(
          Offset(bx, by),
          4.5,
          Paint()..color = nodeA.color.withValues(alpha: 0.35)..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          Offset(bx, by),
          2.8,
          Paint()..color = nodeA.color..style = PaintingStyle.fill,
        );
      }
    }

    // 7. Draw 3D Node Pins and Labels
    for (int i = 0; i < pipelineNodes.length; i++) {
      if (nodeVisibility[i] ?? false) {
        final pos = nodeScreenPositions[i]!;
        final node = pipelineNodes[i];

        final pulseR = 4.0 + 1.8 * math.sin(animationProgress * math.pi * 2);
        canvas.drawCircle(
          pos,
          pulseR + 2,
          Paint()..color = node.color.withValues(alpha: 0.25)..style = PaintingStyle.fill,
        );

        canvas.drawCircle(
          pos,
          4.0,
          Paint()..color = node.color..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          pos,
          1.8,
          Paint()..color = Colors.white..style = PaintingStyle.fill,
        );

        // Node Label
        final tp = TextPainter(
          text: TextSpan(
            text: '${node.name}\n${node.subtitle}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final labelRect = Rect.fromLTWH(
          pos.dx + 8,
          pos.dy - 12,
          tp.width + 10,
          tp.height + 6,
        );

        canvas.drawRRect(
          RRect.fromRectAndRadius(labelRect, const Radius.circular(5)),
          Paint()..color = const Color(0xFF14171E).withValues(alpha: 0.90),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(labelRect, const Radius.circular(5)),
          Paint()
            ..color = node.color.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );

        tp.paint(canvas, Offset(pos.dx + 13, pos.dy - 9));
      }
    }

    canvas.restore();
  }

  void _paint3DOrbitalRing(Canvas canvas, Size size, Offset center) {
    final rx = size.width * 0.36;
    final ry = size.height * 0.28;

    // Outer orbital aura
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 2 + 16, height: ry * 2 + 16),
      Paint()
        ..color = AppColors.brandAccent.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    // 3D Orbital ring path
    final ringPaint = Paint()
      ..color = AppColors.borderSubtle.withValues(alpha: 0.4)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    canvas.drawOval(Rect.fromCenter(center: center, width: rx * 2, height: ry * 2), ringPaint);

    final nodes = [
      _GlobeNode('STAGE 1: THIS PC', 0, 0, 'Layers 1–8 • 5.8 GB', AppColors.brandAccent),
      _GlobeNode('STAGE 2: NODE-SG', 0, 0, 'Layers 9–16 • 5.4 GB', const Color(0xFF38BDF8)),
      _GlobeNode('STAGE 3: NODE-IN', 0, 0, 'Layers 17–24 • 5.6 GB', const Color(0xFF00F5A0)),
      _GlobeNode('STAGE 4: NODE-DE', 0, 0, 'Layers 25–32 • 5.2 GB', const Color(0xFFA855F7)),
    ];

    for (int i = 0; i < nodes.length; i++) {
      final angle = (i * math.pi / 2) + (animationProgress * 2 * math.pi);
      final px = center.dx + rx * math.cos(angle);
      final py = center.dy + ry * math.sin(angle);
      final node = nodes[i];

      final nextAngle = ((i + 1) * math.pi / 2) + (animationProgress * 2 * math.pi);
      final npx = center.dx + rx * math.cos(nextAngle);
      final npy = center.dy + ry * math.sin(nextAngle);

      final packetT = (animationProgress * 2.0 + (i * 0.25)) % 1.0;
      final pCurX = px + (npx - px) * packetT;
      final pCurY = py + (npy - py) * packetT;

      canvas.drawCircle(
        Offset(pCurX, pCurY),
        3.2,
        Paint()..color = node.color.withValues(alpha: 0.7)..style = PaintingStyle.fill,
      );

      // Node dot
      canvas.drawCircle(
        Offset(px, py),
        6,
        Paint()..color = node.color..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(px, py),
        2.5,
        Paint()..color = Colors.white..style = PaintingStyle.fill,
      );

      // Label
      final tp = TextPainter(
        text: TextSpan(
          text: '${node.name}\n${node.subtitle}',
          style: TextStyle(
            color: isLightMode ? AppColors.textPrimary : Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      final labelRect = Rect.fromCenter(
        center: Offset(px, py + 24),
        width: tp.width + 12,
        height: tp.height + 6,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(5)),
        Paint()..color = const Color(0xFF14171E).withValues(alpha: 0.90),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(5)),
        Paint()..color = node.color.withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 0.8,
      );

      tp.paint(canvas, Offset(labelRect.left + 6, labelRect.top + 3));
    }
  }

  @override
  bool shouldRepaint(covariant _PipelineGlobePainter3D oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.isLightMode != isLightMode ||
        oldDelegate.isGlobeMode != isGlobeMode;
  }
}

class _GlobeNode {
  final String name;
  final double lon;
  final double lat;
  final String subtitle;
  final Color color;

  _GlobeNode(this.name, this.lon, this.lat, this.subtitle, this.color);
}
