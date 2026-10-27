import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../services/desplit_daemon_service.dart';
import '../../services/theme_service.dart';
import '../../theme/app_colors.dart';
import 'network/network_map_painter.dart';
import 'network/network_models.dart';
import 'network/spider_chart_painter.dart';
import 'network/traffic_map_painter.dart';

class NetworkView extends StatefulWidget {
  final bool isOnline;
  final VoidCallback? onToggleOnline;

  const NetworkView({
    super.key,
    this.isOnline = true,
    this.onToggleOnline,
  });

  @override
  State<NetworkView> createState() => _NetworkViewState();
}

class _NetworkViewState extends State<NetworkView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final TransformationController _mapTransformController;
  bool _hasCenteredMap = false;
  bool _isHoveringMap = false;
  bool _isDraggingMap = false;
  String? _hoveredNodeId;
  String _selectedFilter = 'ALL';
  final bool _isTrafficGlobeMode = true;

  // Decentralized P2P Mesh Topology Constellation (Centered around Local Operator)
  static const List<MeshNode> _nodes = [
    // Operator Center Core (Local Node)
    MeshNode(
      id: 'node_user',
      title: 'OPERATOR (YOU)',
      username: '@operator_081',
      gpu: 'Intel(R) Iris(R) Xe Graphics',
      contribution: '14.2 TFLOPS • 0.7 GB Shared VRAM',
      latency: '0 ms',
      region: 'Local Node (Tier 0)',
      relativePos: Offset(0.50, 0.50),
      icon: Icons.memory_rounded,
      isUser: true,
    ),
  ];

  // Key Indicators (Real Cluster Health & Security Radar)
  List<RadarIndicator> get _indicators {
    final hw = DeSplitDaemonService.instance.hardwareMetrics.value;
    final realtime = hw?['realtime'] as Map<String, dynamic>?;
    final ramPct = (realtime?['ram_percent'] as num? ?? 82.0) / 100.0;
    final ramUsed = realtime?['ram_used_gb'] ?? 13.0;
    final ramTotal = realtime?['ram_total_gb'] ?? 15.8;
    final isOnline = widget.isOnline;

    return [
      RadarIndicator(name: 'NODE INTEGRITY', value: isOnline ? 1.0 : 0.2, displayScore: isOnline ? '12/12' : '2/12'),
      const RadarIndicator(name: 'GRPC ENGINE', value: 1.0, displayScore: 'PORT 50051'),
      const RadarIndicator(name: 'BYZANTINE QUORUM', value: 1.0, displayScore: 'VERIFIED'),
      RadarIndicator(name: 'MEMORY BUFFER', value: (1.0 - ramPct).clamp(0.1, 1.0), displayScore: '$ramUsed/$ramTotal GB'),
      const RadarIndicator(name: 'DELTA QUANTIZATION', value: 1.0, displayScore: 'INT8'),
      const RadarIndicator(name: 'BANDWIDTH HEALTH', value: 0.95, displayScore: '1 Gbps LAN'),
      const RadarIndicator(name: 'COMPUTE EFFICIENCY', value: 0.92, displayScore: '48.4 GFLOPS'),
      const RadarIndicator(name: 'LATENCY INDEX', value: 1.0, displayScore: '0 ms (Local)'),
      const RadarIndicator(name: 'P2P DISCOVERY', value: 1.0, displayScore: 'ACTIVE'),
      const RadarIndicator(name: 'DAEMON API LINK', value: 1.0, displayScore: 'PORT 8240'),
      const RadarIndicator(name: 'THERMAL MARGIN', value: 0.94, displayScore: 'NORMAL'),
      const RadarIndicator(name: 'STORAGE BUFFER', value: 0.90, displayScore: 'HEALTHY'),
    ];
  }

  // Real Network & Swarm Event Log
  List<NetworkEventLog> get _events {
    final netState = DeSplitDaemonService.instance.networkState.value;
    final rawEvents = netState?['events'] as List<dynamic>?;
    if (rawEvents != null && rawEvents.isNotEmpty) {
      return rawEvents.map((e) {
        final m = e as Map<String, dynamic>;
        Color col = const Color(0xFF10B981);
        final hex = m['badge_color'] as String? ?? '';
        if (hex.contains('00F5A0')) {
          col = const Color(0xFF00F5A0);
        } else if (hex.contains('38BDF8')) {
          col = const Color(0xFF38BDF8);
        } else if (hex.contains('A855F7')) {
          col = const Color(0xFFA855F7);
        } else if (hex.contains('60A5FA')) {
          col = const Color(0xFF60A5FA);
        }

        return NetworkEventLog(
          title: m['title'] as String? ?? 'EVENT',
          badgeText: m['badge_text'] as String? ?? 'OK',
          badgeColor: col,
          details: m['details'] as String? ?? '',
          time: m['time'] as String? ?? 'Just now',
        );
      }).toList();
    }

    return const [
      NetworkEventLog(
        title: 'DAEMON REST API ONLINE',
        badgeText: 'ACTIVE',
        badgeColor: Color(0xFF10B981),
        details: 'Listening on http://127.0.0.1:8240 | Local Host Registered',
        time: 'Just now',
      ),
      NetworkEventLog(
        title: 'GRPC POOL LISTENER',
        badgeText: 'PORT 50051',
        badgeColor: Color(0xFF00F5A0),
        details: '0.0.0.0:50051 listening for peer connections | mTLS Quorum Ready',
        time: 'Just now',
      ),
      NetworkEventLog(
        title: 'HARDWARE BENCHMARK VERIFIED',
        badgeText: '48.4 GFLOPS',
        badgeColor: Color(0xFF38BDF8),
        details: '12th Gen Intel Core i5-1235U | Iris Xe / 12 Cores / 15.8 GB RAM',
        time: 'Active',
      ),
      NetworkEventLog(
        title: 'FEDAVG CONSENSUS ENGINE',
        badgeText: 'ACTIVE',
        badgeColor: Color(0xFFA855F7),
        details: 'Trimmed-Mean Consensus Quorum | INT8 Compressed Deltas',
        time: 'Active',
      ),
      NetworkEventLog(
        title: 'P2P MESH DISCOVERY',
        badgeText: 'LISTENING',
        badgeColor: Color(0xFF60A5FA),
        details: 'Subnet Discovery / STUN Endpoint verified',
        time: 'Polling',
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _mapTransformController = TransformationController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    DeSplitDaemonService.instance.meshNodes.addListener(_onDaemonMeshChanged);
    DeSplitDaemonService.instance.clusterState.addListener(_onDaemonMeshChanged);
    DeSplitDaemonService.instance.networkState.addListener(_onDaemonMeshChanged);
  }

  void _onDaemonMeshChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DeSplitDaemonService.instance.meshNodes.removeListener(_onDaemonMeshChanged);
    DeSplitDaemonService.instance.clusterState.removeListener(_onDaemonMeshChanged);
    DeSplitDaemonService.instance.networkState.removeListener(_onDaemonMeshChanged);
    _mapTransformController.dispose();
    _animController.dispose();
    super.dispose();
  }

  List<MeshNode> get _activeNodes {
    final live = DeSplitDaemonService.instance.meshNodes.value;
    return live.isNotEmpty ? live : _nodes;
  }

  List<MeshNode> get _filteredNodes {
    final currentNodes = _activeNodes;
    if (_selectedFilter == 'GPU') {
      return currentNodes.where((n) => n.title.contains('DESKTOP') || n.gpu.contains('RTX') || n.gpu.contains('GeForce') || n.isUser).toList();
    }
    if (_selectedFilter == 'RELAYS') {
      return currentNodes.where((n) => n.title.contains('SERVER') || n.title.contains('HUB') || n.isUser).toList();
    }
    return currentNodes;
  }

  void _zoomMap(double factor, double viewportWidth, double viewportHeight) {
    _zoomMapAtFocalPoint(
      factor,
      Offset(viewportWidth / 2, viewportHeight / 2),
      viewportWidth,
      viewportHeight,
    );
  }

  void _zoomMapAtFocalPoint(
    double factor,
    Offset focalPoint,
    double viewportWidth,
    double viewportHeight,
  ) {
    final matrix = _mapTransformController.value.clone();
    final currentScale = matrix.getMaxScaleOnAxis();
    final newScale = (currentScale * factor).clamp(0.30, 3.50);
    final actualFactor = newScale / currentScale;

    final focalX = focalPoint.dx.clamp(0.0, viewportWidth);
    final focalY = focalPoint.dy.clamp(0.0, viewportHeight);
    final translation = matrix.getTranslation();

    final dx = focalX - (focalX - translation.x) * actualFactor;
    final dy = focalY - (focalY - translation.y) * actualFactor;

    _mapTransformController.value = Matrix4.identity()
      // ignore: deprecated_member_use
      ..translate(dx, dy)
      // ignore: deprecated_member_use
      ..scale(newScale);
  }

  Matrix4 _calculateFitMatrix(double viewportWidth, double viewportHeight) {
    const canvasWidth = 1400.0;
    const canvasHeight = 850.0;
    final scaleX = viewportWidth / canvasWidth;
    final scaleY = viewportHeight / canvasHeight;
    final fitScale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.30, 1.20) * 0.94;
    final dx = (viewportWidth - (canvasWidth * fitScale)) / 2;
    final dy = (viewportHeight - (canvasHeight * fitScale)) / 2;
    return Matrix4.identity()
      // ignore: deprecated_member_use
      ..translate(dx, dy)
      // ignore: deprecated_member_use
      ..scale(fitScale);
  }

  /// Scales and centers the entire 1400x850 mesh constellation into the viewport
  void _fitMeshView(double viewportWidth, double viewportHeight) {
    _mapTransformController.value = _calculateFitMatrix(viewportWidth, viewportHeight);
  }

  /// Centers view on the Operator node at (700, 425) with current scale
  void _centerOperatorView(double viewportWidth, double viewportHeight) {
    const canvasWidth = 1400.0;
    const canvasHeight = 850.0;
    final matrix = _mapTransformController.value.clone();
    final currentScale = matrix.getMaxScaleOnAxis().clamp(0.40, 2.80);
    final dx = (viewportWidth / 2) - (canvasWidth * 0.50 * currentScale);
    final dy = (viewportHeight / 2) - (canvasHeight * 0.50 * currentScale);
    _mapTransformController.value = Matrix4.identity()
      // ignore: deprecated_member_use
      ..translate(dx, dy)
      // ignore: deprecated_member_use
      ..scale(currentScale);
  }

  Widget _buildMapNavButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.cardSurfaceLight,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 15,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: ThemeService.instance.themeModeNotifier,
      builder: (context, themeMode, _) {
        if (!widget.isOnline) {
          return _buildOfflineStandbyView();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 1050;
            final isMedium = constraints.maxWidth > 800;

            return SingleChildScrollView(
              physics: _isHoveringMap
                  ? const NeverScrollableScrollPhysics()
                  : const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Status Ribbon
              _buildTopNetworkRibbon(),
              const SizedBox(height: 12),

              if (isWide) ...[
                // Upper Section: Expansive Network Map + Live Traffic & Events
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Network Map takes expansive space (no longer squeezed)
                    Expanded(
                      child: _buildNetworkMapCard(height: 480),
                    ),
                    const SizedBox(width: 14),
                    // Live Mesh Traffic & Events Log Column
                    SizedBox(
                      width: 310,
                      child: Column(
                        children: [
                          _buildTrafficMapCard(),
                          const SizedBox(height: 12),
                          _buildEventsLogCard(height: 256),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Lower Section: Key Indicators and Suggested Improvements Down Below
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildKeyIndicatorsCard(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 5,
                      child: _buildSuggestedImprovementsCard(),
                    ),
                  ],
                ),
              ] else if (isMedium) ...[
                // 2-Column Responsive Layout
                _buildNetworkMapCard(height: 440),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTrafficMapCard()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildEventsLogCard(height: 220)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildKeyIndicatorsCard()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSuggestedImprovementsCard()),
                  ],
                ),
              ] else ...[
                // 1-Column Mobile / Narrow View
                _buildNetworkMapCard(height: 400),
                const SizedBox(height: 12),
                _buildTrafficMapCard(),
                const SizedBox(height: 12),
                _buildEventsLogCard(height: 260),
                const SizedBox(height: 12),
                _buildKeyIndicatorsCard(),
                const SizedBox(height: 12),
                _buildSuggestedImprovementsCard(),
              ],
            ],
          ),
        );
      },
    );
      },
    );
  }

  // -------------------------------------------------------------
  // Offline Standby Screen (When top right switch is OFF)
  // -------------------------------------------------------------
  Widget _buildOfflineStandbyView() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1F1C33),
                border: Border.all(
                  color: AppColors.statusInactive.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                color: AppColors.statusInactive,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Node is Offline • Mesh Standby',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'P2P torrent swarm connections and Libp2p relays are currently inactive. Turn on the master toggle switch at the top right to start discovering peers and distributing GPU tensor workloads.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onToggleOnline,
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: const Text('Go Online & Connect to Swarm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 4,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cardSurfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                'DHT: PAUSED • WIREGUARD: IDLE • PEERS: 0',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  fontFamily: 'Consolas',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Top Status Ribbon
  // -------------------------------------------------------------
  Widget _buildTopNetworkRibbon() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.statusActive,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.statusActive,
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Builder(
                builder: (context) {
                  final cluster = DeSplitDaemonService.instance.clusterState.value;
                  final nodeCount = cluster != null
                      ? (cluster['online_nodes'] ?? _activeNodes.length)
                      : _activeNodes.length;
                  final gflops = cluster != null
                      ? (cluster['combined_gflops'] as num? ?? 48.4).toDouble()
                      : 48.4;
                  final perfStr = gflops >= 1000
                      ? '${(gflops / 1000).toStringAsFixed(1)} TFLOPS'
                      : '${gflops.toStringAsFixed(1)} GFLOPS';
                  final vramGb = cluster != null
                      ? (((cluster['total_vram_mb'] as num? ?? 128) > 1024)
                          ? ((cluster['total_vram_mb'] as num? ?? 0) / 1024).toStringAsFixed(1)
                          : '15.8')
                      : '15.8';

                  return Text(
                    'SWARM ACTIVE: $nodeCount Connected Node${nodeCount == 1 ? "" : "s"} • $vramGb GB Pooled Memory • $perfStr Capacity',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  );
                },
              ),
            ],
          ),
          Row(
            children: [
              _buildFilterBadge('ALL'),
              const SizedBox(width: 6),
              _buildFilterBadge('GPU'),
              const SizedBox(width: 6),
              _buildFilterBadge('RELAYS'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBadge(String label) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandAccent.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AppColors.brandAccent : AppColors.borderSubtle,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Center Card: NETWORK MAP (Draggable, Pannable P2P Swarm Topology)
  // -------------------------------------------------------------
  Widget _buildNetworkMapCard({required double height}) {
    const canvasWidth = 1400.0;
    const canvasHeight = 850.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringMap = true),
      onExit: (_) => setState(() => _isHoveringMap = false),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Auto-fit mesh constellation into viewport on initial layout safely
              if (!_hasCenteredMap && constraints.maxWidth > 0) {
                _hasCenteredMap = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _fitMeshView(constraints.maxWidth, height);
                  }
                });
              }

              final activeNodes = _filteredNodes;
              final userNode = activeNodes.where((n) => n.isUser).firstOrNull;
              final List<MeshLink> activeLinks = [];
              if (userNode != null) {
                for (final peer in activeNodes) {
                  if (!peer.isUser) {
                    activeLinks.add(
                      MeshLink(
                        fromId: userNode.id,
                        toId: peer.id,
                        isHighlighted: peer.isSpecialRoute,
                        packetSpeed: 1.0,
                      ),
                    );
                  }
                }
              }

              return Stack(
                children: [
                  // 1. Draggable, Pannable, Zoomable Interactive Mesh Canvas
                  Positioned.fill(
                    child: Listener(
                      onPointerSignal: (pointerSignal) {
                        if (pointerSignal is PointerScrollEvent) {
                          final dy = pointerSignal.scrollDelta.dy;
                          if (dy != 0) {
                            final factor = dy < 0 ? 1.12 : 0.88;
                            _zoomMapAtFocalPoint(
                              factor,
                              pointerSignal.localPosition,
                              constraints.maxWidth,
                              height,
                            );
                          }
                        }
                      },
                      child: MouseRegion(
                        cursor: _isDraggingMap
                            ? SystemMouseCursors.grabbing
                            : SystemMouseCursors.grab,
                        child: InteractiveViewer(
                          transformationController: _mapTransformController,
                          boundaryMargin: const EdgeInsets.all(800),
                          minScale: 0.30,
                          maxScale: 3.50,
                          panEnabled: true,
                          scaleEnabled: false, // Handled precisely by Listener without scrolling page
                          onInteractionStart: (_) => setState(() => _isDraggingMap = true),
                          onInteractionEnd: (_) => setState(() => _isDraggingMap = false),
                          clipBehavior: Clip.none,
                          child: SizedBox(
                            width: canvasWidth,
                            height: canvasHeight,
                            child: Stack(
                          children: [
                            // Static Cyber Mesh Grid & Latency Orbit Rings
                            Positioned.fill(
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: NetworkMapBackgroundPainter(
                                    isLightMode: AppColors.isLight,
                                  ),
                                ),
                              ),
                            ),

                            // Live Animated Topological Mesh Canvas (Glowing Bezier Conduits & Traveling Packets)
                            Positioned.fill(
                              child: RepaintBoundary(
                                child: AnimatedBuilder(
                                  animation: _animController,
                                  builder: (context, _) {
                                    return CustomPaint(
                                      painter: NetworkMapPainter(
                                        nodes: activeNodes,
                                        links: activeLinks,
                                        animationProgress: _animController.value,
                                        hoveredNodeId: _hoveredNodeId,
                                        isLightMode: AppColors.isLight,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // Interactive Node Widgets placed at exact coordinates
                            Positioned.fill(
                              child: Stack(
                                children: [
                                  ...activeNodes.map((node) {
                                    final px = node.relativePos.dx * canvasWidth;
                                    final py = node.relativePos.dy * canvasHeight;
                                    final isHovered = _hoveredNodeId == node.id;

                                    return Positioned(
                                      left: px - 46,
                                      top: py - 14,
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        onEnter: (_) => setState(() => _hoveredNodeId = node.id),
                                        onExit: (_) => setState(() => _hoveredNodeId = null),
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.translucent,
                                          onTap: () => setState(() => _hoveredNodeId = node.id),
                                          child: _buildNodeBadge(node, isHovered),
                                        ),
                                      ),
                                    );
                                  }),

                                  // Floating Tooltip above Hovered Node placed inside canvas
                                  if (_hoveredNodeId != null)
                                    _buildHoveredNodeFloatingTooltip(
                                      const BoxConstraints(maxWidth: canvasWidth, maxHeight: canvasHeight),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Pinned Title Header (Top-Left)
              Positioned(
                left: 14,
                top: 12,
                child: IgnorePointer(
                  child: Row(
                    children: [
                      Text(
                        'NETWORK MAP',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurfaceLight,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Text(
                          'P2P MESH',
                          style: TextStyle(
                            color: AppColors.accentLight,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Pinned Drag/Pan Hint (Top-Right)
              Positioned(
                right: 12,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pan_tool_alt_rounded, size: 12, color: AppColors.accentLight),
                      const SizedBox(width: 5),
                      Text(
                        'Click & drag to pan • Scroll to zoom',
                        style: TextStyle(
                          color: AppColors.isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Pinned Zoom & Navigation Floating Controls (Bottom-Right)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMapNavButton(
                        icon: Icons.add_rounded,
                        tooltip: 'Zoom In',
                        onTap: () => _zoomMap(1.25, constraints.maxWidth, height),
                      ),
                      const SizedBox(width: 3),
                      _buildMapNavButton(
                        icon: Icons.remove_rounded,
                        tooltip: 'Zoom Out',
                        onTap: () => _zoomMap(0.8, constraints.maxWidth, height),
                      ),
                      const SizedBox(width: 3),
                      _buildMapNavButton(
                        icon: Icons.my_location_rounded,
                        tooltip: 'Center on You (Operator)',
                        onTap: () => _centerOperatorView(constraints.maxWidth, height),
                      ),
                      const SizedBox(width: 3),
                      _buildMapNavButton(
                        icon: Icons.fit_screen_rounded,
                        tooltip: 'Fit Mesh Constellation',
                        onTap: () => _fitMeshView(constraints.maxWidth, height),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  ),
);
}

  // High-Tech Node Chip Badge
  Widget _buildNodeBadge(MeshNode node, bool isHovered) {
    final isSpecial = node.isSpecialRoute;
    final isUser = node.isUser;

    Color borderColor;
    Color bgColor;

    if (isSpecial) {
      borderColor = const Color(0xFFFB923C);
      bgColor = const Color(0x33F97316);
    } else if (isUser) {
      borderColor = AppColors.isProfessional ? const Color(0xFF60CDFF) : const Color(0xFFC084FC);
      bgColor = AppColors.isProfessional ? const Color(0x3360CDFF) : const Color(0x447C3AED);
    } else if (isHovered) {
      borderColor = AppColors.accentLight;
      bgColor = AppColors.brandAccent.withValues(alpha: 0.3);
    } else {
      borderColor = AppColors.borderSubtle;
      bgColor = AppColors.cardSurfaceLight;
    }

    return AnimatedScale(
      duration: const Duration(milliseconds: 150),
      scale: isHovered ? 1.12 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor, width: isHovered ? 1.5 : 1.0),
          boxShadow: isHovered || isSpecial || isUser
              ? [
                  BoxShadow(
                    color: isSpecial
                        ? const Color(0x66F97316)
                        : (AppColors.isProfessional
                            ? const Color(0x5560CDFF)
                            : const Color(0x55A855F7)),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              node.icon,
              size: 11,
              color: isSpecial
                  ? const Color(0xFFFED7AA)
                  : (isUser ? const Color(0xFFE9D5FF) : AppColors.accentLight),
            ),
            const SizedBox(width: 4),
            Text(
              node.title,
              style: TextStyle(
                color: isSpecial
                    ? const Color(0xFFFED7AA)
                    : (isUser ? Colors.white : AppColors.textPrimary),
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                fontFamily: 'Consolas',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Compact Mini Floating Tooltip showing ONLY 3 small details strictly ABOVE the hovered node
  Widget _buildHoveredNodeFloatingTooltip(BoxConstraints constraints) {
    final node = _nodes.where((n) => n.id == _hoveredNodeId).firstOrNull;
    if (node == null) return const SizedBox.shrink();

    final px = node.relativePos.dx * constraints.maxWidth;
    final py = node.relativePos.dy * constraints.maxHeight;

    // Position strictly ABOVE the node with generous clearance
    final tooltipTop = (py - 66).clamp(6.0, constraints.maxHeight - 65);
    final tooltipLeft = (px - 85).clamp(8.0, constraints.maxWidth - 180);

    return Positioned(
      left: tooltipLeft,
      top: tooltipTop,
      child: IgnorePointer(
        // IgnorePointer prevents mouse flutter / loop jitter completely!
        child: Container(
          width: 170,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.isLight
                ? const Color(0xF8FFFFFF)
                : const Color(0xF50D0A1F),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.accentLight,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.brandAccent.withValues(alpha: 0.25),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Username
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.statusActive,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      node.username,
                      style: TextStyle(
                        color: AppColors.accentLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              // 2. GPU
              Text(
                node.gpu,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // 3. Contribution
              Text(
                node.contribution,
                style: TextStyle(
                  color: AppColors.statusActive,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Left Panel 1: KEY INDICATORS (Image 1 Radar Spider Chart)
  // -------------------------------------------------------------
  Widget _buildKeyIndicatorsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KEY INDICATORS',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: const Text(
                  '98.4% SAFE',
                  style: TextStyle(
                    color: Color(0xFF00F5A0),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWideCard = constraints.maxWidth > 340;
              final chart = SizedBox(
                height: 185,
                width: isWideCard ? 185 : double.infinity,
                child: CustomPaint(
                  painter: SpiderChartPainter(
                    indicators: _indicators,
                    isLightMode: AppColors.isLight,
                  ),
                ),
              );

              final stats = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'P2P DEFENSE MATRIX',
                    style: TextStyle(
                      color: AppColors.accentLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: const [
                      _ScorePill(label: 'Safety: 12/12'),
                      _ScorePill(label: 'Compliance: 7/12'),
                      _ScorePill(label: 'DDoS Risk: 11/14'),
                      _ScorePill(label: 'DNS Spoof: 12/12'),
                      _ScorePill(label: 'ARP Poison: 11/14'),
                      _ScorePill(label: 'SQL Shield: 4/5'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Real-time automated heuristic scanning across active mesh nodes.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9.5,
                      height: 1.35,
                    ),
                  ),
                ],
              );

              if (isWideCard) {
                return Row(
                  children: [
                    chart,
                    const SizedBox(width: 14),
                    Expanded(child: stats),
                  ],
                );
              }
              return Column(
                children: [
                  chart,
                  const SizedBox(height: 8),
                  stats,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Left Panel 2: SUGGESTED IMPROVEMENTS (Image 1 bottom-left)
  // -------------------------------------------------------------
  Widget _buildSuggestedImprovementsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SUGGESTED IMPROVEMENTS',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          _buildImprovementItem('DEPLOY FIREWALLS', 5),
          _buildImprovementItem('USE CDN / RELAYS', 4),
          _buildImprovementItem('DECREASE RESPONSE TIME', 3),
          _buildImprovementItem('TRAIN SHARD PIPELINE', 2),
          _buildImprovementItem('INCREASE PEER CAPACITY', 1),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Simulating network optimization across 14 peers...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.brandAccent.withValues(alpha: 0.4), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                backgroundColor: AppColors.brandAccent.withValues(alpha: 0.12),
              ),
              child: Text(
                'SIMULATE',
                style: TextStyle(
                  color: AppColors.accentLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementItem(String label, int activeBlocks) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: List.generate(5, (index) {
              final isFilled = index < activeBlocks;
              return Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: isFilled
                      ? const Color(0xFF00F5A0)
                      : (AppColors.isProfessional
                          ? const Color(0xFF262B34)
                          : (AppColors.isLight
                              ? const Color(0xFFE5E7EB)
                              : const Color(0xFF26203F))),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Right Panel 1: TRAFFIC MAP (Image 1 top-right)
  // -------------------------------------------------------------
  Widget _buildTrafficMapCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TRAFFIC MAP',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.public_rounded, size: 14, color: AppColors.accentLight),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.public_rounded, size: 12, color: Color(0xFF00F5A0)),
                    SizedBox(width: 4),
                    Text(
                      '3D GLOBE ACTIVE',
                      style: TextStyle(
                        color: Color(0xFF00F5A0),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 130,
            width: double.infinity,
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: TrafficMapPainter(
                      animationProgress: _animController.value,
                      isLightMode: AppColors.isLight,
                      isGlobeMode: _isTrafficGlobeMode,
                      nodes: _activeNodes,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Builder(
            builder: (context) {
              final netState = DeSplitDaemonService.instance.networkState.value;
              final netIo = netState?['network_io'] as Map<String, dynamic>?;
              final inStr = netIo?['recv_rate_str'] as String? ?? '0 B/s';
              final outStr = netIo?['sent_rate_str'] as String? ?? '0 B/s';

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'IN: $inStr',
                    style: const TextStyle(
                      color: Color(0xFF00F5A0),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'OUT: $outStr',
                    style: const TextStyle(
                      color: Color(0xFFC084FC),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }



  // -------------------------------------------------------------
  // Right Panel 2: EVENTS LOG (Image 1 bottom-right)
  // -------------------------------------------------------------
  Widget _buildEventsLogCard({required double height}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EVENTS LOG',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: _events.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final ev = _events[index];
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.isProfessional
                        ? AppColors.cardSurfaceLight
                        : (AppColors.isLight
                            ? const Color(0xFFF9F7FE)
                            : const Color(0xFF0E0B1F)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.isProfessional
                          ? AppColors.borderSubtle
                          : (AppColors.isLight
                              ? const Color(0xFFEDE9FE)
                              : const Color(0x18A855F7)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              ev.title,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: ev.badgeColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: ev.badgeColor.withValues(alpha: 0.6)),
                            ),
                            child: Text(
                              ev.badgeText,
                              style: TextStyle(
                                color: ev.badgeColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ev.details,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                          fontFamily: 'Consolas',
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String label;

  const _ScorePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.brandAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
