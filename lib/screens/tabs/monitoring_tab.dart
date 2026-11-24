import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/status_badges.dart';
import '../../models/irrigation_models.dart';
import '../../state/irrigation_store.dart';

class MonitoringTab extends StatelessWidget {
  const MonitoringTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = IrrigationStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return RefreshIndicator(
          onRefresh: store.refreshData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!store.isAppOnline) ...[
                const OfflineReadOnlyBanner(),
                const SizedBox(height: 12),
              ],
              const Text(
                'Daftar Stasiun Telemetri',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ketuk stasiun untuk melihat grafik tren 60 menit, kualitas data, dan status baterai.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              ...store.nodes.map((node) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _StationCard(
                      node: node,
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed('/monitoring/${node.slug}');
                      },
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _StationCard extends StatelessWidget {
  final TelemetryNode node;
  final VoidCallback onTap;

  const _StationCard({required this.node, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          node.location,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AlertLevelBadge(level: node.overallLevel),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ConnectivityBadge(status: node.connectivity, compact: true),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.battery_std_rounded,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Baterai ${node.batteryPercent}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _SensorValueBlock(
                      title: 'Curah Hujan',
                      value: '${node.rainfallMm}',
                      unit: 'mm/jam',
                      level: node.rainfallLevel,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SensorValueBlock(
                      title: 'Tinggi Muka Air',
                      value: '${node.waterLevelCm}',
                      unit: 'cm',
                      level: node.waterLevelStatus,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FreshnessChip(
                    freshness: node.freshness,
                    updatedAt: node.updatedAt,
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.navyPrimary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SensorValueBlock extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final AlertLevel level;

  const _SensorValueBlock({
    required this.title,
    required this.value,
    required this.unit,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AlertLevelBadge(level: level, compact: true),
        ],
      ),
    );
  }
}
