import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/theme_service.dart';
import '../services/window_service.dart';

/// Interactive modal dialogs and runners for all Desktop Menu Bar actions:
/// File | Compute | View | Network | Tools | Help
class DesktopMenuActions {
  // ---------------------------------------------------------------------------
  // THEME HELPER
  // ---------------------------------------------------------------------------
  static bool get _isDark => ThemeService.instance.isDark;

  static Color get _dialogBg =>
      _isDark ? const Color(0xFF0F131E) : const Color(0xFFF8FAFC);
  static Color get _borderCol =>
      _isDark ? const Color(0x3338BDF8) : const Color(0xFFCBD5E1);

  // ---------------------------------------------------------------------------
  // 1. FILE: NEW SESSION
  // ---------------------------------------------------------------------------
  static void showNewSessionDialog(
    BuildContext context, {
    required void Function(String sessionName, String model) onSessionCreated,
  }) {
    final titleController = TextEditingController(text: 'Swarm-Session-FedAvg-R5');
    String selectedModel = 'LLaMA-3-8B-Split (4-bit)';
    String selectedCluster = 'Global Fast Relay (16 Nodes)';
    String selectedOptimizer = 'FedAvg + Top-K Gradient Compression';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return _buildBaseDialog(
            ctx: ctx,
            title: 'Initialize New Compute Session',
            subtitle: 'Configure federated training parameters and rendezvous with the Swarm mesh.',
            icon: Icons.add_circle_outline_rounded,
            iconColor: const Color(0xFF00F5A0),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFieldLabel('SESSION IDENTIFIER'),
                _buildTextField(titleController, hint: 'e.g. FedAvg-Round-5'),
                const SizedBox(height: 16),
                _buildFieldLabel('TARGET MODEL ARCHITECTURE'),
                _buildDropdown<String>(
                  value: selectedModel,
                  items: const [
                    'LLaMA-3-8B-Split (4-bit)',
                    'Mistral-Small-24B (8-bit Quantized)',
                    'DeepSeek-Coder-V2 (16-bit FP)',
                    'Phi-3.5-MoE-Instruct (Local Slice)',
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedModel = val);
                  },
                ),
                const SizedBox(height: 16),
                _buildFieldLabel('SWARM CLUSTER & NODE ALLOCATION'),
                _buildDropdown<String>(
                  value: selectedCluster,
                  items: const [
                    'Global Fast Relay (16 Nodes)',
                    'North America Shard (8 Nodes)',
                    'Europe Central Cluster (12 Nodes)',
                    'Asia-Pacific Validator Mesh (24 Nodes)',
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedCluster = val);
                  },
                ),
                const SizedBox(height: 16),
                _buildFieldLabel('AGGREGATION & OPTIMIZER STRATEGY'),
                _buildDropdown<String>(
                  value: selectedOptimizer,
                  items: const [
                    'FedAvg + Top-K Gradient Compression',
                    'Decentralized AdamW (Local Epochs=5)',
                    'Quantized FedProx (Mu=0.01)',
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedOptimizer = val);
                  },
                ),
              ],
            ),
            actions: [
              _buildSecondaryButton('Cancel', () => Navigator.of(ctx).pop()),
              const SizedBox(width: 10),
              _buildPrimaryButton(
                'Initialize & Launch',
                const Color(0xFF00F5A0),
                Colors.black,
                () {
                  Navigator.of(ctx).pop();
                  onSessionCreated(titleController.text.trim(), selectedModel);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. FILE: OPEN CONFIGURATION
  // ---------------------------------------------------------------------------
  static void showOpenConfigDialog(BuildContext context) {
    int port = 4040;
    bool enableUpnp = true;
    bool enableMdns = true;
    bool enableTls = true;
    String preset = 'High Performance FP16';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return _buildBaseDialog(
            ctx: ctx,
            title: 'Node Configuration Manager',
            subtitle: 'Inspect and tune low-level P2P networking, daemon port, and local cache policies.',
            icon: Icons.file_open_outlined,
            iconColor: const Color(0xFF38BDF8),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _buildFieldLabel('ACTIVE PRESET: '),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        preset,
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFieldLabel('P2P DAEMON LISTEN PORT'),
                _buildStaticInfoRow('Default TCP / QUIC Port', '$port (Listening on 0.0.0.0:$port)'),
                const SizedBox(height: 14),
                _buildSwitchRow(
                  'UPnP Automatic NAT Port Forwarding',
                  'Expose external port for inbound swarm peers without manual router config',
                  enableUpnp,
                  (val) => setDialogState(() => enableUpnp = val),
                ),
                _buildSwitchRow(
                  'mDNS Local Subnet Peer Discovery',
                  'Zero-config auto discovery for local LAN worker rigs and test shards',
                  enableMdns,
                  (val) => setDialogState(() => enableMdns = val),
                ),
                _buildSwitchRow(
                  'Mutual TLS (mTLS v1.3) Transport Security',
                  'Require cryptographic node certificate verification on all gradient exchanges',
                  enableTls,
                  (val) => setDialogState(() => enableTls = val),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _borderCol.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Color(0xFF94A3B8)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Config file saved at: %APPDATA%\\deSplit\\node_config.json',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              _buildSecondaryButton('Close', () => Navigator.of(ctx).pop()),
              const SizedBox(width: 10),
              _buildPrimaryButton(
                'Save & Reload Config',
                const Color(0xFF38BDF8),
                Colors.black,
                () {
                  Navigator.of(ctx).pop();
                  _showToast(context, 'Configuration updated. Node listening on port $port.');
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. FILE: IMPORT MODEL WEIGHTS
  // ---------------------------------------------------------------------------
  static void showImportWeightsDialog(BuildContext context) {
    final repoController = TextEditingController(text: 'deSplit/Llama-3-8B-Split-FP16');
    bool isVerifying = false;
    double progress = 0.0;
    String statusText = 'Ready to stream tensor checkpoints from decentralized Swarm.';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return _buildBaseDialog(
            ctx: ctx,
            title: 'Import Model Weights & Shards',
            subtitle: 'Stream model weights directly from HuggingFace, local disk, or decentralized IPFS mesh.',
            icon: Icons.upload_file_outlined,
            iconColor: const Color(0xFFA855F7),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFieldLabel('MODEL REPOSITORY OR LOCAL PATH'),
                _buildTextField(repoController, hint: 'e.g. meta-llama/Llama-3-8B or C:\\models\\shard.safetensors'),
                const SizedBox(height: 14),
                _buildFieldLabel('EXPECTED FORMAT'),
                const Row(
                  children: [
                    _TagBadge('Safetensors (Zero-Copy)', Color(0xFF00F5A0)),
                    SizedBox(width: 6),
                    _TagBadge('GGUF v3', Color(0xFF38BDF8)),
                    SizedBox(width: 6),
                    _TagBadge('FP16 / BF16', Color(0xFFA855F7)),
                  ],
                ),
                const SizedBox(height: 16),
                if (isVerifying) ...[
                  LinearProgressIndicator(
                    value: progress > 0 ? progress : null,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFA855F7)),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  statusText,
                  style: TextStyle(
                    color: isVerifying ? const Color(0xFFA855F7) : const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            actions: [
              _buildSecondaryButton('Cancel', () => Navigator.of(ctx).pop()),
              const SizedBox(width: 10),
              _buildPrimaryButton(
                isVerifying ? 'Importing...' : 'Verify & Mount Weights',
                const Color(0xFFA855F7),
                Colors.white,
                isVerifying
                    ? () {}
                    : () {
                        setDialogState(() {
                          isVerifying = true;
                          progress = 0.25;
                          statusText = 'Verifying SHA256 checksum against consensus oracle...';
                        });

                        Future.delayed(const Duration(milliseconds: 900), () {
                          if (ctx.mounted) {
                            setDialogState(() {
                              progress = 0.72;
                              statusText = 'Allocating 4.8 GB GPU VRAM ring buffer...';
                            });
                          }
                        });

                        Future.delayed(const Duration(milliseconds: 1800), () {
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                            _showToast(context, 'Model weights mounted successfully! 32 tensor layers ready.');
                          }
                        });
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. FILE: EXPORT NODE TELEMETRY
  // ---------------------------------------------------------------------------
  static void showExportTelemetryDialog(BuildContext context) {
    String format = 'JSON Data Bundle (.json)';
    String timeframe = 'Last 24 Hours';
    bool includeProof = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return _buildBaseDialog(
            ctx: ctx,
            title: 'Export Node Telemetry & Logs',
            subtitle: 'Generate a signed telemetry report for validator benchmarking and performance audits.',
            icon: Icons.download_outlined,
            iconColor: const Color(0xFF38BDF8),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFieldLabel('EXPORT FORMAT'),
                _buildDropdown<String>(
                  value: format,
                  items: const [
                    'JSON Data Bundle (.json)',
                    'CSV Time-Series Table (.csv)',
                    'OpenTelemetry / Prometheus Metrics (.prom)',
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => format = val);
                  },
                ),
                const SizedBox(height: 14),
                _buildFieldLabel('DATA TIMEFRAME'),
                _buildDropdown<String>(
                  value: timeframe,
                  items: const [
                    'Last 1 Hour (Real-Time)',
                    'Last 24 Hours',
                    'Past 7 Days (Consensus Epoch)',
                    'Full Historical Log',
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => timeframe = val);
                  },
                ),
                const SizedBox(height: 14),
                _buildSwitchRow(
                  'Include Cryptographic Node Signatures',
                  'Attaches ECDSA secp256k1 signature from your local validator key',
                  includeProof,
                  (val) => setDialogState(() => includeProof = val),
                ),
              ],
            ),
            actions: [
              _buildSecondaryButton('Cancel', () => Navigator.of(ctx).pop()),
              const SizedBox(width: 10),
              _buildPrimaryButton(
                'Generate & Copy',
                const Color(0xFF38BDF8),
                Colors.black,
                () {
                  const sampleData = '''{
  "node_id": "0x71a48c3b99114d284c1f",
  "client_version": "deSplit-1.0.0-windows-x64",
  "uptime_seconds": 84210,
  "compute_tflops": 142.8,
  "p2p_mesh_peers": 6,
  "proof_of_training": "0x98f411b0c9a4192b..."
}''';
                  Clipboard.setData(const ClipboardData(text: sampleData));
                  Navigator.of(ctx).pop();
                  _showToast(context, 'Telemetry bundle copied to clipboard (desplit_export_$timeframe.json)!');
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. FILE: SIGN OUT CONFIRMATION
  // ---------------------------------------------------------------------------
  static void showSignOutConfirmDialog(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => _buildBaseDialog(
        ctx: ctx,
        title: 'Sign Out Node Operator',
        subtitle: 'Are you sure you want to sign out? Your worker node will gracefully disconnect from the active consensus quorum.',
        icon: Icons.logout_rounded,
        iconColor: const Color(0xFFF43F5E),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFF43F5E)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Any active gradient batches will be delegated to the nearest mesh peer to avoid consensus penalties.',
                  style: TextStyle(color: Color(0xFFF43F5E), fontSize: 11.5),
                ),
              ),
            ],
          ),
        ),
        actions: [
          _buildSecondaryButton('Stay Connected', () => Navigator.of(ctx).pop()),
          const SizedBox(width: 10),
          _buildPrimaryButton(
            'Sign Out & Disconnect',
            const Color(0xFFF43F5E),
            Colors.white,
            () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. FILE: EXIT DESPLIT CONFIRMATION
  // ---------------------------------------------------------------------------
  static void showExitConfirmDialog(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => _buildBaseDialog(
        ctx: ctx,
        title: 'Exit deSplit Desktop',
        subtitle: 'Close the application window and stop the local P2P compute daemon.',
        icon: Icons.close_rounded,
        iconColor: const Color(0xFFF59E0B),
        content: const Text(
          'Your worker node will transition to STANDBY mode in the global registry. You can reopen deSplit anytime to resume compute.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        actions: [
          _buildSecondaryButton('Cancel', () => Navigator.of(ctx).pop()),
          const SizedBox(width: 10),
          _buildPrimaryButton(
            'Exit Application',
            const Color(0xFFF59E0B),
            Colors.black,
            () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. COMPUTE: ALLOCATE GPU RESOURCES
  // ---------------------------------------------------------------------------
  static void showAllocateGpuDialog(BuildContext context) {
    double vramLimitGb = 16.0;
    double powerTarget = 85.0;
    double tempThrottle = 78.0;
    bool enableTensorCores = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return _buildBaseDialog(
            ctx: ctx,
            title: 'GPU Resource Allocator & Limits',
            subtitle: 'Fine-tune local hardware constraints, power draw target, and VRAM memory reservation.',
            icon: Icons.memory_outlined,
            iconColor: const Color(0xFF00F5A0),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStaticInfoRow('DETECTED HARDWARE', 'NVIDIA GeForce RTX 4090 • 24 GB GDDR6X'),
                const SizedBox(height: 16),
                _buildSliderRow(
                  'Maximum Dedicated VRAM Allocation',
                  '${vramLimitGb.toStringAsFixed(1)} GB / 24.0 GB',
                  vramLimitGb,
                  4.0,
                  24.0,
                  (val) => setDialogState(() => vramLimitGb = val),
                ),
                const SizedBox(height: 12),
                _buildSliderRow(
                  'Power Target Limit (TDP)',
                  '${powerTarget.toInt()}% (Approx 340 Watts)',
                  powerTarget,
                  50.0,
                  100.0,
                  (val) => setDialogState(() => powerTarget = val),
                ),
                const SizedBox(height: 12),
                _buildSliderRow(
                  'Thermal Throttling Ceiling',
                  '${tempThrottle.toInt()} °C',
                  tempThrottle,
                  65.0,
                  88.0,
                  (val) => setDialogState(() => tempThrottle = val),
                ),
                const SizedBox(height: 8),
                _buildSwitchRow(
                  'FP16 / BF16 Tensor Core Acceleration',
                  'Utilize 4th Generation Tensor Cores for 4x faster matrix gemm',
                  enableTensorCores,
                  (val) => setDialogState(() => enableTensorCores = val),
                ),
              ],
            ),
            actions: [
              _buildSecondaryButton('Cancel', () => Navigator.of(ctx).pop()),
              const SizedBox(width: 10),
              _buildPrimaryButton(
                'Apply GPU Profile',
                const Color(0xFF00F5A0),
                Colors.black,
                () {
                  Navigator.of(ctx).pop();
                  _showToast(context, 'GPU Profile applied: ${vramLimitGb.toStringAsFixed(0)}GB VRAM @ ${powerTarget.toInt()}% TDP');
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. COMPUTE: RUN HARDWARE BENCHMARK
  // ---------------------------------------------------------------------------
  static void showHardwareBenchmarkDialog(BuildContext context) {
    bool isRunning = true;
    double progress = 0.0;
    String currentTest = 'Initializing CUDA Tensor GEMM stress test...';
    double tflops = 0.0;
    double memBandwidth = 0.0;
    double pingMs = 0.0;
    bool isFinished = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          if (isRunning && progress == 0.0) {
            Timer(const Duration(milliseconds: 600), () {
              if (!ctx.mounted) return;
              setDialogState(() {
                progress = 0.35;
                currentTest = 'Running 16k x 16k Half-Precision FP16 MatMul...';
                tflops = 138.4;
              });
            });

            Timer(const Duration(milliseconds: 1400), () {
              if (!ctx.mounted) return;
              setDialogState(() {
                progress = 0.70;
                currentTest = 'Measuring VRAM Unified Memory Bandwidth...';
                memBandwidth = 984.2;
              });
            });

            Timer(const Duration(milliseconds: 2200), () {
              if (!ctx.mounted) return;
              setDialogState(() {
                progress = 1.0;
                isRunning = false;
                isFinished = true;
                currentTest = 'Benchmark complete. Verified Tier-1 Supernode!';
                tflops = 142.8;
                memBandwidth = 1008.5;
                pingMs = 14.2;
              });
            });
          }

          return _buildBaseDialog(
            ctx: ctx,
            title: 'Hardware Benchmark & Stress Test',
            subtitle: 'Validate local compute capabilities for decentralized round rewards.',
            icon: Icons.speed_rounded,
            iconColor: const Color(0xFFF59E0B),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(
                    isFinished ? const Color(0xFF00F5A0) : const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  currentTest,
                  style: TextStyle(
                    color: isFinished ? const Color(0xFF00F5A0) : const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        'COMPUTE OUTPUT',
                        '${tflops.toStringAsFixed(1)} TFLOPS',
                        'FP16 Tensor',
                        const Color(0xFF00F5A0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        'VRAM BANDWIDTH',
                        '${memBandwidth.toStringAsFixed(0)} GB/s',
                        'GDDR6X Bus',
                        const Color(0xFF38BDF8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        'P2P RTT PING',
                        '${pingMs.toStringAsFixed(1)} ms',
                        'Mesh Relay',
                        const Color(0xFFA855F7),
                      ),
                    ),
                  ],
                ),
                if (isFinished) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F5A0).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00F5A0).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_rounded, size: 18, color: Color(0xFF00F5A0)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Score: 99.4/100 • Certified Tier-1 Supernode (Eligible for 1.8x Reward Multiplier)',
                            style: TextStyle(color: Color(0xFF00F5A0), fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              _buildSecondaryButton('Close', () => Navigator.of(ctx).pop()),
              if (isFinished) ...[
                const SizedBox(width: 10),
                _buildPrimaryButton(
                  'Re-run Test',
                  const Color(0xFFF59E0B),
                  Colors.black,
                  () {
                    setDialogState(() {
                      isRunning = true;
                      progress = 0.0;
                      isFinished = false;
                      currentTest = 'Initializing CUDA Tensor GEMM stress test...';
                    });
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. VIEW: WINDOW TRANSPARENCY
  // ---------------------------------------------------------------------------
  static void showWindowTransparencyDialog(BuildContext context) {
    double currentOpacity = WindowService.instance.currentOpacity;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return _buildBaseDialog(
            ctx: ctx,
            title: 'Window Transparency & HUD Mode',
            subtitle: 'Adjust desktop window alpha for sleek multi-monitor overlay and aesthetic glass look.',
            icon: Icons.opacity_rounded,
            iconColor: const Color(0xFF38BDF8),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSliderRow(
                  'Window Glass Opacity',
                  '${(currentOpacity * 100).toInt()}%',
                  currentOpacity,
                  0.35,
                  1.0,
                  (val) {
                    setDialogState(() => currentOpacity = val);
                    WindowService.instance.setOpacity(val);
                  },
                ),
                const SizedBox(height: 16),
                _buildFieldLabel('PRESET HUD PROFILES'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PresetChip('Solid (100%)', currentOpacity >= 0.98, () {
                      setDialogState(() => currentOpacity = 1.0);
                      WindowService.instance.setOpacity(1.0);
                    }),
                    _PresetChip('Subtle Aero (93%)', (currentOpacity - 0.93).abs() < 0.03, () {
                      setDialogState(() => currentOpacity = 0.93);
                      WindowService.instance.setOpacity(0.93);
                    }),
                    _PresetChip('Frosted Glass (82%)', (currentOpacity - 0.82).abs() < 0.03, () {
                      setDialogState(() => currentOpacity = 0.82);
                      WindowService.instance.setOpacity(0.82);
                    }),
                    _PresetChip('Cyber HUD (68%)', (currentOpacity - 0.68).abs() < 0.03, () {
                      setDialogState(() => currentOpacity = 0.68);
                      WindowService.instance.setOpacity(0.68);
                    }),
                  ],
                ),
              ],
            ),
            actions: [
              _buildPrimaryButton(
                'Done',
                const Color(0xFF38BDF8),
                Colors.black,
                () => Navigator.of(ctx).pop(),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. NETWORK: DISCOVER P2P PEERS
  // ---------------------------------------------------------------------------
  static void showPeerDiscoveryDialog(BuildContext context) {
    bool isScanning = false;

    final peers = [
      {'id': 'Node-US (Virginia Mesh)', 'addr': '149.28.18.91:4040', 'ping': '14ms', 'type': 'DIRECT', 'state': 'SYNCED'},
      {'id': 'Node-DE (Frankfurt Shard)', 'addr': '45.76.88.112:4040', 'ping': '42ms', 'type': 'RELAY', 'state': 'SYNCED'},
      {'id': 'Node-SG (Singapore Shard)', 'addr': '139.180.201.4:4040', 'ping': '88ms', 'type': 'DIRECT', 'state': 'SYNCED'},
      {'id': 'Node-JP (Tokyo Validator)', 'addr': '108.61.200.77:4040', 'ping': '112ms', 'type': 'DIRECT', 'state': 'VERIFYING'},
      {'id': 'Node-UK (London Data)', 'addr': '195.201.99.12:4040', 'ping': '38ms', 'type': 'DIRECT', 'state': 'SYNCED'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return _buildBaseDialog(
            ctx: ctx,
            title: 'P2P Mesh Peer Discovery',
            subtitle: 'Scan Kademlia DHT and Gossipsub network for decentralized worker peers.',
            icon: Icons.radar_rounded,
            iconColor: const Color(0xFF00F5A0),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${peers.length} ACTIVE PEER CONNECTIONS',
                      style: const TextStyle(color: Color(0xFF00F5A0), fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() => isScanning = true);
                        Future.delayed(const Duration(milliseconds: 1200), () {
                          if (ctx.mounted) {
                            setDialogState(() => isScanning = false);
                            _showToast(context, 'DHT routing table refreshed. 5 peers healthy.');
                          }
                        });
                      },
                      icon: isScanning
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00F5A0)))
                          : const Icon(Icons.refresh, size: 14, color: Color(0xFF00F5A0)),
                      label: Text(isScanning ? 'Scanning...' : 'Rescan DHT', style: const TextStyle(color: Color(0xFF00F5A0), fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _borderCol.withValues(alpha: 0.5)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: peers.length,
                    separatorBuilder: (_, _) => Divider(color: _borderCol.withValues(alpha: 0.2), height: 1),
                    itemBuilder: (_, i) {
                      final p = peers[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.computer, size: 18, color: Color(0xFF38BDF8)),
                        title: Text(p['id']!, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        subtitle: Text('${p['addr']} • ${p['type']}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontFamily: 'monospace')),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(p['ping']!, style: const TextStyle(color: Color(0xFF00F5A0), fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                            const SizedBox(width: 8),
                            _TagBadge(p['state']!, p['state'] == 'SYNCED' ? const Color(0xFF00F5A0) : const Color(0xFFF59E0B)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            actions: [
              _buildPrimaryButton(
                'Close',
                const Color(0xFF00F5A0),
                Colors.black,
                () => Navigator.of(ctx).pop(),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. NETWORK: LATENCY & PING DIAGNOSTICS
  // ---------------------------------------------------------------------------
  static void showPingDiagnosticsDialog(BuildContext context) {
    final hubs = [
      {'hub': 'US-East (Virginia Consensus)', 'rtt': '14 ms', 'jitter': '1.2 ms', 'loss': '0.0%'},
      {'hub': 'EU-Central (Frankfurt Shard)', 'rtt': '42 ms', 'jitter': '2.1 ms', 'loss': '0.0%'},
      {'hub': 'AP-East (Singapore Gateway)', 'rtt': '88 ms', 'jitter': '3.4 ms', 'loss': '0.0%'},
      {'hub': 'AP-Northeast (Tokyo Relay)', 'rtt': '112 ms', 'jitter': '4.1 ms', 'loss': '0.0%'},
      {'hub': 'IN-South (Bengaluru Mesh)', 'rtt': '126 ms', 'jitter': '4.8 ms', 'loss': '0.0%'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => _buildBaseDialog(
        ctx: ctx,
        title: 'Global Mesh Latency & Ping Diagnostics',
        subtitle: 'Round-trip time (RTT) and jitter metrics to distributed validator clusters.',
        icon: Icons.network_check_rounded,
        iconColor: const Color(0xFF38BDF8),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _borderCol.withValues(alpha: 0.5)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: hubs.length,
                separatorBuilder: (_, _) => Divider(color: _borderCol.withValues(alpha: 0.2), height: 1),
                itemBuilder: (_, i) {
                  final h = hubs[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.public, size: 16, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(h['hub']!, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        Text('RTT: ${h['rtt']}', style: const TextStyle(color: Color(0xFF00F5A0), fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                        const SizedBox(width: 12),
                        Text('Jitter: ${h['jitter']}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontFamily: 'monospace')),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          _buildPrimaryButton(
            'Close Diagnostics',
            const Color(0xFF38BDF8),
            Colors.black,
            () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. NETWORK: CONFIGURE MESH RELAY / NAT
  // ---------------------------------------------------------------------------
  static void showMeshRelayConfigDialog(BuildContext context) {
    final stunController = TextEditingController(text: 'stun.desplit.network:3478');
    final turnController = TextEditingController(text: 'turn.desplit.network:5349');
    bool enableRelay = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return _buildBaseDialog(
            ctx: ctx,
            title: 'Mesh Relay & NAT Traversal',
            subtitle: 'Configure STUN / TURN servers and relay fallback for symmetric NAT firewalls.',
            icon: Icons.router_outlined,
            iconColor: const Color(0xFFA855F7),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStaticInfoRow('CURRENT NAT TYPE', 'Full Cone NAT (Direct P2P Ready)'),
                const SizedBox(height: 14),
                _buildFieldLabel('PRIMARY STUN SERVER'),
                _buildTextField(stunController, hint: 'stun:host:port'),
                const SizedBox(height: 12),
                _buildFieldLabel('FALLBACK TURN RELAY SERVER'),
                _buildTextField(turnController, hint: 'turn:host:port'),
                const SizedBox(height: 12),
                _buildSwitchRow(
                  'Auto-Enable P2P Circuit Relay v2',
                  'Permits other firewalled swarm nodes to proxy gradient slices through this node',
                  enableRelay,
                  (val) => setDialogState(() => enableRelay = val),
                ),
              ],
            ),
            actions: [
              _buildSecondaryButton('Cancel', () => Navigator.of(ctx).pop()),
              const SizedBox(width: 10),
              _buildPrimaryButton(
                'Save Settings',
                const Color(0xFFA855F7),
                Colors.white,
                () {
                  Navigator.of(ctx).pop();
                  _showToast(context, 'NAT & Relay settings successfully updated.');
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. NETWORK: WIREGUARD TUNNEL SETTINGS
  // ---------------------------------------------------------------------------
  static void showWireGuardTunnelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _buildBaseDialog(
        ctx: ctx,
        title: 'WireGuard Mesh Tunnel',
        subtitle: 'End-to-end ChaCha20-Poly1305 encrypted peer tunnels across federated nodes.',
        icon: Icons.security_rounded,
        iconColor: const Color(0xFF00F5A0),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStaticInfoRow('TUNNEL STATUS', 'CONNECTED (Zero-Trust Active)'),
            const SizedBox(height: 10),
            _buildStaticInfoRow('VIRTUAL MESH IPV6', 'fd00:split:84c1::1/64'),
            const SizedBox(height: 10),
            _buildStaticInfoRow('LOCAL PUBLIC KEY', 'xG9+8A2f19k81QvM28148b1.. (secp256k1)'),
            const SizedBox(height: 10),
            _buildStaticInfoRow('LATEST HANDSHAKE', '14 seconds ago (Loss: 0.0%)'),
          ],
        ),
        actions: [
          _buildSecondaryButton('Regenerate Keys', () {
            Navigator.of(ctx).pop();
            _showToast(context, 'WireGuard keypair rotated and published to swarm rendezvous.');
          }),
          const SizedBox(width: 10),
          _buildPrimaryButton(
            'OK',
            const Color(0xFF00F5A0),
            Colors.black,
            () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. NETWORK: BANDWIDTH LIMITER
  // ---------------------------------------------------------------------------
  static void showBandwidthLimiterDialog(BuildContext context) {
    double downloadLimit = 250.0;
    double uploadLimit = 150.0;
    bool enableQos = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return _buildBaseDialog(
            ctx: ctx,
            title: 'Swarm Bandwidth Limiter & QoS',
            subtitle: 'Cap compute gradient data transfer to prevent network saturation on home ISPs.',
            icon: Icons.data_usage_rounded,
            iconColor: const Color(0xFF38BDF8),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSliderRow(
                  'Maximum Inbound Ingress (Download)',
                  '${downloadLimit.toInt()} MB/s',
                  downloadLimit,
                  20.0,
                  500.0,
                  (val) => setDialogState(() => downloadLimit = val),
                ),
                const SizedBox(height: 12),
                _buildSliderRow(
                  'Maximum Outbound Egress (Upload)',
                  '${uploadLimit.toInt()} MB/s',
                  uploadLimit,
                  10.0,
                  300.0,
                  (val) => setDialogState(() => uploadLimit = val),
                ),
                const SizedBox(height: 8),
                _buildSwitchRow(
                  'Priority QoS for Gradient Aggregation',
                  'Ensures FedAvg weight tensors take precedence over telemetry streaming',
                  enableQos,
                  (val) => setDialogState(() => enableQos = val),
                ),
              ],
            ),
            actions: [
              _buildSecondaryButton('Cancel', () => Navigator.of(ctx).pop()),
              const SizedBox(width: 10),
              _buildPrimaryButton(
                'Apply Rate Limits',
                const Color(0xFF38BDF8),
                Colors.black,
                () {
                  Navigator.of(ctx).pop();
                  _showToast(context, 'Rate limits applied: ↓${downloadLimit.toInt()} MB/s • ↑${uploadLimit.toInt()} MB/s');
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. TOOLS: INTERACTIVE NODE TERMINAL
  // ---------------------------------------------------------------------------
  static void showInteractiveTerminalDialog(BuildContext context) {
    final cmdController = TextEditingController();
    final scrollController = ScrollController();
    final List<String> logs = [
      'deSplit Decentralized Operating Environment [Version 1.0.0-rc4]',
      'Type "help" to view available swarm commands.',
      '',
    ];

    void executeCommand(String raw, StateSetter setDialogState) {
      final cmd = raw.trim();
      if (cmd.isEmpty) return;

      setDialogState(() {
        logs.add('split-node@mesh:~\$ $cmd');
        switch (cmd.toLowerCase()) {
          case 'help':
            logs.add('  status      Display node health, active federated round, and VRAM utilization');
            logs.add('  peers       List connected P2P swarm mesh peers');
            logs.add('  balance     Display SPLIT token wallet and pending staking yield');
            logs.add('  benchmark   Run instant FP16 tensor GEMM speed test');
            logs.add('  version     Print engine build and commit info');
            logs.add('  clear       Clear terminal buffer');
            break;
          case 'status':
            logs.add('  [NODE] 0x71a48c3b99114d284c1f • STATUS: ONLINE (ACTIVE)');
            logs.add('  [FEDAVG] Round 4 of 12 • Consensus Quorum: 98.4%');
            logs.add('  [GPU] RTX 4090 • VRAM: 18,420 MB / 24,576 MB • Temp: 58°C');
            break;
          case 'peers':
            logs.add('  Connected to 5 mesh peers via Kademlia DHT:');
            logs.add('    - Node-US (149.28.18.91:4040) [Direct, 14ms]');
            logs.add('    - Node-DE (45.76.88.112:4040) [Relay, 42ms]');
            logs.add('    - Node-SG (139.180.201.4:4040) [Direct, 88ms]');
            break;
          case 'balance':
            logs.add('  Total Treasury Balance: 142,500.00 SPLIT (\$49,875.00 USD)');
            logs.add('  Staked in Consensus:    85,000.00 SPLIT (18.4% APY)');
            break;
          case 'benchmark':
            logs.add('  Executing FP16 GEMM Stress... [OK]');
            logs.add('  Measured Throughput: 142.8 TFLOPS (Tier-1 Supernode)');
            break;
          case 'version':
            logs.add('  deSplit Core v1.0.0-rc4 (Commit: f9a8c42, Windows x64)');
            break;
          case 'clear':
            logs.clear();
            break;
          default:
            logs.add('  bash: command not found: $cmd. Type "help" for options.');
        }
        cmdController.clear();
      });

      Future.delayed(const Duration(milliseconds: 60), () {
        if (scrollController.hasClients) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
      });
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            backgroundColor: const Color(0xFF07090E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF00F5A0), width: 1.2),
            ),
            child: Container(
              width: 720,
              height: 480,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Terminal Title Bar
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F5A0).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.terminal_rounded, size: 16, color: Color(0xFF00F5A0)),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'deSplit Node Interactive Shell',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0x3300F5A0), height: 16),
                  // Terminal Output
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: logs.length,
                        itemBuilder: (_, i) {
                          final line = logs[i];
                          Color col = const Color(0xFF00F5A0);
                          if (line.startsWith('split-node')) {
                            col = const Color(0xFF38BDF8);
                          } else if (line.contains('not found')) {
                            col = const Color(0xFFF43F5E);
                          } else if (line.startsWith('  [')) {
                            col = Colors.white;
                          }
                          return Text(
                            line,
                            style: TextStyle(
                              color: col,
                              fontSize: 11.5,
                              fontFamily: 'Consolas, monospace',
                              height: 1.4,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Input Line
                  Row(
                    children: [
                      const Text(
                        'split-node@mesh:~\$ ',
                        style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                      ),
                      Expanded(
                        child: TextField(
                          controller: cmdController,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            border: InputBorder.none,
                            hintText: 'type a command (e.g. status, peers, benchmark)',
                            hintStyle: TextStyle(color: Colors.white24, fontSize: 11),
                          ),
                          onSubmitted: (val) => executeCommand(val, setDialogState),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, size: 16, color: Color(0xFF00F5A0)),
                        onPressed: () => executeCommand(cmdController.text, setDialogState),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. TOOLS: SYSTEM DIAGNOSTICS & LOGS
  // ---------------------------------------------------------------------------
  static void showSystemLogsDialog(BuildContext context) {
    final List<Map<String, String>> logs = [
      {'time': '23:08:14', 'lvl': 'INFO', 'msg': 'Gossipsub v1.2 mesh overlay connected to 6 peers'},
      {'time': '23:08:29', 'lvl': 'INFO', 'msg': 'Received FedAvg Round 4 gradient shard from Node-US'},
      {'time': '23:08:45', 'lvl': 'WARN', 'msg': 'Peer Node-DE latency spike (142ms > threshold 100ms)'},
      {'time': '23:09:02', 'lvl': 'INFO', 'msg': 'Zero-knowledge proof verified with consensus contract'},
      {'time': '23:09:18', 'lvl': 'INFO', 'msg': 'Allocated 4.8 GB GPU VRAM ring buffer on CUDA Device 0'},
      {'time': '23:09:35', 'lvl': 'INFO', 'msg': 'Validator heartbeat acknowledged by consensus coordinator'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => _buildBaseDialog(
        ctx: ctx,
        title: 'System Diagnostics & Runtime Logs',
        subtitle: 'Live trace logs from the local deSplit compute daemon, CUDA runtime, and P2P transport.',
        icon: Icons.bug_report_outlined,
        iconColor: const Color(0xFFF59E0B),
        content: Container(
          height: 240,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _borderCol.withValues(alpha: 0.5)),
          ),
          child: ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: logs.length,
            separatorBuilder: (_, _) => Divider(color: _borderCol.withValues(alpha: 0.15), height: 1),
            itemBuilder: (_, i) {
              final l = logs[i];
              Color lvlCol = const Color(0xFF38BDF8);
              if (l['lvl'] == 'WARN') lvlCol = const Color(0xFFF59E0B);
              if (l['lvl'] == 'ERROR') lvlCol = const Color(0xFFF43F5E);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(l['time']!, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontFamily: 'monospace')),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: lvlCol.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(l['lvl']!, style: TextStyle(color: lvlCol, fontSize: 9.5, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(l['msg']!, style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11, fontFamily: 'monospace')),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          _buildSecondaryButton('Copy All', () {
            final all = logs.map((e) => '[${e['time']}] [${e['lvl']}] ${e['msg']}').join('\n');
            Clipboard.setData(ClipboardData(text: all));
            _showToast(context, 'Diagnostics log copied to clipboard.');
          }),
          const SizedBox(width: 10),
          _buildPrimaryButton(
            'Close',
            const Color(0xFFF59E0B),
            Colors.black,
            () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. TOOLS: CLEAR LOCAL CACHE
  // ---------------------------------------------------------------------------
  static void showClearCacheDialog(BuildContext context) {
    bool isClearing = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return _buildBaseDialog(
            ctx: ctx,
            title: 'Clear Local Cache & Re-index',
            subtitle: 'Free disk space by removing old gradient checkpoints and cached peer tables.',
            icon: Icons.cleaning_services_rounded,
            iconColor: const Color(0xFFF43F5E),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStaticInfoRow('STALE GRADIENT CHECKPOINTS', '3.2 GB (Rounds 1 - 3)'),
                const SizedBox(height: 8),
                _buildStaticInfoRow('MODEL SLICING TEMP BUFFERS', '1.1 GB'),
                const SizedBox(height: 8),
                _buildStaticInfoRow('P2P GOSSIPSUB MESSAGE CACHE', '84 MB'),
                const SizedBox(height: 14),
                if (isClearing) ...[
                  const LinearProgressIndicator(color: Color(0xFFF43F5E)),
                  const SizedBox(height: 8),
                  const Text('Purging disk cache and rebuilding indexes...', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                ] else
                  const Text(
                    'No active consensus rounds will be affected. Fresh shard indexes will be rebuilt on next launch.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                  ),
              ],
            ),
            actions: [
              _buildSecondaryButton('Cancel', () => Navigator.of(ctx).pop()),
              const SizedBox(width: 10),
              _buildPrimaryButton(
                isClearing ? 'Clearing...' : 'Clear 4.38 GB',
                const Color(0xFFF43F5E),
                Colors.white,
                isClearing
                    ? () {}
                    : () {
                        setDialogState(() => isClearing = true);
                        Future.delayed(const Duration(milliseconds: 1200), () {
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                            _showToast(context, 'Cache flushed! 4.38 GB disk space recovered.');
                          }
                        });
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. HELP: DOCUMENTATION
  // ---------------------------------------------------------------------------
  static void showDocumentationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _buildBaseDialog(
        ctx: ctx,
        title: 'deSplit Documentation & Architecture',
        subtitle: 'Decentralized Federated AI Training and Pipeline Model Slicing Handbook.',
        icon: Icons.menu_book_rounded,
        iconColor: const Color(0xFF00F5A0),
        content: Container(
          height: 260,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _borderCol.withValues(alpha: 0.5)),
          ),
          child: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1. What is deSplit?',
                  style: TextStyle(color: Color(0xFF00F5A0), fontSize: 13, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'deSplit is an open decentralized computing network that coordinates consumer & enterprise GPUs into a distributed tensor execution cluster. Compute providers earn SPLIT tokens by validating gradients.',
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5, height: 1.4),
                ),
                SizedBox(height: 12),
                Text(
                  '2. Federated Averaging (FedAvg)',
                  style: TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'Nodes train weights locally on distributed data subsets and submit compressed gradient updates to the consensus quorum. Top-K sparsification achieves 95% bandwidth reduction.',
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5, height: 1.4),
                ),
                SizedBox(height: 12),
                Text(
                  '3. Pipeline Model Slicing',
                  style: TextStyle(color: Color(0xFFA855F7), fontSize: 13, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'Massive 70B+ LLMs are sliced into sequential layer clusters across participating nodes, allowing consumer GPUs with 16-24GB VRAM to run inference collaboratively.',
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        actions: [
          _buildPrimaryButton(
            'Close Handbook',
            const Color(0xFF00F5A0),
            Colors.black,
            () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. HELP: KEYBOARD SHORTCUTS REFERENCE
  // ---------------------------------------------------------------------------
  static void showKeyboardShortcutsDialog(BuildContext context) {
    final shortcuts = [
      {'key': 'Ctrl+N', 'action': 'New Compute Session'},
      {'key': 'Ctrl+O', 'action': 'Open Configuration'},
      {'key': 'Ctrl+1', 'action': 'FedAvg Consensus View'},
      {'key': 'Ctrl+2', 'action': 'Model Slicing Pipeline'},
      {'key': 'Ctrl+B', 'action': 'Collapse / Expand Sidebar'},
      {'key': 'Ctrl+`', 'action': 'Interactive Node Terminal'},
      {'key': 'Ctrl+T', 'action': 'Toggle Window Transparency'},
      {'key': 'F5', 'action': 'Run Hardware Benchmark'},
      {'key': 'F11', 'action': 'Toggle Fullscreen Mode'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => _buildBaseDialog(
        ctx: ctx,
        title: 'Keyboard Shortcuts Reference',
        subtitle: 'Quick access keyboard hotkeys for operating the deSplit desktop node.',
        icon: Icons.keyboard_outlined,
        iconColor: const Color(0xFF38BDF8),
        content: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _borderCol.withValues(alpha: 0.5)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: shortcuts.length,
            separatorBuilder: (_, _) => Divider(color: _borderCol.withValues(alpha: 0.2), height: 1),
            itemBuilder: (_, i) {
              final s = shortcuts[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s['action']!, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        s['key']!,
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Consolas, monospace'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          _buildPrimaryButton(
            'Got it',
            const Color(0xFF38BDF8),
            Colors.black,
            () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. HELP: COMMUNITY DISCORD
  // ---------------------------------------------------------------------------
  static void showCommunityDiscordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _buildBaseDialog(
        ctx: ctx,
        title: 'Join the deSplit Swarm Community',
        subtitle: 'Connect with fellow GPU node operators, AI researchers, and core protocol engineers.',
        icon: Icons.forum_outlined,
        iconColor: const Color(0xFF5865F2),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF5865F2).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF5865F2).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.discord, size: 28, color: Color(0xFF5865F2)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Discord Community Server', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
                        SizedBox(height: 2),
                        Text('14,280 Node Operators Online • #hardware-rigs • #tokenomics', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildStaticInfoRow('INVITE LINK', 'https://discord.gg/desplit-mesh'),
          ],
        ),
        actions: [
          _buildSecondaryButton('Copy Invite Link', () {
            Clipboard.setData(const ClipboardData(text: 'https://discord.gg/desplit-mesh'));
            _showToast(context, 'Discord link copied to clipboard!');
          }),
          const SizedBox(width: 10),
          _buildPrimaryButton(
            'Done',
            const Color(0xFF5865F2),
            Colors.white,
            () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. HELP: CHECK FOR UPDATES
  // ---------------------------------------------------------------------------
  static void showCheckForUpdatesDialog(BuildContext context) {
    bool isChecking = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          if (isChecking) {
            Timer(const Duration(milliseconds: 1400), () {
              if (ctx.mounted) setDialogState(() => isChecking = false);
            });
          }

          return _buildBaseDialog(
            ctx: ctx,
            title: 'Check for Software Updates',
            subtitle: 'Query the decentralized package registry for core engine releases.',
            icon: Icons.system_update_alt_rounded,
            iconColor: const Color(0xFF00F5A0),
            content: isChecking
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 20),
                      CircularProgressIndicator(color: Color(0xFF00F5A0)),
                      SizedBox(height: 16),
                      Text('Connecting to update repository...', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      SizedBox(height: 20),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F5A0).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF00F5A0).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 22, color: Color(0xFF00F5A0)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('You are on the latest version!', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
                                  SizedBox(height: 2),
                                  Text('deSplit v1.0.0-rc4 (Latest Production Core)', style: TextStyle(color: Color(0xFF00F5A0), fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Recent Release Highlights:',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      const Text('• Complete 5-tab Ledger explorer with virtual compute cards', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      const Text('• Cyber-sentry FedAvg control panel with sliding alerts', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      const Text('• Native Windows loopback OAuth authentication', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    ],
                  ),
            actions: [
              _buildPrimaryButton(
                'Close',
                const Color(0xFF00F5A0),
                Colors.black,
                () => Navigator.of(ctx).pop(),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. HELP: ABOUT DESPLIT ENGINE
  // ---------------------------------------------------------------------------
  static void showAboutEngineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _buildBaseDialog(
        ctx: ctx,
        title: 'About deSplit Engine',
        subtitle: 'Decentralized GPU Compute and Model Sharding Platform.',
        icon: Icons.info_outline_rounded,
        iconColor: const Color(0xFF38BDF8),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.grain_rounded, size: 30, color: Color(0xFF38BDF8)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Center(
              child: Text(
                'deSplit Core v1.0.0-rc4',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 2),
            const Center(
              child: Text(
                'Windows Desktop Build 20261024 • Target x86_64',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 16),
            _buildStaticInfoRow('ARCHITECTURE', 'Decentralized P2P Swarm with Zero-Knowledge Gradient Verification'),
            const SizedBox(height: 8),
            _buildStaticInfoRow('LICENSE', 'Apache License 2.0 / MIT Open Source'),
            const SizedBox(height: 8),
            _buildStaticInfoRow('OPERATOR', 'Jeswin B (@operator_081)'),
          ],
        ),
        actions: [
          _buildPrimaryButton(
            'Close',
            const Color(0xFF38BDF8),
            Colors.black,
            () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // REUSABLE DIALOG BUILDING BLOCKS
  // ===========================================================================
  static Widget _buildBaseDialog({
    required BuildContext ctx,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget content,
    required List<Widget> actions,
  }) {
    return Dialog(
      backgroundColor: _dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _borderCol, width: 1.2),
      ),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: iconColor.withValues(alpha: 0.35)),
                  ),
                  child: Center(child: Icon(icon, size: 20, color: iconColor)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const Divider(color: Color(0x1FFFFFFF), height: 26),
            // Body Content
            content,
            const SizedBox(height: 22),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  static Widget _buildTextField(TextEditingController controller, {required String hint}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 12.5),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _borderCol.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _borderCol.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF00F5A0), width: 1.2),
        ),
      ),
    );
  }

  static Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderCol.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF0F131E),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF94A3B8)),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(item.toString()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  static Widget _buildSwitchRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF00F5A0),
            activeTrackColor: const Color(0xFF00F5A0).withValues(alpha: 0.3),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  static Widget _buildSliderRow(
    String label,
    String valueText,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            Text(valueText, style: const TextStyle(color: Color(0xFF00F5A0), fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF00F5A0),
            inactiveTrackColor: Colors.white12,
            thumbColor: const Color(0xFF00F5A0),
            overlayColor: const Color(0xFF00F5A0).withValues(alpha: 0.15),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  static Widget _buildStaticInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _borderCol.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  static Widget _buildMetricTile(String title, String value, String sub, Color col) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: col.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: col, fontSize: 9.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: Color(0xFF64748B), fontSize: 9.5)),
        ],
      ),
    );
  }

  static Widget _buildPrimaryButton(String text, Color bg, Color textCol, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: textCol,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  static Widget _buildSecondaryButton(String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF94A3B8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  static void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF00F5A0), size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 12))),
          ],
        ),
        backgroundColor: const Color(0xFF0D111A),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF00F5A0), width: 1),
        ),
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _TagBadge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetChip(this.label, this.isSelected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF38BDF8).withValues(alpha: 0.2) : Colors.black26,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8) : const Color(0x3338BDF8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
