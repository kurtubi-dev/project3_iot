import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/status_badges.dart';
import '../models/irrigation_models.dart';
import '../state/irrigation_store.dart';

class NodeDetailScreen extends StatefulWidget {
  final String nodeSlug; // 'hulu' or 'hilir'

  const NodeDetailScreen({super.key, required this.nodeSlug});

  @override
  State<NodeDetailScreen> createState() => _NodeDetailScreenState();
}

class _NodeDetailScreenState extends State<NodeDetailScreen> {
  bool _showRainfallChart = false; // false = TMA (cm), true = Curah Hujan (mm)

  @override
  Widget build(BuildContext context) {
    final store = IrrigationStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final node =
            widget.nodeSlug == 'hilir' ? store.hilirNode : store.huluNode;

        return Scaffold(
          appBar: AppBar(
            title: Text(node.name),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!store.isAppOnline) ...[
                const OfflineReadOnlyBanner(),
                const SizedBox(height: 12),
              ],
              ContextHeaderBar(
                icon: Icons.sensors_rounded,
                title: node.name,
                subtitle: node.location,
                trailing: ConnectivityBadge(
                  status: node.connectivity,
                  compact: true,
                ),
              ),
              const SizedBox(height: 14),

              // Nilai Sensor Terkini (Eksplisit + Satuan)
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Curah Hujan',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${node.rainfallMm} mm/jam',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            AlertLevelBadge(
                              level: node.rainfallLevel,
                              compact: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tinggi Muka Air',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${node.waterLevelCm} cm',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            AlertLevelBadge(
                              level: node.waterLevelStatus,
                              compact: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Grafik Tren 60 Menit
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Grafik Tren 60 Menit Terakhir',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Tinggi Muka Air (cm)'),
                            icon: Icon(Icons.waves_rounded),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Curah Hujan (mm)'),
                            icon: Icon(Icons.grain_rounded),
                          ),
                        ],
                        selected: {_showRainfallChart},
                        onSelectionChanged: (selected) {
                          setState(() {
                            _showRainfallChart = selected.first;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _TrendChartPainter(
                            points: node.trend60m,
                            showRainfall: _showRainfallChart,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatClock(node.trend60m.first.timestamp),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            formatClock(node.trend60m.last.timestamp),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Kesehatan Perangkat, Kualitas Data & Waktu Pembaruan
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kesehatan Perangkat & Kualitas Data',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Divider(height: 22),
                      _DetailRow(
                        label: 'Status Baterai',
                        value: '${node.batteryPercent}%',
                      ),
                      const SizedBox(height: 10),
                      _DetailRow(
                        label: 'Kualitas Data',
                        value: node.dataQuality,
                      ),
                      const SizedBox(height: 10),
                      _DetailRow(
                        label: 'Kondisi Lingkungan',
                        value: node.overallLevel == AlertLevel.kritis
                            ? 'Kritis (Waspada Debit Tinggi)'
                            : (node.overallLevel == AlertLevel.waspada
                                ? 'Waspada'
                                : 'Normal'),
                      ),
                      const SizedBox(height: 12),
                      FreshnessChip(
                        freshness: node.freshness,
                        updatedAt: node.updatedAt,
                      ),
                    ],
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<TelemetryPoint> points;
  final bool showRainfall;

  _TrendChartPainter({
    required this.points,
    required this.showRainfall,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final values = points
        .map((p) => showRainfall ? p.rainfallMm : p.waterLevelCm)
        .toList();
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final gridPaint = Paint()
      ..color = AppColors.borderLight
      ..strokeWidth = 1;

    for (var i = 0; i <= 3; i++) {
      final y = (size.height - 20) * (i / 3) + 10;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final lineColor = showRainfall ? AppColors.info : AppColors.navyPrimary;
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final stepX = size.width / (points.length - 1).clamp(1, 999);

    for (var i = 0; i < points.length; i++) {
      final x = i * stepX;
      final normalized = (values[i] - minVal) / range;
      final y = (size.height - 24) - (normalized * (size.height - 36)) + 12;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.showRainfall != showRainfall ||
        oldDelegate.points != points;
  }
}
