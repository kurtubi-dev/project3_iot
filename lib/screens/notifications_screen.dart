import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/status_badges.dart';
import '../models/irrigation_models.dart';
import '../state/irrigation_store.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _filter = 'semua'; // 'semua' | 'belum_dibaca' | 'kritis'

  Future<void> _acknowledgeAlert(
    BuildContext context,
    AppNotification notif,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Akui Peringatan Kritis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notif.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Acknowledgement akan mencatat identitas Anda dan waktu pembacaan. Tindakan ini TIDAK otomatis mengubah posisi pintu atau menyelesaikan kondisi lapangan.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.kritis),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Saya Mengerti & Akui'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      IrrigationStore.instance.acknowledgeCriticalNotification(notif.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Peringatan kritis telah diakui dan dicatat di riwayat.'),
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
        final items = store.notifications.where((n) {
          if (_filter == 'belum_dibaca') return !n.isRead;
          if (_filter == 'kritis') return n.alertLevel == AlertLevel.kritis;
          return true;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Pusat Notifikasi'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Semua'),
                    selected: _filter == 'semua',
                    onSelected: (_) => setState(() => _filter = 'semua'),
                  ),
                  ChoiceChip(
                    label: Text('Belum Dibaca (${store.unreadNotificationCount})'),
                    selected: _filter == 'belum_dibaca',
                    onSelected: (_) => setState(() => _filter = 'belum_dibaca'),
                  ),
                  ChoiceChip(
                    label: const Text('Kritis'),
                    selected: _filter == 'kritis',
                    onSelected: (_) => setState(() => _filter = 'kritis'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Tidak ada notifikasi pada filter ini.'),
                  ),
                )
              else
                ...items.map((notif) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        color: notif.isRead
                            ? AppColors.surface
                            : AppColors.infoBg.withValues(alpha: 0.45),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => store.markNotificationRead(notif.id),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    AlertLevelBadge(
                                      level: notif.alertLevel,
                                      compact: true,
                                    ),
                                    Row(
                                      children: [
                                        if (!notif.isRead)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.navyPrimary,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Text(
                                              'Baru',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        Text(
                                          formatRelativeTime(notif.createdAt),
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  notif.title,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notif.message,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Objek: ${notif.objectName}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (notif.requiresAck) ...[
                                  const SizedBox(height: 10),
                                  if (notif.isAcknowledged)
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.normalBg,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 16,
                                            color: AppColors.normal,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Diakui oleh ${notif.acknowledgedBy} • ${formatClock(notif.acknowledgedAt ?? notif.createdAt)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.normal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.kritis,
                                        ),
                                        onPressed: () =>
                                            _acknowledgeAlert(context, notif),
                                        icon: const Icon(
                                          Icons.fact_check_outlined,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          'Akui Peringatan Kritis (Wajib)',
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }
}
