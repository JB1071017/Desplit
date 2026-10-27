import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Horizontal desktop menu bar with:
/// File | Compute | View | Network | Tools | Help
class DesktopMenuBar extends StatefulWidget {
  final ValueChanged<String>? onMenuAction;

  const DesktopMenuBar({
    super.key,
    this.onMenuAction,
  });

  @override
  State<DesktopMenuBar> createState() => _DesktopMenuBarState();
}

class _DesktopMenuBarState extends State<DesktopMenuBar> {
  String? _hoveredMenu;

  final Map<String, List<_MenuItemData>> _menuItems = {
    'File': [
      _MenuItemData(title: 'New Session', shortcut: 'Ctrl+N', icon: Icons.add_circle_outline),
      _MenuItemData(title: 'Open Configuration...', shortcut: 'Ctrl+O', icon: Icons.file_open_outlined),
      _MenuItemData(title: 'Import Model Weights...', shortcut: 'Ctrl+I', icon: Icons.upload_file_outlined),
      _MenuItemData(title: 'Export Node Telemetry...', shortcut: 'Ctrl+E', icon: Icons.download_outlined),
      _MenuItemData(isDivider: true),
      _MenuItemData(title: 'Sign Out Node Operator', shortcut: 'Ctrl+W', icon: Icons.logout_rounded),
      _MenuItemData(title: 'Exit deSplit', shortcut: 'Alt+F4', icon: Icons.close_rounded),
    ],
    'Compute': [
      _MenuItemData(title: 'FedAvg Consensus Stage', shortcut: 'Ctrl+1', icon: Icons.merge_type_rounded),
      _MenuItemData(title: 'Model Slicing Pipeline', shortcut: 'Ctrl+2', icon: Icons.layers_rounded),
      _MenuItemData(title: 'Start Worker Daemon', shortcut: 'Ctrl+R', icon: Icons.play_arrow_outlined),
      _MenuItemData(title: 'Pause All Compute', shortcut: 'Ctrl+P', icon: Icons.pause_circle_outline),
      _MenuItemData(title: 'Allocate GPU Resources...', shortcut: 'Ctrl+G', icon: Icons.memory_outlined),
      _MenuItemData(isDivider: true),
      _MenuItemData(title: 'Run Hardware Benchmark', shortcut: 'F5', icon: Icons.speed_rounded),
    ],
    'View': [
      _MenuItemData(title: 'Toggle Fullscreen', shortcut: 'F11', icon: Icons.fullscreen_rounded),
      _MenuItemData(title: 'Collapse / Expand Sidebar', shortcut: 'Ctrl+B', icon: Icons.view_sidebar_outlined),
      _MenuItemData(title: 'Zoom In', shortcut: 'Ctrl++', icon: Icons.zoom_in_rounded),
      _MenuItemData(title: 'Zoom Out', shortcut: 'Ctrl+-', icon: Icons.zoom_out_rounded),
      _MenuItemData(title: 'Reset Zoom & Layout', shortcut: 'Ctrl+0', icon: Icons.refresh_rounded),
      _MenuItemData(isDivider: true),
      _MenuItemData(title: 'Toggle Window Transparency', shortcut: 'Ctrl+T', icon: Icons.opacity_rounded),
    ],
    'Network': [
      _MenuItemData(title: 'Discover P2P Peers', shortcut: 'Ctrl+Shift+D', icon: Icons.radar_rounded),
      _MenuItemData(title: 'Latency & Ping Diagnostics', shortcut: 'Ctrl+L', icon: Icons.network_check_rounded),
      _MenuItemData(title: 'Configure Mesh Relay / NAT', shortcut: '', icon: Icons.router_outlined),
      _MenuItemData(title: 'WireGuard Tunnel Settings', shortcut: '', icon: Icons.security_rounded),
      _MenuItemData(isDivider: true),
      _MenuItemData(title: 'Bandwidth Limiter', shortcut: '', icon: Icons.data_usage_rounded),
    ],
    'Tools': [
      _MenuItemData(title: 'Interactive Node Terminal', shortcut: 'Ctrl+`', icon: Icons.terminal_rounded),
      _MenuItemData(title: 'Live Telemetry Stream', shortcut: 'Ctrl+Shift+T', icon: Icons.insights_rounded),
      _MenuItemData(title: 'Smart Contract Ledger Explorer', shortcut: '', icon: Icons.receipt_long_rounded),
      _MenuItemData(title: 'System Diagnostics & Logs', shortcut: '', icon: Icons.bug_report_outlined),
      _MenuItemData(isDivider: true),
      _MenuItemData(title: 'Clear Local Cache & Re-index', shortcut: '', icon: Icons.cleaning_services_rounded),
    ],
    'Help': [
      _MenuItemData(title: 'deSplit Documentation', shortcut: 'F1', icon: Icons.menu_book_rounded),
      _MenuItemData(title: 'Keyboard Shortcuts Reference', shortcut: 'Ctrl+/', icon: Icons.keyboard_outlined),
      _MenuItemData(title: 'Join Community Discord', shortcut: '', icon: Icons.forum_outlined),
      _MenuItemData(title: 'Check for Updates...', shortcut: '', icon: Icons.system_update_alt_rounded),
      _MenuItemData(isDivider: true),
      _MenuItemData(title: 'About deSplit Engine', shortcut: '', icon: Icons.info_outline_rounded),
    ],
  };

  void _showDropdown(BuildContext context, String menuTitle, Rect buttonRect) {
    final items = _menuItems[menuTitle];
    if (items == null) return;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        buttonRect.left,
        buttonRect.bottom + 4,
        buttonRect.right,
        buttonRect.bottom,
      ),
      color: AppColors.cardSurfaceLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.borderGlow, width: 1.2),
      ),
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.6),
      items: items.map((item) {
        if (item.isDivider) {
          return PopupMenuItem<String>(
            enabled: false,
            height: 12,
            child: Divider(color: AppColors.borderSubtle, height: 1),
          );
        }

        return PopupMenuItem<String>(
          value: '$menuTitle:${item.title}',
          height: 38,
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, size: 16, color: AppColors.accentLight),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (item.shortcut.isNotEmpty) ...[
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.borderSubtle,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    item.shortcut,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Consolas',
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    ).then((selected) {
      if (selected != null) {
        widget.onMenuAction?.call(selected);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.menuBarBg,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderSubtle,
            width: 1.0,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _menuItems.keys.map((menuTitle) {
          final isHovered = _hoveredMenu == menuTitle;
          return Builder(
            builder: (buttonContext) {
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _hoveredMenu = menuTitle),
                onExit: (_) => setState(() => _hoveredMenu = null),
                child: GestureDetector(
                  onTap: () {
                    final renderBox =
                        buttonContext.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                      final offset = renderBox.localToGlobal(Offset.zero);
                      final rect = offset & renderBox.size;
                      _showDropdown(context, menuTitle, rect);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isHovered
                          ? AppColors.brandAccent.withValues(alpha: 0.22)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isHovered
                            ? AppColors.accentLight.withValues(alpha: 0.45)
                            : Colors.transparent,
                        width: 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      menuTitle,
                      style: TextStyle(
                        color: isHovered
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight:
                            isHovered ? FontWeight.w600 : FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
        ),
      ),
    );
  }
}

class _MenuItemData {
  final String title;
  final String shortcut;
  final IconData? icon;
  final bool isDivider;

  _MenuItemData({
    this.title = '',
    this.shortcut = '',
    this.icon,
    this.isDivider = false,
  });
}
