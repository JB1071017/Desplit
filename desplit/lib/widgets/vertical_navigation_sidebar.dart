import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../theme/app_colors.dart';

class NavTabItem {
  final int index;
  final String title;
  final IconData icon;
  final String badgeText;

  const NavTabItem({
    required this.index,
    required this.title,
    required this.icon,
    this.badgeText = '',
  });
}

class VerticalNavigationSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onSignOut;
  final bool isCollapsed;

  const VerticalNavigationSidebar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.onSignOut,
    this.isCollapsed = false,
  });

  // Keep exact tab names and indices 0 to 6
  static const List<NavTabItem> tabs = [
    NavTabItem(
      index: 0,
      title: 'FedAvg',
      icon: Icons.alt_route_rounded,
      badgeText: 'Round 4',
    ),
    NavTabItem(
      index: 1,
      title: 'Model Slicing',
      icon: Icons.layers_rounded,
      badgeText: 'Pipeline',
    ),
    NavTabItem(
      index: 2,
      title: 'Telementary',
      icon: Icons.insights_rounded,
    ),
    NavTabItem(
      index: 3,
      title: 'Network',
      icon: Icons.hub_rounded,
      badgeText: 'P2P',
    ),
    NavTabItem(
      index: 4,
      title: 'Ledger',
      icon: Icons.account_balance_wallet_outlined,
    ),
    NavTabItem(
      index: 5,
      title: 'Profile',
      icon: Icons.person_outline_rounded,
    ),
    NavTabItem(
      index: 6,
      title: 'Settings',
      icon: Icons.tune_rounded,
    ),
  ];

  @override
  State<VerticalNavigationSidebar> createState() =>
      _VerticalNavigationSidebarState();
}

class _VerticalNavigationSidebarState extends State<VerticalNavigationSidebar> {
  int? _hoveredIndex;
  bool _hoverOptions = false;

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final displayName = user?.displayName ?? 'Jeswin B';
    final email = user?.email ?? 'jeswin@desplit.network';

    return ValueListenableBuilder(
      valueListenable: ThemeService.instance.themeModeNotifier,
      builder: (context, mode, child) {
        final isDark = ThemeService.instance.isDark;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: widget.isCollapsed ? 64 : 228,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF090614) : AppColors.sidebarBg,
            border: Border(
              right: BorderSide(
                color: isDark
                    ? const Color(0x1FA78BFA)
                    : AppColors.borderSubtle,
                width: 1.0,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Brand Header (Inspired by Image 2: Connected Node Icon + Title + Options)
              if (widget.isCollapsed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.grain_rounded,
                          size: 16,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(
                    left: 18,
                    right: 16,
                    top: 18,
                    bottom: 16,
                  ),
                  child: Row(
                    children: [
                      // Node Mesh Icon
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.grain_rounded,
                            size: 16,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Title
                      Text(
                        'DESPLIT',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const Spacer(),
                      // Options button
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        onEnter: (_) => setState(() => _hoverOptions = true),
                        onExit: (_) => setState(() => _hoverOptions = false),
                        child: GestureDetector(
                          onTap: () => widget.onTabSelected(6), // Settings
                          child: Text(
                            'Options',
                            style: TextStyle(
                              color: _hoverOptions
                                  ? AppColors.accentLight
                                  : (isDark
                                      ? const Color(0xFF94A3B8)
                                      : AppColors.textMuted),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Navigation Sections List (Scrollable if height constrained)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECTION 1: OVERVIEW (FedAvg, Model Slicing, Telementary)
                      _buildSectionHeader('OVERVIEW'),
                      _buildNavItem(VerticalNavigationSidebar.tabs[0]), // FedAvg
                      _buildNavItem(VerticalNavigationSidebar.tabs[1]), // Model Slicing
                      _buildNavItem(VerticalNavigationSidebar.tabs[2]), // Telementary

                      const SizedBox(height: 14),

                      // SECTION 2: EXPLORER (Network, Ledger)
                      _buildSectionHeader('EXPLORER'),
                      _buildNavItem(VerticalNavigationSidebar.tabs[3]), // Network
                      _buildNavItem(VerticalNavigationSidebar.tabs[4]), // Ledger

                      const SizedBox(height: 14),

                      // SECTION 3: SETTINGS (Profile, Settings, Dark theme)
                      _buildSectionHeader('SETTINGS'),
                      _buildNavItem(VerticalNavigationSidebar.tabs[5]), // Profile
                      _buildNavItem(VerticalNavigationSidebar.tabs[6]), // Settings

                      // Dark Theme Toggle Item (matching Image 2 bottom row)
                      _buildThemeToggleItem(isDark),
                    ],
                  ),
                ),
              ),

              // Bottom Node Operator Card
              if (widget.isCollapsed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Tooltip(
                      message: '$displayName\n$email',
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            AppColors.brandAccent.withValues(alpha: 0.35),
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'J',
                          style: TextStyle(
                            color: AppColors.accentLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF130E26)
                        : AppColors.cardSurfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0x1FA78BFA)
                          : AppColors.borderSubtle,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            AppColors.brandAccent.withValues(alpha: 0.35),
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'J',
                          style: TextStyle(
                            color: AppColors.accentLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              email,
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : AppColors.textMuted,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (widget.onSignOut != null)
                        Tooltip(
                          message: 'Sign Out',
                          child: InkWell(
                            onTap: widget.onSignOut,
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.logout_rounded,
                                size: 15,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
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

  // Small top heading texts (matching Image 2)
  Widget _buildSectionHeader(String title) {
    if (widget.isCollapsed) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Divider(color: Color(0x1FA78BFA), height: 1),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 6, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: ThemeService.instance.isDark
              ? const Color(0xFF64748B)
              : const Color(0xFF6B7280),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.3,
        ),
      ),
    );
  }

  // Tab Item (Styled like Image 2 active rounded pill)
  Widget _buildNavItem(NavTabItem tab) {
    final isSelected = widget.selectedIndex == tab.index;
    final isHovered = _hoveredIndex == tab.index;
    final isDark = ThemeService.instance.isDark;

    if (widget.isCollapsed) {
      return Tooltip(
        message: tab.title,
        preferBelow: false,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hoveredIndex = tab.index),
          onExit: (_) => setState(() => _hoveredIndex = null),
          child: GestureDetector(
            onTap: () => widget.onTabSelected(tab.index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isSelected
                    ? (AppColors.isProfessional
                        ? AppColors.cardSurfaceLight
                        : (isDark
                            ? const Color(0xFF221A3B)
                            : const Color(0xFFEDE9FE)))
                    : (!isSelected && isHovered
                        ? (isDark
                            ? const Color(0xFF140F26)
                            : const Color(0xFFF1F5F9))
                        : Colors.transparent),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF38BDF8)
                      : Colors.transparent,
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Icon(
                  tab.icon,
                  size: 20,
                  color: isSelected
                      ? const Color(0xFF38BDF8)
                      : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredIndex = tab.index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () => widget.onTabSelected(tab.index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            // Distinct active rounded pill
            color: isSelected
                ? (AppColors.isProfessional
                    ? AppColors.cardSurfaceLight
                    : (isDark
                        ? const Color(0xFF221A3B)
                        : const Color(0xFFEDE9FE)))
                : (!isSelected && isHovered
                    ? (AppColors.isProfessional
                        ? AppColors.cardSurfaceHover
                        : (isDark
                            ? const Color(0xFF140F26)
                            : const Color(0xFFF1F5F9)))
                    : Colors.transparent),
            border: Border.all(
              color: isSelected
                  ? (AppColors.isProfessional
                      ? AppColors.brandAccent
                      : (isDark
                          ? const Color(0x3FA78BFA)
                          : const Color(0x447C3AED)))
                  : Colors.transparent,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              // Tab Icon
              Icon(
                tab.icon,
                size: 18,
                color: isSelected
                    ? (AppColors.isProfessional
                        ? AppColors.brandAccent
                        : (isDark ? Colors.white : const Color(0xFF6D28D9)))
                    : (isHovered
                        ? (isDark || AppColors.isProfessional ? Colors.white : AppColors.textPrimary)
                        : (isDark
                            ? const Color(0xFF94A3B8)
                            : AppColors.textSecondary)),
              ),
              const SizedBox(width: 11),

              // Tab Title (Strictly preserves original names)
              Expanded(
                child: Text(
                  tab.title,
                  style: TextStyle(
                    color: isSelected
                        ? (isDark || AppColors.isProfessional ? Colors.white : const Color(0xFF1E1B4B))
                        : (isHovered
                            ? (isDark || AppColors.isProfessional ? Colors.white : AppColors.textPrimary)
                            : (isDark
                                ? const Color(0xFFCBD5E1)
                                : AppColors.textSecondary)),
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              // Optional Badge
              if (tab.badgeText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (AppColors.isProfessional
                            ? AppColors.brandAccent.withValues(alpha: 0.2)
                            : (isDark
                                ? const Color(0xFF8B5CF6).withValues(alpha: 0.35)
                                : const Color(0xFF8B5CF6).withValues(alpha: 0.2)))
                        : AppColors.cardSurfaceLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tab.badgeText,
                    style: TextStyle(
                      color: isSelected
                          ? (AppColors.isProfessional
                              ? AppColors.brandAccent
                              : (isDark ? Colors.white : const Color(0xFF6D28D9)))
                          : (AppColors.isProfessional
                              ? AppColors.brandAccent
                              : (isDark
                                  ? const Color(0xFFA78BFA)
                                  : const Color(0xFF64748B))),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Dark Theme Toggle Item (matching Image 2)
  Widget _buildThemeToggleItem(bool isDark) {
    final isHovered = _hoveredIndex == 99;
    final currentMode = ThemeService.instance.currentMode;
    final String modeLabel;
    final IconData modeIcon;
    switch (currentMode) {
      case AppThemeMode.professional:
        modeLabel = 'Theme: Professional';
        modeIcon = Icons.laptop_windows_rounded;
        break;
      case AppThemeMode.dark:
        modeLabel = 'Theme: Dark Violet';
        modeIcon = Icons.dark_mode_outlined;
        break;
      case AppThemeMode.light:
        modeLabel = 'Theme: Light';
        modeIcon = Icons.light_mode_outlined;
        break;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredIndex = 99),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: () => ThemeService.instance.toggleTheme(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isHovered
                ? (AppColors.isProfessional
                    ? AppColors.cardSurfaceHover
                    : (isDark ? const Color(0xFF140F26) : const Color(0xFFF1F5F9)))
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                modeIcon,
                size: 18,
                color: AppColors.isProfessional
                    ? AppColors.brandAccent
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  modeLabel,
                  style: TextStyle(
                    color: isDark || AppColors.isProfessional
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF475569),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Subtle indicator dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.isProfessional
                      ? AppColors.brandAccent
                      : (isDark
                          ? const Color(0xFF00F5A0)
                          : const Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
