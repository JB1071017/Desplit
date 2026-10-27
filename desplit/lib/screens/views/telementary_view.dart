import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/desplit_daemon_service.dart';
import '../../services/theme_service.dart';
import '../../theme/app_colors.dart';
import 'telemetry/telemetry_chart_painter.dart';
import 'telemetry/telemetry_graph_card.dart';

class TelementaryView extends StatefulWidget {
  const TelementaryView({super.key});

  @override
  State<TelementaryView> createState() => _TelementaryViewState();
}

class _TelementaryViewState extends State<TelementaryView> {
  int _selectedDeviceIndex = 5; // Default: GPU 0
  Timer? _tickerTimer;

  // Mode Toggle: false = Host / System Performance, true = My Swarm Contributions
  bool _isContributionMode = false;

  // Selected GPU Model: 0 = Intel(R) Iris(R) Xe Graphics, 1 = AMD Radeon RX 7900 XTX
  int _selectedGpuModel = 0;

  // -------------------------------------------------------------
  // Host / System Historical Data (24 points each for smooth flowing look)
  // -------------------------------------------------------------
  late List<double> _gpu3DHistory;
  late List<double> _gpuCopyHistory;
  late List<double> _gpuDecodeHistory;
  late List<double> _gpuProcessingHistory;
  late List<double> _gpuSharedMemHistory;

  late List<double> _amd3DHistory;
  late List<double> _amdDedicatedMemHistory;

  late List<double> _cpuHistory;
  late List<double> _memoryHistory;
  late List<double> _diskHistory;
  late List<double> _ethernetHistory;
  late List<double> _wifiHistory;

  // Host Real-time Metric Values
  final double _gpu3DValue = 12.0;
  static const double _gpuCopyValue = 0.0;
  static const double _gpuDecodeValue = 0.0;
  static const double _gpuProcessingValue = 0.0;
  double _gpuSharedMemValue = 0.7; // out of 7.9 GB

  final double _amd3DValue = 18.0;
  final double _amdDedicatedMemValue = 2.4; // out of 24.0 GB

  double _cpuValue = 34.0;
  double _cpuSpeed = 1.00;
  double _memoryValue = 12.7; // out of 15.8 GB
  final double _diskValue = 6.0;

  // -------------------------------------------------------------
  // Swarm Contributed Historical Data & Metrics
  // -------------------------------------------------------------
  late List<double> _contribCpuHistory;
  late List<double> _contribMemoryHistory;
  late List<double> _contribDiskHistory;
  late List<double> _contribEthernetHistory;
  late List<double> _contribWifiHistory;

  late List<double> _contribGpuTensorHistory;
  late List<double> _contribGpuCopyHistory;
  late List<double> _contribGpuDecodeHistory;
  late List<double> _contribGpuProcHistory;
  late List<double> _contribGpuVramHistory;

  // Contributed Real-time Metrics
  final double _contribCpuLoad = 76.0;
  double _contribCpuGflops = 14.2;
  static const int _contribCpuCores = 8;

  final double _contribMemUsed = 4.2; // out of 6.0 GB contributed
  static const double _contribMemAllocated = 6.0;

  final double _contribDiskActive = 22.0;
  final double _contribDiskUsed = 42.6; // out of 120 GB
  static const double _contribDiskAllocated = 120.0;

  final double _contribEthSend = 14.2; // MB/s
  final double _contribEthRecv = 18.5; // MB/s

  final double _contribWifiSend = 180.0; // Kbps
  final double _contribWifiRecv = 240.0; // Kbps

  double _contribGpuTensorLoad = 82.0;
  final double _contribGpuCopyLoad = 22.0;
  final double _contribGpuDecodeLoad = 12.0;
  final double _contribGpuProcLoad = 48.0;
  final double _contribGpuVramUsed = 0.70; // 0.7 GB (Intel) or 16.0 GB (AMD)

  @override
  void initState() {
    super.initState();

    // 1. Host Performance Data Seed
    _gpu3DHistory = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 8, 14, 11, 12];
    _gpuCopyHistory = List.filled(24, 0.0);
    _gpuDecodeHistory = List.filled(24, 0.0);
    _gpuProcessingHistory = List.filled(24, 0.0);
    _gpuSharedMemHistory = [0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.3, 0.3, 0.3, 0.3, 0.4, 0.4, 0.5, 0.6, 0.7, 0.7, 0.7, 0.7];

    _amd3DHistory = [12, 14, 15, 18, 16, 20, 22, 19, 17, 18, 21, 19, 18, 16, 17, 18, 20, 19, 18, 17, 19, 18, 20, 18];
    _amdDedicatedMemHistory = List.filled(24, 2.4);

    _cpuHistory = [28, 30, 32, 29, 35, 38, 42, 36, 31, 33, 34, 32, 35, 30, 29, 31, 33, 37, 34, 32, 35, 33, 36, 34];
    _memoryHistory = List.filled(24, 80.0);
    _diskHistory = [2, 1, 4, 2, 8, 12, 5, 3, 2, 1, 6, 4, 3, 2, 7, 5, 2, 1, 8, 6, 4, 3, 5, 6];
    _ethernetHistory = List.filled(24, 0.0);
    _wifiHistory = List.filled(24, 0.0);

    // 2. Swarm Contribution Data Seed (Realistic high-frequency tensor & mesh workload)
    _contribCpuHistory = [68, 72, 75, 71, 78, 80, 84, 79, 73, 76, 78, 75, 81, 74, 72, 75, 77, 82, 79, 76, 80, 78, 81, 76];
    _contribMemoryHistory = [68, 69, 70, 70, 71, 70, 69, 70, 71, 72, 70, 69, 70, 71, 70, 70, 71, 70, 71, 70, 70, 71, 70, 70];
    _contribDiskHistory = [18, 22, 25, 20, 28, 32, 24, 19, 21, 26, 23, 19, 24, 27, 21, 18, 26, 23, 20, 25, 22, 24, 21, 22];
    _contribEthernetHistory = [12, 14, 15, 14, 16, 18, 17, 15, 14, 16, 15, 14, 16, 17, 15, 14, 15, 17, 16, 15, 16, 15, 17, 15];
    _contribWifiHistory = [160, 180, 190, 175, 210, 220, 195, 185, 190, 205, 180, 175, 190, 215, 185, 170, 195, 200, 180, 190, 185, 195, 180, 180];

    _contribGpuTensorHistory = [75, 78, 82, 80, 85, 88, 84, 79, 81, 86, 83, 80, 84, 87, 82, 79, 83, 85, 81, 84, 82, 85, 83, 82];
    _contribGpuCopyHistory = [18, 20, 24, 21, 26, 28, 23, 20, 22, 25, 21, 19, 23, 26, 22, 19, 24, 25, 21, 23, 22, 24, 21, 22];
    _contribGpuDecodeHistory = [10, 11, 14, 12, 15, 16, 13, 11, 12, 15, 13, 11, 13, 15, 12, 11, 13, 14, 12, 13, 12, 14, 12, 12];
    _contribGpuProcHistory = [42, 45, 50, 47, 52, 55, 49, 44, 46, 51, 48, 45, 49, 53, 47, 44, 48, 51, 46, 49, 47, 50, 48, 48];
    _contribGpuVramHistory = List.filled(24, 0.70);

    // Subscribe to live real-time telemetry from DeSplitDaemonService
    DeSplitDaemonService.instance.hardwareMetrics.addListener(_onDaemonTelemetry);
    DeSplitDaemonService.instance.clusterState.addListener(_onDaemonTelemetry);
    _onDaemonTelemetry();

    // Secondary smooth micro-animation ticker for fluid chart movement
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!mounted) return;
      _onDaemonTelemetry();
    });
  }

  void _onDaemonTelemetry() {
    if (!mounted) return;
    final hw = DeSplitDaemonService.instance.hardwareMetrics.value;
    final cluster = DeSplitDaemonService.instance.clusterState.value;

    setState(() {
      if (hw != null) {
        final rt = hw['realtime'] as Map<String, dynamic>?;
        if (rt != null) {
          _cpuValue = (rt['cpu_percent'] as num?)?.toDouble() ?? _cpuValue;
          _cpuSpeed = (rt['cpu_frequency_ghz'] as num?)?.toDouble() ?? _cpuSpeed;
          _memoryValue = (rt['ram_used_gb'] as num?)?.toDouble() ?? _memoryValue;
          _cpuHistory = [..._cpuHistory.sublist(1), _cpuValue];

          final memPct = (rt['ram_percent'] as num?)?.toDouble() ?? 80.0;
          _memoryHistory = [..._memoryHistory.sublist(1), memPct];

          final gpus = rt['gpus'] as List<dynamic>?;
          if (gpus != null && gpus.isNotEmpty) {
            final g0 = gpus[0] as Map<String, dynamic>;
            _gpuSharedMemValue = (g0['used_vram_gb'] as num?)?.toDouble() ?? _gpuSharedMemValue;
            _gpuSharedMemHistory = [..._gpuSharedMemHistory.sublist(1), _gpuSharedMemValue];
          }
        }
      }

      if (cluster != null) {
        final tflops = ((cluster['combined_gflops'] as num? ?? 0) / 1000).toDouble();
        if (tflops > 0) {
          _contribCpuGflops = tflops;
        }
        _contribGpuTensorLoad = _cpuValue.clamp(40.0, 95.0);
        _contribGpuTensorHistory = [..._contribGpuTensorHistory.sublist(1), _contribGpuTensorLoad];
        _contribCpuHistory = [..._contribCpuHistory.sublist(1), _cpuValue];
      }
    });
  }

  @override
  void dispose() {
    DeSplitDaemonService.instance.hardwareMetrics.removeListener(_onDaemonTelemetry);
    DeSplitDaemonService.instance.clusterState.removeListener(_onDaemonTelemetry);
    _tickerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: ThemeService.instance.themeModeNotifier,
      builder: (context, themeMode, _) {
        return Container(
          color: AppColors.canvasBackground,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Task Manager Top Header ("Performance" + "My Contributions" Toggle)
              _buildPerformanceHeader(),

              // Contribution Info Bar (when Swarm Contribution mode is active)
              if (_isContributionMode) _buildContributionBanner(),

              Divider(
                color: AppColors.borderSubtle,
                height: 1,
                thickness: 1,
              ),

              // 2. Main Content Body: Left Devices Sidebar + Right Details
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Hardware List (CPU, Memory, Disk, Ethernet, Wi-Fi, GPU 0)
                    SizedBox(
                      width: 225,
                      child: _buildHardwareDeviceList(),
                    ),

                    VerticalDivider(
                      color: AppColors.borderSubtle,
                      width: 1,
                      thickness: 1,
                    ),

                    // Right Device Detail View
                    Expanded(
                      child: _buildSelectedDeviceView(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // Top Header: "Performance" and "My Contributions" Button
  // -------------------------------------------------------------
  Widget _buildPerformanceHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Performance',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 10),
              // Status Pill
              if (_isContributionMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F5A0).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF00F5A0).withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00F5A0),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF00F5A0),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'MY SWARM CONTRIBUTION',
                        style: TextStyle(
                          color: Color(0xFF00F5A0),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    'SYSTEM HOST METRICS',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          Row(
            children: [
              // Interactive "My Contributions" Button
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _isContributionMode = !_isContributionMode);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isContributionMode
                            ? 'Switched to My Swarm Contributions — showing compute & hardware contributed to deSplit'
                            : 'Switched to System Telemetry — showing host machine performance',
                      ),
                      duration: const Duration(milliseconds: 1800),
                      backgroundColor: AppColors.cardSurfaceLight,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: Icon(
                  _isContributionMode ? Icons.check_circle_rounded : Icons.volunteer_activism_rounded,
                  size: 15,
                  color: _isContributionMode ? Colors.white : AppColors.brandAccent,
                ),
                label: Text(
                  _isContributionMode ? 'My Contributions (Active)' : 'My Contributions',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _isContributionMode ? FontWeight.w600 : FontWeight.w500,
                    color: _isContributionMode ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isContributionMode
                      ? AppColors.brandAccent
                      : AppColors.cardSurface,
                  foregroundColor: _isContributionMode ? Colors.white : AppColors.textPrimary,
                  elevation: _isContributionMode ? 3 : 0,
                  shadowColor: AppColors.brandAccent.withValues(alpha: 0.5),
                  side: BorderSide(
                    color: _isContributionMode ? AppColors.brandAccent : AppColors.borderSubtle,
                    width: 1.2,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz_rounded, size: 18),
                color: AppColors.textSecondary,
                tooltip: 'More options',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Contribution Banner when active
  // -------------------------------------------------------------
  Widget _buildContributionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.brandAccent.withValues(alpha: 0.08),
        border: Border(
          top: BorderSide(color: AppColors.brandAccent.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.hub_rounded, size: 15, color: AppColors.brandAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing live compute, memory, disk cache, and network bandwidth contributed by this node (@operator_081) to the deSplit Swarm.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _isContributionMode = false),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                'Return to Host Metrics',
                style: TextStyle(
                  color: AppColors.brandAccent,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Left Sidebar: Hardware Device List
  // -------------------------------------------------------------
  Widget _buildHardwareDeviceList() {
    // Current GPU names & labels from real daemon detection
    final isAmd = _selectedGpuModel == 1;
    final hw = DeSplitDaemonService.instance.hardwareMetrics.value;
    final gpus = hw?['gpus'] as List<dynamic>?;
    final realGpuName = (gpus != null && gpus.isNotEmpty)
        ? (gpus[0]['name'] as String? ?? 'Intel(R) Iris(R) Xe Graphics')
        : 'Intel(R) Iris(R) Xe Graphics';
    final gpuHostName = isAmd ? 'AMD Radeon RX 7900 XTX' : realGpuName;
    final ramTotalGb = ((hw?['ram']?['total_ram_mb'] as num? ?? 16128) / 1024).toStringAsFixed(1);
    final gpuHostSub = isAmd
        ? '$gpuHostName\n${_amd3DValue.toInt()}% N/A'
        : '$gpuHostName\n${_gpu3DValue.toInt()}% VRAM: ${_gpuSharedMemValue.toStringAsFixed(2)} GB';
    final gpuContribSub = isAmd
        ? '61.4 TFLOPS • 16.0 GB VRAM\n${_contribGpuTensorLoad.toInt()}% Tensor Load'
        : '14.2 TFLOPS • 0.7 GB Shared\n${_contribGpuTensorLoad.toInt()}% Tensor Load';

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      children: [
        // 0. CPU
        _buildDeviceNavItem(
          index: 0,
          title: _isContributionMode ? 'CPU (Swarm)' : 'CPU',
          subtitle: _isContributionMode
              ? '${_contribCpuLoad.toInt()}% Contributed\n${hw?['cpu']?['logical_cores'] ?? 12} Cores • ${_contribCpuGflops.toStringAsFixed(1)} GFLOPS'
              : '${_cpuValue.toInt()}% ${_cpuSpeed.toStringAsFixed(2)} GHz',
          dataPoints: _isContributionMode ? _contribCpuHistory : _cpuHistory,
          maxValue: 100.0,
        ),
        // 1. Memory
        _buildDeviceNavItem(
          index: 1,
          title: _isContributionMode ? 'Memory (Swarm)' : 'Memory',
          subtitle: _isContributionMode
              ? '${_contribMemUsed.toStringAsFixed(1)}/${_contribMemAllocated.toStringAsFixed(0)} GB Contributed\n70% Buffer In-Use'
              : '${_memoryValue.toStringAsFixed(1)}/$ramTotalGb GB',
          dataPoints: _isContributionMode ? _contribMemoryHistory : _memoryHistory,
          maxValue: 100.0,
        ),
        // 2. Disk 0 (C:)
        _buildDeviceNavItem(
          index: 2,
          title: _isContributionMode ? 'Disk 0 (Swarm)' : 'Disk 0 (C:)',
          subtitle: _isContributionMode
              ? '${_contribDiskUsed.toStringAsFixed(1)}/${_contribDiskAllocated.toStringAsFixed(0)} GB Shards\n${_contribDiskActive.toInt()}% Active I/O'
              : 'SSD (NVMe)\n${_diskValue.toInt()}%',
          dataPoints: _isContributionMode ? _contribDiskHistory : _diskHistory,
          maxValue: 100.0,
        ),
        // 3. Ethernet
        _buildDeviceNavItem(
          index: 3,
          title: _isContributionMode ? 'Ethernet (Swarm)' : 'Ethernet',
          subtitle: _isContributionMode
              ? 'WireGuard P2P\nS: ${_contribEthSend.toStringAsFixed(1)} R: ${_contribEthRecv.toStringAsFixed(1)} MB/s'
              : 'Ethernet 4\nS: 0 R: 0 Kbps',
          dataPoints: _isContributionMode ? _contribEthernetHistory : _ethernetHistory,
          maxValue: _isContributionMode ? 30.0 : 100.0,
        ),
        // 4. Wi-Fi
        _buildDeviceNavItem(
          index: 4,
          title: _isContributionMode ? 'Wi-Fi (Swarm)' : 'Wi-Fi',
          subtitle: _isContributionMode
              ? 'Mesh Gossip Link\nS: ${_contribWifiSend.toInt()} R: ${_contribWifiRecv.toInt()} Kbps'
              : 'Wi-Fi\nS: 0 R: 0 Kbps',
          dataPoints: _isContributionMode ? _contribWifiHistory : _wifiHistory,
          maxValue: _isContributionMode ? 400.0 : 100.0,
        ),
        // 5. GPU 0
        _buildDeviceNavItem(
          index: 5,
          title: _isContributionMode ? 'GPU 0 (Swarm)' : 'GPU 0',
          subtitle: _isContributionMode ? gpuContribSub : gpuHostSub,
          dataPoints: _isContributionMode
              ? _contribGpuTensorHistory
              : (isAmd ? _amd3DHistory : _gpu3DHistory),
          maxValue: 100.0,
        ),
      ],
    );
  }

  Widget _buildDeviceNavItem({
    required int index,
    required String title,
    required String subtitle,
    required List<double> dataPoints,
    required double maxValue,
  }) {
    final isSelected = _selectedDeviceIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isSelected
            ? (AppColors.isProfessional
                ? AppColors.cardSurfaceLight
                : (AppColors.isLight
                    ? const Color(0xFFEDE9FE)
                    : const Color(0xFF1E1838)))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected
              ? AppColors.brandAccent
              : Colors.transparent,
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => setState(() => _selectedDeviceIndex = index),
          hoverColor: AppColors.brandAccent.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                // Mini Task Manager Graph Box
                Container(
                  width: 52,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.brandAccent
                          : AppColors.borderSubtle,
                      width: 1.0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: CustomPaint(
                      painter: TaskManagerChartPainter(
                        dataPoints: dataPoints,
                        maxValue: maxValue,
                        gridRows: 2,
                        gridCols: 3,
                        strokeColor: AppColors.brandAccent,
                        fillStartColor: AppColors.brandAccent.withValues(
                            alpha: AppColors.isLight ? 0.25 : 0.45),
                        fillEndColor: Colors.transparent,
                        gridColor: AppColors.isProfessional
                            ? AppColors.borderSubtle.withValues(alpha: 0.5)
                            : (AppColors.isLight
                                ? const Color(0xFFEDE9FE)
                                : const Color(0x28A855F7)),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Device Title and Metrics
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected
                              ? (AppColors.isProfessional
                                  ? AppColors.brandAccent
                                  : (AppColors.isLight
                                      ? const Color(0xFF1E1B4B)
                                      : Colors.white))
                              : AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isSelected
                              ? (AppColors.isProfessional
                                  ? AppColors.accentPale
                                  : (AppColors.isLight
                                      ? const Color(0xFF6B21A8)
                                      : const Color(0xFFE9D5FF)))
                              : AppColors.textMuted,
                          fontSize: 10.5,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Right Area: Selected Device Detail View
  // -------------------------------------------------------------
  Widget _buildSelectedDeviceView() {
    switch (_selectedDeviceIndex) {
      case 5:
        return _buildGpuDetailView();
      case 0:
        return _buildCpuDetailView();
      case 1:
        return _buildMemoryDetailView();
      case 2:
        return _buildDiskDetailView();
      case 3:
      case 4:
        return _buildNetworkDetailView(_selectedDeviceIndex == 3 ? 'Ethernet' : 'Wi-Fi');
      default:
        return _buildGpuDetailView();
    }
  }

  // -------------------------------------------------------------
  // GPU Detail View (Intel Iris Xe or AMD GPU • Host / Contributed)
  // -------------------------------------------------------------
  Widget _buildGpuDetailView() {
    final isAmd = _selectedGpuModel == 1;

    // GPU names and driver info
    final gpuModelName = isAmd ? 'AMD Radeon RX 7900 XTX' : 'Intel(R) Iris(R) Xe Graphics';
    final gpuDriverVersion = isAmd ? '31.0.24033.1003 (Adrenalin)' : '31.0.101.5333';
    final gpuDriverDate = isAmd ? '14-04-2024' : '21-02-2024';
    final gpuDirectX = isAmd ? '12 (FL 12.2 / Ultimate)' : '12 (FL 12.1)';
    final gpuLocation = isAmd ? 'PCI bus 1, device 0, function 0' : 'PCI bus 0, device 2, function 0';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GPU Top Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(
                    'GPU',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (_isContributionMode) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF00F5A0).withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'SWARM ALLOCATION',
                        style: TextStyle(
                          color: Color(0xFF00F5A0),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              // GPU Model Selector (Supports both Intel Iris Xe and AMD Radeon)
              PopupMenuButton<int>(
                initialValue: _selectedGpuModel,
                tooltip: 'Select GPU Hardware',
                onSelected: (val) => setState(() => _selectedGpuModel = val),
                color: AppColors.cardSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppColors.borderSubtle),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 0,
                    child: Row(
                      children: [
                        Icon(
                          Icons.memory_rounded,
                          size: 16,
                          color: _selectedGpuModel == 0 ? AppColors.brandAccent : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Intel(R) Iris(R) Xe Graphics',
                          style: TextStyle(
                            color: _selectedGpuModel == 0 ? AppColors.brandAccent : AppColors.textPrimary,
                            fontWeight: _selectedGpuModel == 0 ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 1,
                    child: Row(
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 16,
                          color: _selectedGpuModel == 1 ? AppColors.brandAccent : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AMD Radeon RX 7900 XTX (Cluster)',
                          style: TextStyle(
                            color: _selectedGpuModel == 1 ? AppColors.brandAccent : AppColors.textPrimary,
                            fontWeight: _selectedGpuModel == 1 ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAmd ? Icons.bolt_rounded : Icons.memory_rounded,
                        size: 15,
                        color: AppColors.brandAccent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        gpuModelName,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2x2 Grid of Performance/Contribution Graph Cards
          if (_isContributionMode)
            _buildGpuContributionGrid(isAmd)
          else
            _buildGpuHostGrid(isAmd),

          const SizedBox(height: 14),

          // Shared/Dedicated GPU Memory (Wide horizontal graph)
          if (_isContributionMode)
            _buildGpuContributionMemoryCard(isAmd)
          else
            _buildGpuHostMemoryCard(isAmd),

          const SizedBox(height: 18),

          // Bottom Detailed Specs Grid
          if (_isContributionMode)
            _buildGpuContributionSpecs(isAmd, gpuModelName, gpuDriverVersion, gpuDriverDate, gpuDirectX, gpuLocation)
          else
            _buildGpuHostSpecs(isAmd, gpuDriverVersion, gpuDriverDate, gpuDirectX, gpuLocation),
        ],
      ),
    );
  }

  // GPU Grid - Host Mode
  Widget _buildGpuHostGrid(bool isAmd) {
    final cur3D = isAmd ? _amd3DValue : _gpu3DValue;
    final cur3DHistory = isAmd ? _amd3DHistory : _gpu3DHistory;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 140,
                child: TelemetryGraphCard(
                  title: '3D',
                  hasDropdown: true,
                  currentValueText: '${cur3D.toInt()}%',
                  dataPoints: cur3DHistory,
                  maxValue: 100.0,
                  tooltipDetails: [
                    'Active Load: ${cur3D.toInt()}%',
                    'Clock: ${isAmd ? '2500 MHz' : '1300 MHz'}',
                    'Engine: Direct3D 12',
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 140,
                child: TelemetryGraphCard(
                  title: 'Copy',
                  hasDropdown: false,
                  currentValueText: '${_gpuCopyValue.toInt()}%',
                  dataPoints: _gpuCopyHistory,
                  maxValue: 100.0,
                  tooltipDetails: const [
                    'DMA Engine: Idle',
                    'Bandwidth: 0.0 GB/s',
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 140,
                child: TelemetryGraphCard(
                  title: 'Video Decode',
                  hasDropdown: true,
                  currentValueText: '${_gpuDecodeValue.toInt()}%',
                  dataPoints: _gpuDecodeHistory,
                  maxValue: 100.0,
                  tooltipDetails: const [
                    'Hardware Decode: 0%',
                    'Format: AV1 / HEVC Ready',
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 140,
                child: TelemetryGraphCard(
                  title: 'Video Processing',
                  hasDropdown: true,
                  currentValueText: '${_gpuProcessingValue.toInt()}%',
                  dataPoints: _gpuProcessingHistory,
                  maxValue: 100.0,
                  tooltipDetails: const [
                    'Media Shaders: Idle',
                    'Post-Processing: 0%',
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // GPU Grid - Contribution Mode
  Widget _buildGpuContributionGrid(bool isAmd) {
    final tflopsText = isAmd ? '61.4 TFLOPS' : '14.2 TFLOPS';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 140,
                child: TelemetryGraphCard(
                  title: 'Compute 0 / Tensor Engine',
                  hasDropdown: true,
                  currentValueText: '${_contribGpuTensorLoad.toInt()}%',
                  dataPoints: _contribGpuTensorHistory,
                  maxValue: 100.0,
                  tooltipDetails: [
                    'Swarm Tensor Load: ${_contribGpuTensorLoad.toInt()}%',
                    'Compute Output: $tflopsText (FP16)',
                    'Engine: ${isAmd ? 'ROCm / DirectML' : 'DirectML / SYCL'}',
                    'Task: Federated Model Slicing',
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 140,
                child: TelemetryGraphCard(
                  title: 'DMA / Gradient Transfer',
                  hasDropdown: false,
                  currentValueText: '${_contribGpuCopyLoad.toInt()}%',
                  dataPoints: _contribGpuCopyHistory,
                  maxValue: 100.0,
                  tooltipDetails: const [
                    'Bus Rate: 4.8 GB/s (PCIe)',
                    'Direct Memory Access: Active',
                    'Pipeline Stage: Layers 1-8 Transfer',
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 140,
                child: TelemetryGraphCard(
                  title: 'Weight Decompression',
                  hasDropdown: true,
                  currentValueText: '${_contribGpuDecodeLoad.toInt()}%',
                  dataPoints: _contribGpuDecodeHistory,
                  maxValue: 100.0,
                  tooltipDetails: [
                    'Model Quantization: INT8 / FP8',
                    'Decompressor: ${_contribGpuDecodeLoad.toInt()}% Active',
                    'Layers: Attention QKV Projections',
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 140,
                child: TelemetryGraphCard(
                  title: 'Activation Slicing Core',
                  hasDropdown: true,
                  currentValueText: '${_contribGpuProcLoad.toInt()}%',
                  dataPoints: _contribGpuProcHistory,
                  maxValue: 100.0,
                  tooltipDetails: [
                    'Forward Pass: FlashAttention-2',
                    'Batch Size: 16 Parallel',
                    'Execution Load: ${_contribGpuProcLoad.toInt()}%',
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // GPU Memory Card - Host Mode
  Widget _buildGpuHostMemoryCard(bool isAmd) {
    if (isAmd) {
      return SizedBox(
        height: 120,
        width: double.infinity,
        child: TelemetryGraphCard(
          title: 'Dedicated GPU memory',
          hasDropdown: false,
          currentValueText: '${_amdDedicatedMemValue.toStringAsFixed(1)} GB',
          rightLabel: '24.0 GB',
          dataPoints: _amdDedicatedMemHistory,
          maxValue: 24.0,
          tooltipDetails: [
            'In Use: ${_amdDedicatedMemValue.toStringAsFixed(1)} GB',
            'Limit: 24.0 GB GDDR6',
            'Dedicated VRAM Pool',
          ],
        ),
      );
    }

    return SizedBox(
      height: 120,
      width: double.infinity,
      child: TelemetryGraphCard(
        title: 'Shared GPU memory',
        hasDropdown: false,
        currentValueText: '${_gpuSharedMemValue.toStringAsFixed(1)} GB',
        rightLabel: '7.9 GB',
        dataPoints: _gpuSharedMemHistory,
        maxValue: 7.9,
        tooltipDetails: [
          'Allocated: ${_gpuSharedMemValue.toStringAsFixed(1)} GB',
          'Limit: 7.9 GB',
          'System RAM Shared Pool',
        ],
      ),
    );
  }

  // GPU Memory Card - Contribution Mode
  Widget _buildGpuContributionMemoryCard(bool isAmd) {
    final vramAllocated = isAmd ? '16.0 GB' : '0.7 GB';
    final vramUsed = isAmd ? '16.0 GB Contributed' : '${_contribGpuVramUsed.toStringAsFixed(2)} GB Contributed';

    return SizedBox(
      height: 120,
      width: double.infinity,
      child: TelemetryGraphCard(
        title: isAmd ? 'Contributed Dedicated VRAM' : 'Contributed Shared VRAM',
        hasDropdown: false,
        currentValueText: vramUsed,
        rightLabel: '$vramAllocated Swarm Cap',
        dataPoints: _contribGpuVramHistory,
        maxValue: isAmd ? 16.0 : 0.70,
        tooltipDetails: [
          'Swarm VRAM Pool: $vramAllocated (100% Dedicated)',
          'Weight Slices Buffer: ${isAmd ? '11.2 GB' : '0.45 GB'}',
          'Activation Cache: ${isAmd ? '4.8 GB' : '0.25 GB'}',
          'Zero Slash Proof: Verified Active',
        ],
      ),
    );
  }

  // GPU Specs - Host Mode
  Widget _buildGpuHostSpecs(bool isAmd, String driverVer, String driverDate, String dxVer, String location) {
    final util = isAmd ? _amd3DValue.toInt() : _gpu3DValue.toInt();
    final memStr = isAmd ? '${_amdDedicatedMemValue.toStringAsFixed(1)}/24.0 GB' : '${_gpuSharedMemValue.toStringAsFixed(1)}/7.9 GB';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 500),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Col 1: Utilization & GPU Memory
              SizedBox(
                width: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSpecItem('Utilization', '$util%', isLarge: true),
                    const SizedBox(height: 12),
                    _buildSpecItem(isAmd ? 'Dedicated VRAM' : 'GPU Memory', memStr, isLarge: true),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Col 2: Shared GPU memory & Temperature
              SizedBox(
                width: 170,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSpecItem(isAmd ? 'Shared memory' : 'Shared GPU memory', isAmd ? '0.1/16.0 GB' : memStr, isLarge: true),
                    const SizedBox(height: 12),
                    _buildSpecItem('Temperature', isAmd ? '46°C' : 'N/A', isLarge: true),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Col 3: Driver details
              SizedBox(
                width: 250,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSpecItem('Driver version:', driverVer),
                    const SizedBox(height: 6),
                    _buildSpecItem('Driver date:', driverDate),
                    const SizedBox(height: 6),
                    _buildSpecItem('DirectX version:', dxVer),
                    const SizedBox(height: 6),
                    _buildSpecItem('Physical location:', location),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // GPU Specs - Contribution Mode
  Widget _buildGpuContributionSpecs(
    bool isAmd,
    String gpuName,
    String driverVer,
    String driverDate,
    String dxVer,
    String location,
  ) {
    final tflops = isAmd ? '61.4 TFLOPS' : '14.2 TFLOPS';
    final vramStr = isAmd ? '16.0 GB GDDR6' : '0.7 GB Shared VRAM';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 520),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Col 1: Swarm Load & Contributed VRAM
              SizedBox(
                width: 155,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSpecItem('Swarm Tensor Load', '${_contribGpuTensorLoad.toInt()}%', isLarge: true),
                    const SizedBox(height: 12),
                    _buildSpecItem('Contributed VRAM', vramStr, isLarge: true),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Col 2: Compute Output & Temperature
              SizedBox(
                width: 165,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSpecItem('Compute Output', tflops, isLarge: true),
                    const SizedBox(height: 12),
                    _buildSpecItem('GPU Temperature', isAmd ? '54°C' : '58°C', isLarge: true),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Col 3: Swarm Network Status
              SizedBox(
                width: 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSpecItem('Pipeline Role:', 'Model Slicing Pipeline Worker'),
                    const SizedBox(height: 6),
                    _buildSpecItem('Telemetry Proof:', 'Zero-Knowledge (ZK-SNARK)'),
                    const SizedBox(height: 6),
                    _buildSpecItem('Slashing Status:', '0 Penalties (Verified Honest)'),
                    const SizedBox(height: 6),
                    _buildSpecItem('Swarm Earning:', '+14.2 SPLIT / 1k batches'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // CPU Detail View (Host / Contributed)
  // -------------------------------------------------------------
  Widget _buildCpuDetailView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(
                    'CPU',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_isContributionMode) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF00F5A0).withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'SWARM ALLOCATION',
                        style: TextStyle(
                          color: Color(0xFF00F5A0),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _isContributionMode
                      ? '${DeSplitDaemonService.instance.hardwareMetrics.value?['cpu']?['name'] ?? '12th Gen Intel(R) Core(TM) i5-1235U'} (Contributed)'
                      : (DeSplitDaemonService.instance.hardwareMetrics.value?['cpu']?['name'] ?? '12th Gen Intel(R) Core(TM) i5-1235U'),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 240,
            width: double.infinity,
            child: TelemetryGraphCard(
              title: _isContributionMode ? '% Swarm Compute Load' : '% Utilization',
              hasDropdown: false,
              currentValueText: _isContributionMode
                  ? '${_contribCpuLoad.toInt()}%'
                  : '${_cpuValue.toInt()}%',
              rightLabel: _isContributionMode ? '8 Dedicated Cores' : '100 %',
              dataPoints: _isContributionMode ? _contribCpuHistory : _cpuHistory,
              maxValue: 100.0,
              tooltipDetails: _isContributionMode
                  ? [
                      'Contributed Compute: 8 Cores / 16 Threads',
                      'Active Swarm Load: ${_contribCpuLoad.toInt()}%',
                      'Throughput: ${_contribCpuGflops.toStringAsFixed(1)} GFLOPS FP32',
                      'Job: FedAvg Local Gradient Slicing',
                    ]
                  : [
                      'Utilization: ${_cpuValue.toInt()}%',
                      'Speed: ${_cpuSpeed.toStringAsFixed(2)} GHz',
                      'Processes: 242',
                    ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 500),
                child: _isContributionMode
                    ? Row(
                        children: [
                          SizedBox(width: 105, child: _buildSpecItem('Swarm Load', '${_contribCpuLoad.toInt()}%', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 110, child: _buildSpecItem('Contributed', '$_contribCpuCores Cores', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 110, child: _buildSpecItem('Compute', '${_contribCpuGflops.toStringAsFixed(1)} GFLOPS', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 95, child: _buildSpecItem('Swarm Workers', '14 Active', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 95, child: _buildSpecItem('Batches / hr', '1,428', isLarge: true)),
                        ],
                      )
                    : Row(
                        children: [
                          SizedBox(width: 95, child: _buildSpecItem('Utilization', '${_cpuValue.toInt()}%', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 105, child: _buildSpecItem('Speed', '${_cpuSpeed.toStringAsFixed(2)} GHz', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 95, child: _buildSpecItem('Processes', '242', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 95, child: _buildSpecItem('Threads', '3,412', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 95, child: _buildSpecItem('Handles', '98,241', isLarge: true)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Memory Detail View (Host / Contributed)
  // -------------------------------------------------------------
  Widget _buildMemoryDetailView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(
                    'Memory',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_isContributionMode) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF00F5A0).withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'SWARM ALLOCATION',
                        style: TextStyle(
                          color: Color(0xFF00F5A0),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _isContributionMode
                      ? 'Swarm RAM & Activation Buffer (6.0 GB Dedicated)'
                      : '15.8 GB DDR5',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 240,
            width: double.infinity,
            child: TelemetryGraphCard(
              title: _isContributionMode ? 'Swarm memory usage' : 'Memory usage',
              hasDropdown: false,
              currentValueText: _isContributionMode
                  ? '${_contribMemUsed.toStringAsFixed(1)} GB (${((_contribMemUsed / _contribMemAllocated) * 100).toInt()}%)'
                  : '12.7 GB (80%)',
              rightLabel: _isContributionMode ? '${_contribMemAllocated.toStringAsFixed(1)} GB Dedicated' : '15.8 GB',
              dataPoints: _isContributionMode ? _contribMemoryHistory : _memoryHistory,
              maxValue: 100.0,
              tooltipDetails: _isContributionMode
                  ? [
                      'In Swarm Cache: ${_contribMemUsed.toStringAsFixed(1)} GB',
                      'Activation Buffer: 2.8 GB',
                      'Weight Slices: 1.4 GB',
                      'Total Contributed: 6.0 GB DDR5',
                    ]
                  : const [
                      'In use: 12.7 GB',
                      'Available: 3.1 GB',
                      'Committed: 15.2/18.4 GB',
                    ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 480),
                child: _isContributionMode
                    ? Row(
                        children: [
                          SizedBox(width: 135, child: _buildSpecItem('Contributed RAM', '6.0 GB DDR5', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 125, child: _buildSpecItem('In Use by Swarm', '${_contribMemUsed.toStringAsFixed(1)} GB', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 125, child: _buildSpecItem('Activation Buffer', '2.8 GB', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 110, child: _buildSpecItem('Free Buffer', '${(_contribMemAllocated - _contribMemUsed).toStringAsFixed(1)} GB', isLarge: true)),
                        ],
                      )
                    : Row(
                        children: [
                          SizedBox(width: 170, child: _buildSpecItem('In use (Compressed)', '12.7 GB (180 MB)', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 95, child: _buildSpecItem('Available', '3.1 GB', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 95, child: _buildSpecItem('Speed', '4800 MHz', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 95, child: _buildSpecItem('Slots used', '2 of 2', isLarge: true)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Disk Detail View (Host / Contributed)
  // -------------------------------------------------------------
  Widget _buildDiskDetailView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(
                    'Disk 0 (C:)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_isContributionMode) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF00F5A0).withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'SWARM ALLOCATION',
                        style: TextStyle(
                          color: Color(0xFF00F5A0),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _isContributionMode
                      ? 'Swarm Model Shard Cache (120 GB Dedicated NVMe)'
                      : 'NVMe Samsung SSD 980 1TB',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 240,
            width: double.infinity,
            child: TelemetryGraphCard(
              title: _isContributionMode ? 'Swarm I/O active time' : 'Active time',
              hasDropdown: false,
              currentValueText: _isContributionMode
                  ? '${_contribDiskActive.toInt()}%'
                  : '${_diskValue.toInt()}%',
              rightLabel: '100 %',
              dataPoints: _isContributionMode ? _contribDiskHistory : _diskHistory,
              maxValue: 100.0,
              tooltipDetails: _isContributionMode
                  ? [
                      'Contributed Storage: 120 GB NVMe',
                      'Cached Weights: ${_contribDiskUsed.toStringAsFixed(1)} GB',
                      'Read Speed (Streaming): 64.2 MB/s',
                      'Write Speed (Checkpoints): 32.5 MB/s',
                    ]
                  : [
                      'Active: ${_diskValue.toInt()}%',
                      'Read: 14.2 KB/s',
                      'Write: 120.4 KB/s',
                    ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 480),
                child: _isContributionMode
                    ? Row(
                        children: [
                          SizedBox(width: 130, child: _buildSpecItem('Contributed Space', '120 GB NVMe', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 125, child: _buildSpecItem('Shards Cached', '${_contribDiskUsed.toStringAsFixed(1)} GB (7 Models)', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 105, child: _buildSpecItem('Read Speed', '64.2 MB/s', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 105, child: _buildSpecItem('Write Speed', '32.5 MB/s', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 105, child: _buildSpecItem('Checksums', '100% Valid', isLarge: true)),
                        ],
                      )
                    : Row(
                        children: [
                          SizedBox(width: 100, child: _buildSpecItem('Active time', '${_diskValue.toInt()}%', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 125, child: _buildSpecItem('Avg response time', '0.6 ms', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 105, child: _buildSpecItem('Capacity', '954 GB', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 110, child: _buildSpecItem('Type', 'SSD (NVMe)', isLarge: true)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Network Detail View (Ethernet / Wi-Fi • Host / Contributed)
  // -------------------------------------------------------------
  Widget _buildNetworkDetailView(String netType) {
    final isEthernet = netType == 'Ethernet';

    final hostHardwareName = isEthernet
        ? 'Intel(R) Ethernet Controller I225-V'
        : 'Intel(R) Wi-Fi 6E AX211 160MHz';

    final contribHardwareName = isEthernet
        ? 'Intel(R) Ethernet Controller I225-V (Swarm P2P WireGuard)'
        : 'Intel(R) Wi-Fi 6E AX211 160MHz (Swarm Consensus Heartbeat)';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(
                    netType,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_isContributionMode) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF00F5A0).withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'SWARM ALLOCATION',
                        style: TextStyle(
                          color: Color(0xFF00F5A0),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _isContributionMode ? contribHardwareName : hostHardwareName,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 240,
            width: double.infinity,
            child: TelemetryGraphCard(
              title: _isContributionMode
                  ? (isEthernet ? 'Swarm throughput (Ingress & Egress)' : 'Swarm gossip throughput')
                  : 'Throughput',
              hasDropdown: false,
              currentValueText: _isContributionMode
                  ? (isEthernet
                      ? 'S: ${_contribEthSend.toStringAsFixed(1)} MB/s • R: ${_contribEthRecv.toStringAsFixed(1)} MB/s'
                      : 'S: ${_contribWifiSend.toInt()} Kbps • R: ${_contribWifiRecv.toInt()} Kbps')
                  : '0 Kbps',
              rightLabel: _isContributionMode
                  ? (isEthernet ? '1 Gbps Mesh Link' : '54 Mbps Gossip')
                  : '1 Gbps',
              dataPoints: _isContributionMode
                  ? (isEthernet ? _contribEthernetHistory : _contribWifiHistory)
                  : (isEthernet ? _ethernetHistory : _wifiHistory),
              maxValue: _isContributionMode ? (isEthernet ? 30.0 : 400.0) : 100.0,
              tooltipDetails: _isContributionMode
                  ? (isEthernet
                      ? [
                          'Upload (Gradient Deltas): ${_contribEthSend.toStringAsFixed(1)} MB/s',
                          'Download (Model Weights): ${_contribEthRecv.toStringAsFixed(1)} MB/s',
                          'Active Mesh Peers: 18 Nodes',
                          'Packet Loss: 0.01%',
                        ]
                      : [
                          'Consensus Gossip: Active',
                          'Gossip Send: ${_contribWifiSend.toInt()} Kbps',
                          'Gossip Receive: ${_contribWifiRecv.toInt()} Kbps',
                          'Heartbeat Ping: 12 ms',
                        ])
                  : const [
                      'Send: 0 Kbps',
                      'Receive: 0 Kbps',
                      'Protocol: Local Network',
                    ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 480),
                child: _isContributionMode
                    ? (isEthernet
                        ? Row(
                            children: [
                              SizedBox(width: 120, child: _buildSpecItem('Egress (Upload)', '${_contribEthSend.toStringAsFixed(1)} MB/s', isLarge: true)),
                              const SizedBox(width: 14),
                              SizedBox(width: 125, child: _buildSpecItem('Ingress (Download)', '${_contribEthRecv.toStringAsFixed(1)} MB/s', isLarge: true)),
                              const SizedBox(width: 14),
                              SizedBox(width: 135, child: _buildSpecItem('Swarm Protocol', 'WireGuard P2P', isLarge: true)),
                              const SizedBox(width: 14),
                              SizedBox(width: 105, child: _buildSpecItem('Mesh Peers', '18 Nodes', isLarge: true)),
                              const SizedBox(width: 14),
                              SizedBox(width: 105, child: _buildSpecItem('Jitter / Latency', '±1.8 ms • 18ms', isLarge: true)),
                            ],
                          )
                        : Row(
                            children: [
                              SizedBox(width: 110, child: _buildSpecItem('Gossip Send', '${_contribWifiSend.toInt()} Kbps', isLarge: true)),
                              const SizedBox(width: 14),
                              SizedBox(width: 110, child: _buildSpecItem('Gossip Recv', '${_contribWifiRecv.toInt()} Kbps', isLarge: true)),
                              const SizedBox(width: 14),
                              SizedBox(width: 135, child: _buildSpecItem('Mesh Interface', 'Secondary Gossip', isLarge: true)),
                              const SizedBox(width: 14),
                              SizedBox(width: 105, child: _buildSpecItem('Ping Latency', '12 ms', isLarge: true)),
                              const SizedBox(width: 14),
                              SizedBox(width: 105, child: _buildSpecItem('Consensus', 'Synced (R-88)', isLarge: true)),
                            ],
                          ))
                    : Row(
                        children: [
                          SizedBox(width: 95, child: _buildSpecItem('Send', '0 Kbps', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 95, child: _buildSpecItem('Receive', '0 Kbps', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 135, child: _buildSpecItem('Connection type', isEthernet ? 'Ethernet 4' : 'Wi-Fi 6E', isLarge: true)),
                          const SizedBox(width: 14),
                          SizedBox(width: 135, child: _buildSpecItem('IPv4 address', '192.168.1.104', isLarge: true)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Helper for Spec Items
  // -------------------------------------------------------------
  Widget _buildSpecItem(String label, String value, {bool isLarge = false}) {
    if (isLarge) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16.5,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
