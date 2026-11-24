import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/status_badges.dart';
import '../../models/irrigation_models.dart';
import '../../state/irrigation_store.dart';

class HomeTab extends StatelessWidget {
  final void Function(int tabIndex) onSwitchTab;

  const HomeTab({super.key, required this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    final store = IrrigationStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final criticalAlerts = store.unacknowledgedCriticalAlerts;
        final pendingRecs = store.recommendations
            .where((r) => r.decision == RecommendationDecision.pending && !r.isExpired)
            .toList();

        return RefreshIndicator(
          onRefresh: store.refreshData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!store.isAppOnline) ...[
                const OfflineReadOnlyBanner(),
                const SizedBox(height: 12),
              ],

              // Ringkasan Kondisi Sistem
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, ${store.currentUser?.name ?? 'Petugas'}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Ringkasan Siaga Irigasi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AlertLevelBadge(level: store.highestSystemAlertLevel),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _QuickStatChip(
                          label: 'Node Online',
                          value:
                              '${store.nodes.where((n) => n.connectivity == ConnectivityStatus.online).length}/${store.nodes.length}',
                        ),
                        const SizedBox(width: 8),
                        _QuickStatChip(
                          label: 'Pintu Aktif',
                          value:
                              '${store.gates.where((g) => g.connectivity == ConnectivityStatus.online).length}/${store.gates.length}',
                        ),
                        const SizedBox(width: 8),
                        _QuickStatChip(
                          label: 'Saran AI',
                          value: '${pendingRecs.length} Baru',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Peringatan Kritis Belum Diakui
              if (criticalAlerts.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.kritisBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.kritis, width: 1.4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.notification_important_rounded,
                            color: AppColors.kritis,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${criticalAlerts.length} Peringatan Kritis Belum Diakui',
                              style: const TextStyle(
                                color: AppColors.kritis,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        criticalAlerts.first.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.kritis,
                          ),
                          onPressed: () {
                            Navigator.of(context).pushNamed('/notifikasi');
                          },
                          icon: const Icon(Icons.fact_check_outlined, size: 18),
                          label: const Text('Buka & Akui Peringatan'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Akses Cepat
              const Text(
                'Akses Cepat',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.sensors_rounded,
                      label: 'Monitoring',
                      onTap: () => onSwitchTab(1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Rekomendasi AI',
                      onTap: () => onSwitchTab(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.tune_rounded,
                      label: 'Kendali Pintu',
                      onTap: () => onSwitchTab(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Kondisi Node 1 Hulu & Node 2 Hilir
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kondisi Stasiun Telemetri',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onSwitchTab(1),
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              ...store.nodes.map((node) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _NodeSummaryCard(
                      node: node,
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed('/monitoring/${node.slug}');
                      },
                    ),
                  )),
              const SizedBox(height: 8),

              // Rekomendasi AI Terbaru
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Rekomendasi AI Terbaru',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onSwitchTab(2),
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              if (pendingRecs.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Tidak ada rekomendasi AI yang menunggu keputusan saat ini.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ...pendingRecs.take(2).map(
                      (rec) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed('/rekomendasi/${rec.id}');
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          rec.gateName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14.5,
                                          ),
                                        ),
                                      ),
                                      AlertLevelBadge(
                                        level: rec.alertLevel,
                                        compact: true,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        'Saat ini: ${rec.currentOpening}%',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Icon(Icons.arrow_forward_rounded,
                                            size: 16),
                                      ),
                                      Text(
                                        'Saran AI: ${rec.recommendedOpening}%',
                                        style: const TextStyle(
                                          color: AppColors.navyPrimary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    rec.reason,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 8),

              // Ringkasan Posisi Pintu Irigasi Terdaftar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Posisi Pintu Irigasi Terdaftar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onSwitchTab(3),
                    child: const Text('Kendali'),
                  ),
                ],
              ),
              ...store.gates.map(
                (gate) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      onTap: () {
                        Navigator.of(context).pushNamed('/kendali/${gate.id}');
                      },
                      title: Text(
                        gate.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        gate.location,
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${gate.actualOpening}%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navyPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          ConnectivityBadge(
                            status: gate.connectivity,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickStatChip extends StatelessWidget {
  final String label;
  final String value;

  const _QuickStatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.navyPrimary, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NodeSummaryCard extends StatelessWidget {
  final TelemetryNode node;
  final VoidCallback onTap;

  const _NodeSummaryCard({required this.node, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      node.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  ConnectivityBadge(status: node.connectivity, compact: true),
                  const SizedBox(width: 6),
                  AlertLevelBadge(level: node.overallLevel, compact: true),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MetricBox(
                      label: 'Curah Hujan',
                      value: '${node.rainfallMm} mm/jam',
                      icon: Icons.grain_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricBox(
                      label: 'Tinggi Muka Air',
                      value: '${node.waterLevelCm} cm',
                      icon: Icons.waves_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FreshnessChip(freshness: node.freshness, updatedAt: node.updatedAt),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.navyPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
