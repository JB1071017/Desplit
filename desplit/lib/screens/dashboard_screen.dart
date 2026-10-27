import 'dart:io' show exit;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../theme/app_colors.dart';
import '../widgets/ambient_violet_background.dart';
import '../widgets/desktop_menu_actions.dart';
import '../widgets/desktop_menu_bar.dart';
import '../widgets/master_power_switch.dart';
import '../widgets/vertical_navigation_sidebar.dart';
import 'login_screen.dart';
import 'views/fedavg_view.dart';
import 'views/ledger_view.dart';
import 'views/model_slicing_view.dart';
import 'views/network_view.dart';
import 'views/profile_view.dart';
import 'views/settings_view.dart';
import 'views/telementary_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTabIndex = 0;
  bool _isNodeOnline = true;
  bool _isSidebarCollapsed = false;
  bool _isFullscreen = false;
  double _uiScaleFactor = 1.0;

  Future<void> _handleSignOut() async {
    await AuthService.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      // -----------------------------------------------------------------------
      // FILE
      // -----------------------------------------------------------------------
      case 'File:New Session':
        DesktopMenuActions.showNewSessionDialog(
          context,
          onSessionCreated: (name, model) {
            setState(() => _selectedTabIndex = 0);
            _showNotification('Session "$name" initialized with $model.');
          },
        );
        break;
      case 'File:Open Configuration...':
        DesktopMenuActions.showOpenConfigDialog(context);
        break;
      case 'File:Import Model Weights...':
        DesktopMenuActions.showImportWeightsDialog(context);
        break;
      case 'File:Export Node Telemetry...':
        DesktopMenuActions.showExportTelemetryDialog(context);
        break;
      case 'File:Sign Out Node Operator':
        DesktopMenuActions.showSignOutConfirmDialog(context, _handleSignOut);
        break;
      case 'File:Exit deSplit':
        DesktopMenuActions.showExitConfirmDialog(context, () {
          if (!kIsWeb) exit(0);
        });
        break;

      // -----------------------------------------------------------------------
      // COMPUTE
      // -----------------------------------------------------------------------
      case 'Compute:FedAvg Consensus Stage':
        setState(() => _selectedTabIndex = 0);
        _showNotification('Switched to FedAvg Consensus Stage.');
        break;
      case 'Compute:Model Slicing Pipeline':
        setState(() => _selectedTabIndex = 1);
        _showNotification('Switched to Model Slicing Pipeline.');
        break;
      case 'Compute:Start Worker Daemon':
        setState(() => _isNodeOnline = true);
        _showNotification('Compute Worker Daemon started (8 cores active).');
        break;
      case 'Compute:Pause All Compute':
        setState(() => _isNodeOnline = false);
        _showNotification('All local worker compute paused. Standby mode active.');
        break;
      case 'Compute:Allocate GPU Resources...':
        DesktopMenuActions.showAllocateGpuDialog(context);
        break;
      case 'Compute:Run Hardware Benchmark':
        DesktopMenuActions.showHardwareBenchmarkDialog(context);
        break;

      // -----------------------------------------------------------------------
      // VIEW
      // -----------------------------------------------------------------------
      case 'View:Toggle Fullscreen':
        setState(() => _isFullscreen = !_isFullscreen);
        _showNotification(_isFullscreen ? 'Entered Fullscreen Mode (Press F11 to exit).' : 'Exited Fullscreen Mode.');
        break;
      case 'View:Collapse / Expand Sidebar':
        setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
        break;
      case 'View:Zoom In':
        setState(() {
          _uiScaleFactor = (_uiScaleFactor + 0.1).clamp(0.7, 1.4);
        });
        _showNotification('UI Zoom: ${(_uiScaleFactor * 100).toInt()}%');
        break;
      case 'View:Zoom Out':
        setState(() {
          _uiScaleFactor = (_uiScaleFactor - 0.1).clamp(0.7, 1.4);
        });
        _showNotification('UI Zoom: ${(_uiScaleFactor * 100).toInt()}%');
        break;
      case 'View:Reset Zoom & Layout':
        setState(() {
          _uiScaleFactor = 1.0;
          _isSidebarCollapsed = false;
          _isFullscreen = false;
        });
        _showNotification('UI Zoom & Layout reset to default.');
        break;
      case 'View:Toggle Window Transparency':
        DesktopMenuActions.showWindowTransparencyDialog(context);
        break;

      // -----------------------------------------------------------------------
      // NETWORK
      // -----------------------------------------------------------------------
      case 'Network:Discover P2P Peers':
        DesktopMenuActions.showPeerDiscoveryDialog(context);
        break;
      case 'Network:Latency & Ping Diagnostics':
        DesktopMenuActions.showPingDiagnosticsDialog(context);
        break;
      case 'Network:Configure Mesh Relay / NAT':
        DesktopMenuActions.showMeshRelayConfigDialog(context);
        break;
      case 'Network:WireGuard Tunnel Settings':
        DesktopMenuActions.showWireGuardTunnelDialog(context);
        break;
      case 'Network:Bandwidth Limiter':
        DesktopMenuActions.showBandwidthLimiterDialog(context);
        break;

      // -----------------------------------------------------------------------
      // TOOLS
      // -----------------------------------------------------------------------
      case 'Tools:Interactive Node Terminal':
        DesktopMenuActions.showInteractiveTerminalDialog(context);
        break;
      case 'Tools:Live Telemetry Stream':
        setState(() => _selectedTabIndex = 2);
        _showNotification('Switched to Live Telemetry Stream.');
        break;
      case 'Tools:Smart Contract Ledger Explorer':
        setState(() => _selectedTabIndex = 4);
        _showNotification('Navigated to Smart Contract Ledger.');
        break;
      case 'Tools:System Diagnostics & Logs':
        DesktopMenuActions.showSystemLogsDialog(context);
        break;
      case 'Tools:Clear Local Cache & Re-index':
        DesktopMenuActions.showClearCacheDialog(context);
        break;

      // -----------------------------------------------------------------------
      // HELP
      // -----------------------------------------------------------------------
      case 'Help:deSplit Documentation':
        DesktopMenuActions.showDocumentationDialog(context);
        break;
      case 'Help:Keyboard Shortcuts Reference':
        DesktopMenuActions.showKeyboardShortcutsDialog(context);
        break;
      case 'Help:Join Community Discord':
        DesktopMenuActions.showCommunityDiscordDialog(context);
        break;
      case 'Help:Check for Updates...':
        DesktopMenuActions.showCheckForUpdatesDialog(context);
        break;
      case 'Help:About deSplit Engine':
        DesktopMenuActions.showAboutEngineDialog(context);
        break;

      default:
        _showNotification('Action triggered: $action');
        break;
    }
  }

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF38BDF8), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0D111A),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF38BDF8), width: 1),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return const FedAvgView(key: ValueKey('fedavg_view'));
      case 1:
        return ModelSlicingView(
          key: const ValueKey('model_slicing_view'),
          isOnline: _isNodeOnline,
          onToggleOnline: () => setState(() => _isNodeOnline = true),
        );
      case 2:
        return const TelementaryView(key: ValueKey('telementary_view'));
      case 3:
        return NetworkView(
          key: const ValueKey('network_view'),
          isOnline: _isNodeOnline,
          onToggleOnline: () => setState(() => _isNodeOnline = true),
        );
      case 4:
        return const LedgerView(key: ValueKey('ledger_view'));
      case 5:
        return ProfileView(
          key: const ValueKey('profile_view'),
          onSignOut: _handleSignOut,
        );
      case 6:
        return const SettingsView(key: ValueKey('settings_view'));
      default:
        return const FedAvgView(key: ValueKey('default_fedavg_view'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () => _handleMenuAction('File:New Session'),
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): () => _handleMenuAction('File:Open Configuration...'),
        const SingleActivator(LogicalKeyboardKey.keyI, control: true): () => _handleMenuAction('File:Import Model Weights...'),
        const SingleActivator(LogicalKeyboardKey.keyE, control: true): () => _handleMenuAction('File:Export Node Telemetry...'),
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () => _handleMenuAction('Compute:FedAvg Consensus Stage'),
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () => _handleMenuAction('Compute:Model Slicing Pipeline'),
        const SingleActivator(LogicalKeyboardKey.keyR, control: true): () => _handleMenuAction('Compute:Start Worker Daemon'),
        const SingleActivator(LogicalKeyboardKey.keyP, control: true): () => _handleMenuAction('Compute:Pause All Compute'),
        const SingleActivator(LogicalKeyboardKey.f5): () => _handleMenuAction('Compute:Run Hardware Benchmark'),
        const SingleActivator(LogicalKeyboardKey.f11): () => _handleMenuAction('View:Toggle Fullscreen'),
        const SingleActivator(LogicalKeyboardKey.keyB, control: true): () => _handleMenuAction('View:Collapse / Expand Sidebar'),
        const SingleActivator(LogicalKeyboardKey.keyT, control: true): () => _handleMenuAction('View:Toggle Window Transparency'),
        const SingleActivator(LogicalKeyboardKey.backquote, control: true): () => _handleMenuAction('Tools:Interactive Node Terminal'),
        const SingleActivator(LogicalKeyboardKey.f1): () => _handleMenuAction('Help:deSplit Documentation'),
        const SingleActivator(LogicalKeyboardKey.slash, control: true): () => _handleMenuAction('Help:Keyboard Shortcuts Reference'),
      },
      child: Focus(
        autofocus: true,
        child: ValueListenableBuilder<AppThemeMode>(
          valueListenable: ThemeService.instance.themeModeNotifier,
          builder: (context, themeMode, _) {
            return Scaffold(
              backgroundColor: AppColors.canvasBackground,
              body: AmbientVioletBackground(
                child: SafeArea(
                  child: Column(
                    children: [
                      // 1. Top Window Bar: Logo, App Name (middle), and Master Toggle Switch (right)
                      if (!_isFullscreen)
                        Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: AppColors.topBarBg,
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.borderSubtle,
                                width: 1.0,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Left: Logo & Node status pill
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/logo_icon.png',
                                    width: 24,
                                    height: 24,
                                    errorBuilder: (_, _, _) => Icon(
                                      Icons.memory_rounded,
                                      size: 22,
                                      color: AppColors.accentLight,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardSurfaceLight,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.borderSubtle,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _isNodeOnline
                                                ? AppColors.statusActive
                                                : AppColors.statusInactive,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _isNodeOnline ? 'P2P MESH' : 'STANDBY',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Middle Top: Our app's name "desplit"
                              Expanded(
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'de',
                                              style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.8,
                                                fontFamily: 'Segoe UI',
                                              ),
                                            ),
                                            TextSpan(
                                              text: 'split',
                                              style: TextStyle(
                                                color: AppColors.accentLight,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.8,
                                                fontFamily: 'Segoe UI',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.brandAccent.withValues(
                                            alpha: 0.25,
                                          ),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: AppColors.borderSubtle,
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          'v1.0.0',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Right Corner: Switch to toggle ON and OFF
                              MasterPowerSwitch(
                                value: _isNodeOnline,
                                onChanged: (val) {
                                  setState(() {
                                    _isNodeOnline = val;
                                  });
                                },
                              ),
                            ],
                          ),
                        )
                      else
                        // Floating exit fullscreen banner
                        Container(
                          height: 32,
                          color: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'FULLSCREEN DISTRACTION-FREE MONITORING',
                                style: TextStyle(color: Color(0xFF00F5A0), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1),
                              ),
                              InkWell(
                                onTap: () => setState(() => _isFullscreen = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFF38BDF8), width: 0.8),
                                  ),
                                  child: const Text('Exit Fullscreen (F11)', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 2. Horizontal Menu Bar: File | Compute | View | Network | Tools | Help
                      DesktopMenuBar(
                        onMenuAction: _handleMenuAction,
                      ),

                      // 3. Main Workspace: Vertical Navigation Sidebar + Animated Tab Content
                      Expanded(
                        child: Transform.scale(
                          scale: _uiScaleFactor,
                          alignment: Alignment.topLeft,
                          child: Row(
                            children: [
                              // Left vertical tab navigation:
                              // Workload, Telementary, Network, Ledger, Profile, Settings
                              VerticalNavigationSidebar(
                                selectedIndex: _selectedTabIndex,
                                isCollapsed: _isSidebarCollapsed,
                                onTabSelected: (index) {
                                  setState(() {
                                    _selectedTabIndex = index;
                                  });
                                },
                                onSignOut: _handleSignOut,
                              ),

                              // Animated Tab Content View with smooth transition animation
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 280),
                                  reverseDuration: const Duration(milliseconds: 200),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  transitionBuilder: (child, animation) {
                                    final slideAnimation = Tween<Offset>(
                                      begin: const Offset(0.0, 0.03),
                                      end: Offset.zero,
                                    ).animate(animation);

                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: slideAnimation,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: _buildActiveTabContent(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
