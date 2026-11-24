import 'package:flutter/material.dart';
import '../../models/irrigation_models.dart';
import '../theme/app_theme.dart';

String formatRelativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) {
    return 'Baru saja';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} mnt lalu';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} jam lalu';
  }
  return '${diff.inDays} hari lalu';
}

String formatClock(DateTime time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m WIB';
}

class ConnectivityBadge extends StatelessWidget {
  final ConnectivityStatus status;
  final bool compact;

  const ConnectivityBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    late final Color fg;
    late final Color bg;
    late final Color border;
    late final IconData icon;
    late final String label;

    switch (status) {
      case ConnectivityStatus.online:
        fg = AppColors.normal;
        bg = AppColors.normalBg;
        border = AppColors.normalBorder;
        icon = Icons.wifi_rounded;
        label = 'Online';
        break;
      case ConnectivityStatus.offline:
        fg = AppColors.offline;
        bg = AppColors.offlineBg;
        border = AppColors.offlineBorder;
        icon = Icons.wifi_off_rounded;
        label = 'Offline';
        break;
      case ConnectivityStatus.gangguan:
        fg = AppColors.kritis;
        bg = AppColors.kritisBg;
        border = AppColors.kritisBorder;
        icon = Icons.error_outline_rounded;
        label = 'Gangguan';
        break;
      case ConnectivityStatus.connecting:
        fg = AppColors.info;
        bg = AppColors.infoBg;
        border = AppColors.infoBorder;
        icon = Icons.sync_rounded;
        label = 'Menghubungkan';
        break;
      case ConnectivityStatus.unknown:
        fg = AppColors.textMuted;
        bg = AppColors.surfaceSubtle;
        border = AppColors.border;
        icon = Icons.help_outline_rounded;
        label = 'Tidak Diketahui';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 13 : 15, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class AlertLevelBadge extends StatelessWidget {
  final AlertLevel level;
  final bool compact;

  const AlertLevelBadge({
    super.key,
    required this.level,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    late final Color fg;
    late final Color bg;
    late final Color border;
    late final IconData icon;
    late final String label;

    switch (level) {
      case AlertLevel.normal:
        fg = AppColors.normal;
        bg = AppColors.normalBg;
        border = AppColors.normalBorder;
        icon = Icons.check_circle_outline_rounded;
        label = 'Normal';
        break;
      case AlertLevel.waspada:
        fg = AppColors.waspada;
        bg = AppColors.waspadaBg;
        border = AppColors.waspadaBorder;
        icon = Icons.warning_amber_rounded;
        label = 'Waspada';
        break;
      case AlertLevel.kritis:
        fg = AppColors.kritis;
        bg = AppColors.kritisBg;
        border = AppColors.kritisBorder;
        icon = Icons.dangerous_outlined;
        label = 'Kritis';
        break;
      case AlertLevel.unknown:
        fg = AppColors.textMuted;
        bg = AppColors.surfaceSubtle;
        border = AppColors.border;
        icon = Icons.help_outline_rounded;
        label = 'Tidak Diketahui';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 13 : 15, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class FreshnessChip extends StatelessWidget {
  final DataFreshness freshness;
  final DateTime updatedAt;

  const FreshnessChip({
    super.key,
    required this.freshness,
    required this.updatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final isStale = freshness == DataFreshness.kedaluwarsa ||
        freshness == DataFreshness.terlambat;
    final color = freshness == DataFreshness.kedaluwarsa
        ? AppColors.kritis
        : (freshness == DataFreshness.terlambat
            ? AppColors.waspada
            : AppColors.textSecondary);

    String prefix;
    switch (freshness) {
      case DataFreshness.terkini:
        prefix = 'Diperbarui';
        break;
      case DataFreshness.terlambat:
        prefix = 'Terlambat';
        break;
      case DataFreshness.kedaluwarsa:
        prefix = 'Kedaluwarsa';
        break;
      case DataFreshness.belumAdaData:
        prefix = 'Belum ada data';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isStale ? Icons.schedule_rounded : Icons.update_rounded,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          freshness == DataFreshness.belumAdaData
              ? prefix
              : '$prefix • ${formatRelativeTime(updatedAt)} (${formatClock(updatedAt)})',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: isStale ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class OfflineReadOnlyBanner extends StatelessWidget {
  final String reason;

  const OfflineReadOnlyBanner({
    super.key,
    this.reason =
        'Aplikasi sedang offline. Data terakhir tetap dapat dibaca, namun kendali pintu dinonaktifkan (tidak ada antrean perintah otomatis).',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.waspadaBg,
        border: Border.all(color: AppColors.waspadaBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: AppColors.waspada,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              reason,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContextHeaderBar extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const ContextHeaderBar({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.navyPrimary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.puprGold, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
