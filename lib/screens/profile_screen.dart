import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/status_badges.dart';
import '../models/irrigation_models.dart';
import '../state/irrigation_store.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Sesi?'),
        content: const Text(
          'Anda perlu masuk kembali menggunakan akun Petugas Lapang untuk mengakses monitoring dan kendali pintu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.kritis),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await IrrigationStore.instance.logout();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = IrrigationStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final user = store.currentUser;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil Petugas'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ContextHeaderBar(
                icon: Icons.person_outline_rounded,
                title: user?.name ?? 'Petugas Lapang',
                subtitle: user?.unitKerja ?? 'Dinas PUPR Kab. Subang — Bidang SDA',
                trailing: ConnectivityBadge(
                  status: store.isAppOnline
                      ? ConnectivityStatus.online
                      : ConnectivityStatus.offline,
                  compact: true,
                ),
              ),
              const SizedBox(height: 16),

              // Detail Akun
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Akun & Sesi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Divider(height: 22),
                      _InfoRow(label: 'ID Petugas', value: user?.id ?? '-'),
                      const SizedBox(height: 10),
                      _InfoRow(
                        label: 'Role Pengguna',
                        value: user?.role ?? 'PETUGAS_LAPANGAN',
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        label: 'Status Akun',
                        value: user?.status ?? 'ACTIVE',
                        valueColor: AppColors.normal,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Penjelasan Hak Operasional Setara
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.infoBorder),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.info, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hak Operasional Petugas Lapang',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Semua Petugas Lapang dengan akun valid dan sesi aktif memiliki hak operasional yang sama untuk melihat monitoring, meninjau rekomendasi AI, dan mengendalikan pintu irigasi. Identitas dicatat untuk jejak audit.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Simulasi Kondisi Online / Offline
              Card(
                child: SwitchListTile(
                  value: store.isAppOnline,
                  onChanged: (val) => store.setAppOnline(val),
                  title: const Text(
                    'Simulasi Koneksi Aplikasi',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                  subtitle: Text(
                    store.isAppOnline
                        ? 'Online — Data dapat disegarkan & kendali pintu aktif.'
                        : 'Offline — Mode read-only aktif; kendali pintu dinonaktifkan.',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  secondary: Icon(
                    store.isAppOnline
                        ? Icons.wifi_rounded
                        : Icons.wifi_off_rounded,
                    color: store.isAppOnline ? AppColors.normal : AppColors.kritis,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kritis,
                ),
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar (Logout)'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
