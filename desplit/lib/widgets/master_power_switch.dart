import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Interactive high-tech toggle switch located in the top-right corner.
/// Toggles the node / compute engine state between ON (Active) and OFF (Standby).
class MasterPowerSwitch extends StatefulWidget {
  final bool? value;
  final bool initialValue;
  final ValueChanged<bool>? onChanged;

  const MasterPowerSwitch({
    super.key,
    this.value,
    this.initialValue = true,
    this.onChanged,
  });

  @override
  State<MasterPowerSwitch> createState() => _MasterPowerSwitchState();
}

class _MasterPowerSwitchState extends State<MasterPowerSwitch> {
  late bool _internalOn;
  bool _isHovered = false;

  bool get _isOn => widget.value ?? _internalOn;

  @override
  void initState() {
    super.initState();
    _internalOn = widget.value ?? widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant MasterPowerSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != null) {
      _internalOn = widget.value!;
    } else if (widget.initialValue != oldWidget.initialValue) {
      _internalOn = widget.initialValue;
    }
  }

  void _toggle() {
    final nextVal = !_isOn;
    if (widget.value == null) {
      setState(() {
        _internalOn = nextVal;
      });
    }
    widget.onChanged?.call(nextVal);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _toggle,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _isOn
                ? AppColors.cardSurface.withValues(alpha: 0.85)
                : AppColors.cardSurfaceLight.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isOn
                  ? (_isHovered ? AppColors.accentLight : AppColors.borderGlow)
                  : (_isHovered
                      ? AppColors.borderSubtle
                      : AppColors.borderSubtle.withValues(alpha: 0.5)),
              width: 1.2,
            ),
            boxShadow: _isOn
                ? [
                    BoxShadow(
                      color: AppColors.brandAccent.withValues(
                        alpha: _isHovered ? 0.35 : 0.20,
                      ),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status Indicator Dot with animated glow
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isOn ? AppColors.statusActive : AppColors.statusInactive,
                  boxShadow: _isOn
                      ? [
                          BoxShadow(
                            color: AppColors.statusActive.withValues(alpha: 0.8),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
              ),

              const SizedBox(width: 8),

              // Status Text
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  color: _isOn ? AppColors.textPrimary : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  fontFamily: 'Segoe UI',
                ),
                child: Text(_isOn ? 'ONLINE' : 'OFFLINE'),
              ),

              const SizedBox(width: 10),

              // The Switch Capsule
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOutCubic,
                width: 44,
                height: 24,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: _isOn
                      ? LinearGradient(
                          colors: [
                            AppColors.brandAccent,
                            AppColors.accentHover,
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            AppColors.switchTrackInactive,
                            AppColors.switchTrackInactive.withValues(alpha: 0.7),
                          ],
                        ),
                  border: Border.all(
                    color: _isOn
                        ? AppColors.accentLight.withValues(alpha: 0.8)
                        : AppColors.borderSubtle,
                    width: 1.0,
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOutCubic,
                  alignment:
                      _isOn ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: _isOn
                              ? AppColors.accentNeon.withValues(alpha: 0.8)
                              : Colors.black.withValues(alpha: 0.4),
                          blurRadius: _isOn ? 8 : 4,
                          spreadRadius: _isOn ? 1 : 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isOn ? Icons.power_settings_new_rounded : Icons.circle,
                        size: 11,
                        color: _isOn
                            ? AppColors.brandAccent
                            : const Color(0xFF6B648C),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
