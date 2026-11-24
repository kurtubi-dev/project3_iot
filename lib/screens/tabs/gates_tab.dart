import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/status_badges.dart';
import '../../models/irrigation_models.dart';
import '../../state/irrigation_store.dart';

class GatesTab extends StatelessWidget {
  const GatesTab({super.key});

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
                'Daftar Pintu Irigasi',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pilih pintu untuk meninjau rekomendasi AI, mengatur target bukaan, dan mengirim perintah.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              ...store.gates.map((gate) {
                final rec = store.getLatestRecommendationForGate(gate.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.of(context).pushNamed('/kendali/${gate.id}');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        gate.name,
                                        style: const TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        gate.location,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ConnectivityBadge(
                                  status: gate.connectivity,
                                  compact: true,
                                ),
                              ],
                            ),
                            const Divider(height: 22),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Posisi Bukaan Aktual',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${gate.actualOpening}%',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.navyPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pushNamed('/kendali/${gate.id}');
                                  },
                                  icon: const Icon(Icons.tune_rounded, size: 18),
                                  label: Text(
                                    gate.connectivity ==
                                            ConnectivityStatus.online
                                        ? 'Atur Target'
                                        : 'Lihat Detail',
                                  ),
                                ),
                              ],
                            ),
                            if (rec != null &&
                                rec.decision ==
                                    RecommendationDecision.pending &&
                                !rec.isExpired) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.infoBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 15,
                                      color: AppColors.info,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Rekomendasi AI tersedia: ${rec.recommendedOpening}%',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navyPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            FreshnessChip(
                              freshness: gate.freshness,
                              updatedAt: gate.updatedAt,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
