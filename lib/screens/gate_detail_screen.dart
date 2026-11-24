import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/status_badges.dart';
import '../models/irrigation_models.dart';
import '../state/irrigation_store.dart';

class GateDetailScreen extends StatefulWidget {
  final String gateId;
  final String? recommendationId;
  final int? initialTarget;
  final String? mode; // 'apply' | 'modify' | null

  const GateDetailScreen({
    super.key,
    required this.gateId,
    this.recommendationId,
    this.initialTarget,
    this.mode,
  });

  @override
  State<GateDetailScreen> createState() => _GateDetailScreenState();
}

class _GateDetailScreenState extends State<GateDetailScreen> {
  static const List<int> _presets = [0, 25, 50, 75, 100];

  late TextEditingController _targetController;
  final _reasonController = TextEditingController();
  bool _acknowledgeNoAi = false;
  int _selectedTarget = 0;

  bool _isExecuting = false;
  GateCommandStatus? _liveStatus;
  GateCommand? _lastResult;

  // Opsi simulasi untuk walkthrough/testing (Normal, Timeout, Gagal)
  String _simOutcome = 'executed'; // 'executed' | 'timeout' | 'failed'

  @override
  void initState() {
    super.initState();
    final gate = IrrigationStore.instance.getGateById(widget.gateId);
    _selectedTarget = widget.initialTarget ?? gate?.actualOpening ?? 0;
    _targetController = TextEditingController(text: '$_selectedTarget');
  }

  @override
  void dispose() {
    _targetController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _setTarget(int val) {
    final clamped = val.clamp(0, 100);
    setState(() {
      _selectedTarget = clamped;
      _targetController.text = '$clamped';
    });
  }

  Future<void> _confirmAndSend(
    Gate gate,
    AiRecommendation? activeRec,
    bool requiresReason,
    bool noValidAi,
  ) async {
    if (noValidAi && !_acknowledgeNoAi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harap centang persetujuan kendali manual tanpa rekomendasi AI terlebih dahulu.',
          ),
        ),
      );
      return;
    }

    if (requiresReason && _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Alasan wajib diisi karena target menyimpang signifikan atau AI tidak tersedia.',
          ),
        ),
      );
      return;
    }

    final diff = _selectedTarget - gate.actualOpening;
    final diffText = diff >= 0 ? '+$diff%' : '$diff%';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Perintah Pintu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.navyPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gate.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    gate.location,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _ConfirmRow(label: 'Posisi Saat Ini', value: '${gate.actualOpening}%'),
            _ConfirmRow(label: 'Target Bukaan', value: '$_selectedTarget%'),
            _ConfirmRow(label: 'Perubahan', value: diffText),
            if (activeRec != null && !activeRec.isExpired)
              _ConfirmRow(
                label: 'Rekomendasi AI',
                value: '${activeRec.recommendedOpening}%',
              ),
            if (_reasonController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Alasan: ${_reasonController.text.trim()}',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kirim Perintah'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isExecuting = true;
      _lastResult = null;
      _liveStatus = GateCommandStatus.sending;
    });

    try {
      final result = await IrrigationStore.instance.submitGateCommand(
        gateId: gate.id,
        targetOpening: _selectedTarget,
        recommendationId: activeRec != null && !activeRec.isExpired
            ? activeRec.id
            : null,
        deviationReason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
        simulateTimeout: _simOutcome == 'timeout',
        simulateFailure: _simOutcome == 'failed',
        onProgress: (status) {
          if (mounted) {
            setState(() => _liveStatus = status);
          }
        },
      );
      if (mounted) {
        setState(() {
          _isExecuting = false;
          _lastResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExecuting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
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
        final gate = store.getGateById(widget.gateId);
        if (gate == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Pintu')),
            body: const Center(child: Text('Pintu tidak ditemukan.')),
          );
        }

        final activeRec = widget.recommendationId != null
            ? store.getRecommendationById(widget.recommendationId!)
            : store.getLatestRecommendationForGate(gate.id);

        final bool hasValidAi = activeRec != null &&
            activeRec.isAiAvailable &&
            !activeRec.isExpired;

        final int deviation = hasValidAi
            ? (_selectedTarget - activeRec.recommendedOpening).abs()
            : 0;
        final bool isSignificantDeviation = hasValidAi &&
            deviation >= IrrigationStore.significantDeviationThreshold;

        final bool requiresReason = isSignificantDeviation || !hasValidAi;

        final bool canControl = store.isAppOnline &&
            gate.connectivity == ConnectivityStatus.online &&
            gate.freshness != DataFreshness.kedaluwarsa &&
            !_isExecuting &&
            _selectedTarget != gate.actualOpening;

        return Scaffold(
          appBar: AppBar(
            title: Text(gate.name),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!store.isAppOnline) ...[
                const OfflineReadOnlyBanner(),
                const SizedBox(height: 12),
              ] else if (gate.connectivity != ConnectivityStatus.online) ...[
                OfflineReadOnlyBanner(
                  reason:
                      'Perangkat ${gate.name} sedang offline/gangguan. Kendali dinonaktifkan dan tidak ada antrean perintah.',
                ),
                const SizedBox(height: 12),
              ],

              // Context Header Pintu
              ContextHeaderBar(
                icon: Icons.water_damage_outlined,
                title: gate.name,
                subtitle: gate.location,
                trailing: ConnectivityBadge(
                  status: gate.connectivity,
                  compact: true,
                ),
              ),
              const SizedBox(height: 12),

              // Status Posisi Aktual & Pembanding AI
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FreshnessChip(
                        freshness: gate.freshness,
                        updatedAt: gate.updatedAt,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _CompareColumn(
                              label: 'Posisi Sekarang',
                              value: '${gate.actualOpening}%',
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Expanded(
                            child: _CompareColumn(
                              label: 'Target Petugas',
                              value: '$_selectedTarget%',
                              color: AppColors.navyPrimary,
                            ),
                          ),
                          Expanded(
                            child: _CompareColumn(
                              label: 'Target AI',
                              value: hasValidAi
                                  ? '${activeRec.recommendedOpening}%'
                                  : 'Tidak Tersedia',
                              color: hasValidAi
                                  ? AppColors.info
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Peringatan jika AI tidak tersedia / kedaluwarsa
              if (!hasValidAi) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.waspadaBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.waspadaBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: AppColors.waspada),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Rekomendasi AI Tidak Tersedia / Kedaluwarsa',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Kendali manual tetap dapat dilakukan jika perangkat online, namun Anda wajib mengakui peringatan ini dan mengisi alasan keputusan.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _acknowledgeNoAi,
                        onChanged: store.isAppOnline &&
                                gate.connectivity == ConnectivityStatus.online
                            ? (v) => setState(() => _acknowledgeNoAi = v ?? false)
                            : null,
                        title: const Text(
                          'Saya memahami kendali dilakukan tanpa rekomendasi AI valid.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Form Pengaturan Target (Preset + Input Manual)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Atur Target Bukaan Pintu',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Memilih preset atau angka tidak langsung mengirim perintah.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _presets.map((p) {
                          final isSelected = _selectedTarget == p;
                          return ChoiceChip(
                            label: Text('$p%'),
                            selected: isSelected,
                            onSelected: store.isAppOnline &&
                                    gate.connectivity ==
                                        ConnectivityStatus.online &&
                                    !_isExecuting
                                ? (_) => _setTarget(p)
                                : null,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _targetController,
                        enabled: store.isAppOnline &&
                            gate.connectivity == ConnectivityStatus.online &&
                            !_isExecuting,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Persentase Target Manual (0 – 100%)',
                          suffixText: '%',
                        ),
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null) {
                            setState(() {
                              _selectedTarget = parsed.clamp(0, 100);
                            });
                          }
                        },
                      ),
                      if (requiresReason) ...[
                        const SizedBox(height: 14),
                        TextField(
                          controller: _reasonController,
                          enabled: store.isAppOnline &&
                              gate.connectivity == ConnectivityStatus.online &&
                              !_isExecuting,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: isSignificantDeviation
                                ? 'Alasan Penyimpangan dari AI (Wajib)'
                                : 'Alasan Kendali Manual (Wajib)',
                            hintText:
                                'Jelaskan pertimbangan kondisi lapangan saat ini...',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Simulasi Outcome untuk Uji Prototipe
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Simulasi Hasil Perangkat (Mode Prototipe)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'executed', label: Text('Berhasil')),
                          ButtonSegment(value: 'timeout', label: Text('Timeout')),
                          ButtonSegment(value: 'failed', label: Text('Gagal')),
                        ],
                        selected: {_simOutcome},
                        onSelectionChanged: _isExecuting
                            ? null
                            : (s) => setState(() => _simOutcome = s.first),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tombol Kirim / Konfirmasi
              ElevatedButton.icon(
                onPressed: canControl
                    ? () => _confirmAndSend(
                          gate,
                          activeRec,
                          requiresReason,
                          !hasValidAi,
                        )
                    : null,
                icon: _isExecuting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isExecuting
                      ? 'Mengirim & Menunggu Perangkat...'
                      : (_selectedTarget == gate.actualOpening
                          ? 'Target Sama dengan Posisi Aktual'
                          : 'Tinjau & Kirim Perintah ($_selectedTarget%)'),
                ),
              ),

              // Live Progress & Hasil Eksekusi
              if (_isExecuting && _liveStatus != null) ...[
                const SizedBox(height: 14),
                Card(
                  color: AppColors.infoBg,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const CircularProgressIndicator(strokeWidth: 2.4),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Status perintah: ${_statusLabel(_liveStatus!)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (_lastResult != null) ...[
                const SizedBox(height: 14),
                _ExecutionResultCard(command: _lastResult!),
              ],
            ],
          ),
        );
      },
    );
  }

  String _statusLabel(GateCommandStatus status) {
    switch (status) {
      case GateCommandStatus.sending:
        return 'Mengirim ke server...';
      case GateCommandStatus.serverAccepted:
        return 'Diterima server (APPROVED)...';
      case GateCommandStatus.deviceAccepted:
        return 'Diterima perangkat ESP32 (ACK)...';
      case GateCommandStatus.moving:
        return 'Pintu sedang bergerak...';
      case GateCommandStatus.executed:
        return 'Berhasil mencapai target';
      case GateCommandStatus.timeout:
        return 'Timeout — status belum diketahui';
      case GateCommandStatus.failed:
        return 'Gagal dieksekusi';
      default:
        return status.name;
    }
  }
}

class _CompareColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CompareColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConfirmRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ExecutionResultCard extends StatelessWidget {
  final GateCommand command;

  const _ExecutionResultCard({required this.command});

  @override
  Widget build(BuildContext context) {
    final isSuccess = command.status == GateCommandStatus.executed;
    final isTimeout = command.status == GateCommandStatus.timeout;

    final Color fg = isSuccess
        ? AppColors.normal
        : (isTimeout ? AppColors.waspada : AppColors.kritis);
    final Color bg = isSuccess
        ? AppColors.normalBg
        : (isTimeout ? AppColors.waspadaBg : AppColors.kritisBg);
    final IconData icon = isSuccess
        ? Icons.check_circle_rounded
        : (isTimeout ? Icons.hourglass_disabled_rounded : Icons.error_rounded);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSuccess
                      ? 'Eksekusi Berhasil (${command.finalOpening}%)'
                      : (isTimeout
                          ? 'Timeout — Perlu Verifikasi Lapangan'
                          : 'Eksekusi Perintah Gagal'),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            command.deviceMessage ?? '-',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ref ID: ${command.referenceId}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
                arguments: {'tab': 4},
              );
            },
            icon: const Icon(Icons.history_rounded, size: 18),
            label: const Text('Lihat di Riwayat'),
          ),
        ],
      ),
    );
  }
}
