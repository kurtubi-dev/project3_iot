enum ConnectivityStatus {
  online,
  offline,
  gangguan,
  connecting,
  unknown,
}

enum DataFreshness {
  terkini,
  terlambat,
  kedaluwarsa,
  belumAdaData,
}

enum AlertLevel {
  normal,
  waspada,
  kritis,
  unknown,
}

enum RecommendationDecision {
  pending,
  applied,
  modified,
  rejected,
  expired,
}

enum GateCommandStatus {
  draft,
  sending,
  serverAccepted,
  deviceAccepted,
  moving,
  executed,
  failed,
  timeout,
  cancelled,
  unknown,
}

enum NotificationType {
  sensorAlert,
  deviceIssue,
  aiUpdate,
  commandResult,
}

enum HistoryCategory {
  monitoring,
  rekomendasi,
  kendali,
}

class AppUser {
  final String id;
  final String name;
  final String role;
  final String status;
  final String unitKerja;

  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    required this.unitKerja,
  });
}

class TelemetryPoint {
  final DateTime timestamp;
  final double rainfallMm;
  final double waterLevelCm;
  final bool isAnomaly;

  const TelemetryPoint({
    required this.timestamp,
    required this.rainfallMm,
    required this.waterLevelCm,
    this.isAnomaly = false,
  });
}

class TelemetryNode {
  final String id;
  final String slug; // 'hulu' or 'hilir'
  final String name;
  final String location;
  final ConnectivityStatus connectivity;
  final double rainfallMm;
  final double waterLevelCm;
  final AlertLevel rainfallLevel;
  final AlertLevel waterLevelStatus;
  final int batteryPercent;
  final String dataQuality; // 'NORMAL' | 'ANOMALY'
  final DateTime updatedAt;
  final DataFreshness freshness;
  final List<TelemetryPoint> trend60m;

  const TelemetryNode({
    required this.id,
    required this.slug,
    required this.name,
    required this.location,
    required this.connectivity,
    required this.rainfallMm,
    required this.waterLevelCm,
    required this.rainfallLevel,
    required this.waterLevelStatus,
    required this.batteryPercent,
    required this.dataQuality,
    required this.updatedAt,
    required this.freshness,
    required this.trend60m,
  });

  AlertLevel get overallLevel {
    if (rainfallLevel == AlertLevel.kritis || waterLevelStatus == AlertLevel.kritis) {
      return AlertLevel.kritis;
    }
    if (rainfallLevel == AlertLevel.waspada || waterLevelStatus == AlertLevel.waspada) {
      return AlertLevel.waspada;
    }
    if (connectivity == ConnectivityStatus.unknown) {
      return AlertLevel.unknown;
    }
    return AlertLevel.normal;
  }
}

class NodeSnapshot {
  final String nodeName;
  final double rainfallMm;
  final double waterLevelCm;
  final AlertLevel level;
  final DateTime capturedAt;

  const NodeSnapshot({
    required this.nodeName,
    required this.rainfallMm,
    required this.waterLevelCm,
    required this.level,
    required this.capturedAt,
  });
}

class AiRecommendation {
  final String id;
  final String gateId;
  final String gateName;
  final String gateLocation;
  final int currentOpening;
  final int recommendedOpening;
  final AlertLevel alertLevel;
  final String reason;
  final NodeSnapshot huluSnapshot;
  final NodeSnapshot hilirSnapshot;
  final DateTime createdAt;
  final DateTime expiresAt;
  final RecommendationDecision decision;
  final String? decidedBy;
  final DateTime? decidedAt;
  final String? rejectionNote;
  final bool isAiAvailable;

  const AiRecommendation({
    required this.id,
    required this.gateId,
    required this.gateName,
    required this.gateLocation,
    required this.currentOpening,
    required this.recommendedOpening,
    required this.alertLevel,
    required this.reason,
    required this.huluSnapshot,
    required this.hilirSnapshot,
    required this.createdAt,
    required this.expiresAt,
    required this.decision,
    this.decidedBy,
    this.decidedAt,
    this.rejectionNote,
    this.isAiAvailable = true,
  });

  bool get isExpired =>
      decision == RecommendationDecision.expired || DateTime.now().isAfter(expiresAt);

  AiRecommendation copyWith({
    RecommendationDecision? decision,
    String? decidedBy,
    DateTime? decidedAt,
    String? rejectionNote,
  }) {
    return AiRecommendation(
      id: id,
      gateId: gateId,
      gateName: gateName,
      gateLocation: gateLocation,
      currentOpening: currentOpening,
      recommendedOpening: recommendedOpening,
      alertLevel: alertLevel,
      reason: reason,
      huluSnapshot: huluSnapshot,
      hilirSnapshot: hilirSnapshot,
      createdAt: createdAt,
      expiresAt: expiresAt,
      decision: decision ?? this.decision,
      decidedBy: decidedBy ?? this.decidedBy,
      decidedAt: decidedAt ?? this.decidedAt,
      rejectionNote: rejectionNote ?? this.rejectionNote,
      isAiAvailable: isAiAvailable,
    );
  }
}

class Gate {
  final String id;
  final String name;
  final String location;
  final ConnectivityStatus connectivity;
  final int actualOpening;
  final int? targetOpening;
  final String operationalStatus; // NORMAL, MOVING, ERROR, OFFLINE
  final DateTime updatedAt;
  final DataFreshness freshness;
  final String? activeCommandId;

  const Gate({
    required this.id,
    required this.name,
    required this.location,
    required this.connectivity,
    required this.actualOpening,
    this.targetOpening,
    required this.operationalStatus,
    required this.updatedAt,
    required this.freshness,
    this.activeCommandId,
  });

  Gate copyWith({
    ConnectivityStatus? connectivity,
    int? actualOpening,
    int? targetOpening,
    bool clearTarget = false,
    String? operationalStatus,
    DateTime? updatedAt,
    DataFreshness? freshness,
    String? activeCommandId,
    bool clearActiveCommand = false,
  }) {
    return Gate(
      id: id,
      name: name,
      location: location,
      connectivity: connectivity ?? this.connectivity,
      actualOpening: actualOpening ?? this.actualOpening,
      targetOpening: clearTarget ? null : (targetOpening ?? this.targetOpening),
      operationalStatus: operationalStatus ?? this.operationalStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      freshness: freshness ?? this.freshness,
      activeCommandId:
          clearActiveCommand ? null : (activeCommandId ?? this.activeCommandId),
    );
  }
}

class GateCommand {
  final String id;
  final String referenceId;
  final String gateId;
  final String gateName;
  final String userId;
  final String userName;
  final int initialOpening;
  final int targetOpening;
  final int? finalOpening;
  final String? recommendationId;
  final int? aiRecommendedOpening;
  final String? deviationReason;
  final GateCommandStatus status;
  final String? deviceMessage;
  final DateTime createdAt;
  final DateTime? completedAt;

  const GateCommand({
    required this.id,
    required this.referenceId,
    required this.gateId,
    required this.gateName,
    required this.userId,
    required this.userName,
    required this.initialOpening,
    required this.targetOpening,
    this.finalOpening,
    this.recommendationId,
    this.aiRecommendedOpening,
    this.deviationReason,
    required this.status,
    this.deviceMessage,
    required this.createdAt,
    this.completedAt,
  });

  GateCommand copyWith({
    int? finalOpening,
    GateCommandStatus? status,
    String? deviceMessage,
    DateTime? completedAt,
  }) {
    return GateCommand(
      id: id,
      referenceId: referenceId,
      gateId: gateId,
      gateName: gateName,
      userId: userId,
      userName: userName,
      initialOpening: initialOpening,
      targetOpening: targetOpening,
      finalOpening: finalOpening ?? this.finalOpening,
      recommendationId: recommendationId,
      aiRecommendedOpening: aiRecommendedOpening,
      deviationReason: deviationReason,
      status: status ?? this.status,
      deviceMessage: deviceMessage ?? this.deviceMessage,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class AppNotification {
  final String id;
  final NotificationType type;
  final AlertLevel alertLevel;
  final String title;
  final String message;
  final String? objectId;
  final String objectName;
  final String? suggestedAction;
  final DateTime createdAt;
  final bool isRead;
  final bool requiresAck;
  final bool isAcknowledged;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.alertLevel,
    required this.title,
    required this.message,
    this.objectId,
    required this.objectName,
    this.suggestedAction,
    required this.createdAt,
    this.isRead = false,
    this.requiresAck = false,
    this.isAcknowledged = false,
    this.acknowledgedBy,
    this.acknowledgedAt,
  });

  AppNotification copyWith({
    bool? isRead,
    bool? isAcknowledged,
    String? acknowledgedBy,
    DateTime? acknowledgedAt,
  }) {
    return AppNotification(
      id: id,
      type: type,
      alertLevel: alertLevel,
      title: title,
      message: message,
      objectId: objectId,
      objectName: objectName,
      suggestedAction: suggestedAction,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      requiresAck: requiresAck,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    );
  }
}

class HistoryEvent {
  final String id;
  final HistoryCategory category;
  final String title;
  final String summary;
  final String actorName;
  final String statusLabel;
  final AlertLevel alertLevel;
  final String? gateName;
  final String? nodeName;
  final int? initialOpening;
  final int? targetOpening;
  final int? finalOpening;
  final int? aiRecommendedOpening;
  final String? recommendationId;
  final String? deviationReason;
  final String referenceId;
  final DateTime timestamp;

  const HistoryEvent({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.actorName,
    required this.statusLabel,
    required this.alertLevel,
    this.gateName,
    this.nodeName,
    this.initialOpening,
    this.targetOpening,
    this.finalOpening,
    this.aiRecommendedOpening,
    this.recommendationId,
    this.deviationReason,
    required this.referenceId,
    required this.timestamp,
  });
}
