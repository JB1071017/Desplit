import 'package:flutter/material.dart';
import '../../services/theme_service.dart';
import '../../theme/app_colors.dart';

class WorkloadView extends StatelessWidget {
  const WorkloadView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: ThemeService.instance.themeModeNotifier,
      builder: (context, themeMode, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // View Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.brandAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderGlow),
                    ),
                child: Icon(
                  Icons.developer_board_rounded,
                  color: AppColors.accentLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compute Workload Manager',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Decentralized model inference, batch execution & sharded GPU tasks',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Overview Status Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth <= 0) return const SizedBox.shrink();
              final isWide = constraints.maxWidth > 700;
              final cardWidth = isWide
                  ? ((constraints.maxWidth - 32) / 3)
                      .clamp(180.0, double.infinity)
                  : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildMetricCard(
                    title: 'ACTIVE TASKS',
                    value: '12 Active',
                    subtitle: '4 pending distributed queue',
                    icon: Icons.sync_rounded,
                    accentColor: AppColors.statusActive,
                    width: cardWidth,
                  ),
                  _buildMetricCard(
                    title: 'GPU ALLOCATION',
                    value: '78.4%',
                    subtitle: 'CUDA Cores Under Load',
                    icon: Icons.memory_rounded,
                    accentColor: AppColors.accentLight,
                    width: cardWidth,
                  ),
                  _buildMetricCard(
                    title: 'AVERAGE LATENCY',
                    value: '18.2 ms',
                    subtitle: 'Local Worker Shards',
                    icon: Icons.speed_rounded,
                    accentColor: AppColors.accentNeon,
                    width: cardWidth,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Pipeline placeholder container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Workload Execution Pipeline',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brandAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Text(
                        'Ready for Workload Modules',
                        style: TextStyle(
                          color: AppColors.accentLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.cardSurfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.borderSubtle,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.dashboard_customize_outlined,
                          size: 38,
                          color: AppColors.accentLight.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Workload Module Ready',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Awaiting next step instructions to configure task pipelines',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 18, color: accentColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
