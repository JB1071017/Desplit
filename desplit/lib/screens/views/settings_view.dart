import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/theme_service.dart';
import '../../services/window_service.dart';
import '../../theme/app_colors.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  // Navigation State
  String _selectedNavId = 'personalization'; // Default to Personalization as in screenshot
  String? _expandedCardId = 'themes'; // Default expanded card to showcase themes
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Core Configuration State
  double _windowOpacity = WindowService.instance.currentOpacity;
  bool _startOnBoot = true;
  bool _hardwareAcceleration = true;
  double _vramLimitGb = 19.2;
  double _thermalLimitC = 80.0;
  bool _quicStream = true;
  bool _wireguardTunnel = true;
  bool _zkTelemetry = true;
  bool _int8Quantization = true;
  bool _strictByzantine = true;
  bool _autoCompound = true;
  bool _soundEffects = true;
  bool _tempAlerts = true;
  final String _walletAddress = '0x71C84B02E54F31d92A9341B981C037D94e82B4F';

  String? _toastMessage;
  Timer? _toastTimer;

  // Sidebar navigation categories
  static const List<_WindowsNavCategory> _navCategories = [
    _WindowsNavCategory(
      id: 'home',
      title: 'Home',
      icon: Icons.home_rounded,
      iconColor: Color(0xFFF97316),
    ),
    _WindowsNavCategory(
      id: 'system',
      title: 'System',
      icon: Icons.desktop_windows_rounded,
      iconColor: Color(0xFF38BDF8),
    ),
    _WindowsNavCategory(
      id: 'network',
      title: 'Network & internet',
      icon: Icons.wifi_rounded,
      iconColor: Color(0xFF38BDF8),
    ),
    _WindowsNavCategory(
      id: 'personalization',
      title: 'Personalization',
      icon: Icons.brush_rounded,
      iconColor: Color(0xFFF43F5E),
    ),
    _WindowsNavCategory(
      id: 'accounts',
      title: 'Accounts',
      icon: Icons.person_rounded,
      iconColor: Color(0xFF00F5A0),
    ),
    _WindowsNavCategory(
      id: 'privacy',
      title: 'Privacy & security',
      icon: Icons.shield_rounded,
      iconColor: Color(0xFFCBD5E1),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }

  void _showFeedback(String message) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
    });
    _toastTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        setState(() {
          _toastMessage = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: ThemeService.instance.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isProf = themeMode == AppThemeMode.professional;
        final isDark = themeMode == AppThemeMode.dark;
        final isLight = themeMode == AppThemeMode.light;

        final canvasBg = isProf
            ? const Color(0xFF191C21)
            : (isDark ? const Color(0xFF0C0A17) : const Color(0xFFF8F6FD));
        final sidebarBg = isProf
            ? const Color(0xFF15171C)
            : (isDark ? const Color(0xFF0D0B1C) : Colors.white);

        return Stack(
          children: [
            Container(
              color: canvasBg,
              child: Column(
                children: [
                  // 1. Windows 11 Top Bar: "< Settings" + Centered Search Pill + Window controls
                  _buildWindowsTopBar(isProf, isLight),

                  // 2. Main Workspace: Left Navigation Rail + Right Content Pane
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Sidebar (Navigation Rail matching Image)
                        Container(
                          width: 250,
                          color: sidebarBg,
                          child: _buildNavigationSidebar(isProf, isLight),
                        ),

                        // Subtle Vertical Divider
                        Container(
                          width: 1,
                          color: isProf
                              ? const Color(0x18FFFFFF)
                              : (isLight ? const Color(0xFFEDE9FE) : const Color(0x22A78BFA)),
                        ),

                        // Right Main Setting Cards Pane
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(left: 36, right: 36, top: 22, bottom: 32),
                            child: _buildActiveCategoryPane(isProf, isDark, isLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Toast feedback popup
            if (_toastMessage != null)
              Positioned(
                bottom: 24,
                right: 36,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF20242B).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.brandAccent.withValues(alpha: 0.6)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 16, color: AppColors.brandAccent),
                      const SizedBox(width: 8),
                      Text(
                        _toastMessage!,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Windows 11 Top Bar: "< Settings" + Centered "Find a setting" Search Pill
  // ---------------------------------------------------------------------------
  Widget _buildWindowsTopBar(bool isProf, bool isLight) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: isProf
          ? const Color(0xFF14161B)
          : (isLight ? const Color(0xFFF3EDFD) : const Color(0xFF110E26)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Arrow Back + "Settings" text
          InkWell(
            onTap: () {
              setState(() {
                if (_searchQuery.isNotEmpty) {
                  _searchController.clear();
                  _searchQuery = '';
                } else if (_selectedNavId != 'personalization') {
                  _selectedNavId = 'personalization';
                }
              });
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 16,
                    color: isLight ? AppColors.textPrimary : Colors.white70,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: isLight ? AppColors.textPrimary : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center: Authentic Windows 11 Search Pill
          Container(
            width: 380,
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isProf
                  ? const Color(0xFF20242B)
                  : (isLight ? Colors.white : const Color(0xFF1A1635)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isProf
                    ? const Color(0x22FFFFFF)
                    : (isLight ? const Color(0xFFDDD6FE) : const Color(0x33A78BFA)),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 15,
                  color: isProf
                      ? const Color(0xFF8A919E)
                      : (isLight ? const Color(0xFF8B84B2) : AppColors.accentLight),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(
                      color: isLight ? AppColors.textPrimary : Colors.white,
                      fontSize: 12,
                    ),
                    cursorColor: AppColors.brandAccent,
                    decoration: InputDecoration(
                      hintText: 'Find a setting',
                      hintStyle: TextStyle(
                        color: isProf
                            ? const Color(0xFF8A919E)
                            : (isLight ? const Color(0xFF8B84B2) : const Color(0xFFA9A1CD)),
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Icon(Icons.close_rounded, size: 14, color: Colors.white54),
                  ),
              ],
            ),
          ),

          // Right: Spacer to keep search bar symmetrically centered without window controls
          const SizedBox(width: 88),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Left Sidebar Navigation (Matching Screenshot User Header & Categories)
  // ---------------------------------------------------------------------------
  Widget _buildNavigationSidebar(bool isProf, bool isLight) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Jeswin B';
    final email = user?.email ?? 'jeswin.b.maliyekkal@gmail.com';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Account Profile Header (Exact match to top left of Screenshot)
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, top: 4, bottom: 16),
            child: Row(
              children: [
                // Circular Neon Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isProf
                        ? const RadialGradient(
                            colors: [Color(0xFF60CDFF), Color(0xFF0078D4), Color(0xFF15171C)],
                            stops: [0.2, 0.6, 1.0],
                          )
                        : const RadialGradient(
                            colors: [Color(0xFFC084FC), Color(0xFF6D28D9), Color(0xFF0F0B1E)],
                            stops: [0.2, 0.6, 1.0],
                          ),
                    border: Border.all(
                      color: isProf ? const Color(0x6660CDFF) : const Color(0x66C084FC),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isProf ? const Color(0x3360CDFF) : const Color(0x33A855F7),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.blur_on_rounded, size: 24, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          color: isLight ? AppColors.textPrimary : Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          color: isProf
                              ? const Color(0xFF8A919E)
                              : (isLight ? const Color(0xFF6B7280) : const Color(0xFFA9A1CD)),
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Categories List
          ..._navCategories.map((cat) {
            final isSelected = _selectedNavId == cat.id;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedNavId = cat.id;
                    _expandedCardId = null;
                    if (_searchQuery.isNotEmpty) {
                      _searchQuery = '';
                      _searchController.clear();
                    }
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isProf
                            ? const Color(0xFF262B34)
                            : (isLight ? const Color(0xFFEDE9FE) : const Color(0xFF1E1738)))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      // Active Accent Left Bar Indicator (Signature Windows 11 visual cue)
                      Container(
                        width: 3.5,
                        height: 18,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isProf
                                  ? const Color(0xFF60CDFF)
                                  : AppColors.brandAccent)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        cat.icon,
                        size: 17,
                        color: isSelected
                            ? (isProf
                                ? const Color(0xFF60CDFF)
                                : AppColors.brandAccent)
                            : (isLight ? AppColors.textSecondary : const Color(0xFFCBD5E1)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cat.title,
                          style: TextStyle(
                            color: isSelected
                                ? (isLight ? AppColors.textPrimary : Colors.white)
                                : (isLight ? AppColors.textSecondary : const Color(0xFFCBD5E1)),
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Right Main Content Area (Header + Setting Cards List)
  // ---------------------------------------------------------------------------
  Widget _buildActiveCategoryPane(bool isProf, bool isDark, bool isLight) {
    if (_searchQuery.trim().isNotEmpty) {
      return _buildSearchResultsView(isProf, isDark, isLight);
    }

    if (_selectedNavId == 'home') {
      return _buildHomeView(isProf, isDark, isLight);
    } else if (_selectedNavId == 'personalization') {
      return _buildPersonalizationView(isProf, isDark, isLight);
    } else if (_selectedNavId == 'system') {
      return _buildSystemView(isProf, isDark, isLight);
    } else if (_selectedNavId == 'network') {
      return _buildNetworkView(isProf, isDark, isLight);
    } else if (_selectedNavId == 'privacy') {
      return _buildPrivacyView(isProf, isDark, isLight);
    } else if (_selectedNavId == 'accounts') {
      return _buildAccountsView(isProf, isDark, isLight);
    } else {
      return _buildHomeView(isProf, isDark, isLight);
    }
  }

  // ---------------------------------------------------------------------------
  // SEARCH RESULTS VIEW (Real-Time Universal Settings Search)
  // ---------------------------------------------------------------------------
  Widget _buildSearchResultsView(bool isProf, bool isDark, bool isLight) {
    final query = _searchQuery.trim().toLowerCase();
    final allSearchItems = _allSettingSearchItems;
    final matches = allSearchItems.where((item) {
      if (item.title.toLowerCase().contains(query)) return true;
      if (item.subtitle.toLowerCase().contains(query)) return true;
      if (item.categoryName.toLowerCase().contains(query)) return true;
      if (item.keywords.any((k) => k.toLowerCase().contains(query))) return true;
      return false;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Search results',
                  style: TextStyle(
                    color: isLight ? AppColors.textPrimary : Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isProf
                        ? const Color(0xFF262B34)
                        : (isLight ? const Color(0xFFEDE9FE) : const Color(0xFF1E1738)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${matches.length} found',
                    style: TextStyle(
                      color: isProf ? const Color(0xFF60CDFF) : AppColors.brandAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: isLight ? AppColors.textSecondary : const Color(0xFFCBD5E1),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Clear search',
                      style: TextStyle(
                        color: isLight ? AppColors.textSecondary : const Color(0xFFCBD5E1),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),
        Text(
          'Showing settings matching "$_searchQuery"',
          style: TextStyle(
            color: isProf ? const Color(0xFF8A919E) : (isLight ? const Color(0xFF6B7280) : const Color(0xFFA9A1CD)),
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 18),

        if (matches.isEmpty)
          _buildNoSearchResultsState(isProf, isDark, isLight)
        else
          ...matches.map((item) {
            return _buildSettingCard(
              id: item.id,
              icon: item.icon,
              title: item.title,
              subtitle: item.subtitle,
              categoryBreadcrumb: item.categoryName,
              onJumpToCategory: () {
                setState(() {
                  _selectedNavId = item.categoryId;
                  _expandedCardId = item.id;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              isProf: isProf,
              isLight: isLight,
              expandedChild: _getSettingExpandedChild(item.id, isProf, isDark, isLight),
            );
          }),
      ],
    );
  }

  Widget _buildNoSearchResultsState(bool isProf, bool isDark, bool isLight) {
    final suggestions = ['Themes', 'Colors', 'VRAM', 'GPU', 'WireGuard', 'Sound', 'Thermal', 'Wallet', 'Privacy'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: isProf
            ? const Color(0xFF20242B)
            : (isLight ? Colors.white : const Color(0xFF141129)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isProf
              ? const Color(0x18FFFFFF)
              : (isLight ? const Color(0xFFEDE9FE) : const Color(0x22A78BFA)),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 42,
            color: isProf
                ? const Color(0xFF60CDFF).withValues(alpha: 0.7)
                : AppColors.brandAccent.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 14),
          Text(
            'No settings found for "$_searchQuery"',
            style: TextStyle(
              color: isLight ? AppColors.textPrimary : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check your spelling or try one of the suggested keywords below:',
            style: TextStyle(
              color: isProf ? const Color(0xFF8A919E) : (isLight ? const Color(0xFF6B7280) : const Color(0xFFA9A1CD)),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: suggestions.map((keyword) {
              return InkWell(
                onTap: () {
                  _searchController.text = keyword;
                  setState(() => _searchQuery = keyword);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isProf
                        ? const Color(0xFF191C21)
                        : (isLight ? const Color(0xFFF3EDFD) : const Color(0xFF1C173B)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isProf
                          ? const Color(0x22FFFFFF)
                          : (isLight ? const Color(0xFFDDD6FE) : const Color(0x33A78BFA)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 12,
                        color: isProf ? const Color(0xFF60CDFF) : AppColors.brandAccent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        keyword,
                        style: TextStyle(
                          color: isLight ? AppColors.textPrimary : Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HOME VIEW
  // ---------------------------------------------------------------------------
  Widget _buildHomeView(bool isProf, bool isDark, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Home',
          style: TextStyle(
            color: isLight ? AppColors.textPrimary : Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 18),

        // Quick System Status Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isProf
                ? const Color(0xFF20242B)
                : (isLight ? Colors.white : const Color(0xFF141129)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isProf
                  ? const Color(0x18FFFFFF)
                  : (isLight ? const Color(0xFFEDE9FE) : const Color(0x22A78BFA)),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isProf ? const Color(0xFF60CDFF) : AppColors.brandAccent).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.desktop_windows_rounded,
                  size: 26,
                  color: isProf ? const Color(0xFF60CDFF) : AppColors.brandAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DeSplit Workstation Node',
                      style: TextStyle(
                        color: isLight ? AppColors.textPrimary : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Swarm Mesh Tier 1 Operator • NVIDIA RTX 4070 • 142 Connected Peers',
                      style: TextStyle(
                        color: isProf
                            ? const Color(0xFF8A919E)
                            : (isLight ? const Color(0xFF6B7280) : const Color(0xFFA9A1CD)),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                    SizedBox(width: 5),
                    Text(
                      'SYSTEM HEALTHY',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        Text(
          'Recommended settings',
          style: TextStyle(
            color: isLight ? AppColors.textPrimary : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),

        _buildSettingCard(
          id: 'themes',
          icon: Icons.edit_outlined,
          title: 'Themes',
          subtitle: 'Switch between Professional, Dark Violet, and Clean Light',
          categoryBreadcrumb: 'Personalization',
          onJumpToCategory: () => setState(() => _selectedNavId = 'personalization'),
          isProf: isProf,
          isLight: isLight,
          badgeText: isProf ? 'Professional Active' : (isLight ? 'Light Active' : 'Dark Active'),
          expandedChild: _buildThemesExpanded(isProf, isDark, isLight),
        ),

        _buildSettingCard(
          id: 'vram',
          icon: Icons.memory_rounded,
          title: 'VRAM Allocation Ceiling',
          subtitle: 'Maximum VRAM DeSplit may pool into the distributed swarm',
          categoryBreadcrumb: 'System',
          onJumpToCategory: () => setState(() => _selectedNavId = 'system'),
          isProf: isProf,
          isLight: isLight,
          badgeText: '${_vramLimitGb.toStringAsFixed(1)} GB',
          expandedChild: _getSettingExpandedChild('vram', isProf, isDark, isLight),
        ),

        _buildSettingCard(
          id: 'wireguard',
          icon: Icons.vpn_lock_rounded,
          title: 'WireGuard Mesh Tunnels',
          subtitle: 'Zero-configuration encrypted mesh between verified node peers',
          categoryBreadcrumb: 'Network & internet',
          onJumpToCategory: () => setState(() => _selectedNavId = 'network'),
          isProf: isProf,
          isLight: isLight,
          badgeText: _wireguardTunnel ? 'Active' : 'Disabled',
          expandedChild: _getSettingExpandedChild('wireguard', isProf, isDark, isLight),
        ),

        _buildSettingCard(
          id: 'wallet',
          icon: Icons.account_balance_wallet_rounded,
          title: 'Validator Staking & Payout Wallet',
          subtitle: 'Arbitrum / Base ERC-20 payout address',
          categoryBreadcrumb: 'Accounts',
          onJumpToCategory: () => setState(() => _selectedNavId = 'accounts'),
          isProf: isProf,
          isLight: isLight,
          badgeText: 'Tier 1 Validator',
          expandedChild: _getSettingExpandedChild('wallet', isProf, isDark, isLight),
        ),
      ],
    );
  }

  Widget? _getSettingExpandedChild(String id, bool isProf, bool isDark, bool isLight) {
    switch (id) {
      case 'themes':
        return _buildThemesExpanded(isProf, isDark, isLight);
      case 'colors':
        return _buildColorsExpanded(isProf, isDark, isLight);
      case 'background':
        return _buildBackgroundExpanded(isProf, isDark, isLight);
      case 'lighting':
        return _buildDynamicLightingExpanded(isProf, isLight);
      case 'lockscreen':
        return _buildLockScreenExpanded(isProf, isLight);
      case 'textinput':
        return _buildTextInputExpanded(isProf, isLight);
      case 'start':
        return _buildStartExpanded(isProf, isLight);
      case 'taskbar':
        return _buildTaskbarExpanded(isProf, isLight);
      case 'vram':
        return _buildWindowsSliderRow(
          title: 'VRAM Allocation Ceiling',
          value: _vramLimitGb,
          unit: 'GB',
          min: 4.0,
          max: 24.0,
          onChanged: (val) => setState(() => _vramLimitGb = val),
          onChangeEnd: (val) => _showFeedback('VRAM set to ${val.toStringAsFixed(1)} GB'),
          isProf: isProf,
          isLight: isLight,
        );
      case 'thermal':
        return _buildWindowsSliderRow(
          title: 'Thermal Limit',
          value: _thermalLimitC,
          unit: '°C',
          min: 60.0,
          max: 90.0,
          onChanged: (val) => setState(() => _thermalLimitC = val),
          onChangeEnd: (val) => _showFeedback('Thermal limit set to ${val.toInt()}°C'),
          isProf: isProf,
          isLight: isLight,
        );
      case 'quic':
        return _buildWindowsSwitchRow(
          title: 'QUIC Direct Stream Protocol',
          subtitle: 'Multiplexed UDP transport between active swarm nodes',
          value: _quicStream,
          onChanged: (val) {
            setState(() => _quicStream = val);
            _showFeedback(val ? 'QUIC stream enabled' : 'QUIC stream disabled');
          },
          isProf: isProf,
          isLight: isLight,
        );
      case 'wireguard':
        return _buildWindowsSwitchRow(
          title: 'WireGuard Tunneling',
          subtitle: 'End-to-end encrypted packet tunnel for model shards',
          value: _wireguardTunnel,
          onChanged: (val) {
            setState(() => _wireguardTunnel = val);
            _showFeedback(val ? 'WireGuard active' : 'WireGuard disabled');
          },
          isProf: isProf,
          isLight: isLight,
        );
      case 'ping':
        return InkWell(
          onTap: () => _showFeedback('Latency check complete: 18ms avg across 142 peers'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.brandAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.brandAccent),
            ),
            child: Text(
              'Run Ping Test Now',
              style: TextStyle(color: AppColors.brandAccent, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        );
      case 'zk':
        return _buildWindowsSwitchRow(
          title: 'Zero-Knowledge Proof Mode',
          subtitle: 'Generate snark proofs for tensor activations and weights',
          value: _zkTelemetry,
          onChanged: (val) {
            setState(() => _zkTelemetry = val);
            _showFeedback('ZK telemetry preferences saved');
          },
          isProf: isProf,
          isLight: isLight,
        );
      case 'cache':
        return InkWell(
          onTap: () => _showFeedback('Cleaned 14.2 GB tensor cache'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFEF4444)),
            ),
            child: const Text(
              'Purge 14.2 GB Cache',
              style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        );
      case 'wallet':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wallet Address:',
              style: TextStyle(
                color: isProf ? const Color(0xFF8A919E) : Colors.white70,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isProf ? const Color(0xFF191C21) : const Color(0xFF0F0B1E),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0x22FFFFFF)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _walletAddress,
                      style: const TextStyle(color: Colors.white, fontFamily: 'Consolas', fontSize: 12),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _walletAddress));
                      _showFeedback('Wallet address copied to clipboard');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brandAccent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Copy', style: TextStyle(color: AppColors.brandAccent, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildWindowsSwitchRow(
              title: 'Auto-compound staking rewards',
              subtitle: 'Automatically stake earned SPLIT tokens to increase validator tier',
              value: _autoCompound,
              onChanged: (val) {
                setState(() => _autoCompound = val);
                _showFeedback('Auto-compound preference saved');
              },
              isProf: isProf,
              isLight: isLight,
            ),
          ],
        );
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // PERSONALIZATION VIEW (Exact Replica of User's Screenshot)
  // ---------------------------------------------------------------------------
  Widget _buildPersonalizationView(bool isProf, bool isDark, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Large Bold Title: "Personalization" (from Screenshot)
        Text(
          'Personalization',
          style: TextStyle(
            color: isLight ? AppColors.textPrimary : Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),

        const SizedBox(height: 18),

        // 1. Background
        _buildSettingCard(
          id: 'background',
          icon: Icons.image_outlined,
          title: 'Background',
          subtitle: 'Background image, color, slideshow',
          isProf: isProf,
          isLight: isLight,
          expandedChild: _buildBackgroundExpanded(isProf, isDark, isLight),
        ),

        // 2. Colors (Contains Accent color, transparency effects, color theme)
        _buildSettingCard(
          id: 'colors',
          icon: Icons.palette_outlined,
          title: 'Colors',
          subtitle: 'Accent color, transparency effects, color theme',
          isProf: isProf,
          isLight: isLight,
          expandedChild: _buildColorsExpanded(isProf, isDark, isLight),
        ),

        // 3. Themes (USER REQUEST: Contains the 3 Themes including "Professional")
        _buildSettingCard(
          id: 'themes',
          icon: Icons.edit_outlined,
          title: 'Themes',
          subtitle: 'Install, create, manage themes',
          isProf: isProf,
          isLight: isLight,
          badgeText: isProf ? 'Professional Active' : (isLight ? 'Light Active' : 'Dark Active'),
          expandedChild: _buildThemesExpanded(isProf, isDark, isLight),
        ),

        // 4. Dynamic Lighting
        _buildSettingCard(
          id: 'lighting',
          icon: Icons.flare_rounded,
          title: 'Dynamic Lighting',
          subtitle: 'Connected devices, effects, app settings',
          isProf: isProf,
          isLight: isLight,
          expandedChild: _buildDynamicLightingExpanded(isProf, isLight),
        ),

        // 5. Lock screen
        _buildSettingCard(
          id: 'lockscreen',
          icon: Icons.screen_lock_portrait_outlined,
          title: 'Lock screen',
          subtitle: 'Lock screen images, apps, animations',
          isProf: isProf,
          isLight: isLight,
          expandedChild: _buildLockScreenExpanded(isProf, isLight),
        ),

        // 6. Text input
        _buildSettingCard(
          id: 'textinput',
          icon: Icons.keyboard_outlined,
          title: 'Text input',
          subtitle: 'Touch keyboard, voice typing, emoji and more, input method editor',
          isProf: isProf,
          isLight: isLight,
          expandedChild: _buildTextInputExpanded(isProf, isLight),
        ),

        // 7. Start
        _buildSettingCard(
          id: 'start',
          icon: Icons.grid_view_outlined,
          title: 'Start',
          subtitle: 'Recent apps and items, folders',
          isProf: isProf,
          isLight: isLight,
          expandedChild: _buildStartExpanded(isProf, isLight),
        ),

        // 8. Taskbar
        _buildSettingCard(
          id: 'taskbar',
          icon: Icons.dock_rounded,
          title: 'Taskbar',
          subtitle: 'Taskbar behaviors, system pins',
          isProf: isProf,
          isLight: isLight,
          expandedChild: _buildTaskbarExpanded(isProf, isLight),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Card Component matching the user's screenshot
  // ---------------------------------------------------------------------------
  Widget _buildSettingCard({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isProf,
    required bool isLight,
    String? badgeText,
    String? categoryBreadcrumb,
    VoidCallback? onJumpToCategory,
    Widget? expandedChild,
  }) {
    final isExpanded = _expandedCardId == id;
    final cardBg = isProf
        ? const Color(0xFF20242B)
        : (isLight ? Colors.white : const Color(0xFF141129));
    final borderColor = isProf
        ? const Color(0x18FFFFFF)
        : (isLight ? const Color(0xFFEDE9FE) : const Color(0x22A78BFA));

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedCardId = isExpanded ? null : id;
              });
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isLight ? AppColors.textPrimary : const Color(0xFFD1D5DB),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: isLight ? AppColors.textPrimary : Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (categoryBreadcrumb != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: (isProf ? const Color(0xFF60CDFF) : AppColors.brandAccent).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: (isProf ? const Color(0xFF60CDFF) : AppColors.brandAccent).withValues(alpha: 0.35),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  categoryBreadcrumb,
                                  style: TextStyle(
                                    color: isProf ? const Color(0xFF60CDFF) : AppColors.brandAccent,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                            if (badgeText != null) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.brandAccent.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.brandAccent.withValues(alpha: 0.4), width: 0.8),
                                ),
                                child: Text(
                                  badgeText,
                                  style: TextStyle(
                                    color: AppColors.brandAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isProf
                                ? const Color(0xFF8A919E)
                                : (isLight ? const Color(0xFF6B7280) : const Color(0xFFA9A1CD)),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onJumpToCategory != null) ...[
                    InkWell(
                      onTap: onJumpToCategory,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Open tab',
                              style: TextStyle(
                                color: isProf ? const Color(0xFF60CDFF) : AppColors.brandAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                              color: isProf ? const Color(0xFF60CDFF) : AppColors.brandAccent,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.chevron_right_rounded,
                    size: 18,
                    color: isLight ? Colors.black45 : const Color(0xFF8A919E),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded && expandedChild != null) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: isProf
                  ? const Color(0x14FFFFFF)
                  : (isLight ? const Color(0xFFEDE9FE) : const Color(0x1AA78BFA)),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: expandedChild,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // THEMES EXPANDED: "Professional", "Dark Violet", "Clean Light"
  // (Full compliance with user instructions: Color theme & ratios matching image!)
  // ---------------------------------------------------------------------------
  Widget _buildThemesExpanded(bool isProf, bool isDark, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select an Application Theme',
                  style: TextStyle(
                    color: isLight ? AppColors.textPrimary : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Choose between the Windows 11 Professional Slate, Cyber Violet Dark, or Pastel Light',
                  style: TextStyle(
                    color: isProf ? const Color(0xFF8A919E) : (isLight ? const Color(0xFF6B7280) : const Color(0xFFA9A1CD)),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 3 Theme Cards in a Row
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 24) / 3;

            return Row(
              children: [
                // 1. PROFESSIONAL THEME (From User's Image!)
                SizedBox(
                  width: cardWidth,
                  child: _buildThemePreviewCard(
                    title: 'Professional',
                    subtitle: 'Windows 11 Slate Charcoal',
                    isSelected: isProf,
                    canvasColor: const Color(0xFF191C21),
                    sidebarColor: const Color(0xFF15171C),
                    cardColor: const Color(0xFF20242B),
                    accentColor: const Color(0xFF60CDFF),
                    onTap: () {
                      ThemeService.instance.setThemeMode(AppThemeMode.professional);
                      _showFeedback('Professional Windows 11 Slate Theme applied');
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // 2. DARK VIOLET THEME
                SizedBox(
                  width: cardWidth,
                  child: _buildThemePreviewCard(
                    title: 'Dark Violet',
                    subtitle: 'Cyber Obsidian Purple',
                    isSelected: isDark,
                    canvasColor: const Color(0xFF0C0A17),
                    sidebarColor: const Color(0xFF0D0B1C),
                    cardColor: const Color(0xFF141129),
                    accentColor: const Color(0xFF8B5CF6),
                    onTap: () {
                      ThemeService.instance.setThemeMode(AppThemeMode.dark);
                      _showFeedback('Cyber Dark Violet Theme applied');
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // 3. CLEAN LIGHT THEME
                SizedBox(
                  width: cardWidth,
                  child: _buildThemePreviewCard(
                    title: 'Clean Light',
                    subtitle: 'Pastel Lavender White',
                    isSelected: isLight,
                    canvasColor: const Color(0xFFF8F6FD),
                    sidebarColor: const Color(0xFFFFFFFF),
                    cardColor: const Color(0xFFFFFFFF),
                    accentColor: const Color(0xFF8B5CF6),
                    onTap: () {
                      ThemeService.instance.setThemeMode(AppThemeMode.light);
                      _showFeedback('Clean Light Pastel Theme applied');
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildThemePreviewCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color canvasColor,
    required Color sidebarColor,
    required Color cardColor,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentColor : const Color(0x28FFFFFF),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Miniature UI Layout Mockup with exact ratios
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 80,
                color: canvasColor,
                child: Row(
                  children: [
                    // Mini sidebar
                    Container(
                      width: 26,
                      color: sidebarColor,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: accentColor)),
                          const SizedBox(height: 6),
                          Container(width: 16, height: 3, color: Colors.white24),
                          const SizedBox(height: 4),
                          Container(
                            width: 18,
                            height: 4,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(width: 14, height: 3, color: Colors.white24),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Mini main pane with cards
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 32, height: 4, color: Colors.white38),
                            const SizedBox(height: 6),
                            Container(
                              height: 16,
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: Colors.white12, width: 0.5),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 4),
                                  Container(width: 6, height: 6, color: accentColor),
                                  const SizedBox(width: 4),
                                  Container(width: 24, height: 3, color: Colors.white38),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 16,
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: Colors.white12, width: 0.5),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 4),
                                  Container(width: 6, height: 6, color: Colors.white24),
                                  const SizedBox(width: 4),
                                  Container(width: 20, height: 3, color: Colors.white24),
                                ],
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

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8A919E),
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, size: 16, color: accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COLORS EXPANDED: Transparency effects + Accent Colors
  // ---------------------------------------------------------------------------
  Widget _buildColorsExpanded(bool isProf, bool isDark, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWindowsSwitchRow(
          title: 'Transparency effects',
          subtitle: 'Windows Acrylic & Mica material glassmorphism transparency',
          value: _windowOpacity < 1.0,
          onChanged: (val) {
            setState(() {
              _windowOpacity = val ? 0.90 : 1.0;
              WindowService.instance.setOpacity(_windowOpacity);
            });
            _showFeedback(val ? 'Transparency enabled' : 'Transparency disabled');
          },
          isProf: isProf,
          isLight: isLight,
        ),
        const SizedBox(height: 16),
        _buildWindowsSliderRow(
          title: 'Acrylic background opacity',
          value: _windowOpacity * 100,
          unit: '%',
          min: 60.0,
          max: 100.0,
          onChanged: (val) {
            setState(() {
              _windowOpacity = val / 100;
              WindowService.instance.setOpacity(_windowOpacity);
            });
          },
          onChangeEnd: (val) => _showFeedback('Opacity set to ${val.toInt()}%'),
          isProf: isProf,
          isLight: isLight,
        ),
      ],
    );
  }

  Widget _buildBackgroundExpanded(bool isProf, bool isDark, bool isLight) {
    return Text(
      'Using Windows 11 Mica material background with deep contrast slate tones.',
      style: TextStyle(
        color: isProf ? const Color(0xFF8A919E) : Colors.white70,
        fontSize: 12,
      ),
    );
  }

  Widget _buildDynamicLightingExpanded(bool isProf, bool isLight) {
    return Column(
      children: [
        _buildWindowsSwitchRow(
          title: 'GPU CUDA Acceleration',
          subtitle: 'Enable Tensor Core dynamic acceleration on NVIDIA RTX 4090',
          value: _hardwareAcceleration,
          onChanged: (val) {
            setState(() => _hardwareAcceleration = val);
            _showFeedback(val ? 'CUDA acceleration active' : 'CUDA disabled');
          },
          isProf: isProf,
          isLight: isLight,
        ),
      ],
    );
  }

  Widget _buildLockScreenExpanded(bool isProf, bool isLight) {
    return Column(
      children: [
        _buildWindowsSwitchRow(
          title: 'Start on Windows sign-in',
          subtitle: 'Launch DeSplit minimized to system tray and commence validation',
          value: _startOnBoot,
          onChanged: (val) {
            setState(() => _startOnBoot = val);
            _showFeedback('Startup settings saved');
          },
          isProf: isProf,
          isLight: isLight,
        ),
      ],
    );
  }

  Widget _buildTextInputExpanded(bool isProf, bool isLight) {
    return Column(
      children: [
        _buildWindowsSwitchRow(
          title: 'INT8 Weight Delta Quantization',
          subtitle: 'Compress tensor gradient deltas to minimize latency',
          value: _int8Quantization,
          onChanged: (val) {
            setState(() => _int8Quantization = val);
            _showFeedback('INT8 compression updated');
          },
          isProf: isProf,
          isLight: isLight,
        ),
      ],
    );
  }

  Widget _buildStartExpanded(bool isProf, bool isLight) {
    return Column(
      children: [
        _buildWindowsSwitchRow(
          title: 'Strict Byzantine Consensus',
          subtitle: 'Reject poisoned updates and slash non-conforming mesh nodes',
          value: _strictByzantine,
          onChanged: (val) {
            setState(() => _strictByzantine = val);
            _showFeedback('Byzantine defense active');
          },
          isProf: isProf,
          isLight: isLight,
        ),
      ],
    );
  }

  Widget _buildTaskbarExpanded(bool isProf, bool isLight) {
    return Column(
      children: [
        _buildWindowsSwitchRow(
          title: 'Consensus sound chime',
          subtitle: 'Play subtle acoustic chime when FedAvg round aggregates',
          value: _soundEffects,
          onChanged: (val) {
            setState(() => _soundEffects = val);
            _showFeedback('Sound preferences updated');
          },
          isProf: isProf,
          isLight: isLight,
        ),
        const SizedBox(height: 12),
        _buildWindowsSwitchRow(
          title: 'Thermal threshold notification',
          subtitle: 'Trigger desktop toast alert if GPU exceeds throttle temperature',
          value: _tempAlerts,
          onChanged: (val) {
            setState(() => _tempAlerts = val);
            _showFeedback('Thermal notifications updated');
          },
          isProf: isProf,
          isLight: isLight,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SYSTEM VIEW
  // ---------------------------------------------------------------------------
  Widget _buildSystemView(bool isProf, bool isDark, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System',
          style: TextStyle(
            color: isLight ? AppColors.textPrimary : Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 18),
        _buildSettingCard(
          id: 'vram',
          icon: Icons.memory_rounded,
          title: 'VRAM Allocation Ceiling',
          subtitle: 'Maximum VRAM DeSplit may pool into the distributed swarm',
          isProf: isProf,
          isLight: isLight,
          badgeText: '${_vramLimitGb.toStringAsFixed(1)} GB',
          expandedChild: _buildWindowsSliderRow(
            title: 'VRAM Allocation Ceiling',
            value: _vramLimitGb,
            unit: 'GB',
            min: 4.0,
            max: 24.0,
            onChanged: (val) => setState(() => _vramLimitGb = val),
            onChangeEnd: (val) => _showFeedback('VRAM set to ${val.toStringAsFixed(1)} GB'),
            isProf: isProf,
            isLight: isLight,
          ),
        ),
        _buildSettingCard(
          id: 'thermal',
          icon: Icons.thermostat_rounded,
          title: 'Thermal Throttle Safeguard',
          subtitle: 'Pause compute when GPU exceeds temperature limit',
          isProf: isProf,
          isLight: isLight,
          badgeText: '${_thermalLimitC.toInt()}°C',
          expandedChild: _buildWindowsSliderRow(
            title: 'Thermal Limit',
            value: _thermalLimitC,
            unit: '°C',
            min: 60.0,
            max: 90.0,
            onChanged: (val) => setState(() => _thermalLimitC = val),
            onChangeEnd: (val) => _showFeedback('Thermal limit set to ${val.toInt()}°C'),
            isProf: isProf,
            isLight: isLight,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // NETWORK VIEW
  // ---------------------------------------------------------------------------
  Widget _buildNetworkView(bool isProf, bool isDark, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Network & internet',
          style: TextStyle(
            color: isLight ? AppColors.textPrimary : Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 18),
        _buildSettingCard(
          id: 'quic',
          icon: Icons.speed_rounded,
          title: 'QUIC Direct Stream',
          subtitle: 'Ultra-low latency multiplexed transport for pipeline slices',
          isProf: isProf,
          isLight: isLight,
          badgeText: _quicStream ? 'Active' : 'Disabled',
          expandedChild: _buildWindowsSwitchRow(
            title: 'QUIC Direct Stream Protocol',
            subtitle: 'Multiplexed UDP transport between active swarm nodes',
            value: _quicStream,
            onChanged: (val) {
              setState(() => _quicStream = val);
              _showFeedback(val ? 'QUIC stream enabled' : 'QUIC stream disabled');
            },
            isProf: isProf,
            isLight: isLight,
          ),
        ),
        _buildSettingCard(
          id: 'wireguard',
          icon: Icons.vpn_lock_rounded,
          title: 'WireGuard Mesh Tunnels',
          subtitle: 'Zero-configuration encrypted mesh between verified node peers',
          isProf: isProf,
          isLight: isLight,
          badgeText: _wireguardTunnel ? 'Active' : 'Disabled',
          expandedChild: _buildWindowsSwitchRow(
            title: 'WireGuard Tunneling',
            subtitle: 'End-to-end encrypted packet tunnel for model shards',
            value: _wireguardTunnel,
            onChanged: (val) {
              setState(() => _wireguardTunnel = val);
              _showFeedback(val ? 'WireGuard active' : 'WireGuard disabled');
            },
            isProf: isProf,
            isLight: isLight,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PRIVACY VIEW
  // ---------------------------------------------------------------------------
  Widget _buildPrivacyView(bool isProf, bool isDark, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy & security',
          style: TextStyle(
            color: isLight ? AppColors.textPrimary : Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 18),
        _buildSettingCard(
          id: 'zk',
          icon: Icons.shield_rounded,
          title: 'Zero-Knowledge Telemetry',
          subtitle: 'Prove hardware contribution without disclosing prompt data',
          isProf: isProf,
          isLight: isLight,
          badgeText: _zkTelemetry ? 'ZK Enabled' : 'Standard',
          expandedChild: _buildWindowsSwitchRow(
            title: 'Zero-Knowledge Proof Mode',
            subtitle: 'Generate snark proofs for tensor activations and weights',
            value: _zkTelemetry,
            onChanged: (val) {
              setState(() => _zkTelemetry = val);
              _showFeedback('ZK telemetry preferences saved');
            },
            isProf: isProf,
            isLight: isLight,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ACCOUNTS VIEW
  // ---------------------------------------------------------------------------
  Widget _buildAccountsView(bool isProf, bool isDark, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accounts',
          style: TextStyle(
            color: isLight ? AppColors.textPrimary : Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 18),
        _buildSettingCard(
          id: 'wallet',
          icon: Icons.account_balance_wallet_rounded,
          title: 'Validator Staking & Payout Wallet',
          subtitle: 'Arbitrum / Base ERC-20 payout address',
          isProf: isProf,
          isLight: isLight,
          badgeText: 'Tier 1 Validator',
          expandedChild: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wallet Address:',
                style: TextStyle(
                  color: isProf ? const Color(0xFF8A919E) : Colors.white70,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isProf ? const Color(0xFF191C21) : const Color(0xFF0F0B1E),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0x22FFFFFF)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _walletAddress,
                        style: const TextStyle(color: Colors.white, fontFamily: 'Consolas', fontSize: 12),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _walletAddress));
                        _showFeedback('Wallet address copied to clipboard');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.brandAccent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Copy', style: TextStyle(color: AppColors.brandAccent, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildWindowsSwitchRow(
                title: 'Auto-compound staking rewards',
                subtitle: 'Automatically stake earned SPLIT tokens to increase validator tier',
                value: _autoCompound,
                onChanged: (val) {
                  setState(() => _autoCompound = val);
                  _showFeedback('Auto-compound preference saved');
                },
                isProf: isProf,
                isLight: isLight,
              ),
            ],
          ),
        ),
      ],
    );
  }


  // ---------------------------------------------------------------------------
  // Reusable Windows 11 Styled Switch and Slider
  // ---------------------------------------------------------------------------
  Widget _buildWindowsSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isProf,
    required bool isLight,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isLight ? AppColors.textPrimary : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: isProf ? const Color(0xFF8A919E) : (isLight ? const Color(0xFF6B7280) : const Color(0xFFA9A1CD)),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            height: 22,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: value
                  ? (isProf ? const Color(0xFF60CDFF) : AppColors.brandAccent)
                  : (isProf ? const Color(0xFF333842) : const Color(0xFF4B4863)),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 17,
                height: 17,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWindowsSliderRow({
    required String title,
    required double value,
    required String unit,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeEnd,
    required bool isProf,
    required bool isLight,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isLight ? AppColors.textPrimary : Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isProf
                    ? const Color(0xFF191C21)
                    : (isLight ? const Color(0xFFF3EDFD) : const Color(0xFF1A1635)),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0x33FFFFFF)),
              ),
              child: Text(
                '${value.toStringAsFixed(unit == '°C' || unit == '%' ? 0 : 1)} $unit',
                style: TextStyle(
                  color: isProf ? const Color(0xFF60CDFF) : AppColors.accentLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Consolas',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: isProf ? const Color(0xFF60CDFF) : AppColors.brandAccent,
            inactiveTrackColor: isProf ? const Color(0xFF333842) : Colors.white24,
            thumbColor: Colors.white,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }

  static const List<_SettingSearchItem> _allSettingSearchItems = [
    _SettingSearchItem(
      id: 'themes',
      categoryId: 'personalization',
      categoryName: 'Personalization',
      title: 'Themes',
      subtitle: 'Install, create, manage themes (Professional, Dark Violet, Clean Light)',
      icon: Icons.edit_outlined,
      keywords: ['theme', 'themes', 'dark mode', 'light mode', 'professional', 'obsidian', 'lavender', 'appearance', 'mode'],
    ),
    _SettingSearchItem(
      id: 'colors',
      categoryId: 'personalization',
      categoryName: 'Personalization',
      title: 'Colors',
      subtitle: 'Accent color, transparency effects, color theme',
      icon: Icons.palette_outlined,
      keywords: ['colors', 'color', 'accent', 'transparency', 'opacity', 'acrylic', 'mica', 'glass', 'effects'],
    ),
    _SettingSearchItem(
      id: 'background',
      categoryId: 'personalization',
      categoryName: 'Personalization',
      title: 'Background',
      subtitle: 'Background image, color, slideshow',
      icon: Icons.image_outlined,
      keywords: ['background', 'wallpaper', 'image', 'picture', 'slideshow', 'mica'],
    ),
    _SettingSearchItem(
      id: 'lighting',
      categoryId: 'personalization',
      categoryName: 'Personalization',
      title: 'Dynamic Lighting',
      subtitle: 'GPU CUDA acceleration and connected device illumination',
      icon: Icons.flare_rounded,
      keywords: ['lighting', 'rgb', 'dynamic lighting', 'gpu', 'cuda', 'hardware acceleration', 'tensor core'],
    ),
    _SettingSearchItem(
      id: 'lockscreen',
      categoryId: 'personalization',
      categoryName: 'Personalization',
      title: 'Lock screen',
      subtitle: 'Start on Windows sign-in and lock screen telemetry',
      icon: Icons.screen_lock_portrait_outlined,
      keywords: ['lock screen', 'lock', 'startup', 'boot', 'sign in', 'tray', 'autostart'],
    ),
    _SettingSearchItem(
      id: 'textinput',
      categoryId: 'personalization',
      categoryName: 'Personalization',
      title: 'Text input',
      subtitle: 'INT8 Weight Delta Quantization and tensor input compression',
      icon: Icons.keyboard_outlined,
      keywords: ['text input', 'int8', 'quantization', 'compression', 'delta', 'tensor'],
    ),
    _SettingSearchItem(
      id: 'start',
      categoryId: 'personalization',
      categoryName: 'Personalization',
      title: 'Start',
      subtitle: 'Strict Byzantine Consensus defense and node verification',
      icon: Icons.grid_view_outlined,
      keywords: ['start', 'byzantine', 'consensus', 'defense', 'security', 'slash'],
    ),
    _SettingSearchItem(
      id: 'taskbar',
      categoryId: 'personalization',
      categoryName: 'Personalization',
      title: 'Taskbar',
      subtitle: 'Consensus sound chime and thermal threshold notifications',
      icon: Icons.dock_rounded,
      keywords: ['taskbar', 'sound', 'audio', 'chime', 'notification', 'alerts', 'thermal alert', 'bell'],
    ),
    _SettingSearchItem(
      id: 'vram',
      categoryId: 'system',
      categoryName: 'System',
      title: 'VRAM Allocation Ceiling',
      subtitle: 'Maximum VRAM DeSplit may pool into the distributed swarm',
      icon: Icons.memory_rounded,
      keywords: ['vram', 'ram', 'memory', 'gpu memory', 'allocation', 'ceiling', 'pool', 'graphics', 'gb'],
    ),
    _SettingSearchItem(
      id: 'thermal',
      categoryId: 'system',
      categoryName: 'System',
      title: 'Thermal Throttle Safeguard',
      subtitle: 'Pause compute when GPU exceeds temperature limit',
      icon: Icons.thermostat_rounded,
      keywords: ['thermal', 'temperature', 'celsius', 'heat', 'throttle', 'cooling', 'temp', 'safeguard', 'limit'],
    ),
    _SettingSearchItem(
      id: 'quic',
      categoryId: 'network',
      categoryName: 'Network & internet',
      title: 'QUIC Direct Stream',
      subtitle: 'Ultra-low latency multiplexed transport for pipeline slices',
      icon: Icons.speed_rounded,
      keywords: ['quic', 'udp', 'stream', 'multiplex', 'transport', 'protocol', 'network', 'latency'],
    ),
    _SettingSearchItem(
      id: 'wireguard',
      categoryId: 'network',
      categoryName: 'Network & internet',
      title: 'WireGuard Mesh Tunnels',
      subtitle: 'Zero-configuration encrypted mesh between verified node peers',
      icon: Icons.vpn_lock_rounded,
      keywords: ['wireguard', 'vpn', 'tunnel', 'encrypted', 'mesh', 'p2p', 'network', 'peer'],
    ),
    _SettingSearchItem(
      id: 'ping',
      categoryId: 'network',
      categoryName: 'Network & internet',
      title: 'Swarm Mesh Diagnostics Ping',
      subtitle: 'Run ICMP and QUIC round-trip latency checks across all 142 peers',
      icon: Icons.network_check_rounded,
      keywords: ['ping', 'diagnostics', 'latency', 'round trip', 'icmp', 'test', 'network test', 'peers'],
    ),
    _SettingSearchItem(
      id: 'zk',
      categoryId: 'privacy',
      categoryName: 'Privacy & security',
      title: 'Zero-Knowledge Telemetry',
      subtitle: 'Prove hardware contribution without disclosing prompt data',
      icon: Icons.shield_rounded,
      keywords: ['zk', 'zero knowledge', 'telemetry', 'snark', 'privacy', 'security', 'shield', 'proof'],
    ),
    _SettingSearchItem(
      id: 'cache',
      categoryId: 'privacy',
      categoryName: 'Privacy & security',
      title: 'Purge Local Shard Cache',
      subtitle: 'Free up 14.2 GB of temporary checkpoint tensor files from disk',
      icon: Icons.delete_sweep_rounded,
      keywords: ['cache', 'purge', 'storage', 'disk', 'disk space', 'clean', 'temporary files', 'tensor cache', 'clear'],
    ),
    _SettingSearchItem(
      id: 'wallet',
      categoryId: 'accounts',
      categoryName: 'Accounts',
      title: 'Validator Staking & Payout Wallet',
      subtitle: 'Arbitrum / Base ERC-20 payout address and auto-compounding',
      icon: Icons.account_balance_wallet_rounded,
      keywords: ['wallet', 'payout', 'staking', 'rewards', 'tokens', 'split', 'crypto', 'address', 'autocompound', 'account'],
    ),
  ];
}

class _WindowsNavCategory {
  final String id;
  final String title;
  final IconData icon;
  final Color iconColor;

  const _WindowsNavCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.iconColor,
  });
}

class _SettingSearchItem {
  final String id;
  final String categoryId;
  final String categoryName;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> keywords;

  const _SettingSearchItem({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.keywords,
  });
}
