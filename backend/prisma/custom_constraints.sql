-- =========================================================================
-- Custom SQL Constraints & Triggers — Main Backend
-- Dokumen Acuan: docs/DATABASE_SCHEMA.md & docs/DATABASE_RELATIONS.md
-- Jalankan migration ini setelah `prisma migrate dev` awal
-- =========================================================================

-- 1. Composite Foreign Key pada telemetry_readings
-- Memastikan sensor_id yang dikirim benar-benar milik device_id tersebut
ALTER TABLE telemetry_readings 
ADD CONSTRAINT fk_telemetry_sensor_device 
FOREIGN KEY (sensor_id, device_id) 
REFERENCES sensors(id, device_id) 
ON DELETE RESTRICT;

-- 2. CHECK Constraints untuk Range Bukaan Pintu (0.00 s/d 100.00 %)
ALTER TABLE gates 
ADD CONSTRAINT chk_gates_actual_opening 
CHECK (actual_opening >= 0.00 AND actual_opening <= 100.00);

ALTER TABLE gate_commands 
ADD CONSTRAINT chk_commands_target_opening 
CHECK (target_opening >= 0.00 AND target_opening <= 100.00);

ALTER TABLE gate_commands 
ADD CONSTRAINT chk_command_type_target_match 
CHECK (
  (command_type = 'OPEN' AND target_opening = 100.00) OR
  (command_type = 'CLOSE' AND target_opening = 0.00) OR
  (command_type = 'SET_PERCENTAGE')
);

ALTER TABLE gate_operation_logs 
ADD CONSTRAINT chk_op_logs_openings 
CHECK (
  previous_opening >= 0.00 AND previous_opening <= 100.00 AND
  target_opening >= 0.00 AND target_opening <= 100.00 AND
  actual_opening >= 0.00 AND actual_opening <= 100.00
);

ALTER TABLE recommendations 
ADD CONSTRAINT chk_recommendations_openings 
CHECK (
  current_opening >= 0.00 AND current_opening <= 100.00 AND
  recommended_opening >= 0.00 AND recommended_opening <= 100.00
);

-- 3. CHECK Constraints untuk Sumber Warning (Exclusive Arc)
-- Warning ACTUAL: sensor_id wajib diisi, prediction_id harus NULL
-- Warning PREDICTION: prediction_id wajib diisi, sensor_id harus NULL
ALTER TABLE warnings 
ADD CONSTRAINT chk_warning_source_exclusive 
CHECK (
  (warning_type = 'ACTUAL' AND sensor_id IS NOT NULL AND prediction_id IS NULL) OR
  (warning_type = 'PREDICTION' AND prediction_id IS NOT NULL AND sensor_id IS NULL)
);

-- 4. CHECK Constraints untuk Command Source & Recommendation ID
-- MANUAL: recommendation_id harus NULL
-- AI_RECOMMENDATION: recommendation_id wajib diisi
ALTER TABLE gate_commands 
ADD CONSTRAINT chk_command_source_recommendation 
CHECK (
  (source = 'MANUAL' AND recommendation_id IS NULL) OR
  (source = 'AI_RECOMMENDATION' AND recommendation_id IS NOT NULL)
);

-- 5. CHECK Constraints untuk Nilai Float Finite (Mencegah NaN dan Infinity)
ALTER TABLE telemetry_readings 
ADD CONSTRAINT chk_telemetry_value_finite 
CHECK (value IS NOT NULL AND NOT ismissing(value) AND value NOT IN ('NaN'::float8, 'Infinity'::float8, '-Infinity'::float8));

ALTER TABLE predictions 
ADD CONSTRAINT chk_prediction_value_finite 
CHECK (predicted_value IS NOT NULL AND predicted_value NOT IN ('NaN'::float8, 'Infinity'::float8, '-Infinity'::float8));

ALTER TABLE warning_rules 
ADD CONSTRAINT chk_warning_rule_threshold_finite 
CHECK (threshold_value IS NOT NULL AND threshold_value NOT IN ('NaN'::float8, 'Infinity'::float8, '-Infinity'::float8));

-- 6. Partial Unique Index untuk Kredensial Perangkat Aktif
-- Hanya boleh ada satu kredensial aktif (revoked_at IS NULL) per perangkat
CREATE UNIQUE INDEX uq_active_device_credential 
ON device_credentials (device_id) 
WHERE revoked_at IS NULL;

