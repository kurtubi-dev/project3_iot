# Product Requirements Document (PRD)
## Main Backend — Sistem Monitoring Telemetri Curah Hujan dan Tinggi Muka Air untuk Rekomendasi Bukaan Pintu Irigasi Berbasis AI

- Versi: 1.0 (Draft)
- Tanggal: 11 November 2026
- Status: Draft untuk implementasi bertahap

## 1. Tujuan Dokumen

Dokumen ini mendefinisikan kebutuhan, ruang lingkup, modul, peran pengguna, integrasi, dan standar teknis Main Backend. Dokumen ini menjadi acuan AI coding agent dan pengembang.

## 2. Gambaran Sistem

Main Backend adalah pusat pengelolaan data dan proses operasional. Backend menerima telemetri dari perangkat IoT melalui MQTT, memvalidasi dan menyimpan data ke PostgreSQL, mengelola Early Warning System (EWS), berkomunikasi dengan AI Service, mengelola rekomendasi, serta mengirim perintah pengoperasian pintu irigasi kepada perangkat.

AI Service terpisah dari Main Backend. Perhitungan/pemodelan AI tidak diimplementasikan di Main Backend.

## 3. Ruang Lingkup

Termasuk:
- REST API berversi `/api/v1/`.
- Autentikasi, sesi, dan otorisasi berbasis role.
- Manajemen pengguna, invitation, perangkat, kredensial perangkat, dan sensor.
- Penerimaan, validasi, penyimpanan, dan penyajian telemetri.
- Integrasi MQTT dengan Eclipse Mosquitto.
- Manajemen pintu, command, event command, dan operation log.
- EWS berbasis data aktual dan prediksi AI.
- Manajemen warning rules.
- Integrasi AI Service melalui HTTP REST.
- Manajemen rekomendasi.
- Audit log dan runtime configuration.
- Testing, logging, dan penanganan error.

Tidak termasuk:
- Firmware ESP32.
- Implementasi perangkat keras/sensor/aktuator.
- Aplikasi Flutter.
- Website Next.js.
- Pelatihan dan implementasi model AI.
- Antarmuka pengguna frontend.

## 4. Tujuan Produk

1. Mengelola data dan proses operasional sistem monitoring irigasi.
2. Menyimpan data curah hujan dan tinggi muka air secara konsisten.
3. Menyediakan data melalui REST API.
4. Menghasilkan warning dari ambang batas data aktual dan prediksi.
5. Mengelola rekomendasi bukaan pintu dari AI Service.
6. Mengelola persetujuan, pengiriman, dan hasil command pintu.
7. Menyediakan histori operasi dan audit aktivitas.

## 5. Peran dan Hak Akses

Sistem memiliki tepat tiga role:

### ADMIN
- Mengelola akun, role, dan status pengguna.
- Mengelola perangkat, kredensial, dan sensor.
- Mengelola warning rules dan runtime configuration.
- Melihat telemetri, warning, rekomendasi, dan riwayat operasi.
- Menyetujui/menolak rekomendasi.
- Membuat, menyetujui, dan membatalkan command sesuai aturan.
- Melihat audit log.
- Mencabut seluruh sesi milik pengguna.

### PETUGAS_LAPANGAN
- Melihat perangkat, sensor, dan telemetri.
- Melihat dan acknowledge warning.
- Melihat, menyetujui, atau menolak rekomendasi.
- Membuat dan menyetujui command pintu.
- Melihat riwayat operasi.
- Tidak mengelola akun, warning rules, runtime configuration, atau audit log.

### PENGELOLA
- Melihat perangkat, sensor, telemetri, warning, rekomendasi, dan riwayat operasi.
- Tidak dapat mengubah data operasional, acknowledge warning, meninjau rekomendasi, atau mengoperasikan pintu.

Ketentuan tambahan:
- Admin dan Petugas Lapangan dapat membuat serta menyetujui command.
- Pembuat command boleh menyetujui command miliknya sendiri.
- Pembuat dapat membatalkan command PENDING miliknya.
- Admin dapat membatalkan command PENDING siapa pun.
- Hanya Admin yang dapat melihat audit log dan mengelola konfigurasi/rules.

## 6. Teknologi

| Komponen | Teknologi |
|---|---|
| Runtime | Node.js |
| Framework | Express.js |
| Bahasa | TypeScript strict |
| ORM | Prisma |
| Database | PostgreSQL |
| Database prototipe | Supabase PostgreSQL |
| MQTT broker | Eclipse Mosquitto |
| MQTT client | MQTT.js |
| AI Service | Python + FastAPI |
| API | REST |
| Validasi | Zod |
| Auth | JWT + Google OIDC |
| Password hashing | Argon2 |
| Logging | Pino + pino-http |
| Scheduler | node-cron |
| Testing | Vitest + Supertest |
| API manual testing | Postman |
| Package manager | npm |
| Code quality | ESLint + Prettier |

Arsitektur aplikasi: Modular Monolith. Satu aplikasi Express dengan modul domain terpisah.

## 7. Modul Fungsional

### 7.1 Authentication
- Login email/password.
- Login Google untuk akun yang telah terdaftar.
- Refresh token dengan rotation.
- Logout sesi aktif.
- Ganti password.
- Pengaitan akun Google setelah autentikasi akun lokal.
- Tidak ada registrasi publik.
- Access token 15 menit.
- Refresh token 7 hari.
- Refresh token disimpan dalam bentuk hash.
- Multi-session diperbolehkan.
- Akun INACTIVE tidak dapat login atau refresh.
- Logout mencabut sesi aktif; Admin dapat mencabut semua sesi user.

### 7.2 User Management
- Admin membuat akun melalui invitation.
- Admin mengubah profil, role, dan status.
- Akun inactive diblokir dan seluruh sesi dicabut.
- Data historis pengguna dipertahankan; tidak dihapus secara fisik.

### 7.3 Device Management
- Registrasi, detail, perubahan, aktivasi, dan deaktivasi perangkat.
- Pemantauan ONLINE/OFFLINE dan `last_seen_at`.
- Setiap perangkat memiliki kredensial terpisah dari JWT pengguna.
- Secret disimpan sebagai hash.
- Rotasi secret mencabut credential lama.
- Perangkat inactive tidak boleh mengirim telemetri operasional.

### 7.4 Sensor Management
- Registrasi dan pengelolaan sensor.
- Sensor terhubung ke satu device.
- Tipe awal: `RAINFALL` dan `WATER_LEVEL`.
- Sensor dinonaktifkan, bukan dihapus secara fisik, agar histori tetap terjaga.

### 7.5 Telemetry
- Telemetri diterima melalui MQTT, bukan endpoint publik biasa.
- Validasi credential device, status device, sensor, kepemilikan sensor, timestamp, tipe data, dan unit.
- Pesan duplikat ditolak berdasarkan `message_id`.
- Simpan `measured_at` dari perangkat dan `received_at` dari backend.
- Data malformed/identitas tidak valid ditolak.
- Data valid secara format tetapi tidak wajar dapat disimpan sebagai `ANOMALY`.
- Data ANOMALY tidak digunakan sebagai input AI sampai memenuhi aturan kelayakan.
- Data bersifat append-only.
- API menyediakan latest, detail, history, filter waktu, pagination, dan sorting.

Contoh payload konseptual:
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

### 7.6 MQTT
Topik:
- `devices/{device_code}/telemetry`: ESP32 → Backend.
- `devices/{device_code}/status`: ESP32 → Backend.
- `devices/{device_code}/commands`: Backend → ESP32.
- `devices/{device_code}/command-ack`: ESP32 → Backend.
- `devices/{device_code}/config`: Backend → ESP32.
- `devices/{device_code}/config-ack`: ESP32 → Backend.

Ketentuan:
- QoS 1 untuk keenam topik.
- `message_id` untuk telemetri; `command_id` untuk command; identifier/version untuk config.
- Retained message hanya untuk `config`.
- Command tidak retained agar tidak diputar ulang setelah reconnect.
- ESP32 menggunakan LWT untuk status OFFLINE dan menerbitkan ONLINE setelah reconnect.
- Status koneksi perangkat dibedakan dari status operasional pintu.
- Detail autentikasi broker dan payload final ditetapkan dalam API/integration contract.

### 7.7 Irrigation
Command:
- `OPEN`: target 100%.
- `CLOSE`: target 0%.
- `SET_PERCENTAGE`: target 0–100%.

Alur:
`PENDING → APPROVED → SENT → EXECUTED | FAILED | TIMEOUT`
dan `PENDING → CANCELLED`.

Ketentuan:
- Command dikirim melalui MQTT setelah disetujui.
- APPROVED tidak berarti pintu telah bergerak.
- ACK hanya membuktikan penerimaan command.
- ESP32 melaporkan status MOVING dan hasil akhir beserta actual opening.
- `DELIVERY_FAILED` berbeda dari `EXECUTION_FAILED`.
- Retry terbatas dan menggunakan `command_id` sama.
- ESP32 wajib idempotent terhadap command yang sama.
- Timeout/retry configurable.
- Event command append-only.
- Operation log mencatat hasil operasi.

### 7.8 Early Warning System
Tipe:
- `ACTUAL`: berasal dari pembacaan sensor aktual.
- `PREDICTION`: berasal dari prediksi AI.

Risk level:
`NORMAL`, `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`.

Status:
`ACTIVE`, `ACKNOWLEDGED`, `RESOLVED`.

Backend mengevaluasi nilai aktual berdasarkan warning rules. Backend juga menyimpan prediksi AI dan mengevaluasi hasil prediksi untuk membuat warning. Warning yang sama selama satu kejadian berlangsung diperbarui, bukan dibuat berulang. Setelah resolved, kejadian berulang menghasilkan warning baru.

### 7.9 Recommendations
- Backend meminta rekomendasi dari AI Service secara berkala.
- Simpan gate, current opening, recommended opening, reason, supporting data, status, reviewer, waktu dibuat, dan expiry.
- Status: `PENDING`, `APPROVED`, `REJECTED`, `EXPIRED`.
- Admin/Petugas Lapangan dapat approve/reject; Pengelola read-only.
- Pending otomatis EXPIRED setelah `expires_at`.
- Status akhir tidak dapat dibuka kembali.
- Perubahan masa berlaku berlaku untuk rekomendasi baru.
- Rekomendasi approved dapat menghasilkan maksimal satu command.
- Jika current opening sama dengan recommended opening, rekomendasi tetap disimpan tanpa command.

### 7.10 Audit Log
Mencatat aktivitas penting: auth, user, device, sensor, warning rules, recommendation review, command/operasi, dan runtime config. Append-only; hanya Admin dapat melihat. Jangan mencatat password, token, API key, atau secret.

### 7.11 Runtime Configuration
Konfigurasi operasional dapat diubah Admin melalui API/dashboard. Contoh interval EWS, interval rekomendasi, expiry rekomendasi, retry MQTT, dan timeout command. Secret dan kredensial hanya di environment configuration, tidak di database runtime config.

## 8. Integrasi AI Service

AI Service terpisah menggunakan FastAPI. Main Backend memanggil melalui HTTP REST.

Endpoint awal:
- `POST /api/v1/ews/predict`
- `POST /api/v1/recommendations/generate`

Autentikasi service-to-service menggunakan API Key dari environment. Backend menerapkan timeout dan retry terbatas. Kegagalan dicatat dan tidak boleh diganti dengan prediksi/rekomendasi palsu. Payload final ditetapkan pada `MQTT_AI_INTEGRATION.md`.

## 9. REST API Standards

Semua endpoint menggunakan prefix `/api/v1/`.

Success:
```json
{
  "success": true,
  "message": "Data berhasil diambil",
  "data": {}
}
```

Error:
```json
{
  "success": false,
  "message": "Perangkat tidak ditemukan",
  "error": { "code": "DEVICE_NOT_FOUND" }
}
```

- Validasi menggunakan Zod.
- Pagination `page` mulai 1, `limit` maksimal awal 100.
- Filter/sort harus memakai allowlist.
- Centralized error middleware.
- HTTP status code harus sesuai.
- Device authentication terpisah dari user JWT.

## 10. Non-Functional Requirements

### Security
- Argon2 untuk password.
- Hash refresh token dan device secret.
- RBAC pada endpoint.
- Helmet, CORS, rate limiting.
- Validasi input.
- Jangan log secret.

### Reliability
- MQTT QoS 1 dan idempotensi.
- Telemetri append-only.
- Timeout/retry terkontrol.
- Job scheduler tidak overlap untuk job yang sama.
- Kegagalan AI/MQTT dicatat.

### Maintainability
- Modular Monolith.
- TypeScript strict.
- ESLint + Prettier.
- Environment config dipisah dari source code.

### Testing
- Vitest unit dan integration.
- Supertest endpoint.
- Postman manual testing.
- Uji validasi, autentikasi, otorisasi, business logic, dan integrasi.

## 11. Scheduler

Menggunakan `node-cron` untuk EWS, recommendation generation, expiry recommendation, timeout command, dan pekerjaan berkala lain. Interval contoh 5 menit untuk EWS dan 10 menit untuk recommendation hanya ilustrasi, bukan keputusan final. Interval aktual configurable. Pada satu instance, cegah overlap job yang sama. Jika kelak multi-instance, gunakan distributed lock.

## 12. Kriteria Penerimaan

- Login dan otorisasi berjalan sesuai role.
- Admin dapat mengelola akun, device, sensor, rules, dan runtime config.
- Device dapat mengirim telemetri melalui MQTT.
- Telemetri tersimpan dan dapat diakses melalui REST.
- EWS dapat membuat dan memperbarui warning.
- Backend dapat berkomunikasi dengan AI Service.
- Recommendation dapat disimpan dan direview.
- Command dikirim setelah persetujuan dan hasil operasi dikonfirmasi perangkat.
- Audit log merekam aktivitas penting.
- Pengujian utama berhasil.

## 13. Hal yang Belum Final

Jangan mengarang keputusan untuk hal berikut. Tandai sebagai TODO/assumption dan minta konfirmasi sebelum mengunci implementasi:
1. Identitas teknis deduplikasi warning.
2. Batas normal/anomali setiap sensor.
3. Payload final MQTT dan autentikasi broker.
4. Payload request/response AI Service.
5. Timeout dan retry final.
6. Kondisi/frekuensi pembuatan recommendation.
7. Kebijakan retensi/arsip telemetry.
8. Detail invitation/email delivery.
9. Kebijakan konflik beberapa command untuk gate yang sama.
10. Apakah operator dapat mengubah persentase rekomendasi sebelum approve.
