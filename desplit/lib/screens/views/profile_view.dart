import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../theme/app_colors.dart';
import 'profile/arc_gauge_painter.dart';
import 'profile/badge_widget.dart';
import 'profile/contribution_grid.dart';

class ProfileView extends StatefulWidget {
  final VoidCallback? onSignOut;

  const ProfileView({
    super.key,
    this.onSignOut,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
  // -------------------------------------------------------------
  // User-Entered State
  // -------------------------------------------------------------
  String _alias = 'Jeswin B';
  final String _handle = 'JB1071017';
  String _wallet = '0x71C84B02E54F31d92A9341B981C037';
  String _role = 'Tier 1 Validator & Shard Worker';
  String _workloads = 'LLM Inference, Stable Diffusion, Whisper ASR';
  String _stake = '5,000 SPLIT Staked';

  // -------------------------------------------------------------
  // Auto-Detected Hardware & Telemetry Metrics
  // -------------------------------------------------------------
  final Map<String, dynamic> _autoMetrics = {
    'Peer-ID': '12D3KooWStD8v5f3a91c28b49e01',
    'GPU': 'NVIDIA GeForce RTX 4090 24GB',
    'VRAM': '24.0 GB GDDR6X (82% Available)',
    'PCIe': 'PCIe 4.0 x16 (31.5 GB/s)',
    'CUDA': 'CUDA 12.4 • Compute SM 8.9',
    'TFLOPS': '82.6 TFLOPS FP16 Tensor',
    'RAM': '32.0 GB DDR5 6000MHz',
    'CPU': '13th Gen Intel Core i9-13900K (24 Cores)',
    'Uptime': '99.98% • 42 Days Online',
    'Trust-Score': '99.8 / 100 (Verified Honest)',
    'Completed-Jobs': '14,892 Batches',
    'Slashes': '0 Penalties (Zero Slash History)',
    'Latency': '18 ms Avg P2P WireGuard',
    'Region': 'India (Asia-South • Mumbai)',
    'Earnings': '1,428.50 SPLIT (≈ \$4,285.50 USD)',
  };

  // -------------------------------------------------------------
  // Badges Data (Daily Contributor, Genesis, GPU Titan, Zero Slash)
  // -------------------------------------------------------------
  static List<NodeBadge> get _badges => [
    NodeBadge(
      id: '50_days_2026',
      title: '50 Days Badge 2026',
      category: 'Daily Contributor',
      dateEarned: 'Oct 2026',
      primaryColor: AppColors.statusActive,
      secondaryColor: AppColors.isProfessional
          ? const Color(0xFF0EA5E9)
          : (AppColors.isLight
              ? const Color(0xFF059669)
              : const Color(0xFF10B981)),
      icon: Icons.bolt_rounded,
      description: 'Contributed compute continuous daily streak for 50 days',
    ),
    NodeBadge(
      id: 'genesis_node',
      title: 'Genesis Validator',
      category: 'Pioneer',
      dateEarned: 'Aug 2026',
      primaryColor: AppColors.isProfessional
          ? const Color(0xFF60CDFF)
          : (AppColors.isLight
              ? const Color(0xFF7C3AED)
              : const Color(0xFFA78BFA)),
      secondaryColor: AppColors.isProfessional
          ? const Color(0xFF0284C7)
          : (AppColors.isLight
              ? const Color(0xFF6D28D9)
              : const Color(0xFF7C3AED)),
      icon: Icons.verified_user_rounded,
      description: 'Participated in the deSplit genesis mesh ignition ceremony',
    ),
    const NodeBadge(
      id: 'gpu_titan',
      title: 'GPU Titan Tier',
      category: 'Hardware',
      dateEarned: 'Sep 2026',
      primaryColor: Color(0xFFFBBF24),
      secondaryColor: Color(0xFFD97706),
      icon: Icons.memory_rounded,
      description: 'Allocated > 80 TFLOPS high-performance tensor cores',
    ),
    NodeBadge(
      id: 'zero_slash',
      title: 'Zero-Slash Guardian',
      category: 'Security',
      dateEarned: 'Oct 2026',
      primaryColor: AppColors.isProfessional
          ? const Color(0xFF38BDF8)
          : const Color(0xFF06B6D4),
      secondaryColor: const Color(0xFF0284C7),
      icon: Icons.shield_rounded,
      description: 'Zero Byzantine faults across 14,000+ verification batches',
    ),
  ];

  // -------------------------------------------------------------
  // iPhone Dynamic Island Notification Animation State
  // -------------------------------------------------------------
  late final AnimationController _islandController;
  late final Animation<double> _islandAnimation;
  bool _showNotification = false;
  String _notificationTitle = 'Profile Updated';
  String _notificationMessage = '';

  @override
  void initState() {
    super.initState();
    _islandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _islandAnimation = CurvedAnimation(
      parent: _islandController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _islandController.dispose();
    super.dispose();
  }

  void _triggerNotification(String message, {String title = 'Profile Synchronized'}) {
    setState(() {
      _notificationTitle = title;
      _notificationMessage = message;
      _showNotification = true;
    });

    _islandController.forward(from: 0.0);

    // Auto-dismiss after 4.0 seconds with smooth collapse
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted && _showNotification) {
        _islandController.reverse().then((_) {
          if (mounted) {
            setState(() => _showNotification = false);
          }
        });
      }
    });
  }

  // -------------------------------------------------------------
  // Edit Profile Modal Dialog
  // -------------------------------------------------------------
  void _openEditProfileDialog() {
    final aliasController = TextEditingController(text: _alias);
    final walletController = TextEditingController(text: _wallet);
    final roleController = TextEditingController(text: _role);
    final workloadsController = TextEditingController(text: _workloads);
    final stakeController = TextEditingController(text: _stake);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.borderGlow, width: 1.2),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  color: AppColors.accentLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Edit Node Profile Credentials',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update your operator alias, settlement wallet, validator role, supported AI workloads, and staked tokens.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildEditField(
                    label: 'Operator Alias (User-Entered)',
                    controller: aliasController,
                    hint: 'e.g. Jeswin B',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildEditField(
                    label: 'Payout Wallet Address (User-Entered)',
                    controller: walletController,
                    hint: '0x...',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildEditField(
                    label: 'Node Role (User-Entered)',
                    controller: roleController,
                    hint: 'e.g. Tier 1 Validator & Shard Worker',
                    icon: Icons.military_tech_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildEditField(
                    label: 'Supported Workloads (User-Entered)',
                    controller: workloadsController,
                    hint: 'e.g. LLM Inference, Diffusion, Whisper',
                    icon: Icons.developer_board_outlined,
                  ),
                  const SizedBox(height: 14),
                  _buildEditField(
                    label: 'Staked Tokens (User-Entered)',
                    controller: stakeController,
                    hint: 'e.g. 5,000 SPLIT Staked',
                    icon: Icons.lock_outline_rounded,
                  ),
                ],
              ),
            ),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _alias = aliasController.text.trim().isNotEmpty
                      ? aliasController.text.trim()
                      : _alias;
                  _wallet = walletController.text.trim().isNotEmpty
                      ? walletController.text.trim()
                      : _wallet;
                  _role = roleController.text.trim().isNotEmpty
                      ? roleController.text.trim()
                      : _role;
                  _workloads = workloadsController.text.trim().isNotEmpty
                      ? workloadsController.text.trim()
                      : _workloads;
                  _stake = stakeController.text.trim().isNotEmpty
                      ? stakeController.text.trim()
                      : _stake;
                });
                Navigator.of(ctx).pop();
                _triggerNotification(
                  'Synced across deSplit peer DHT',
                  title: 'Profile Updated',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandAccent,
                foregroundColor: AppColors.isProfessional
                    ? const Color(0xFF121418)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardSurfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: Icon(icon, size: 18, color: AppColors.accentLight),
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.6),
                fontSize: 12.5,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Build Main Screen
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: ThemeService.instance.themeModeNotifier,
      builder: (context, themeMode, _) {
        final user = AuthService.instance.currentUser ??
            FirebaseAuth.instance.currentUser;
        final displayName =
            _alias.isNotEmpty ? _alias : (user?.displayName ?? 'Jeswin B');
        final screenWidth = MediaQuery.of(context).size.width;

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Extra space for top dynamic island notification if active
              if (_showNotification) const SizedBox(height: 38),

              // Layout: Left Sidebar Profile Card + Right Main Panels
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 950;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Profile Sidebar Card (width 290)
                        SizedBox(
                          width: 290,
                          child: _buildLeftProfileCard(displayName),
                        ),
                        const SizedBox(width: 20),
                        // Right Main Content Column
                        Expanded(
                          child: _buildRightDashboardContent(),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildLeftProfileCard(displayName),
                        const SizedBox(height: 20),
                        _buildRightDashboardContent(),
                      ],
                    );
                  }
                },
              ),

              const SizedBox(height: 24),

              // Auto-Detected Hardware & Node Telemetry Specifications Grid (15 items)
              _buildAutoDetectedHardwareSection(),

              const SizedBox(height: 24),

              // Bottom Sign Out Button
              if (widget.onSignOut != null)
                SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: widget.onSignOut,
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('Sign Out Operator Session'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: AppColors.borderSubtle),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // iPhone Dynamic Island Notification Banner at Top Middle (~1/4th screen width)
        if (_showNotification)
          Positioned(
            top: 14,
            left: 0,
            right: 0,
            child: Center(
              child: _buildDynamicIslandNotification(screenWidth),
            ),
          ),
      ],
    );
      },
    );
  }

  // -------------------------------------------------------------
  // iPhone Dynamic Island Notification (~1/4th of screen width)
  // -------------------------------------------------------------
  Widget _buildDynamicIslandNotification(double screenWidth) {
    // Only ~1/4th of screen width from the middle
    final targetWidth = (screenWidth * 0.25).clamp(260.0, 360.0);
    final accentColor = AppColors.isProfessional
        ? const Color(0xFF60CDFF)
        : (AppColors.isLight ? AppColors.brandAccent : AppColors.accentLight);
    final islandBg = AppColors.isLight
        ? const Color(0xFF16122C)
        : (AppColors.isProfessional
            ? const Color(0xFF121418)
            : const Color(0xFF090716));

    return AnimatedBuilder(
      animation: _islandAnimation,
      builder: (context, child) {
        final progress = _islandAnimation.value;
        // Starts in center as a 36px circle and smoothly blooms out to targetWidth
        final currentWidth = 36.0 + (targetWidth - 36.0) * progress;
        final currentHeight = 44.0;
        final contentOpacity = ((progress - 0.35) / 0.65).clamp(0.0, 1.0);

        return Container(
          width: currentWidth,
          height: currentHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: islandBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.6 * progress),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
              if (progress > 0.4)
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.25 * progress),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: progress < 0.35
              ? Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : Opacity(
                  opacity: contentOpacity,
                  child: Row(
                    children: [
                      // Mini capsule icon
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.check_rounded,
                            color: accentColor,
                            size: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Text content in 1/4th width
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _notificationTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _notificationMessage,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Close button
                      GestureDetector(
                        onTap: () {
                          _islandController.reverse().then((_) {
                            if (mounted) {
                              setState(() => _showNotification = false);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // 1. Left Profile Sidebar Card (deSplit Operator Identity)
  // -------------------------------------------------------------
  Widget _buildLeftProfileCard(String displayName) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Operator Avatar + Name + Verified Status
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.isProfessional
                      ? AppColors.cardSurfaceLight
                      : (AppColors.isLight
                          ? const Color(0xFFF3EDFD)
                          : const Color(0xFF1B1638)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accentLight.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.grid_view_rounded,
                    size: 38,
                    color: AppColors.accentLight,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.verified_rounded,
                          color: AppColors.statusActive,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _handle,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Operator Tier Badge (Replaced LeetCode rank)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.brandAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderGlow),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium_rounded,
                              size: 12, color: AppColors.accentLight),
                          const SizedBox(width: 4),
                          Text(
                            'Genesis Tier • #42',
                            style: TextStyle(
                              color: AppColors.isProfessional
                                  ? const Color(0xFF60CDFF)
                                  : (AppColors.isLight
                                      ? AppColors.brandAccent
                                      : AppColors.accentNeon),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Mesh Node Network Stats (Replaced LeetCode Following / Followers)
          Row(
            children: [
              Text(
                '24 ',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Active Peers   •   ',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              Text(
                '128 ',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'DHT Routes',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Edit Profile Button & Share icon
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openEditProfileDialog,
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.isProfessional
                        ? const Color(0xFF60CDFF).withValues(alpha: 0.16)
                        : AppColors.brandAccent.withValues(
                            alpha: AppColors.isLight ? 0.12 : 0.2),
                    foregroundColor: AppColors.isProfessional
                        ? const Color(0xFF60CDFF)
                        : (AppColors.isLight
                            ? AppColors.brandAccent
                            : AppColors.accentLight),
                    elevation: 0,
                    side: BorderSide(
                      color: AppColors.isProfessional
                          ? const Color(0xFF60CDFF).withValues(alpha: 0.45)
                          : AppColors.brandAccent.withValues(alpha: 0.45),
                      width: 1.0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardSurfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                      text:
                          'deSplit Node Operator: $_alias | Genesis Validator | Wallet: $_wallet',
                    ));
                    _triggerNotification('Profile summary copied to clipboard!');
                  },
                  icon: Icon(
                    Icons.file_upload_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Share Profile',
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          Divider(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
          const SizedBox(height: 14),

          // Location / Region
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                'Mumbai, India (Asia-South)',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // GitHub / Identifier
          Row(
            children: [
              Icon(
                Icons.code_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                _handle,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          Divider(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
          const SizedBox(height: 14),

          // Node Operator Performance (Replaced LeetCode "Community Stats Views / Solutions")
          Text(
            'Node Operator Performance',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _buildNodeStatRow(
            Icons.sync_alt_rounded,
            'Batch Throughput',
            '14,892 Batches',
            AppColors.isProfessional
                ? const Color(0xFF60CDFF)
                : const Color(0xFF38BDF8),
          ),
          const SizedBox(height: 8),
          _buildNodeStatRow(
            Icons.verified_rounded,
            'Consensus Uptime',
            '99.98% Online',
            AppColors.statusActive,
          ),
          const SizedBox(height: 8),
          _buildNodeStatRow(
            Icons.shield_outlined,
            'Penalties / Slashes',
            '0 (Zero Slashes)',
            AppColors.accentLight,
          ),
          const SizedBox(height: 8),
          _buildNodeStatRow(
            Icons.toll_rounded,
            'Accumulated Rewards',
            '1,428.50 SPLIT',
            AppColors.isProfessional
                ? const Color(0xFF60CDFF)
                : const Color(0xFFFBBF24),
          ),

          const SizedBox(height: 18),
          Divider(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
          const SizedBox(height: 14),

          // User-Entered Specs
          Text(
            'User-Entered Specs',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          _buildUserEnteredPill('Role', _role, Icons.military_tech_outlined),
          const SizedBox(height: 6),
          _buildUserEnteredPill('Stake', _stake, Icons.lock_outline_rounded),
          const SizedBox(height: 6),
          _buildUserEnteredPill(
              'Workloads', _workloads, Icons.developer_board_outlined),
          const SizedBox(height: 6),
          _buildUserEnteredPill(
              'Wallet', _wallet, Icons.account_balance_wallet_outlined,
              isMono: true),
        ],
      ),
    );
  }

  Widget _buildNodeStatRow(
      IconData icon, String title, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildUserEnteredPill(String label, String value, IconData icon,
      {bool isMono = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.accentLight),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: isMono ? 'Consolas' : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. Right Dashboard Main Panels
  // -------------------------------------------------------------
  Widget _buildRightDashboardContent() {
    return Column(
      children: [
        // Top Row: AI Compute Workload Gauge (Center) + Badges Showcase (Right)
        LayoutBuilder(
          builder: (context, constraints) {
            final isRow = constraints.maxWidth > 650;
            if (isRow) {
              return Row(
                children: [
                  // Center Card: Compute Workloads Arc Gauge (Replaced LeetCode Solved)
                  Expanded(
                    flex: 5,
                    child: _buildArcGaugeCard(),
                  ),
                  const SizedBox(width: 16),
                  // Right Card: Badges Showcase (50 Days Contributor Badge 2026)
                  Expanded(
                    flex: 4,
                    child: _buildBadgesCard(),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildArcGaugeCard(),
                  const SizedBox(height: 16),
                  _buildBadgesCard(),
                ],
              );
            }
          },
        ),

        const SizedBox(height: 16),

        // Full Width Mesh Compute Contribution Heatmap Grid (Past One Year)
        ContributionGrid(isLightMode: AppColors.isLight),
      ],
    );
  }

  // -------------------------------------------------------------
  // Top Center: AI Workload Allocation Arc Gauge Card (Replaced LeetCode Solved)
  // -------------------------------------------------------------
  Widget _buildArcGaugeCard() {
    final llmColor = AppColors.isProfessional
        ? const Color(0xFF60CDFF)
        : (AppColors.isLight
            ? const Color(0xFF7C3AED)
            : const Color(0xFFC084FC));
    final visionColor = AppColors.isProfessional
        ? const Color(0xFF38BDF8)
        : (AppColors.isLight
            ? const Color(0xFF0284C7)
            : const Color(0xFF38BDF8));
    final audioColor = AppColors.isProfessional
        ? const Color(0xFF10B981)
        : (AppColors.isLight
            ? const Color(0xFF059669)
            : const Color(0xFF00F5A0));

    return Container(
      height: 195,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Circular Arc Gauge
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(140, 140),
                  painter: ArcGaugePainter(
                    llmFraction: 0.56, // LLM Inference
                    visionFraction: 0.28, // Vision & Diffusion
                    audioFraction: 0.16, // Audio & Embeddings
                    isLightMode: AppColors.isLight,
                    llmColor: llmColor,
                    visionColor: visionColor,
                    audioColor: audioColor,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '14,892',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 13,
                          color: llmColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Shards Done',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '18 In-Flight',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Categories Breakdown: LLM & NLP (56%), Vision & Diffusion (28%), Audio & Embed (16%)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCategoryPill(
                  title: 'LLM & NLP',
                  count: '8,420 (56%)',
                  tagColor: llmColor,
                ),
                _buildCategoryPill(
                  title: 'Vision & Diffusion',
                  count: '4,210 (28%)',
                  tagColor: visionColor,
                ),
                _buildCategoryPill(
                  title: 'Audio & Embed',
                  count: '2,262 (16%)',
                  tagColor: audioColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill({
    required String title,
    required String count,
    required Color tagColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tagColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            count,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Top Right: Badges Card (50 Days Daily Contributor Badge 2026)
  // -------------------------------------------------------------
  Widget _buildBadgesCard() {
    return Container(
      height: 195,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Badges 4" with forward arrow
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Node Badges',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_badges.length}',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Badges Icon Showcase
          Row(
            children: _badges
                .take(3)
                .map((b) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: BadgeCardWidget(badge: b),
                    ))
                .toList(),
          ),

          const SizedBox(height: 8),

          // Most Recent Badge label
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Most Recent Milestone',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '50 Days Daily Contributor 2026',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. Auto-Detected Hardware & Node Telemetry Specs (15 Items)
  // -------------------------------------------------------------
  Widget _buildAutoDetectedHardwareSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandAccent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderGlow),
                    ),
                    child: Icon(
                      Icons.memory_rounded,
                      color: AppColors.accentLight,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hardware & Node Telemetry Specs',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Auto-detected by the deSplit background daemon worker',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusActive.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.statusActive),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.statusActive,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '15 / 15 AUTO-DETECTED',
                      style: TextStyle(
                        color: AppColors.statusActive,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 15 Auto-Detected Metrics Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 850;
              final columns = isWide ? 3 : (constraints.maxWidth > 550 ? 2 : 1);
              final itemWidth = (constraints.maxWidth - (columns - 1) * 14) /
                  columns;

              return Wrap(
                spacing: 14,
                runSpacing: 12,
                children: [
                  _buildAutoMetricTile(
                    'Peer-ID',
                    _autoMetrics['Peer-ID'] as String,
                    Icons.fingerprint_rounded,
                    itemWidth,
                    canCopy: true,
                  ),
                  _buildAutoMetricTile(
                    'GPU',
                    _autoMetrics['GPU'] as String,
                    Icons.developer_board_rounded,
                    itemWidth,
                  ),
                  _buildAutoMetricTile(
                    'VRAM',
                    _autoMetrics['VRAM'] as String,
                    Icons.storage_rounded,
                    itemWidth,
                  ),
                  _buildAutoMetricTile(
                    'PCIe',
                    _autoMetrics['PCIe'] as String,
                    Icons.cable_rounded,
                    itemWidth,
                  ),
                  _buildAutoMetricTile(
                    'CUDA',
                    _autoMetrics['CUDA'] as String,
                    Icons.terminal_rounded,
                    itemWidth,
                  ),
                  _buildAutoMetricTile(
                    'TFLOPS',
                    _autoMetrics['TFLOPS'] as String,
                    Icons.speed_rounded,
                    itemWidth,
                    highlight: true,
                  ),
                  _buildAutoMetricTile(
                    'RAM',
                    _autoMetrics['RAM'] as String,
                    Icons.memory_rounded,
                    itemWidth,
                  ),
                  _buildAutoMetricTile(
                    'CPU',
                    _autoMetrics['CPU'] as String,
                    Icons.computer_rounded,
                    itemWidth,
                  ),
                  _buildAutoMetricTile(
                    'Uptime',
                    _autoMetrics['Uptime'] as String,
                    Icons.timelapse_rounded,
                    itemWidth,
                  ),
                  _buildAutoMetricTile(
                    'Trust-Score',
                    _autoMetrics['Trust-Score'] as String,
                    Icons.security_rounded,
                    itemWidth,
                    highlight: true,
                  ),
                  _buildAutoMetricTile(
                    'Completed-Jobs',
                    _autoMetrics['Completed-Jobs'] as String,
                    Icons.task_alt_rounded,
                    itemWidth,
                  ),
                  _buildAutoMetricTile(
                    'Slashes',
                    _autoMetrics['Slashes'] as String,
                    Icons.gavel_rounded,
                    itemWidth,
                  ),
                  _buildAutoMetricTile(
                    'Latency',
                    _autoMetrics['Latency'] as String,
                    Icons.wifi_tethering_rounded,
                    itemWidth,
                  ),
                  _buildAutoMetricTile(
                    'Region',
                    _autoMetrics['Region'] as String,
                    Icons.public_rounded,
                    itemWidth,
                  ),
                  _buildAutoMetricTile(
                    'Earnings',
                    _autoMetrics['Earnings'] as String,
                    Icons.toll_rounded,
                    itemWidth,
                    highlight: true,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAutoMetricTile(
    String label,
    String value,
    IconData icon,
    double width, {
    bool canCopy = false,
    bool highlight = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.brandAccent.withValues(alpha: 0.08)
            : AppColors.cardSurfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? AppColors.borderGlow : AppColors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: highlight ? AppColors.accentLight : AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.brandAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'AUTO',
                        style: TextStyle(
                          color: AppColors.accentLight,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: highlight
                        ? (AppColors.isProfessional
                            ? const Color(0xFF60CDFF)
                            : (AppColors.isLight
                                ? AppColors.brandAccent
                                : AppColors.accentNeon))
                        : AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    fontFamily: canCopy ? 'Consolas' : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (canCopy) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                _triggerNotification('$label copied to clipboard!');
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: AppColors.accentLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
