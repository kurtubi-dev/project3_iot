import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/status_badges.dart';
import '../../models/irrigation_models.dart';
import '../../state/irrigation_store.dart';

class RecommendationsTab extends StatelessWidget {
  const RecommendationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = IrrigationStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final recs = store.recommendations;
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
                'Rekomendasi Bukaan Pintu AI',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'AI bersifat pendukung keputusan. Memilih rekomendasi tidak langsung menggerakkan pintu.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              if (recs.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Belum ada rekomendasi AI yang tersedia.'),
                  ),
                )
              else
                ...recs.map((rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RecommendationCard(
                        rec: rec,
                        onTap: () {
                          Navigator.of(context)
                              .pushNamed('/rekomendasi/${rec.id}');
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

class _RecommendationCard extends StatelessWidget {
  final AiRecommendation rec;
  final VoidCallback onTap;

  const _RecommendationCard({required this.rec, required this.onTap});

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
                    child: Text(
                      rec.gateName,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  AlertLevelBadge(level: rec.alertLevel, compact: true),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _OpeningCompareChip(
                    label: 'Saat ini',
                    value: '${rec.currentOpening}%',
                    isPrimary: false,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward_rounded, size: 18),
                  ),
                  _OpeningCompareChip(
                    label: 'Saran AI',
                    value: '${rec.recommendedOpening}%',
                    isPrimary: true,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                rec.reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RecommendationDecisionBadge(
                    decision: rec.isExpired &&
                            rec.decision == RecommendationDecision.pending
                        ? RecommendationDecision.expired
                        : rec.decision,
                  ),
                  Text(
                    formatRelativeTime(rec.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
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

class _OpeningCompareChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isPrimary;

  const _OpeningCompareChip({
    required this.label,
    required this.value,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.infoBg : AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPrimary ? AppColors.infoBorder : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isPrimary ? AppColors.navyPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class RecommendationDecisionBadge extends StatelessWidget {
  final RecommendationDecision decision;

  const RecommendationDecisionBadge({super.key, required this.decision});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color fg;
    late final Color bg;
    late final IconData icon;

    switch (decision) {
      case RecommendationDecision.pending:
        label = 'Belum diputuskan';
        fg = AppColors.waspada;
        bg = AppColors.waspadaBg;
        icon = Icons.pending_actions_rounded;
        break;
      case RecommendationDecision.applied:
        label = 'Diterapkan';
        fg = AppColors.normal;
        bg = AppColors.normalBg;
        icon = Icons.check_circle_outline_rounded;
        break;
      case RecommendationDecision.modified:
        label = 'Dimodifikasi';
        fg = AppColors.info;
        bg = AppColors.infoBg;
        icon = Icons.edit_note_rounded;
        break;
      case RecommendationDecision.rejected:
        label = 'Tidak diterapkan';
        fg = AppColors.offline;
        bg = AppColors.offlineBg;
        icon = Icons.block_rounded;
        break;
      case RecommendationDecision.expired:
        label = 'Kedaluwarsa';
        fg = AppColors.kritis;
        bg = AppColors.kritisBg;
        icon = Icons.timer_off_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
