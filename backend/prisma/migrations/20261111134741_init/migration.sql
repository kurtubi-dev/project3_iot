-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('ADMIN', 'PETUGAS_LAPANGAN', 'PENGELOLA');

-- CreateEnum
CREATE TYPE "UserStatus" AS ENUM ('ACTIVE', 'INACTIVE');

-- CreateEnum
CREATE TYPE "AuthProvider" AS ENUM ('LOCAL', 'GOOGLE');

-- CreateEnum
CREATE TYPE "DeviceConnectionStatus" AS ENUM ('ONLINE', 'OFFLINE');

-- CreateEnum
CREATE TYPE "SensorType" AS ENUM ('RAINFALL', 'WATER_LEVEL');

-- CreateEnum
CREATE TYPE "TelemetryValidityStatus" AS ENUM ('NORMAL', 'ANOMALY');

-- CreateEnum
CREATE TYPE "GateOperationalStatus" AS ENUM ('NORMAL', 'MOVING', 'ERROR', 'OFFLINE');

-- CreateEnum
CREATE TYPE "GateCommandType" AS ENUM ('OPEN', 'CLOSE', 'SET_PERCENTAGE');

-- CreateEnum
CREATE TYPE "GateCommandSource" AS ENUM ('MANUAL', 'AI_RECOMMENDATION');

-- CreateEnum
CREATE TYPE "GateCommandStatus" AS ENUM ('PENDING', 'APPROVED', 'SENT', 'EXECUTED', 'CANCELLED', 'FAILED', 'TIMEOUT');

-- CreateEnum
CREATE TYPE "GateCommandFailureType" AS ENUM ('DELIVERY_FAILED', 'EXECUTION_FAILED');

-- CreateEnum
CREATE TYPE "GateOperationFinalStatus" AS ENUM ('EXECUTED', 'FAILED', 'TIMEOUT');

-- CreateEnum
CREATE TYPE "GateCommandEventType" AS ENUM ('COMMAND_SENT', 'DELIVERY_ACKNOWLEDGED', 'GATE_MOVING', 'EXECUTION_SUCCEEDED', 'EXECUTION_FAILED', 'DELIVERY_FAILED', 'RETRY_ATTEMPTED', 'COMMAND_TIMEOUT');

-- CreateEnum
CREATE TYPE "PredictionType" AS ENUM ('RAINFALL', 'WATER_LEVEL');

-- CreateEnum
CREATE TYPE "RiskLevel" AS ENUM ('NORMAL', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL');

-- CreateEnum
CREATE TYPE "WarningType" AS ENUM ('ACTUAL', 'PREDICTION');

-- CreateEnum
CREATE TYPE "WarningStatus" AS ENUM ('ACTIVE', 'ACKNOWLEDGED', 'RESOLVED');

-- CreateEnum
CREATE TYPE "ThresholdOperator" AS ENUM ('GT', 'GTE', 'LT', 'LTE');

-- CreateEnum
CREATE TYPE "RecommendationStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'EXPIRED');

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "phone" VARCHAR(30),
    "role" "UserRole" NOT NULL,
    "status" "UserStatus" NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "auth_accounts" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "provider" "AuthProvider" NOT NULL,
    "provider_user_id" VARCHAR(255) NOT NULL,
    "password_hash" VARCHAR(255),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "auth_accounts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sessions" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "refresh_token_hash" VARCHAR(255) NOT NULL,
    "ip_address" VARCHAR(64),
    "user_agent" TEXT,
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "revoked_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "invitations" (
    "id" UUID NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "role" "UserRole" NOT NULL,
    "token_hash" VARCHAR(255) NOT NULL,
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "accepted_at" TIMESTAMPTZ(6),
    "created_by" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "invitations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "devices" (
    "id" UUID NOT NULL,
    "device_code" VARCHAR(50) NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "description" TEXT,
    "location" VARCHAR(255) NOT NULL,
    "connection_status" "DeviceConnectionStatus" NOT NULL DEFAULT 'OFFLINE',
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "last_seen_at" TIMESTAMPTZ(6),
    "created_by" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "devices_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "device_credentials" (
    "id" UUID NOT NULL,
    "device_id" UUID NOT NULL,
    "secret_hash" VARCHAR(255) NOT NULL,
    "created_by" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "revoked_at" TIMESTAMPTZ(6),
    "expires_at" TIMESTAMPTZ(6),

    CONSTRAINT "device_credentials_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "sensors" (
    "id" UUID NOT NULL,
    "device_id" UUID NOT NULL,
    "sensor_code" VARCHAR(50) NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "type" "SensorType" NOT NULL,
    "parameter" VARCHAR(100) NOT NULL,
    "unit" VARCHAR(30) NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "sensors_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "telemetry_readings" (
    "id" UUID NOT NULL,
    "message_id" VARCHAR(100) NOT NULL,
    "device_id" UUID NOT NULL,
    "sensor_id" UUID NOT NULL,
    "measured_at" TIMESTAMPTZ(6) NOT NULL,
    "received_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "value" DOUBLE PRECISION NOT NULL,
    "unit" VARCHAR(30) NOT NULL,
    "validity_status" "TelemetryValidityStatus" NOT NULL DEFAULT 'NORMAL',

    CONSTRAINT "telemetry_readings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "gates" (
    "id" UUID NOT NULL,
    "gate_code" VARCHAR(50) NOT NULL,
    "device_id" UUID NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "location" VARCHAR(255) NOT NULL,
    "actual_opening" DECIMAL(5,2) NOT NULL DEFAULT 0,
    "operational_status" "GateOperationalStatus" NOT NULL DEFAULT 'OFFLINE',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "gates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "gate_commands" (
    "id" UUID NOT NULL,
    "gate_id" UUID NOT NULL,
    "command_type" "GateCommandType" NOT NULL,
    "target_opening" DECIMAL(5,2) NOT NULL,
    "source" "GateCommandSource" NOT NULL,
    "recommendation_id" UUID,
    "status" "GateCommandStatus" NOT NULL DEFAULT 'PENDING',
    "failure_type" "GateCommandFailureType",
    "failure_reason" TEXT,
    "created_by" UUID NOT NULL,
    "approved_by" UUID,
    "approved_at" TIMESTAMPTZ(6),
    "sent_at" TIMESTAMPTZ(6),
    "completed_at" TIMESTAMPTZ(6),
    "retry_count" INTEGER NOT NULL DEFAULT 0,
    "last_retry_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "gate_commands_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "gate_operation_logs" (
    "id" UUID NOT NULL,
    "command_id" UUID NOT NULL,
    "gate_id" UUID NOT NULL,
    "previous_opening" DECIMAL(5,2),
    "target_opening" DECIMAL(5,2) NOT NULL,
    "actual_opening" DECIMAL(5,2),
    "started_at" TIMESTAMPTZ(6),
    "completed_at" TIMESTAMPTZ(6) NOT NULL,
    "final_status" "GateOperationFinalStatus" NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "gate_operation_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "gate_command_events" (
    "id" UUID NOT NULL,
    "command_id" UUID NOT NULL,
    "event_type" "GateCommandEventType" NOT NULL,
    "description" TEXT NOT NULL,
    "payload" JSONB,
    "occurred_at" TIMESTAMPTZ(6) NOT NULL,
    "received_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "gate_command_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "predictions" (
    "id" UUID NOT NULL,
    "sensor_id" UUID NOT NULL,
    "prediction_type" "PredictionType" NOT NULL,
    "predicted_value" DOUBLE PRECISION NOT NULL,
    "unit" VARCHAR(30) NOT NULL,
    "predicted_at" TIMESTAMPTZ(6) NOT NULL,
    "forecast_for" TIMESTAMPTZ(6) NOT NULL,
    "risk_level" "RiskLevel" NOT NULL,
    "model_version" VARCHAR(100) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "predictions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "warnings" (
    "id" UUID NOT NULL,
    "warning_type" "WarningType" NOT NULL,
    "sensor_id" UUID,
    "prediction_id" UUID,
    "risk_level" "RiskLevel" NOT NULL,
    "title" VARCHAR(200) NOT NULL,
    "description" TEXT NOT NULL,
    "status" "WarningStatus" NOT NULL DEFAULT 'ACTIVE',
    "acknowledged_by" UUID,
    "acknowledged_at" TIMESTAMPTZ(6),
    "first_occurred_at" TIMESTAMPTZ(6) NOT NULL,
    "last_updated_at" TIMESTAMPTZ(6) NOT NULL,
    "resolved_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "warnings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "warning_rules" (
    "id" UUID NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "sensor_type" "SensorType" NOT NULL,
    "parameter" VARCHAR(100) NOT NULL,
    "unit" VARCHAR(30) NOT NULL,
    "risk_level" "RiskLevel" NOT NULL,
    "operator" "ThresholdOperator" NOT NULL,
    "threshold_value" DOUBLE PRECISION NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_by" UUID NOT NULL,
    "updated_by" UUID,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "warning_rules_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "recommendations" (
    "id" UUID NOT NULL,
    "gate_id" UUID NOT NULL,
    "current_opening" DECIMAL(5,2) NOT NULL,
    "recommended_opening" DECIMAL(5,2) NOT NULL,
    "reason" TEXT NOT NULL,
    "supporting_data" JSONB NOT NULL,
    "status" "RecommendationStatus" NOT NULL DEFAULT 'PENDING',
    "created_by" UUID,
    "reviewed_by" UUID,
    "reviewed_at" TIMESTAMPTZ(6),
    "expires_at" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "recommendations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "id" UUID NOT NULL,
    "user_id" UUID,
    "action" VARCHAR(100) NOT NULL,
    "resource_type" VARCHAR(100) NOT NULL,
    "resource_id" UUID,
    "old_values" JSONB,
    "new_values" JSONB,
    "ip_address" VARCHAR(64),
    "user_agent" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "runtime_configs" (
    "id" UUID NOT NULL,
    "key" VARCHAR(150) NOT NULL,
    "value" JSONB NOT NULL,
    "description" TEXT,
    "updated_by" UUID,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "runtime_configs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "auth_accounts_user_id_idx" ON "auth_accounts"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "auth_accounts_provider_provider_user_id_key" ON "auth_accounts"("provider", "provider_user_id");

-- CreateIndex
CREATE INDEX "sessions_user_id_revoked_at_idx" ON "sessions"("user_id", "revoked_at");

-- CreateIndex
CREATE INDEX "sessions_expires_at_idx" ON "sessions"("expires_at");

-- CreateIndex
CREATE INDEX "invitations_email_idx" ON "invitations"("email");

-- CreateIndex
CREATE INDEX "invitations_expires_at_accepted_at_idx" ON "invitations"("expires_at", "accepted_at");

-- CreateIndex
CREATE UNIQUE INDEX "devices_device_code_key" ON "devices"("device_code");

-- CreateIndex
CREATE INDEX "devices_connection_status_is_active_idx" ON "devices"("connection_status", "is_active");

-- CreateIndex
CREATE INDEX "device_credentials_device_id_revoked_at_idx" ON "device_credentials"("device_id", "revoked_at");

-- CreateIndex
CREATE INDEX "device_credentials_expires_at_idx" ON "device_credentials"("expires_at");

-- CreateIndex
CREATE UNIQUE INDEX "sensors_sensor_code_key" ON "sensors"("sensor_code");

-- CreateIndex
CREATE INDEX "sensors_device_id_is_active_idx" ON "sensors"("device_id", "is_active");

-- CreateIndex
CREATE UNIQUE INDEX "sensors_id_device_id_key" ON "sensors"("id", "device_id");

-- CreateIndex
CREATE UNIQUE INDEX "telemetry_readings_message_id_key" ON "telemetry_readings"("message_id");

-- CreateIndex
CREATE INDEX "telemetry_readings_sensor_id_measured_at_idx" ON "telemetry_readings"("sensor_id", "measured_at");

-- CreateIndex
CREATE INDEX "telemetry_readings_device_id_measured_at_idx" ON "telemetry_readings"("device_id", "measured_at");

-- CreateIndex
CREATE INDEX "telemetry_readings_received_at_idx" ON "telemetry_readings"("received_at");

-- CreateIndex
CREATE INDEX "telemetry_readings_validity_status_measured_at_idx" ON "telemetry_readings"("validity_status", "measured_at");

-- CreateIndex
CREATE UNIQUE INDEX "gates_gate_code_key" ON "gates"("gate_code");

-- CreateIndex
CREATE UNIQUE INDEX "gates_device_id_key" ON "gates"("device_id");

-- CreateIndex
CREATE UNIQUE INDEX "gate_commands_recommendation_id_key" ON "gate_commands"("recommendation_id");

-- CreateIndex
CREATE INDEX "gate_commands_gate_id_created_at_idx" ON "gate_commands"("gate_id", "created_at");

-- CreateIndex
CREATE INDEX "gate_commands_status_created_at_idx" ON "gate_commands"("status", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "gate_operation_logs_command_id_key" ON "gate_operation_logs"("command_id");

-- CreateIndex
CREATE INDEX "gate_operation_logs_gate_id_completed_at_idx" ON "gate_operation_logs"("gate_id", "completed_at");

-- CreateIndex
CREATE INDEX "gate_command_events_command_id_occurred_at_idx" ON "gate_command_events"("command_id", "occurred_at");

-- CreateIndex
CREATE INDEX "predictions_sensor_id_forecast_for_idx" ON "predictions"("sensor_id", "forecast_for");

-- CreateIndex
CREATE INDEX "predictions_predicted_at_idx" ON "predictions"("predicted_at");

-- CreateIndex
CREATE INDEX "warnings_status_created_at_idx" ON "warnings"("status", "created_at");

-- CreateIndex
CREATE INDEX "warnings_sensor_id_status_idx" ON "warnings"("sensor_id", "status");

-- CreateIndex
CREATE INDEX "warnings_prediction_id_idx" ON "warnings"("prediction_id");

-- CreateIndex
CREATE INDEX "warning_rules_sensor_type_parameter_is_active_idx" ON "warning_rules"("sensor_type", "parameter", "is_active");

-- CreateIndex
CREATE INDEX "recommendations_status_expires_at_idx" ON "recommendations"("status", "expires_at");

-- CreateIndex
CREATE INDEX "recommendations_gate_id_created_at_idx" ON "recommendations"("gate_id", "created_at");

-- CreateIndex
CREATE INDEX "audit_logs_user_id_created_at_idx" ON "audit_logs"("user_id", "created_at");

-- CreateIndex
CREATE INDEX "audit_logs_resource_type_resource_id_idx" ON "audit_logs"("resource_type", "resource_id");

-- CreateIndex
CREATE INDEX "audit_logs_created_at_idx" ON "audit_logs"("created_at");

-- CreateIndex
CREATE UNIQUE INDEX "runtime_configs_key_key" ON "runtime_configs"("key");

-- AddForeignKey
ALTER TABLE "auth_accounts" ADD CONSTRAINT "auth_accounts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invitations" ADD CONSTRAINT "invitations_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "devices" ADD CONSTRAINT "devices_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "device_credentials" ADD CONSTRAINT "device_credentials_device_id_fkey" FOREIGN KEY ("device_id") REFERENCES "devices"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "device_credentials" ADD CONSTRAINT "device_credentials_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sensors" ADD CONSTRAINT "sensors_device_id_fkey" FOREIGN KEY ("device_id") REFERENCES "devices"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "telemetry_readings" ADD CONSTRAINT "telemetry_readings_device_id_fkey" FOREIGN KEY ("device_id") REFERENCES "devices"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "telemetry_readings" ADD CONSTRAINT "telemetry_readings_sensor_id_device_id_fkey" FOREIGN KEY ("sensor_id", "device_id") REFERENCES "sensors"("id", "device_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gates" ADD CONSTRAINT "gates_device_id_fkey" FOREIGN KEY ("device_id") REFERENCES "devices"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gate_commands" ADD CONSTRAINT "gate_commands_gate_id_fkey" FOREIGN KEY ("gate_id") REFERENCES "gates"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gate_commands" ADD CONSTRAINT "gate_commands_recommendation_id_fkey" FOREIGN KEY ("recommendation_id") REFERENCES "recommendations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gate_commands" ADD CONSTRAINT "gate_commands_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gate_commands" ADD CONSTRAINT "gate_commands_approved_by_fkey" FOREIGN KEY ("approved_by") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gate_operation_logs" ADD CONSTRAINT "gate_operation_logs_command_id_fkey" FOREIGN KEY ("command_id") REFERENCES "gate_commands"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gate_operation_logs" ADD CONSTRAINT "gate_operation_logs_gate_id_fkey" FOREIGN KEY ("gate_id") REFERENCES "gates"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gate_command_events" ADD CONSTRAINT "gate_command_events_command_id_fkey" FOREIGN KEY ("command_id") REFERENCES "gate_commands"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "predictions" ADD CONSTRAINT "predictions_sensor_id_fkey" FOREIGN KEY ("sensor_id") REFERENCES "sensors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "warnings" ADD CONSTRAINT "warnings_sensor_id_fkey" FOREIGN KEY ("sensor_id") REFERENCES "sensors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "warnings" ADD CONSTRAINT "warnings_prediction_id_fkey" FOREIGN KEY ("prediction_id") REFERENCES "predictions"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "warnings" ADD CONSTRAINT "warnings_acknowledged_by_fkey" FOREIGN KEY ("acknowledged_by") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "warning_rules" ADD CONSTRAINT "warning_rules_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "warning_rules" ADD CONSTRAINT "warning_rules_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recommendations" ADD CONSTRAINT "recommendations_gate_id_fkey" FOREIGN KEY ("gate_id") REFERENCES "gates"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recommendations" ADD CONSTRAINT "recommendations_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recommendations" ADD CONSTRAINT "recommendations_reviewed_by_fkey" FOREIGN KEY ("reviewed_by") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "runtime_configs" ADD CONSTRAINT "runtime_configs_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
