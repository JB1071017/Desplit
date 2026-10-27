import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import 'telemetry_chart_painter.dart';

class TelemetryGraphCard extends StatefulWidget {
  final String title;
  final bool hasDropdown;
  final String currentValueText;
  final String? rightLabel;
  final List<double> dataPoints;
  final double maxValue;
  final double height;
  final List<String>? tooltipDetails;

  const TelemetryGraphCard({
    super.key,
    required this.title,
    this.hasDropdown = true,
    required this.currentValueText,
    this.rightLabel,
    required this.dataPoints,
    this.maxValue = 100.0,
    this.height = 130.0,
    this.tooltipDetails,
  });

  @override
  State<TelemetryGraphCard> createState() => _TelemetryGraphCardState();
}

class _TelemetryGraphCardState extends State<TelemetryGraphCard> {
  double? _hoverNormalizedX;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isHovered ? AppColors.accentLight : AppColors.borderSubtle,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar: e.g. "⌄ 3D" on left, "12%" on right
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (widget.hasDropdown) ...[
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.rightLabel ?? widget.currentValueText,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Graph area with interactive hover
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return MouseRegion(
                  onEnter: (_) => setState(() => _isHovered = true),
                  onExit: (_) => setState(() {
                    _isHovered = false;
                    _hoverNormalizedX = null;
                  }),
                  onHover: (event) {
                    final normalized =
                        (event.localPosition.dx / constraints.maxWidth)
                            .clamp(0.0, 1.0);
                    setState(() {
                      _hoverNormalizedX = normalized;
                    });
                  },
                  child: Stack(
                    children: [
                      // Grid & Waveform CustomPaint
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          child: CustomPaint(
                            painter: TaskManagerChartPainter(
                              dataPoints: widget.dataPoints,
                              maxValue: widget.maxValue,
                              strokeColor: AppColors.brandAccent,
                              fillStartColor: AppColors.brandAccent.withValues(
                                  alpha: AppColors.isLight ? 0.20 : 0.45),
                              fillEndColor: Colors.transparent,
                              gridColor: AppColors.isProfessional
                                  ? AppColors.borderSubtle.withValues(alpha: 0.5)
                                  : (AppColors.isLight
                                      ? const Color(0xFFEDE9FE)
                                      : const Color(0x22A855F7)),
                              hoverNormalizedX: _hoverNormalizedX,
                              gridRows: 4,
                              gridCols: 10,
                            ),
                          ),
                        ),
                      ),

                      // Floating Hover Tooltip
                      if (_isHovered &&
                          _hoverNormalizedX != null &&
                          widget.tooltipDetails != null)
                        _buildFloatingTooltip(constraints),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingTooltip(BoxConstraints constraints) {
    if (constraints.maxWidth < 160 || constraints.maxHeight < 60) {
      return const SizedBox.shrink();
    }
    final xPos = _hoverNormalizedX! * constraints.maxWidth;
    final isRightSide = xPos > (constraints.maxWidth * 0.52);
    final maxOffset = math.max(6.0, constraints.maxWidth - 150.0);

    return Positioned(
      top: 6,
      left: isRightSide ? null : (xPos + 10).clamp(6.0, maxOffset),
      right: isRightSide
          ? (constraints.maxWidth - xPos + 10).clamp(6.0, maxOffset)
          : null,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.isProfessional
                ? const Color(0xF5191C21)
                : (AppColors.isLight
                    ? const Color(0xF8FFFFFF)
                    : const Color(0xF50B0819)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.borderGlow,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: AppColors.isLight ? 0.1 : 0.6),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentLight,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: AppColors.accentLight,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (widget.tooltipDetails != null)
                ...widget.tooltipDetails!.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      line,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
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
