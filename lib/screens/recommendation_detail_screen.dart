import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/status_badges.dart';
import '../models/irrigation_models.dart';
import '../state/irrigation_store.dart';
import 'tabs/recommendations_tab.dart';

class RecommendationDetailScreen extends StatelessWidget {
  final String recommendationId;

  const RecommendationDetailScreen({super.key, required this.recommendationId});

  Future<void> _confirmReject(BuildContext context, AiRecommendation rec) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tidak Terapkan Rekomendasi?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilihan ini akan mencatat bahwa rekomendasi AI (${rec.recommendedOpening}%) pada ${rec.gateName} tidak diterapkan. Posisi pintu tidak akan berubah dan tidak ada perintah yang dikirim.',
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan tambahan (opsional)',
                hintText: 'Contoh: Kondisi saluran hilir masih padat',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.offline),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Konfirmasi Tidak Terapkan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final note = noteController.text.trim();
      IrrigationStore.instance.rejectRecommendation(
        rec.id,
        note: note.isEmpty ? null : note,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Keputusan dicatat: Rekomendasi tidak diterapkan. Pintu tidak digerakkan.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = IrrigationStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final rec = store.getRecommendationById(recommendationId);
        if (rec == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Rekomendasi')),
            body: const Center(child: Text('Rekomendasi tidak ditemukan.')),
          );
        }

        final isExpired = rec.isExpired;
        final isPending = rec.decision == RecommendationDecision.pending && !isExpired;
        final effectiveDecision = isExpired && rec.decision == RecommendationDecision.pending
            ? RecommendationDecision.expired
            : rec.decision;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Rekomendasi AI'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!store.isAppOnline) ...[
                const OfflineReadOnlyBanner(),
                const SizedBox(height: 12),
              ],
              ContextHeaderBar(
                icon: Icons.auto_awesome_rounded,
                title: rec.gateName,
                subtitle: rec.gateLocation,
                trailing: AlertLevelBadge(level: rec.alertLevel, compact: true),
              ),
              const SizedBox(height: 14),

              // Status Keputusan & Masa Berlaku
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Status Keputusan',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          RecommendationDecisionBadge(decision: effectiveDecision),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Masa Berlaku',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            isExpired
                                ? 'Kedaluwarsa (${formatClock(rec.expiresAt)})'
                                : 'Berlaku s.d. ${formatClock(rec.expiresAt)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isExpired
                                  ? AppColors.kritis
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (rec.decidedBy != null) ...[
                        const Divider(height: 20),
                        Text(
                          'Diputuskan oleh ${rec.decidedBy} (${formatRelativeTime(rec.decidedAt ?? rec.createdAt)})',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Perbandingan Bukaan
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'Posisi Pintu Saat Ini',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${rec.currentOpening}%',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 28),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'Saran Bukaan AI',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.info,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${rec.recommendedOpening}%',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navyPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Penjelasan Alasan Rekomendasi
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alasan Analisis AI',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rec.reason,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Snapshot Data Node Hulu & Hilir
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Snapshot Data Node Pendukung',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _SnapshotTile(snapshot: rec.huluSnapshot),
                      const SizedBox(height: 8),
                      _SnapshotTile(snapshot: rec.hilirSnapshot),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Penegasan Safety UX
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.infoBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.info),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Keputusan tetap berada di tangan Petugas Lapang. Memilih "Terapkan" atau "Ubah target" hanya membuka layar kendali pintu untuk peninjauan & konfirmasi.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (isPending) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/kendali/${rec.gateId}',
                      arguments: {
                        'recommendationId': rec.id,
                        'initialTarget': rec.recommendedOpening,
                        'mode': 'apply',
                      },
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    '1. Terapkan Rekomendasi (${rec.recommendedOpening}%)',
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      '/kendali/${rec.gateId}',
                      arguments: {
                        'recommendationId': rec.id,
                        'initialTarget': rec.currentOpening,
                        'mode': 'modify',
                      },
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('2. Ubah Target Bukaan Manual'),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.kritis,
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: () => _confirmReject(context, rec),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('3. Tidak Terapkan Rekomendasi'),
                ),
              ] else if (isExpired) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/kendali/${rec.gateId}');
                  },
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Buka Kendali Manual Pintu'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SnapshotTile extends StatelessWidget {
  final NodeSnapshot snapshot;

  const _SnapshotTile({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snapshot.nodeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hujan: ${snapshot.rainfallMm} mm/jam • TMA: ${snapshot.waterLevelCm} cm',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AlertLevelBadge(level: snapshot.level, compact: true),
        ],
      ),
    );
  }
}
