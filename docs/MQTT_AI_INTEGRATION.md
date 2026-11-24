# MQTT & AI Service Integration Contract

- Status: Draft
- Tujuan: acuan integrasi Main Backend dengan ESP32/Mosquitto dan AI Service/FastAPI.
- Payload final belum disepakati. Contoh di dokumen ini bersifat ilustratif.

# Part A — MQTT

## 1. Broker dan Client

- Broker: Eclipse Mosquitto.
- Backend client: MQTT.js.
- QoS: 1 untuk semua topic.
- Device credential terpisah dari user JWT.
- Mekanisme autentikasi broker dan ACL per device masih perlu diputuskan.

## 2. Topic Convention

| Topic | Publisher | Subscriber | Retained |
|---|---|---|---:|
| `devices/{device_code}/telemetry` | ESP32 | Backend | No |
| `devices/{device_code}/status` | ESP32 | Backend | No |
| `devices/{device_code}/commands` | Backend | ESP32 | No |
| `devices/{device_code}/command-ack` | ESP32 | Backend | No |
| `devices/{device_code}/config` | Backend | ESP32 | Yes |
| `devices/{device_code}/config-ack` | ESP32 | Backend | No |

## 3. Telemetry Payload

Contoh:
```json
{
  "message_id": "MSG-20261111-000001",
  "device_code": "DEV-001",
  "sensor_code": "SNS-001",
  "timestamp": "2026-11-11T18:00:00+07:00",
  "value": 25.5,
  "unit": "mm"
}
```

Backend harus:
1. Memvalidasi JSON dan field wajib.
2. Mengidentifikasi device dan memvalidasi credential/broker identity.
3. Memastikan device aktif.
4. Memastikan sensor aktif dan milik device tersebut.
5. Memvalidasi timestamp, numeric finite value, dan unit.
6. Mencegah duplikasi berdasarkan message_id.
7. Menyimpan measured_at dan received_at.
8. Menentukan NORMAL atau ANOMALY menurut aturan yang telah dikonfirmasi.

## 4. Device Status dan LWT

- ESP32 mengatur LWT untuk menerbitkan status OFFLINE jika koneksi terputus tak terduga.
- Setelah reconnect berhasil, ESP32 menerbitkan ONLINE.
- Backend memperbarui `devices.connection_status` dan `last_seen_at`.
- Status koneksi device tidak sama dengan `gates.operational_status`.

Payload status final dan heartbeat/offline timeout masih perlu diputuskan.

## 5. Gate Command

Contoh payload ilustratif:
```json
{
  "command_id": "UUID",
  "gate_code": "GATE-001",
  "command_type": "SET_PERCENTAGE",
  "target_opening": 60,
  "issued_at": "2026-11-11T18:00:00Z"
}
```

Flow:
1. User membuat command PENDING.
2. Command disetujui.
3. Backend publish command dan mengubah status menjadi SENT.
4. ESP32 menerima dan menerbitkan delivery ACK.
5. ESP32 melaporkan gate MOVING.
6. ESP32 melaporkan hasil akhir, actual opening, dan command_id.
7. Backend memperbarui command, gate, event, dan operation log.

ACK penerimaan tidak boleh dianggap sebagai keberhasilan eksekusi.

### Idempotensi dan retry
- command_id unik dan sama pada semua retry.
- ESP32 menyimpan/mengetahui command_id yang telah diproses agar tidak mengeksekusi ulang.
- Retry limit dan interval configurable.
- Setelah batas waktu/retry habis, command menjadi TIMEOUT sesuai state machine.
- Bedakan DELIVERY_FAILED dan EXECUTION_FAILED.

Format ACK dan execution result final masih perlu diputuskan.

## 6. Device Configuration

- Backend menyimpan konfigurasi terakhir di PostgreSQL.
- Backend publish ke topic config dengan retained=true.
- ESP32 menerima config saat online/reconnect.
- ESP32 menerbitkan config-ack setelah berhasil menerapkan konfigurasi.
- Config sebaiknya memiliki identifier/version agar ACK dapat dicocokkan dengan versi yang dikirim.

Payload final dan strategi rollback config belum ditetapkan.

# Part B — AI Service

## 7. Komunikasi

- AI Service: Python + FastAPI.
- Main Backend memanggil AI Service melalui HTTP REST.
- Autentikasi service-to-service menggunakan API Key.
- API Key disimpan di environment, tidak di frontend, runtime_configs, atau log.
- Terapkan timeout dan retry terbatas.
- Jangan mengarang hasil ketika AI Service gagal.

## 8. Endpoint Awal

| Method | Endpoint | Tujuan |
|---|---|---|
| POST | `/api/v1/ews/predict` | Meminta prediksi EWS |
| POST | `/api/v1/recommendations/generate` | Meminta rekomendasi bukaan gate |

Base URL disimpan di environment, misalnya `AI_SERVICE_BASE_URL`.

## 9. Alur EWS

1. Scheduler menjalankan job EWS.
2. Backend memilih data telemetry yang memenuhi syarat.
3. Backend memanggil endpoint prediksi AI.
4. Backend memvalidasi response.
5. Backend menyimpan hasil ke `predictions`.
6. Backend mengevaluasi risk/threshold.
7. Backend membuat atau memperbarui `warnings`.
8. Kegagalan AI dicatat; jangan membuat prediction palsu.

## 10. Alur Recommendation

1. Scheduler menjalankan job recommendation.
2. Backend mengumpulkan telemetry valid, prediction, warning, dan kondisi gate yang relevan.
3. Backend memanggil AI Service.
4. Backend memvalidasi response dan gate target.
5. Backend menyimpan recommendation PENDING dengan expiry.
6. User yang berwenang meninjau.
7. Jika approved, backend membuat gate command sesuai business rule.
8. Jika current opening sama dengan recommended opening, jangan membuat command.

## 11. Kontrak yang Masih Dibutuhkan

Jangan mengunci implementasi integrasi sebelum hal berikut disepakati:
- Request/response JSON untuk kedua endpoint AI.
- API Key header name dan rotasi key.
- Timeout, retry, dan backoff.
- Model version dan metadata.
- Idempotency key untuk request.
- Kondisi input data minimum.
- Cara menangani response parsial/tidak valid.
- Penentuan gate target jika lebih dari satu gate.
