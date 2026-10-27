import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class ContributionGrid extends StatefulWidget {
  final bool isLightMode;

  const ContributionGrid({
    super.key,
    this.isLightMode = false,
  });

  @override
  State<ContributionGrid> createState() => _ContributionGridState();
}

class _ContributionGridState extends State<ContributionGrid> {
  // Pre-generate deterministic contribution activity for 52 weeks x 7 days = 364 days
  late final List<List<int>> _contributionMatrix;

  final List<String> _months = [
    'Nov',
    'Dec',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
  ];

  @override
  void initState() {
    super.initState();
    final random = math.Random(42); // deterministic seed matching image clusters
    _contributionMatrix = List.generate(52, (week) {
      return List.generate(7, (day) {
        // Create realistic clusters of activity
        final inCluster = (week >= 1 && week <= 4) ||
            (week >= 10 && week <= 12) ||
            (week >= 18 && week <= 20) ||
            (week >= 28 && week <= 34) ||
            (week >= 38 && week <= 42) ||
            (week >= 46 && week <= 51);

        if (inCluster) {
          final r = random.nextDouble();
          if (r < 0.25) return 0;
          if (r < 0.50) return 1;
          if (r < 0.75) return 2;
          if (r < 0.90) return 3;
          return 4;
        } else {
          return random.nextDouble() < 0.12 ? 1 : 0;
        }
      });
    });
  }

  Color _getCellColor(int level) {
    if (AppColors.isProfessional) {
      switch (level) {
        case 0:
          return const Color(0xFF262B34); // Slate cell
        case 1:
          return const Color(0xFF0C4A6E); // Deep cyan
        case 2:
          return const Color(0xFF0284C7); // Mid cyan
        case 3:
          return const Color(0xFF0EA5E9); // Bright cyan
        case 4:
          return const Color(0xFF60CDFF); // Windows 11 cyan accent
        default:
          return const Color(0xFF262B34);
      }
    } else if (widget.isLightMode) {
      switch (level) {
        case 0:
          return const Color(0xFFEDE9FE); // Soft pastel lilac
        case 1:
          return const Color(0xFFC4B5FD); // Light violet
        case 2:
          return const Color(0xFFA78BFA); // Medium violet
        case 3:
          return const Color(0xFF7C3AED); // Vibrant dark violet
        case 4:
          return const Color(0xFF4C1D95); // Deep dark violet
        default:
          return const Color(0xFFEDE9FE);
      }
    } else {
      switch (level) {
        case 0:
          return const Color(0xFF1B162E); // Inactive dark node cell
        case 1:
          return const Color(0xFF381559); // Dark deep violet
        case 2:
          return const Color(0xFF5B1F8C); // Rich dark violet
        case 3:
          return const Color(0xFF7E22CE); // Vibrant violet
        case 4:
          return const Color(0xFFA855F7); // Glowing electric violet
        default:
          return const Color(0xFF1B162E);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          // Header with count & stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '210 ',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: 'tensor compute batches in the past year',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message:
                          'Track your node batch verification and tensor compute activity across the global mesh network.',
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    'Total active days: ',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '84',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Max streak: ',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '13',
                    style: TextStyle(
                      color: AppColors.accentLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurfaceLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Current',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Scrollable Heatmap
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 52 columns of 7 days
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(52, (weekIdx) {
                    final weekDays = _contributionMatrix[weekIdx];
                    return Padding(
                      padding: const EdgeInsets.only(right: 3.5),
                      child: Column(
                        children: List.generate(7, (dayIdx) {
                          final level = weekDays[dayIdx];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 3.5),
                            child: Tooltip(
                              message:
                                  'Week ${weekIdx + 1}, Day ${dayIdx + 1}: ${level * 14 + (level > 0 ? 6 : 0)} TFLOPS contributed • ${level * 4} batches',
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.isProfessional
                                    ? const Color(0xFF191C21)
                                    : const Color(0xFF131026),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppColors.borderSubtle),
                              ),
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                              child: Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: _getCellColor(level),
                                  borderRadius: BorderRadius.circular(2.5),
                                  boxShadow: level >= 3
                                      ? [
                                          BoxShadow(
                                            color: _getCellColor(level)
                                                .withValues(alpha: 0.4),
                                            blurRadius: 4,
                                            spreadRadius: 0.5,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 8),

                // Month labels below the grid
                SizedBox(
                  width: 52 * (11 + 3.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _months
                        .map(
                          (m) => Text(
                            m,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Less',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 6),
              ...List.generate(5, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _getCellColor(index),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 6),
              Text(
                'More',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
