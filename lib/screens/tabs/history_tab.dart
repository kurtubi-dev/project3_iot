import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/status_badges.dart';
import '../../models/irrigation_models.dart';
import '../../state/irrigation_store.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  HistoryCategory? _selectedCategory; // null = Semua

  void _showHistoryDetail(BuildContext context, HistoryEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                AlertLevelBadge(level: event.alertLevel, compact: true),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              event.summary,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const Divider(height: 24),
            _AuditRow(label: 'Ref ID', value: event.referenceId),
            _AuditRow(label: 'Status', value: event.statusLabel),
            _AuditRow(label: 'Petugas / Aktor', value: event.actorName),
            _AuditRow(
              label: 'Waktu Kejadian',
              value:
                  '${formatClock(event.timestamp)} (${formatRelativeTime(event.timestamp)})',
            ),
            if (event.gateName != null)
              _AuditRow(label: 'Pintu', value: event.gateName!),
            if (event.nodeName != null)
              _AuditRow(label: 'Node', value: event.nodeName!),
            if (event.initialOpening != null && event.targetOpening != null)
              _AuditRow(
                label: 'Posisi Awal → Target',
                value: '${event.initialOpening}% → ${event.targetOpening}%',
              ),
            if (event.finalOpening != null)
              _AuditRow(label: 'Posisi Akhir', value: '${event.finalOpening}%'),
            if (event.aiRecommendedOpening != null)
              _AuditRow(
                label: 'Rekomendasi AI Terkait',
                value: '${event.aiRecommendedOpening}%',
              ),
            if (event.deviationReason != null)
              _AuditRow(label: 'Alasan / Catatan', value: event.deviationReason!),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = IrrigationStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final items = store.history.where((h) {
          if (_selectedCategory == null) return true;
          return h.category == _selectedCategory;
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Riwayat Aktivitas Terpadu',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Jejak monitoring sensor, keputusan rekomendasi AI, dan hasil kendali pintu.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Semua'),
                    selected: _selectedCategory == null,
                    onSelected: (_) => setState(() => _selectedCategory = null),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Monitoring'),
                    selected: _selectedCategory == HistoryCategory.monitoring,
                    onSelected: (_) => setState(
                        () => _selectedCategory = HistoryCategory.monitoring),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Rekomendasi'),
                    selected: _selectedCategory == HistoryCategory.rekomendasi,
                    onSelected: (_) => setState(
                        () => _selectedCategory = HistoryCategory.rekomendasi),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Kendali'),
                    selected: _selectedCategory == HistoryCategory.kendali,
                    onSelected: (_) => setState(
                        () => _selectedCategory = HistoryCategory.kendali),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Belum ada riwayat untuk kategori ini.'),
                ),
              )
            else
              ...items.map((event) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _showHistoryDetail(context, event),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _CategoryTag(category: event.category),
                                  Text(
                                    '${formatClock(event.timestamp)} • ${formatRelativeTime(event.timestamp)}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                event.summary,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (event.initialOpening != null &&
                                  event.targetOpening != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Bukaan: ${event.initialOpening}% → Target ${event.targetOpening}%${event.finalOpening != null ? ' (Akhir: ${event.finalOpening}%)' : ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navyPrimary,
                                  ),
                                ),
                              ],
                              const Divider(height: 18),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      event.actorName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    event.statusLabel,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navyPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )),
          ],
        );
      },
    );
  }
}

class _CategoryTag extends StatelessWidget {
  final HistoryCategory category;

  const _CategoryTag({required this.category});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final IconData icon;
    switch (category) {
      case HistoryCategory.monitoring:
        label = 'Monitoring';
        icon = Icons.sensors_rounded;
        break;
      case HistoryCategory.rekomendasi:
        label = 'Rekomendasi AI';
        icon = Icons.auto_awesome_rounded;
        break;
      case HistoryCategory.kendali:
        label = 'Kendali Pintu';
        icon = Icons.tune_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.navyPrimary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.navyPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  final String label;
  final String value;

  const _AuditRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
