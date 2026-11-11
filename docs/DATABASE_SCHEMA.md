# Database Schema — Main Backend

- Versi: 1.0 (Draft)
- Database: PostgreSQL
- ORM: Prisma
- Jumlah tabel awal: 18

Dokumen ini adalah rancangan konseptual/relasional. Jangan membuat migration produksi sebelum semua constraint dan asumsi penting ditinjau.

## 1. Konvensi

- PK menggunakan UUID.
- Timestamp menggunakan PostgreSQL `TIMESTAMPTZ`; Prisma umumnya `DateTime @db.Timestamptz(6)`.
- Waktu disimpan UTC dan ditampilkan pada `Asia/Jakarta`.
- Tabel dan kolom menggunakan `snake_case`.
- ENUM menggunakan `UPPER_SNAKE_CASE`.
- `created_at` default `now()` jika sesuai.
- Data historis penting tidak dihapus secara fisik.
- Prisma `@default(uuid())` dapat digunakan untuk UUID yang dibuat aplikasi.
- `updated_at` menggunakan `@updatedAt` pada Prisma.
- Untuk CHECK, partial unique index, dan composite FK yang tidak terwakili penuh oleh Prisma, gunakan custom SQL migration.

## 2. Daftar Tabel

1. `users`
2. `auth_accounts`
3. `sessions`
4. `invitations`
5. `devices`
6. `device_credentials`
7. `sensors`
8. `telemetry_readings`
9. `gates`
10. `gate_commands`
11. `gate_operation_logs`
12. `gate_command_events`
13. `predictions`
14. `warnings`
15. `warning_rules`
16. `recommendations`
17. `audit_logs`
18. `runtime_configs`

## 3. Detail Tabel

### 3.1 users

| Column | PostgreSQL type | Null | Constraint/default |
|---|---|---:|---|
| id | UUID | No | PK |
| name | VARCHAR(100) | No | |
| email | VARCHAR(255) | No | UNIQUE |
| phone | VARCHAR(20) | Yes | |
| role | user_role | No | ENUM |
| status | user_status | No | DEFAULT ACTIVE |
| created_at | TIMESTAMPTZ | No | DEFAULT now() |
| updated_at | TIMESTAMPTZ | No | |

ENUM:
- `user_role`: ADMIN, PETUGAS_LAPANGAN, PENGELOLA.
- `user_status`: ACTIVE, INACTIVE.

Rules: email unik; inactive memblokir login/refresh dan menyebabkan seluruh session dicabut; jangan hard-delete user yang memiliki histori.

### 3.2 auth_accounts

| Column | PostgreSQL type | Null | Constraint/default |
|---|---|---:|---|
| id | UUID | No | PK |
| user_id | UUID | No | FK users.id |
| provider | auth_provider | No | ENUM |
| provider_user_id | VARCHAR(255) | No | |
| password_hash | TEXT | Yes | LOCAL only |
| created_at | TIMESTAMPTZ | No | DEFAULT now() |
| updated_at | TIMESTAMPTZ | No | |

ENUM `auth_provider`: LOCAL, GOOGLE.

Constraints:
- UNIQUE (`provider`, `provider_user_id`).
- LOCAL harus memiliki `password_hash`.
- GOOGLE harus memiliki `password_hash IS NULL`.
- `provider_user_id` untuk LOCAL harus ditetapkan konsisten, misalnya identifier lokal yang stabil; jangan mengandalkan email yang dapat berubah sebagai identitas provider tanpa aturan jelas.

### 3.3 sessions

| Column | PostgreSQL type | Null | Constraint/default |
|---|---|---:|---|
| id | UUID | No | PK |
| user_id | UUID | No | FK users.id |
| refresh_token_hash | TEXT | No | |
| ip_address | VARCHAR(45) | Yes | |
| user_agent | TEXT | Yes | |
| expires_at | TIMESTAMPTZ | No | |
| revoked_at | TIMESTAMPTZ | Yes | |
| created_at | TIMESTAMPTZ | No | DEFAULT now() |

Rules: multi-session; logout mencabut sesi saat ini; Admin dapat mencabut semua sesi user; refresh token rotation wajib. Pertimbangkan menambahkan `replaced_by_session_id` atau token-family metadata jika diperlukan untuk mendeteksi reuse token lama. Keputusan ini perlu review sebelum implementasi auth final.

### 3.4 invitations

| Column | PostgreSQL type | Null | Constraint/default |
|---|---|---:|---|
| id | UUID | No | PK |
| email | VARCHAR(255) | No | |
| name | VARCHAR(100) | No | |
| role | user_role | No | ENUM |
| token_hash | TEXT | No | |
| expires_at | TIMESTAMPTZ | No | |
| accepted_at | TIMESTAMPTZ | Yes | |
| created_by | UUID | No | FK users.id |
| created_at | TIMESTAMPTZ | No | DEFAULT now() |

Rules: token single-use, disimpan hash, kedaluwarsa tidak dapat dipakai, hanya Admin yang membuat invitation. Email invitation dan aturan invitation aktif ganda perlu dipastikan saat implementasi.

### 3.5 devices

| Column | PostgreSQL type | Null | Constraint/default |
|---|---|---:|---|
| id | UUID | No | PK |
| device_code | VARCHAR(50) | No | UNIQUE |
| name | VARCHAR(100) | No | |
| description | TEXT | Yes | |
| location | TEXT | No | |
| connection_status | device_connection_status | No | DEFAULT OFFLINE |
| is_active | BOOLEAN | No | DEFAULT TRUE |
| last_seen_at | TIMESTAMPTZ | Yes | |
| created_by | UUID | No | FK users.id |
| created_at | TIMESTAMPTZ | No | DEFAULT now() |
| updated_at | TIMESTAMPTZ | No | |

ENUM `device_connection_status`: ONLINE, OFFLINE.

### 3.6 device_credentials

| Column | PostgreSQL type | Null | Constraint/default |
|---|---|---:|---|
| id | UUID | No | PK |
| device_id | UUID | No | FK devices.id |
| secret_hash | TEXT | No | |
| created_by | UUID | No | FK users.id |
| created_at | TIMESTAMPTZ | No | DEFAULT now() |
| revoked_at | TIMESTAMPTZ | Yes | |
| expires_at | TIMESTAMPTZ | Yes | |

Rules: credential history retained; satu credential aktif per device. Definisi aktif: `revoked_at IS NULL` dan (`expires_at IS NULL` atau `expires_at > now()`). Partial unique index hanya dapat mengunci `revoked_at IS NULL`; expiry tetap harus dicek aplikasi atau memakai mekanisme lain. Jangan menyimpan raw secret.

### 3.7 sensors

| Column | PostgreSQL type | Null | Constraint/default |
|---|---|---:|---|
| id | UUID | No | PK |
| device_id | UUID | No | FK devices.id |
| sensor_code | VARCHAR(50) | No | UNIQUE |
| name | VARCHAR(100) | No | |
| type | sensor_type | No | ENUM |
| parameter | VARCHAR(50) | No | |
| unit | VARCHAR(20) | No | |
| is_active | BOOLEAN | No | DEFAULT TRUE |
| created_at | TIMESTAMPTZ | No | DEFAULT now() |
| updated_at | TIMESTAMPTZ | No | |

ENUM `sensor_type`: RAINFALL, WATER_LEVEL.

Tambahkan UNIQUE (`id`, `device_id`) untuk target composite FK dari telemetry_readings.

### 3.8 telemetry_readings

| Column | PostgreSQL type | Null | Constraint/default |
|---|---|---:|---|
| id | UUID | No | PK |
| message_id | VARCHAR(100) | No | UNIQUE |
| device_id | UUID | No | FK devices.id |
| sensor_id | UUID | No | FK sensors.id |
| measured_at | TIMESTAMPTZ | No | |
| received_at | TIMESTAMPTZ | No | DEFAULT now() |
| value | DOUBLE PRECISION | No | |
| unit | VARCHAR(20) | No | |
| validity_status | telemetry_validity_status | No | DEFAULT NORMAL |

ENUM `telemetry_validity_status`: NORMAL, ANOMALY.

Constraint:
- Composite FK (`sensor_id`, `device_id`) → `sensors(id, device_id)` agar sensor harus milik device pengirim.
- `message_id` unik.
- Nilai finite; PostgreSQL CHECK perlu mengecualikan NaN dan Infinity dengan ekspresi yang diuji terhadap versi PostgreSQL.
- Data append-only.
- Data invalid secara struktur/identitas ditolak; anomali yang valid secara struktur dapat disimpan.

### 3.9 gates

| Column | PostgreSQL type | Null | Constraint/default |
|---|---|---:|---|
| id | UUID | No | PK |
| gate_code | VARCHAR(50) | No | UNIQUE |
| device_id | UUID | No | FK devices.id, UNIQUE |
| name | VARCHAR(100) | No | |
| location | TEXT | No | |
| actual_opening | DECIMAL(5,2) | No | DEFAULT 0 |
| operational_status | gate_operational_status | No | |
| created_at | TIMESTAMPTZ | No | DEFAULT now() |
| updated_at | TIMESTAMPTZ | No | |

ENUM `gate_operational_status`: NORMAL, MOVING, ERROR, OFFLINE.

CHECK `actual_opening >= 0 AND actual_opening <= 100`.

Device-gate 1:1. Penggantian device harus mempertahankan gate dan histori command; perubahan relasi device perlu prosedur aman.

### 3.10 gate_commands

| Column | PostgreSQL type | Null | Constraint/default |
|---|---|---:|---|
| id | UUID | No | PK |
| gate_id | UUID | No | FK gates.id |
| command_type | gate_command_type | No | ENUM |
| target_opening | DECIMAL(5,2) | No | |
| source | command_source | No | ENUM |
| recommendation_id | UUID | Yes | FK recommendations.id, UNIQUE |
| status | gate_command_status | No | DEFAULT PENDING |
| failure_type | command_failure_type | Yes | ENUM |
| failure_reason | TEXT | Yes | |
| created_by | UUID | No | FK users.id |
| approved_by | UUID | Yes | FK users.id |
| approved_at | TIMESTAMPTZ | Yes | |
| sent_at | TIMESTAMPTZ | Yes | |
| completed_at | TIMESTAMPTZ | Yes | |
| retry_count | INTEGER | No | DEFAULT 0 |
| last_retry_at | TIMESTAMPTZ | Yes | |
| created_at | TIMESTAMPTZ | No | DEFAULT now() |
| updated_at | TIMESTAMPTZ | No | |

ENUM:
- `gate_command_type`: OPEN, CLOSE, SET_PERCENTAGE.
- `command_source`: MANUAL, AI_RECOMMENDATION.
- `gate_command_status`: PENDING, APPROVED, SENT, EXECUTED, CANCELLED, FAILED, TIMEOUT.
- `command_failure_type`: DELIVERY_FAILED, EXECUTION_FAILED.

Constraints:
- target_opening antara 0 dan 100.
- OPEN wajib target 100.
- CLOSE wajib target 0.
- SET_PERCENTAGE target 0–100.
- MANUAL harus `recommendation_id IS NULL`.
- AI_RECOMMENDATION harus memiliki recommendation_id.
- `retry_count >= 0`.
- Satu recommendation menghasilkan maksimal satu command.
- State transition divalidasi pada service layer/transaksi; jangan menganggap ENUM mencegah transisi ilegal.
- Perlu keputusan lanjutan untuk command conflict pada satu gate dan semantik retry setelah DELIVERY_FAILED.

### 3.11 gate_operation_logs

| Column | PostgreSQL type | Null | Constraint/default |
|---|---|---:|---|
| id | UUID | No | PK |
| command_id | UUID | No | FK gate_commands.id, UNIQUE |
| previous_opening | DECIMAL(5,2) | No | |
| target_opening | DECIMAL(5,2) | No | |
| actual_opening | DECIMAL(5,2) | No | |
| started_at | TIMESTAMPTZ | Yes | |
| completed_at | TIMESTAMPTZ | Yes | |
| final_status | operation_final_status | No | |
| created_at | TIMESTAMPTZ | No | DEFAULT now() |

ENUM `operation_final_status`: EXECUTED, FAILED, TIMEOUT.

CHECK nilai bukaan 0–100. Satu command maksimal memiliki satu operation log. Pertimbangkan apakah log dibuat hanya setelah command terminal atau sejak operasi mulai; rancangan saat ini mengasumsikan satu record akhir.

### 3.12 gate_command_events

| Column | PostgreSQL type | Null | Constraint/default |
|---|---|---:|---|
| id | UUID | No | PK |
| command_id | UUID | No | FK gate_commands.id |
| event_type | gate_command_event_type | No | ENUM |
| description | TEXT | No | |
| payload | JSONB | Yes | |
| occurred_at | TIMESTAMPTZ | No | |
| received_at | TIMESTAMPTZ | No | |
| created_at | TIMESTAMPTZ | No | DEFAULT now() |

ENUM `gate_command_event_type`:
- COMMAND_SENT
- DELIVERY_ACKNOWLEDGED
- GATE_MOVING
- EXECUTION_SUCCEEDED
- EXECUTION_FAILED
- DELIVERY_FAILED
- RETRY_ATTEMPTED
- COMMAND_TIMEOUT

Event append-only. `occurred_at` adalah waktu kejadian menurut sumber; `received_at` adalah waktu backend menerima event.

### 3.13 predictions

| Column | PostgreSQL type | Null | Constraint/default |
|---|---|---:|---|
| id | UUID | No | PK |
| sensor_id | UUID | No | FK sensors.id |
| prediction_type | prediction_type | No | ENUM |
| predicted_value | DOUBLE PRECISION | No | |
| unit | VARCHAR(20) | No | |
| predicted_at | TIMESTAMPTZ | No | |
| forecast_for | TIMESTAMPTZ | No | |
| risk_level | risk_level | No | ENUM |
| model_version | VARCHAR(50) | No | |
| created_at | TIMESTAMPTZ | No | DEFAULT now() |

ENUM:
- `prediction_type`: RAINFALL, WATER_LEVEL.
- `risk_level`: NORMAL, LOW, MEDIUM, HIGH, CRITICAL.

CHECK predicted_value finite. Pastikan sensor type cocok dengan prediction_type pada service layer atau tambahkan constraint/relasi yang sesuai.

### 3.14 warnings

| Column | PostgreSQL type | Null | Constraint/default |
|---|---|---:|---|
| id | UUID | No | PK |
| warning_type | warning_type | No | ENUM |
| sensor_id | UUID | Yes | FK sensors.id |
| prediction_id | UUID | Yes | FK predictions.id |
| risk_level | risk_level | No | ENUM |
| title | VARCHAR(150) | No | |
| description | TEXT | No | |
| status | warning_status | No | DEFAULT ACTIVE |
| acknowledged_by | UUID | Yes | FK users.id |
| acknowledged_at | TIMESTAMPTZ | Yes | |
| first_occurred_at | TIMESTAMPTZ | No | |
| last_updated_at | TIMESTAMPTZ | No | |
| resolved_at | TIMESTAMPTZ | Yes | |
| created_at | TIMESTAMPTZ | No | DEFAULT now() |

ENUM:
- `warning_type`: ACTUAL, PREDICTION.
- `warning_status`: ACTIVE, ACKNOWLEDGED, RESOLVED.

CHECK source:
- ACTUAL → sensor_id NOT NULL AND prediction_id IS NULL.
- PREDICTION → prediction_id NOT NULL AND sensor_id IS NULL.

Status transition:
- ACTIVE → ACKNOWLEDGED atau RESOLVED.
- ACKNOWLEDGED → RESOLVED.
- RESOLVED terminal.
- Jika risiko masih berlangsung setelah acknowledge, warning tetap ACKNOWLEDGED dan timestamp/detail diperbarui.

Deduplikasi kejadian warning belum final. Jangan membuat unique constraint deduplikasi sebelum event identity disepakati.

### 3.15 warning_rules

| Column | PostgreSQL type | Null | Constraint/default |
|---|---|---:|---|
| id | UUID | No | PK |
| name | VARCHAR(100) | No | |
| sensor_type | sensor_type | No | ENUM |
| parameter | VARCHAR(50) | No | |
| unit | VARCHAR(20) | No | |
| risk_level | warning_rule_risk_level | No | ENUM |
| operator | comparison_operator | No | ENUM |
| threshold_value | DOUBLE PRECISION | No | |
| is_active | BOOLEAN | No | DEFAULT TRUE |
| created_by | UUID | No | FK users.id |
| updated_by | UUID | No | FK users.id |
| created_at | TIMESTAMPTZ | No | DEFAULT now() |
| updated_at | TIMESTAMPTZ | No | |

ENUM:
- `warning_rule_risk_level`: LOW, MEDIUM, HIGH, CRITICAL.
- `comparison_operator`: GT, GTE, LT, LTE.

CHECK threshold finite. Threshold aktual belum ditetapkan; jangan mengarang nilai default.

### 3.16 recommendations

| Column | PostgreSQL type | Null | Constraint/default |
|---|---|---:|---|
| id | UUID | No | PK |
| gate_id | UUID | No | FK gates.id |
| current_opening | DECIMAL(5,2) | No | |
| recommended_opening | DECIMAL(5,2) | No | |
| reason | TEXT | No | |
| supporting_data | JSONB | No | |
| status | recommendation_status | No | DEFAULT PENDING |
| created_by | UUID | Yes | |
| reviewed_by | UUID | Yes | FK users.id |
| reviewed_at | TIMESTAMPTZ | Yes | |
| expires_at | TIMESTAMPTZ | No | |
| created_at | TIMESTAMPTZ | No | DEFAULT now() |

ENUM `recommendation_status`: PENDING, APPROVED, REJECTED, EXPIRED.

Rules:
- current_opening dan recommended_opening 0–100.
- Dibuat oleh sistem; `created_by` NULL merepresentasikan system-generated.
- Pending otomatis expired setelah `expires_at`.
- APPROVED, REJECTED, EXPIRED terminal.
- Jika approved dan bukaan sama, tidak ada command.
- Jika berbeda, dapat menghasilkan satu command melalui `gate_commands.recommendation_id`.

Catatan desain: `created_by` belum memiliki FK karena system actor dapat NULL. Jika suatu saat dibutuhkan actor manusia, tambahkan FK ke users.

### 3.17 audit_logs

| Column | PostgreSQL type | Null | Constraint/default |
|---|---|---:|---|
| id | UUID | No | PK |
| user_id | UUID | Yes | FK users.id |
| action | VARCHAR(100) | No | |
| resource_type | VARCHAR(50) | No | |
| resource_id | UUID | Yes | |
| old_values | JSONB | Yes | |
| new_values | JSONB | Yes | |
| ip_address | VARCHAR(45) | Yes | |
| user_agent | TEXT | Yes | |
| created_at | TIMESTAMPTZ | No | DEFAULT now() |

Append-only. Jangan simpan password, token, refresh token, device secret, API key, atau data rahasia.

### 3.18 runtime_configs

| Column | PostgreSQL type | Null | Constraint/default |
|---|---|---:|---|
| id | UUID | No | PK |
| key | VARCHAR(100) | No | UNIQUE |
| value | JSONB | No | |
| description | TEXT | No | |
| updated_by | UUID | Yes | FK users.id |
| created_at | TIMESTAMPTZ | No | DEFAULT now() |
| updated_at | TIMESTAMPTZ | No | |

Contoh key konfigurasi:
- `ews_interval_minutes`
- `recommendation_interval_minutes`
- `recommendation_expiry_minutes`
- `mqtt_retry_limit`
- `mqtt_retry_interval_seconds`
- `mqtt_command_timeout_seconds`

Jangan menyimpan credential/secret/API key di tabel ini.

## 4. Index yang Direkomendasikan

- `telemetry_readings(sensor_id, measured_at)`
- `telemetry_readings(device_id, measured_at)`
- `telemetry_readings(received_at)`
- `warnings(status, created_at)`
- `predictions(sensor_id, forecast_for)`
- `recommendations(status, expires_at)`
- `gate_commands(gate_id, created_at)`
- `gate_command_events(command_id, occurred_at)`
- `audit_logs(user_id, created_at)`
- `sessions(user_id, revoked_at)`

Unique constraint pada email, device_code, sensor_code, message_id, gate_code, provider/provider_user_id, runtime key, gate command recommendation_id, dan operation log command_id.

## 5. Aturan Penghapusan dan Retensi

- User: deactivate, bukan hard-delete.
- Device: deactivate, histori tetap ada.
- Sensor: deactivate, histori tetap ada.
- Telemetry: append-only; retensi/arsip belum diputuskan.
- Command, events, operation logs, warnings, predictions, audit logs: pertahankan sebagai histori.
- Credential: revoke, bukan hapus.
- Invitation: dapat dibersihkan setelah kebijakan retensi ditetapkan; jangan menghapus jika dibutuhkan untuk audit.

## 6. Hal yang Harus Direview Sebelum Migration Final

1. Apakah `recommendations.created_by` perlu FK nullable ke users atau system actor terpisah.
2. Apakah `gate_operation_logs.started_at` boleh NULL atau harus selalu tersedia.
3. Apakah command log dibuat sekali pada hasil akhir atau memiliki status operasi berjalan.
4. Strategi deduplikasi warning.
5. Refresh token reuse detection/token family.
6. Validasi expiry credential aktif.
7. Constraint finite untuk float PostgreSQL.
8. Constraint hubungan prediction_type dengan sensor type.
9. Unique command aktif per gate atau aturan konflik command.
10. Retensi dan partisi telemetry jika volume data tinggi.
