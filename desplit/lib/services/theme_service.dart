import 'package:flutter/material.dart';

enum AppThemeMode {
  dark,
  light,
  professional,
}

class AppThemeData {
  final AppThemeMode mode;
  final Color canvasBackground;
  final Color windowTranslucent;
  final Color sidebarBg;
  final Color topBarBg;
  final Color menuBarBg;
  final Color cardSurface;
  final Color cardSurfaceLight;
  final Color cardSurfaceHover;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;
  final Color borderSubtle;
  final Color borderGlow;
  final Color borderActive;
  final Color brandAccent;
  final Color accentHover;
  final Color accentLight;
  final Color accentNeon;
  final Color accentPale;
  final Color auraCenter;
  final Color auraMid;
  final Color auraOuter;
  final Color statusActive;
  final Color statusActiveGlow;
  final Color statusInactive;
  final Color progressTrack;
  final Color switchTrackActive;
  final Color switchTrackInactive;

  const AppThemeData({
    required this.mode,
    required this.canvasBackground,
    required this.windowTranslucent,
    required this.sidebarBg,
    required this.topBarBg,
    required this.menuBarBg,
    required this.cardSurface,
    required this.cardSurfaceLight,
    required this.cardSurfaceHover,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.borderSubtle,
    required this.borderGlow,
    required this.borderActive,
    required this.brandAccent,
    required this.accentHover,
    required this.accentLight,
    required this.accentNeon,
    required this.accentPale,
    required this.auraCenter,
    required this.auraMid,
    required this.auraOuter,
    required this.statusActive,
    required this.statusActiveGlow,
    required this.statusInactive,
    required this.progressTrack,
    required this.switchTrackActive,
    required this.switchTrackInactive,
  });

  bool get isLight => mode == AppThemeMode.light;
  bool get isDark => mode == AppThemeMode.dark;
  bool get isProfessional => mode == AppThemeMode.professional;

  // 1. Professional Theme: Exact Windows 11 Settings Slate/Charcoal Theme with Cyan Accent
  static const professionalTheme = AppThemeData(
    mode: AppThemeMode.professional,
    canvasBackground: Color(0xFF191C21), // Windows 11 Slate Dark background
    windowTranslucent: Color(0xF5191C21),
    sidebarBg: Color(0xFF15171C), // Authentic Windows 11 settings left sidebar
    topBarBg: Color(0xFF121418), // Seamless top header
    menuBarBg: Color(0xFF17191E),
    cardSurface: Color(0xFF20242B), // Authentic Windows 11 rounded setting card
    cardSurfaceLight: Color(0xFF262B34),
    cardSurfaceHover: Color(0xFF2C323D),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFD1D5DB),
    textMuted: Color(0xFF8A919E),
    textDisabled: Color(0xFF555B68),
    borderSubtle: Color(0x18FFFFFF), // 9% White hairline border
    borderGlow: Color(0x2860CDFF),
    borderActive: Color(0xFF60CDFF), // Windows 11 signature light blue/cyan
    brandAccent: Color(0xFF60CDFF),
    accentHover: Color(0xFF78D4FF),
    accentLight: Color(0xFF60CDFF),
    accentNeon: Color(0xFF4CC2FF),
    accentPale: Color(0xFFE0F2FE),
    auraCenter: Colors.transparent, // Clean zero-haze for Windows 11 slate theme
    auraMid: Colors.transparent,
    auraOuter: Colors.transparent,
    statusActive: Color(0xFF10B981),
    statusActiveGlow: Color(0x3310B981),
    statusInactive: Color(0xFF555B68),
    progressTrack: Color(0xFF2B303B),
    switchTrackActive: Color(0xFF60CDFF),
    switchTrackInactive: Color(0xFF333842),
  );

  // 2. Dark Theme: Cyber Obsidian Neon Purple
  static const darkTheme = AppThemeData(
    mode: AppThemeMode.dark,
    canvasBackground: Color(0xFF0C0A17),
    windowTranslucent: Color(0xF20B0916),
    sidebarBg: Color(0xF50D0B1C),
    topBarBg: Color(0xFF000000),
    menuBarBg: Color(0xF2110E26),
    cardSurface: Color(0xD9141129),
    cardSurfaceLight: Color(0xF01A1635),
    cardSurfaceHover: Color(0xF51E193E),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFDDD6FE),
    textMuted: Color(0xFFA9A1CD),
    textDisabled: Color(0xFF635E7E),
    borderSubtle: Color(0x30A78BFA),
    borderGlow: Color(0x66A78BFA),
    borderActive: Color(0xFFA78BFA),
    brandAccent: Color(0xFF7C3AED),
    accentHover: Color(0xFF8B5CF6),
    accentLight: Color(0xFFA78BFA),
    accentNeon: Color(0xFFC084FC),
    accentPale: Color(0xFFEDE9FE),
    auraCenter: Color(0x4D8B5CF6),
    auraMid: Color(0x226D28D9),
    auraOuter: Color(0x000A0816),
    statusActive: Color(0xFF00F5A0),
    statusActiveGlow: Color(0x5500F5A0),
    statusInactive: Color(0xFF4B4863),
    progressTrack: Color(0xFF191530),
    switchTrackActive: Color(0xFF7C3AED),
    switchTrackInactive: Color(0xFF1F1C33),
  );

  // 3. Light Theme: Clean Pastel Lavender White
  static const lightTheme = AppThemeData(
    mode: AppThemeMode.light,
    canvasBackground: Color(0xFFF8F6FD),
    windowTranslucent: Color(0xF8F8F6FD),
    sidebarBg: Color(0xFFFFFFFF),
    topBarBg: Color(0xFF16122C), // Deep crisp contrast header
    menuBarBg: Color(0xFFF3EDFD),
    cardSurface: Color(0xFFFFFFFF),
    cardSurfaceLight: Color(0xFFFAF7FE),
    cardSurfaceHover: Color(0xFFF3EBFC),
    textPrimary: Color(0xFF1E1B4B), // Deep royal indigo
    textSecondary: Color(0xFF5B557C),
    textMuted: Color(0xFF8B84B2),
    textDisabled: Color(0xFFC4BDDE),
    borderSubtle: Color(0xFFEDE9FE),
    borderGlow: Color(0xFFDDD6FE),
    borderActive: Color(0xFF8B5CF6),
    brandAccent: Color(0xFF8B5CF6),
    accentHover: Color(0xFF7C3AED),
    accentLight: Color(0xFF7C3AED),
    accentNeon: Color(0xFF9333EA),
    accentPale: Color(0xFFF5F0FE),
    auraCenter: Color(0x288B5CF6),
    auraMid: Color(0x10A855F7),
    auraOuter: Color(0x00F8F6FD),
    statusActive: Color(0xFF10B981),
    statusActiveGlow: Color(0x4410B981),
    statusInactive: Color(0xFF9CA3AF),
    progressTrack: Color(0xFFE9D5FF),
    switchTrackActive: Color(0xFF8B5CF6),
    switchTrackInactive: Color(0xFFE5E7EB),
  );
}

class ThemeService {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  final ValueNotifier<AppThemeMode> themeModeNotifier =
      ValueNotifier<AppThemeMode>(AppThemeMode.professional); // Default to Professional theme

  AppThemeMode get currentMode => themeModeNotifier.value;
  bool get isLight => currentMode == AppThemeMode.light;
  bool get isDark => currentMode == AppThemeMode.dark;
  bool get isProfessional => currentMode == AppThemeMode.professional;

  AppThemeData get currentTheme {
    switch (currentMode) {
      case AppThemeMode.light:
        return AppThemeData.lightTheme;
      case AppThemeMode.professional:
        return AppThemeData.professionalTheme;
      case AppThemeMode.dark:
        return AppThemeData.darkTheme;
    }
  }

  void setThemeMode(AppThemeMode mode) {
    if (themeModeNotifier.value != mode) {
      themeModeNotifier.value = mode;
    }
  }

  void toggleTheme() {
    if (isProfessional) {
      setThemeMode(AppThemeMode.dark);
    } else if (isDark) {
      setThemeMode(AppThemeMode.light);
    } else {
      setThemeMode(AppThemeMode.professional);
    }
  }
}
