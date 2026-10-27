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
    // Tier 1 Cluster: Frankfurt (Highlighted Active Route)
    MeshNode(
      id: 'node_web_1',
      title: 'WEB SERVER',
      username: '@solaris_core',
      gpu: 'NVIDIA RTX 4090 24GB',
      contribution: '142.5 TFLOPS • 18.2 GB VRAM',
      latency: '14 ms',
      region: 'Frankfurt (EU-West)',
      relativePos: Offset(0.39, 0.35),
      icon: Icons.dns_rounded,
      isSpecialRoute: true,
    ),
    // Tier 1 Cluster: London
    MeshNode(
      id: 'node_desk_1',
      title: 'CO DESKTOP',
      username: '@tensor_blade',
      gpu: 'NVIDIA RTX 3080 Ti 12GB',
      contribution: '78.2 TFLOPS • 9.8 GB VRAM',
      latency: '24 ms',
      region: 'London (EU-North)',
      relativePos: Offset(0.61, 0.35),
      icon: Icons.computer_rounded,
    ),
    // Tier 1 Cluster: Paris
    MeshNode(
      id: 'node_cluster_1',
      title: 'CO DESKTOP',
      username: '@quant_shard',
      gpu: 'NVIDIA RTX 3090 24GB',
      contribution: '72.6 TFLOPS • 14.5 GB VRAM',
      latency: '19 ms',
      region: 'Paris (EU-West)',
      relativePos: Offset(0.36, 0.50),
      icon: Icons.computer_rounded,
    ),
    // Tier 1 Cluster: Bengaluru
    MeshNode(
      id: 'node_in_bengaluru',
      title: 'CO DESKTOP',
      username: '@vedic_compute',
      gpu: 'NVIDIA RTX 4060 Ti 16GB',
      contribution: '22.0 TFLOPS • 14.2 GB VRAM',
      latency: '28 ms',
      region: 'Bengaluru (IN-Central)',
      relativePos: Offset(0.64, 0.50),
      icon: Icons.computer_rounded,
    ),
    // Tier 1 Cluster: Zurich
    MeshNode(
      id: 'node_web_3',
      title: 'WEB SERVER',
      username: '@deep_tensor',
      gpu: 'AMD Radeon RX 7900 XTX',
      contribution: '61.4 TFLOPS • 16.0 GB VRAM',
      latency: '22 ms',
      region: 'Zurich (EU-Central)',
      relativePos: Offset(0.40, 0.65),
      icon: Icons.dns_rounded,
    ),
    // Tier 1 Cluster: Amsterdam
    MeshNode(
      id: 'node_web_2',
      title: 'WEB SERVER',
      username: '@hyper_thread',
      gpu: '2x NVIDIA RTX 4090 48GB',
      contribution: '270.0 TFLOPS • 36.4 GB VRAM',
      latency: '26 ms',
      region: 'Amsterdam (EU-Central)',
      relativePos: Offset(0.60, 0.65),
      icon: Icons.dns_rounded,
    ),

    // Tier 2 Swarm: Oregon (US-West)
    MeshNode(
      id: 'node_us_west',
      title: 'WEB SERVER',
      username: '@silicon_matrix',
      gpu: '4x NVIDIA RTX 4090 96GB',
      contribution: '540.0 TFLOPS • 96.0 GB VRAM',
      latency: '68 ms',
      region: 'Oregon (US-West)',
      relativePos: Offset(0.50, 0.17),
      icon: Icons.dns_rounded,
    ),
    // Tier 2 Swarm: Dublin
    MeshNode(
      id: 'node_desk_2',
      title: 'CO DESKTOP',
      username: '@cyber_falcon',
      gpu: 'Apple M2 Ultra 192GB',
      contribution: '92.4 TFLOPS • 64.0 GB VRAM',
      latency: '32 ms',
      region: 'Dublin (EU-West)',
      relativePos: Offset(0.27, 0.26),
      icon: Icons.computer_rounded,
    ),
    // Tier 2 Swarm: Stockholm
    MeshNode(
      id: 'node_cluster_2',
      title: 'WEB SERVER',
      username: '@crypto_pilot',
      gpu: 'NVIDIA RTX 4080 Super',
      contribution: '84.6 TFLOPS • 11.2 GB VRAM',
      latency: '36 ms',
      region: 'Stockholm (EU-North)',
      relativePos: Offset(0.73, 0.26),
      icon: Icons.dns_rounded,
    ),
    // Tier 2 Swarm: Virginia
    MeshNode(
      id: 'node_desk_3',
      title: 'CO DESKTOP',
      username: '@valkyrie_ai',
      gpu: 'NVIDIA RTX 4080 16GB',
      contribution: '88.0 TFLOPS • 12.0 GB VRAM',
      latency: '45 ms',
      region: 'Virginia (US-East)',
      relativePos: Offset(0.20, 0.44),
      icon: Icons.computer_rounded,
    ),
    // Tier 2 Swarm: Tokyo
    MeshNode(
      id: 'node_desk_4',
      title: 'CO DESKTOP',
      username: '@aurora_node',
      gpu: 'NVIDIA A100 80GB SXM',
      contribution: '312.0 TFLOPS • 72.0 GB VRAM',
      latency: '58 ms',
      region: 'Tokyo (AP-East)',
      relativePos: Offset(0.80, 0.44),
      icon: Icons.computer_rounded,
    ),
    // Tier 2 Swarm: Montreal
    MeshNode(
      id: 'node_na_montreal',
      title: 'CO DESKTOP',
      username: '@apex_tensor',
      gpu: 'Tesla V100 32GB',
      contribution: '125.0 TFLOPS • 29.4 GB VRAM',
      latency: '52 ms',
      region: 'Montreal (NA-East)',
      relativePos: Offset(0.24, 0.63),
      icon: Icons.computer_rounded,
    ),
    // Tier 2 Swarm: Singapore
    MeshNode(
      id: 'node_ap_singapore',
      title: 'WEB SERVER',
      username: '@merlion_ai',
      gpu: 'NVIDIA H100 80GB',
      contribution: '312.0 TFLOPS • 72.4 GB VRAM',
      latency: '62 ms',
      region: 'Singapore (AP-Southeast)',
      relativePos: Offset(0.76, 0.63),
      icon: Icons.dns_rounded,
    ),
    // Tier 2 Swarm: Frankfurt #2
    MeshNode(
      id: 'node_cluster_3',
      title: 'CO DESKTOP',
      username: '@vortex_compute',
      gpu: 'NVIDIA RTX 4090 24GB',
      contribution: '138.0 TFLOPS • 21.0 GB VRAM',
      latency: '34 ms',
      region: 'Frankfurt #2',
      relativePos: Offset(0.35, 0.81),
      icon: Icons.computer_rounded,
    ),
    // Tier 2 Swarm: Milan
    MeshNode(
      id: 'node_web_4',
      title: 'WEB SERVER',
      username: '@neuron_flux',
      gpu: 'NVIDIA RTX 4070 Ti 12GB',
      contribution: '48.2 TFLOPS • 8.1 GB VRAM',
      latency: '38 ms',
      region: 'Milan (EU-South)',
      relativePos: Offset(0.65, 0.81),
      icon: Icons.dns_rounded,
    ),

    // Tier 3 Edge Constellation: São Paulo
    MeshNode(
      id: 'node_sa_brazil',
      title: 'CO DESKTOP',
      username: '@samba_cluster',
      gpu: 'NVIDIA RTX 4080 16GB',
      contribution: '88.0 TFLOPS • 14.2 GB VRAM',
      latency: '112 ms',
      region: 'São Paulo (SA-East)',
      relativePos: Offset(0.10, 0.52),
      icon: Icons.computer_rounded,
    ),
    // Tier 3 Edge Constellation: Sydney
    MeshNode(
      id: 'node_ap_sydney',
      title: 'CO DESKTOP',
      username: '@southern_cross',
      gpu: 'Apple M3 Max 128GB',
      contribution: '76.0 TFLOPS • 48.0 GB VRAM',
      latency: '135 ms',
      region: 'Sydney (AP-South)',
      relativePos: Offset(0.90, 0.52),
      icon: Icons.computer_rounded,
    ),
  ];

  // Interconnected Decentralized Mesh Links
  static const List<MeshLink> _links = [
    // 1. Primary Backbone Links (Operator Core to Tier-1 Cluster)
    MeshLink(fromId: 'node_user', toId: 'node_web_1', isHighlighted: true, packetSpeed: 1.3),
    MeshLink(fromId: 'node_user', toId: 'node_desk_1', packetSpeed: 0.95),
    MeshLink(fromId: 'node_user', toId: 'node_cluster_1', packetSpeed: 1.1),
    MeshLink(fromId: 'node_user', toId: 'node_in_bengaluru', packetSpeed: 1.05),
    MeshLink(fromId: 'node_user', toId: 'node_web_3', packetSpeed: 0.9),
    MeshLink(fromId: 'node_user', toId: 'node_web_2', packetSpeed: 1.0),

    // 2. Tier 1 Hexagonal Mesh Ring
    MeshLink(fromId: 'node_web_1', toId: 'node_desk_1', packetSpeed: 0.85),
    MeshLink(fromId: 'node_desk_1', toId: 'node_in_bengaluru', packetSpeed: 0.9),
    MeshLink(fromId: 'node_in_bengaluru', toId: 'node_web_2', packetSpeed: 1.1),
    MeshLink(fromId: 'node_web_2', toId: 'node_web_3', packetSpeed: 0.8),
    MeshLink(fromId: 'node_web_3', toId: 'node_cluster_1', packetSpeed: 0.95),
    MeshLink(fromId: 'node_cluster_1', toId: 'node_web_1', packetSpeed: 1.15),

    // 3. Radial Interconnects (Tier 1 <-> Tier 2 Bridges)
    MeshLink(fromId: 'node_web_1', toId: 'node_desk_2', isHighlighted: true, packetSpeed: 1.25),
    MeshLink(fromId: 'node_web_1', toId: 'node_us_west', packetSpeed: 0.9),
    MeshLink(fromId: 'node_desk_1', toId: 'node_us_west', packetSpeed: 0.8),
    MeshLink(fromId: 'node_desk_1', toId: 'node_cluster_2', packetSpeed: 1.0),
    MeshLink(fromId: 'node_in_bengaluru', toId: 'node_desk_4', packetSpeed: 0.95),
    MeshLink(fromId: 'node_in_bengaluru', toId: 'node_ap_singapore', packetSpeed: 1.1),
    MeshLink(fromId: 'node_web_2', toId: 'node_ap_singapore', packetSpeed: 1.0),
    MeshLink(fromId: 'node_web_2', toId: 'node_web_4', packetSpeed: 0.85),
    MeshLink(fromId: 'node_web_3', toId: 'node_cluster_3', packetSpeed: 1.05),
    MeshLink(fromId: 'node_cluster_1', toId: 'node_desk_3', packetSpeed: 0.9),
    MeshLink(fromId: 'node_cluster_1', toId: 'node_na_montreal', packetSpeed: 1.0),

    // 4. Tier 2 Outer Mesh Ring
    MeshLink(fromId: 'node_desk_2', toId: 'node_us_west', packetSpeed: 0.85),
    MeshLink(fromId: 'node_us_west', toId: 'node_cluster_2', packetSpeed: 0.95),
    MeshLink(fromId: 'node_cluster_2', toId: 'node_desk_4', packetSpeed: 0.8),
    MeshLink(fromId: 'node_desk_4', toId: 'node_ap_singapore', packetSpeed: 1.05),
    MeshLink(fromId: 'node_ap_singapore', toId: 'node_web_4', packetSpeed: 0.9),
    MeshLink(fromId: 'node_web_4', toId: 'node_cluster_3', packetSpeed: 1.1),
    MeshLink(fromId: 'node_cluster_3', toId: 'node_na_montreal', packetSpeed: 0.85),
    MeshLink(fromId: 'node_na_montreal', toId: 'node_desk_3', packetSpeed: 0.9),
    MeshLink(fromId: 'node_desk_3', toId: 'node_desk_2', packetSpeed: 1.0),

    // 5. Tier 3 Global Edge Mesh Conduits
    MeshLink(fromId: 'node_desk_3', toId: 'node_sa_brazil', packetSpeed: 0.8),
    MeshLink(fromId: 'node_na_montreal', toId: 'node_sa_brazil', packetSpeed: 0.9),
    MeshLink(fromId: 'node_cluster_3', toId: 'node_sa_brazil', packetSpeed: 0.75),
    MeshLink(fromId: 'node_desk_4', toId: 'node_ap_sydney', packetSpeed: 0.9),
    MeshLink(fromId: 'node_ap_singapore', toId: 'node_ap_sydney', packetSpeed: 1.0),
    MeshLink(fromId: 'node_cluster_2', toId: 'node_ap_sydney', packetSpeed: 0.85),
  ];

  // Key Indicators (Image 1 Radar Chart)
  static const List<RadarIndicator> _indicators = [
    RadarIndicator(name: 'SAFETY SCORE', value: 1.0, displayScore: '12/12'),
    RadarIndicator(name: 'COMPLIANCE SCORE', value: 0.58, displayScore: '7/12'),
    RadarIndicator(name: 'PORT SCANNING', value: 0.88, displayScore: '8/12'),
    RadarIndicator(name: 'DDOS RISK', value: 0.78, displayScore: '11/14'),
    RadarIndicator(name: 'DNS SPOOFING', value: 1.0, displayScore: '12/12'),
    RadarIndicator(name: 'MAN IN THE MIDDLE', value: 0.44, displayScore: '4/9'),
    RadarIndicator(name: 'PORT SCANNING', value: 0.87, displayScore: '7/8'),
    RadarIndicator(name: 'ARP POISONING', value: 0.78, displayScore: '11/14'),
    RadarIndicator(name: 'VLAN HOPPING', value: 1.0, displayScore: '12/12'),
    RadarIndicator(name: 'PHISHING', value: 0.87, displayScore: '7/8'),
    RadarIndicator(name: 'SQL INJECTION', value: 0.80, displayScore: '4/5'),
    RadarIndicator(name: 'CYBER-ATTACK', value: 0.78, displayScore: '11/14'),
  ];

  // Events Log directly matching Image 1
  static const List<NetworkEventLog> _events = [
    NetworkEventLog(
      title: 'UNUSUAL TRAFFIC',
      badgeText: '⚠ 3.2',
      badgeColor: Color(0xFFEF4444),
      details: 'IP 235.254.63.4 | PAYLOAD 5112 | TYPE CELL PHONE\n| SUR1 SUR2',
      time: 'Just now',
    ),
    NetworkEventLog(
      title: 'DDOS MITIGATION',
      badgeText: '⚠ 3.2',
      badgeColor: Color(0xFFEF4444),
      details: 'IP 182.112.4.9 | PAYLOAD 8920 | TYPE SYN-FLOOD\n| FILTER ACTIVE',
      time: '1m ago',
    ),
    NetworkEventLog(
      title: 'ROGUE SECURITY SOFTWARE',
      badgeText: '⚠ 3.2',
      badgeColor: Color(0xFFEF4444),
      details: 'IP 235.254.63.4 | PAYLOAD 5112 | TYPE CELL PHONE\n| SUR1 SUR2',
      time: '3m ago',
    ),
    NetworkEventLog(
      title: 'SQL INJECTION ATTACK',
      badgeText: '⚠ 2.8',
      badgeColor: Color(0xFFF59E0B),
      details: 'IP 235.254.63.4 | PAYLOAD 5112 | TYPE CELL PHONE\n| BLOCKED GATEWAY',
      time: '6m ago',
    ),
    NetworkEventLog(
      title: 'TENSOR SHARD COMPLETED',
      badgeText: '✓ 1.0',
      badgeColor: Color(0xFF10B981),
      details: 'NODE @tensor_blade | MODEL llama-3-70b | 8.4 TFLOPS\n| BATCH #4018',
      time: '8m ago',
    ),
    NetworkEventLog(
      title: 'NEW PEER DISCOVERED',
      badgeText: 'ℹ 1.2',
      badgeColor: Color(0xFF60A5FA),
      details: 'IP 194.67.210.12 | RELAY Libp2p/QUIC | EU-NORTH\n| WIRE GUARD READY',
      time: '12m ago',
    ),
    NetworkEventLog(
      title: 'PROOF OF COMPUTE VERIFIED',
      badgeText: '✓ 0.8',
      badgeColor: Color(0xFF10B981),
      details: 'BLOCK #2,891,440 | REWARD +4.8 SPLIT\n| ZERO-KNOWLEDGE PROOF',
      time: '15m ago',
    ),
  ];

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
  }

  void _onDaemonMeshChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DeSplitDaemonService.instance.meshNodes.removeListener(_onDaemonMeshChanged);
    DeSplitDaemonService.instance.clusterState.removeListener(_onDaemonMeshChanged);
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
                  final tflops = cluster != null
                      ? ((cluster['combined_gflops'] as num? ?? 142330.0) / 1000).toStringAsFixed(1)
                      : '142.3';
                  final vramGb = cluster != null
                      ? ((cluster['total_vram_mb'] as num? ?? 45184) / 1024).toStringAsFixed(1)
                      : '44.1';

                  return Text(
                    'SWARM ACTIVE: $nodeCount Connected Nodes • $vramGb GB Pooled VRAM • $tflops TFLOPS Capacity',
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
              final activeNodeIds = activeNodes.map((n) => n.id).toSet();
              final activeLinks = _links
                  .where((l) => activeNodeIds.contains(l.fromId) && activeNodeIds.contains(l.toId))
                  .toList();

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
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'IN: 84.2 MB/s',
                style: const TextStyle(
                  color: Color(0xFF00F5A0),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'OUT: 118.6 MB/s',
                style: const TextStyle(
                  color: Color(0xFFC084FC),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
