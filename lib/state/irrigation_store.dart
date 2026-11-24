import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/irrigation_models.dart';

class IrrigationStore extends ChangeNotifier {
  static final IrrigationStore instance = IrrigationStore._internal();
  IrrigationStore._internal() {
    _seedInitialData();
  }

  static const String _sessionUserKey = 'siaga_irigasi_user_id';
  static const int significantDeviationThreshold = 15; // % selisih signifikan dari AI

  AppUser? _currentUser;
  bool _isSessionChecked = false;
  bool _isAppOnline = true;
  bool _isRefreshing = false;

  late List<TelemetryNode> _nodes;
  late List<Gate> _gates;
  late List<AiRecommendation> _recommendations;
  late List<GateCommand> _commands;
  late List<AppNotification> _notifications;
  late List<HistoryEvent> _history;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isSessionChecked => _isSessionChecked;
  bool get isAppOnline => _isAppOnline;
  bool get isRefreshing => _isRefreshing;

  List<TelemetryNode> get nodes => List.unmodifiable(_nodes);
  TelemetryNode get huluNode => _nodes.firstWhere((n) => n.slug == 'hulu');
  TelemetryNode get hilirNode => _nodes.firstWhere((n) => n.slug == 'hilir');

  List<Gate> get gates => List.unmodifiable(_gates);
  List<AiRecommendation> get recommendations => List.unmodifiable(_recommendations);
  List<GateCommand> get commands => List.unmodifiable(_commands);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<HistoryEvent> get history => List.unmodifiable(_history);

  int get unreadNotificationCount =>
      _notifications.where((n) => !n.isRead).length;

  int get unacknowledgedCriticalCount => _notifications
      .where((n) => n.requiresAck && !n.isAcknowledged)
      .length;

  List<AppNotification> get unacknowledgedCriticalAlerts => _notifications
      .where((n) => n.requiresAck && !n.isAcknowledged)
      .toList();

  AlertLevel get highestSystemAlertLevel {
    if (_nodes.any((n) => n.overallLevel == AlertLevel.kritis) ||
        unacknowledgedCriticalCount > 0) {
      return AlertLevel.kritis;
    }
    if (_nodes.any((n) => n.overallLevel == AlertLevel.waspada)) {
      return AlertLevel.waspada;
    }
    return AlertLevel.normal;
  }

  void _seedInitialData() {
    final now = DateTime.now();

    List<TelemetryPoint> buildTrend(double baseRain, double baseTma, bool rising) {
      return List.generate(12, (i) {
        final minsAgo = (11 - i) * 5;
        final factor = rising ? i * 0.45 : (11 - i) * 0.2;
        return TelemetryPoint(
          timestamp: now.subtract(Duration(minutes: minsAgo)),
          rainfallMm: double.parse((baseRain + (i % 3) * 1.8).toStringAsFixed(1)),
          waterLevelCm: double.parse((baseTma + factor).toStringAsFixed(1)),
        );
      });
    }

    _nodes = [
      TelemetryNode(
        id: 'node-hulu',
        slug: 'hulu',
        name: 'Node 1 — Hulu',
        location: 'Bendung Sukamelang (Sektor Hulu)',
        connectivity: ConnectivityStatus.online,
        rainfallMm: 42.6,
        waterLevelCm: 178.5,
        rainfallLevel: AlertLevel.waspada,
        waterLevelStatus: AlertLevel.kritis,
        batteryPercent: 86,
        dataQuality: 'NORMAL',
        updatedAt: now.subtract(const Duration(minutes: 2)),
        freshness: DataFreshness.terkini,
        trend60m: buildTrend(36.0, 172.0, true),
      ),
      TelemetryNode(
        id: 'node-hilir',
        slug: 'hilir',
        name: 'Node 2 — Hilir',
        location: 'Saluran Sekunder Ciasem (Sektor Hilir)',
        connectivity: ConnectivityStatus.online,
        rainfallMm: 18.4,
        waterLevelCm: 124.0,
        rainfallLevel: AlertLevel.normal,
        waterLevelStatus: AlertLevel.waspada,
        batteryPercent: 79,
        dataQuality: 'NORMAL',
        updatedAt: now.subtract(const Duration(minutes: 3)),
        freshness: DataFreshness.terkini,
        trend60m: buildTrend(15.0, 121.0, true),
      ),
    ];

    _gates = [
      Gate(
        id: 'pintu-a',
        name: 'Pintu Air A — Sukamelang',
        location: 'Saluran Primer Bendung Sukamelang',
        connectivity: ConnectivityStatus.online,
        actualOpening: 35,
        operationalStatus: 'NORMAL',
        updatedAt: now.subtract(const Duration(minutes: 2)),
        freshness: DataFreshness.terkini,
      ),
      Gate(
        id: 'pintu-b',
        name: 'Pintu Air B — Ciasem Sekunder',
        location: 'Saluran Sekunder Ciasem KM 4',
        connectivity: ConnectivityStatus.online,
        actualOpening: 50,
        operationalStatus: 'NORMAL',
        updatedAt: now.subtract(const Duration(minutes: 4)),
        freshness: DataFreshness.terkini,
      ),
      Gate(
        id: 'pintu-c',
        name: 'Pintu Air C — Gadung Pelimpah',
        location: 'Saluran Pembuang Bendung Gadung',
        connectivity: ConnectivityStatus.offline,
        actualOpening: 20,
        operationalStatus: 'OFFLINE',
        updatedAt: now.subtract(const Duration(minutes: 48)),
        freshness: DataFreshness.kedaluwarsa,
      ),
    ];

    _recommendations = [
      AiRecommendation(
        id: 'rec-a',
        gateId: 'pintu-a',
        gateName: 'Pintu Air A — Sukamelang',
        gateLocation: 'Saluran Primer Bendung Sukamelang',
        currentOpening: 35,
        recommendedOpening: 75,
        alertLevel: AlertLevel.kritis,
        reason:
            'Kenaikan TMA di Node 1 Hulu mencapai 178.5 cm (Kritis) dengan curah hujan 42.6 mm/jam. Disarankan menaikkan bukaan ke 75% untuk melepas debit banjir ke saluran pelimpah.',
        huluSnapshot: NodeSnapshot(
          nodeName: 'Node 1 — Hulu',
          rainfallMm: 42.6,
          waterLevelCm: 178.5,
          level: AlertLevel.kritis,
          capturedAt: now.subtract(const Duration(minutes: 2)),
        ),
        hilirSnapshot: NodeSnapshot(
          nodeName: 'Node 2 — Hilir',
          rainfallMm: 18.4,
          waterLevelCm: 124.0,
          level: AlertLevel.waspada,
          capturedAt: now.subtract(const Duration(minutes: 3)),
        ),
        createdAt: now.subtract(const Duration(minutes: 4)),
        expiresAt: now.add(const Duration(minutes: 26)),
        decision: RecommendationDecision.pending,
      ),
      AiRecommendation(
        id: 'rec-b',
        gateId: 'pintu-b',
        gateName: 'Pintu Air B — Ciasem Sekunder',
        gateLocation: 'Saluran Sekunder Ciasem KM 4',
        currentOpening: 50,
        recommendedOpening: 40,
        alertLevel: AlertLevel.waspada,
        reason:
            'TMA Node 2 Hilir berada pada status Waspada (124.0 cm). Penurunan bukaan menjadi 40% disarankan untuk menjaga kapasitas tampung hilir tetap aman.',
        huluSnapshot: NodeSnapshot(
          nodeName: 'Node 1 — Hulu',
          rainfallMm: 42.6,
          waterLevelCm: 178.5,
          level: AlertLevel.kritis,
          capturedAt: now.subtract(const Duration(minutes: 2)),
        ),
        hilirSnapshot: NodeSnapshot(
          nodeName: 'Node 2 — Hilir',
          rainfallMm: 18.4,
          waterLevelCm: 124.0,
          level: AlertLevel.waspada,
          capturedAt: now.subtract(const Duration(minutes: 3)),
        ),
        createdAt: now.subtract(const Duration(minutes: 8)),
        expiresAt: now.add(const Duration(minutes: 22)),
        decision: RecommendationDecision.pending,
      ),
      AiRecommendation(
        id: 'rec-c',
        gateId: 'pintu-c',
        gateName: 'Pintu Air C — Gadung Pelimpah',
        gateLocation: 'Saluran Pembuang Bendung Gadung',
        currentOpening: 20,
        recommendedOpening: 50,
        alertLevel: AlertLevel.waspada,
        reason:
            'Rekomendasi sebelumnya telah melewati masa berlaku dan perangkat saat ini offline. Kendali otomatis tidak tersedia.',
        huluSnapshot: NodeSnapshot(
          nodeName: 'Node 1 — Hulu',
          rainfallMm: 31.0,
          waterLevelCm: 162.0,
          level: AlertLevel.waspada,
          capturedAt: now.subtract(const Duration(minutes: 55)),
        ),
        hilirSnapshot: NodeSnapshot(
          nodeName: 'Node 2 — Hilir',
          rainfallMm: 14.2,
          waterLevelCm: 112.0,
          level: AlertLevel.normal,
          capturedAt: now.subtract(const Duration(minutes: 55)),
        ),
        createdAt: now.subtract(const Duration(minutes: 65)),
        expiresAt: now.subtract(const Duration(minutes: 35)),
        decision: RecommendationDecision.expired,
      ),
    ];

    _commands = [];

    _notifications = [
      AppNotification(
        id: 'notif-1',
        type: NotificationType.sensorAlert,
        alertLevel: AlertLevel.kritis,
        title: 'TMA Node 1 Hulu Melampaui Ambang Kritis',
        message:
            'Tinggi muka air tercatat 178.5 cm (ambang kritis ≥ 175 cm). Segera tinjau rekomendasi bukaan pada Pintu Air A — Sukamelang.',
        objectId: 'node-hulu',
        objectName: 'Node 1 — Hulu',
        suggestedAction: 'Tinjau Rekomendasi AI untuk Pintu Air A',
        createdAt: now.subtract(const Duration(minutes: 2)),
        isRead: false,
        requiresAck: true,
        isAcknowledged: false,
      ),
      AppNotification(
        id: 'notif-2',
        type: NotificationType.aiUpdate,
        alertLevel: AlertLevel.waspada,
        title: 'Rekomendasi AI Baru: Pintu Air A (75%)',
        message:
            'AI menyarankan penyesuaian bukaan dari 35% menjadi 75% berdasarkan tren curah hujan dan TMA hulu.',
        objectId: 'rec-a',
        objectName: 'Pintu Air A — Sukamelang',
        suggestedAction: 'Buka Detail Rekomendasi',
        createdAt: now.subtract(const Duration(minutes: 4)),
        isRead: false,
        requiresAck: false,
      ),
      AppNotification(
        id: 'notif-3',
        type: NotificationType.deviceIssue,
        alertLevel: AlertLevel.waspada,
        title: 'Pintu Air C — Gadung Offline',
        message:
            'Tidak ada heartbeat perangkat selama 48 menit terakhir. Kontrol jarak jauh dinonaktifkan sementara.',
        objectId: 'pintu-c',
        objectName: 'Pintu Air C — Gadung Pelimpah',
        suggestedAction: 'Periksa koneksi panel lapangan',
        createdAt: now.subtract(const Duration(minutes: 48)),
        isRead: true,
        requiresAck: false,
      ),
    ];

    _history = [
      HistoryEvent(
        id: 'hist-1',
        category: HistoryCategory.monitoring,
        title: 'Pembaruan Telemetri Node 1 Hulu',
        summary: 'Curah hujan 42.6 mm/jam, TMA 178.5 cm (Status Kritis)',
        actorName: 'Sistem Telemetri ESP32',
        statusLabel: 'Kritis',
        alertLevel: AlertLevel.kritis,
        nodeName: 'Node 1 — Hulu',
        referenceId: 'TEL-20261125-001',
        timestamp: now.subtract(const Duration(minutes: 2)),
      ),
      HistoryEvent(
        id: 'hist-2',
        category: HistoryCategory.rekomendasi,
        title: 'Rekomendasi AI Pintu Air A Dibuat',
        summary: 'Saran bukaan 75% (saat ini 35%) untuk antisipasi debit hulu',
        actorName: 'AI Service (FastAPI)',
        statusLabel: 'Menunggu Keputusan',
        alertLevel: AlertLevel.kritis,
        gateName: 'Pintu Air A — Sukamelang',
        recommendationId: 'rec-a',
        aiRecommendedOpening: 75,
        referenceId: 'REC-A-20261125',
        timestamp: now.subtract(const Duration(minutes: 4)),
      ),
      HistoryEvent(
        id: 'hist-3',
        category: HistoryCategory.kendali,
        title: 'Penyesuaian Bukaan Pintu Air B',
        summary: 'Bukaan diubah dari 30% ke 50% sesuai jadwal irigasi pagi',
        actorName: 'Budi Santoso (Petugas Lapang)',
        statusLabel: 'Berhasil (50%)',
        alertLevel: AlertLevel.normal,
        gateName: 'Pintu Air B — Ciasem Sekunder',
        initialOpening: 30,
        targetOpening: 50,
        finalOpening: 50,
        referenceId: 'CMD-20261125-089',
        timestamp: now.subtract(const Duration(hours: 2, minutes: 15)),
      ),
    ];
  }

  Future<void> checkSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_sessionUserKey);
      if (savedId != null && savedId.isNotEmpty) {
        _currentUser = AppUser(
          id: savedId,
          name: 'Budi Santoso',
          role: 'PETUGAS_LAPANGAN',
          status: 'ACTIVE',
          unitKerja: 'Dinas PUPR Kab. Subang — Bidang SDA',
        );
      }
    } catch (_) {
      // ignore storage errors in test environment
    }
    _isSessionChecked = true;
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String idOrEmail, String password) async {
    final cleanId = idOrEmail.trim();
    final cleanPass = password.trim();

    if (cleanId.isEmpty || cleanPass.isEmpty) {
      return {
        'success': false,
        'message': 'ID Petugas dan kata sandi wajib diisi.',
      };
    }

    // Validasi prototipe lokal (siap disambungkan ke POST /api/v1/auth/login)
    await Future.delayed(const Duration(milliseconds: 500));

    final isValidPass = cleanPass == 'petugas123' ||
        cleanPass == 'petugas123*#' ||
        cleanPass == 'admin123*#';

    if (!isValidPass) {
      return {
        'success': false,
        'message': 'ID Petugas atau kata sandi tidak sesuai.',
      };
    }

    final displayName = cleanId.contains('@')
        ? cleanId.split('@').first.replaceAll('.', ' ').toUpperCase()
        : 'Petugas $cleanId';

    _currentUser = AppUser(
      id: cleanId,
      name: cleanId == 'petugas.sda@subang.go.id' ? 'Budi Santoso' : displayName,
      role: 'PETUGAS_LAPANGAN',
      status: 'ACTIVE',
      unitKerja: 'Dinas PUPR Kab. Subang — Bidang SDA',
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionUserKey, cleanId);
    } catch (_) {}

    notifyListeners();
    return {
      'success': true,
      'message': 'Login berhasil.',
    };
  }

  Future<void> logout() async {
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionUserKey);
    } catch (_) {}
    notifyListeners();
  }

  void setAppOnline(bool online) {
    _isAppOnline = online;
    notifyListeners();
  }

  Future<void> refreshData() async {
    if (!_isAppOnline) return;
    _isRefreshing = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    final now = DateTime.now();
    _nodes = _nodes.map((n) {
      return TelemetryNode(
        id: n.id,
        slug: n.slug,
        name: n.name,
        location: n.location,
        connectivity: n.connectivity,
        rainfallMm: n.rainfallMm,
        waterLevelCm: n.waterLevelCm,
        rainfallLevel: n.rainfallLevel,
        waterLevelStatus: n.waterLevelStatus,
        batteryPercent: n.batteryPercent,
        dataQuality: n.dataQuality,
        updatedAt: now,
        freshness: DataFreshness.terkini,
        trend60m: n.trend60m,
      );
    }).toList();
    _isRefreshing = false;
    notifyListeners();
  }

  Gate? getGateById(String gateId) {
    try {
      return _gates.firstWhere((g) => g.id == gateId);
    } catch (_) {
      return null;
    }
  }

  AiRecommendation? getRecommendationById(String recId) {
    try {
      return _recommendations.firstWhere((r) => r.id == recId);
    } catch (_) {
      return null;
    }
  }

  AiRecommendation? getLatestRecommendationForGate(String gateId) {
    final matches = _recommendations.where((r) => r.gateId == gateId).toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matches.first;
  }

  void rejectRecommendation(String recId, {String? note}) {
    final idx = _recommendations.indexWhere((r) => r.id == recId);
    if (idx == -1) return;

    final actor = _currentUser?.name ?? 'Petugas Lapang';
    final now = DateTime.now();
    final updated = _recommendations[idx].copyWith(
      decision: RecommendationDecision.rejected,
      decidedBy: actor,
      decidedAt: now,
      rejectionNote: note,
    );
    _recommendations[idx] = updated;

    _history.insert(
      0,
      HistoryEvent(
        id: 'hist-${now.millisecondsSinceEpoch}',
        category: HistoryCategory.rekomendasi,
        title: 'Rekomendasi AI Tidak Diterapkan',
        summary:
            'Petugas memilih tidak menerapkan saran bukaan ${updated.recommendedOpening}% pada ${updated.gateName}. Posisi pintu tidak diubah.',
        actorName: actor,
        statusLabel: 'Tidak Diterapkan',
        alertLevel: AlertLevel.normal,
        gateName: updated.gateName,
        recommendationId: updated.id,
        aiRecommendedOpening: updated.recommendedOpening,
        deviationReason: note,
        referenceId: 'DEC-${now.millisecondsSinceEpoch.toString().substring(7)}',
        timestamp: now,
      ),
    );

    notifyListeners();
  }

  Future<GateCommand> submitGateCommand({
    required String gateId,
    required int targetOpening,
    String? recommendationId,
    String? deviationReason,
    bool simulateTimeout = false,
    bool simulateFailure = false,
    void Function(GateCommandStatus status)? onProgress,
  }) async {
    final gateIdx = _gates.indexWhere((g) => g.id == gateId);
    if (gateIdx == -1) {
      throw StateError('Pintu tidak ditemukan.');
    }
    if (!_isAppOnline) {
      throw StateError('Aplikasi sedang offline. Kendali dinonaktifkan.');
    }
    final gate = _gates[gateIdx];
    if (gate.connectivity != ConnectivityStatus.online) {
      throw StateError('Pintu sedang offline atau gangguan.');
    }

    final actorId = _currentUser?.id ?? 'petugas';
    final actorName = _currentUser?.name ?? 'Petugas Lapang';
    final now = DateTime.now();
    final rec = recommendationId != null ? getRecommendationById(recommendationId) : null;
    final refId = 'CMD-${now.millisecondsSinceEpoch.toString().substring(6)}';

    var command = GateCommand(
      id: 'cmd-${now.millisecondsSinceEpoch}',
      referenceId: refId,
      gateId: gate.id,
      gateName: gate.name,
      userId: actorId,
      userName: actorName,
      initialOpening: gate.actualOpening,
      targetOpening: targetOpening,
      recommendationId: recommendationId,
      aiRecommendedOpening: rec?.recommendedOpening,
      deviationReason: deviationReason,
      status: GateCommandStatus.sending,
      createdAt: now,
    );

    _commands.insert(0, command);
    _gates[gateIdx] = gate.copyWith(
      targetOpening: targetOpening,
      activeCommandId: command.id,
      operationalStatus: 'MOVING',
    );
    notifyListeners();
    onProgress?.call(GateCommandStatus.sending);

    await Future.delayed(const Duration(milliseconds: 500));
    command = command.copyWith(status: GateCommandStatus.serverAccepted);
    onProgress?.call(GateCommandStatus.serverAccepted);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    command = command.copyWith(status: GateCommandStatus.deviceAccepted);
    onProgress?.call(GateCommandStatus.deviceAccepted);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));
    command = command.copyWith(status: GateCommandStatus.moving);
    onProgress?.call(GateCommandStatus.moving);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));
    final completedAt = DateTime.now();

    if (simulateTimeout) {
      command = command.copyWith(
        status: GateCommandStatus.timeout,
        deviceMessage:
            'Waktu tunggu konfirmasi perangkat habis. Status akhir belum diketahui — periksa posisi aktual di lapangan.',
        completedAt: completedAt,
      );
      _gates[gateIdx] = _gates[gateIdx].copyWith(
        clearTarget: true,
        clearActiveCommand: true,
        operationalStatus: 'ERROR',
        updatedAt: completedAt,
      );
    } else if (simulateFailure) {
      command = command.copyWith(
        status: GateCommandStatus.failed,
        finalOpening: gate.actualOpening,
        deviceMessage: 'Aktuator pintu melaporkan hambatan mekanis (EXECUTION_FAILED).',
        completedAt: completedAt,
      );
      _gates[gateIdx] = _gates[gateIdx].copyWith(
        clearTarget: true,
        clearActiveCommand: true,
        operationalStatus: 'ERROR',
        updatedAt: completedAt,
      );
    } else {
      command = command.copyWith(
        status: GateCommandStatus.executed,
        finalOpening: targetOpening,
        deviceMessage: 'Pintu berhasil mencapai target bukaan $targetOpening%.',
        completedAt: completedAt,
      );
      _gates[gateIdx] = _gates[gateIdx].copyWith(
        actualOpening: targetOpening,
        clearTarget: true,
        clearActiveCommand: true,
        operationalStatus: 'NORMAL',
        updatedAt: completedAt,
        freshness: DataFreshness.terkini,
      );
    }

    final cmdIdx = _commands.indexWhere((c) => c.id == command.id);
    if (cmdIdx != -1) {
      _commands[cmdIdx] = command;
    }

    // Update recommendation decision status if linked
    if (rec != null && rec.decision == RecommendationDecision.pending) {
      final recIdx = _recommendations.indexWhere((r) => r.id == rec.id);
      if (recIdx != -1) {
        final isModified = targetOpening != rec.recommendedOpening;
        _recommendations[recIdx] = rec.copyWith(
          decision: isModified
              ? RecommendationDecision.modified
              : RecommendationDecision.applied,
          decidedBy: actorName,
          decidedAt: completedAt,
        );
      }
    }

    // Record to unified history
    final statusText = command.status == GateCommandStatus.executed
        ? 'Berhasil ($targetOpening%)'
        : (command.status == GateCommandStatus.timeout ? 'Timeout' : 'Gagal');
    final level = command.status == GateCommandStatus.executed
        ? AlertLevel.normal
        : AlertLevel.kritis;

    _history.insert(
      0,
      HistoryEvent(
        id: 'hist-${completedAt.millisecondsSinceEpoch}',
        category: HistoryCategory.kendali,
        title: 'Kendali ${gate.name}',
        summary: command.deviceMessage ?? 'Perintah bukaan $targetOpening%',
        actorName: actorName,
        statusLabel: statusText,
        alertLevel: level,
        gateName: gate.name,
        initialOpening: command.initialOpening,
        targetOpening: command.targetOpening,
        finalOpening: command.finalOpening,
        aiRecommendedOpening: command.aiRecommendedOpening,
        recommendationId: command.recommendationId,
        deviationReason: command.deviationReason,
        referenceId: command.referenceId,
        timestamp: completedAt,
      ),
    );

    // Record notification
    _notifications.insert(
      0,
      AppNotification(
        id: 'notif-${completedAt.millisecondsSinceEpoch}',
        type: NotificationType.commandResult,
        alertLevel: level,
        title: 'Hasil Kendali ${gate.name}: $statusText',
        message: command.deviceMessage ?? '',
        objectId: gate.id,
        objectName: gate.name,
        createdAt: completedAt,
        isRead: false,
      ),
    );

    notifyListeners();
    return command;
  }

  void markNotificationRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void acknowledgeCriticalNotification(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    final actor = _currentUser?.name ?? 'Petugas Lapang';
    final now = DateTime.now();
    _notifications[idx] = _notifications[idx].copyWith(
      isRead: true,
      isAcknowledged: true,
      acknowledgedBy: actor,
      acknowledgedAt: now,
    );
    _history.insert(
      0,
      HistoryEvent(
        id: 'hist-ack-${now.millisecondsSinceEpoch}',
        category: HistoryCategory.monitoring,
        title: 'Peringatan Kritis Diakui',
        summary:
            '${_notifications[idx].title} telah diakui oleh $actor. Acknowledgement tidak otomatis mengubah posisi pintu.',
        actorName: actor,
        statusLabel: 'Diakui',
        alertLevel: AlertLevel.waspada,
        nodeName: _notifications[idx].objectName,
        referenceId: 'ACK-${now.millisecondsSinceEpoch.toString().substring(7)}',
        timestamp: now,
      ),
    );
    notifyListeners();
  }
}
