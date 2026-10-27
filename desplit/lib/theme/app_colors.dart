import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class AppColors {
  // Brand color specifications
  static AppThemeData get current => ThemeService.instance.currentTheme;
  static bool get isLight => ThemeService.instance.isLight;
  static bool get isDark => ThemeService.instance.isDark;
  static bool get isProfessional => ThemeService.instance.isProfessional;

  static Color get brandAccent => current.brandAccent;
  static Color get accentHover => current.accentHover;
  static Color get accentLight => current.accentLight;
  static Color get accentNeon => current.accentNeon;
  static Color get accentPale => current.accentPale;

  // Canvas & Background
  static Color get canvasBackground => current.canvasBackground;
  static Color get windowTranslucent => current.windowTranslucent;
  static Color get sidebarBg => current.sidebarBg;
  static Color get topBarBg => current.topBarBg;
  static Color get menuBarBg => current.menuBarBg;

  // Text Colors
  static Color get textPrimary => current.textPrimary;
  static Color get textSecondary => current.textSecondary;
  static Color get textMuted => current.textMuted;
  static Color get textDisabled => current.textDisabled;

  // Surface Cards & Glass Panels
  static Color get cardSurface => current.cardSurface;
  static Color get cardSurfaceLight => current.cardSurfaceLight;
  static Color get cardSurfaceHover => current.cardSurfaceHover;

  // Borders & Glows
  static Color get borderSubtle => current.borderSubtle;
  static Color get borderGlow => current.borderGlow;
  static Color get borderActive => current.borderActive;

  // Atmospheric Violet Gradient Aura
  static Color get auraCenter => current.auraCenter;
  static Color get auraMid => current.auraMid;
  static Color get auraOuter => current.auraOuter;

  // Status & Switch Indicators
  static Color get statusActive => current.statusActive;
  static Color get statusActiveGlow => current.statusActiveGlow;
  static Color get statusInactive => current.statusInactive;
  static Color get progressTrack => current.progressTrack;

  // Switch Toggle specific
  static Color get switchTrackActive => current.switchTrackActive;
  static Color get switchTrackInactive => current.switchTrackInactive;
  static const Color switchKnob = Color(0xFFFFFFFF);
  static const Color switchKnobGlow = Color(0x99C084FC);
}
