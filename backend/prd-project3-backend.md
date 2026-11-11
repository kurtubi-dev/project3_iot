# PRODUCT REQUIREMENTS DOCUMENT (PRD)
## Main Backend — Sistem Monitoring Telemetri Curah Hujan dan Tinggi Muka Air untuk Rekomendasi Bukaan Pintu Irigasi Berbasis AI

**Versi:** 1.0  
**Status:** Draft  
**Tanggal:** 11 November 2026

---

## 1. Pendahuluan

### 1.1 Tujuan

Main Backend merupakan pusat pengelolaan data dan komunikasi sistem monitoring irigasi. Backend menerima data telemetri dari perangkat IoT, menyimpan data ke database, mengelola peringatan dini, mengintegrasikan layanan AI, serta mengatur rekomendasi dan perintah pengoperasian pintu irigasi.

### 1.2 Ruang Lingkup

PRD ini hanya mencakup pengembangan Main Backend, meliputi:

- REST API.
- Autentikasi dan otorisasi pengguna.
- Manajemen pengguna, perangkat, dan sensor.
- Penerimaan dan pengelolaan data telemetri.
- Integrasi MQTT.
- Manajemen pintu dan perintah irigasi.
- Early Warning System (EWS).
- Manajemen rekomendasi AI.
- Integrasi AI Service.
- Audit log dan konfigurasi sistem.

Pengembangan firmware ESP32, aplikasi Flutter, website Next.js, dan implementasi model AI tidak termasuk ruang lingkup implementasi Main Backend.

---

## 2. Tujuan Sistem

1. Mengelola seluruh data dan proses operasional sistem monitoring irigasi.
2. Menerima dan menyimpan data curah hujan serta tinggi muka air.
3. Menyediakan data telemetri melalui REST API.
4. Menghasilkan peringatan dini berdasarkan aturan ambang batas dan prediksi AI.
5. Mengelola rekomendasi bukaan pintu irigasi dari AI Service.
6. Mengelola persetujuan dan pengiriman perintah ke perangkat IoT.
7. Menyediakan riwayat operasi dan audit aktivitas pengguna.

---

## 3. Pengguna dan Hak Akses

Sistem memiliki tiga role.

### 3.1 ADMIN

Memiliki akses penuh terhadap pengelolaan sistem.

- Mengelola akun dan role pengguna.
- Mengelola perangkat dan sensor.
- Mengelola aturan EWS.
- Mengelola konfigurasi runtime.
- Melihat seluruh telemetri, peringatan, dan rekomendasi.
- Menyetujui atau menolak rekomendasi.
- Membuat dan menyetujui perintah pintu irigasi.
- Melihat audit log.
- Mencabut seluruh sesi pengguna.

### 3.2 PETUGAS_LAPANGAN

Bertanggung jawab terhadap pemantauan dan operasional lapangan.

- Melihat perangkat dan sensor.
- Melihat data telemetri.
- Melihat dan mengakui peringatan.
- Melihat dan menyetujui atau menolak rekomendasi.
- Membuat dan menyetujui perintah pintu irigasi.
- Melihat riwayat operasi.

Tidak memiliki akses ke manajemen akun, konfigurasi sistem, aturan EWS, dan audit log.

### 3.3 PENGELOLA

Berperan sebagai pemantau.

- Melihat data telemetri.
- Melihat perangkat dan sensor.
- Melihat peringatan dan rekomendasi.
- Melihat riwayat operasi pintu irigasi.

Tidak dapat mengubah data operasional, menyetujui rekomendasi, atau mengoperasikan pintu.

---

## 4. Arsitektur dan Teknologi

### 4.1 Arsitektur

Menggunakan pendekatan **Modular Monolith**. Seluruh modul backend berjalan dalam satu aplikasi Express.js, tetapi memiliki pemisahan tanggung jawab berdasarkan domain.

### 4.2 Teknologi

| Komponen | Teknologi |
|---|---|
| Runtime | Node.js |
| Backend framework | Express.js |
| Bahasa | TypeScript (strict) |
| ORM | Prisma |
| Database | PostgreSQL |
| Prototipe database | Supabase PostgreSQL |
| MQTT Broker | Eclipse Mosquitto |
| MQTT Client | MQTT.js |
| AI Service | Python + FastAPI |
| API | REST API |
| Validasi | Zod |
| Autentikasi | JWT + Google OIDC |
| Password hashing | Argon2 |
| Logging | Pino + pino-http |
| Scheduler | node-cron |
| Testing | Vitest + Supertest |
| API testing | Postman |
| Package manager | npm |

### 4.3 Integrasi Eksternal

**IoT:** Komunikasi perangkat dan backend melalui MQTT.

**AI Service:** Komunikasi backend dengan AI Service melalui HTTP REST.

**Database:** Penyimpanan data menggunakan PostgreSQL melalui Prisma ORM.

---

## 5. Modul dan Kebutuhan Fungsional

### 5.1 Authentication

- Login menggunakan email dan password.
- Login menggunakan Google.
- Refresh access token.
- Logout sesi aktif.
- Ganti password.
- Pengaitan akun Google ke akun lokal.
- Pengelolaan sesi pengguna.
- Tidak menyediakan registrasi publik.

Ketentuan:
- Access token berlaku 15 menit.
- Refresh token berlaku 7 hari.
- Refresh token disimpan dalam bentuk hash.
- Menggunakan refresh token rotation.
- Satu user dapat memiliki beberapa sesi.
- Akun inactive tidak dapat login maupun refresh token.

### 5.2 User Management

- Admin membuat akun melalui invitation.
- Admin mengubah profil dan role.
- Admin mengaktifkan atau menonaktifkan akun.
- Penonaktifan akun mencabut seluruh sesi aktif.
- Data pengguna historis tetap dipertahankan.

### 5.3 Device Management

- Registrasi perangkat ESP32.
- Melihat detail perangkat.
- Mengubah informasi perangkat.
- Mengaktifkan dan menonaktifkan perangkat.
- Memantau status online/offline.
- Melihat waktu komunikasi terakhir.
- Mengelola kredensial perangkat.
- Melakukan rotasi device secret.

### 5.4 Sensor Management

- Registrasi sensor.
- Mengelola informasi sensor.
- Menentukan jenis sensor.
- Menentukan parameter dan satuan.
- Mengaktifkan atau menonaktifkan sensor.
- Menghubungkan sensor dengan perangkat.

Jenis sensor awal:
- RAINFALL.
- WATER_LEVEL.

### 5.5 Telemetry Management

Backend menerima data telemetri melalui MQTT.

Kebutuhan:
- Memvalidasi identitas perangkat.
- Memvalidasi sensor dan kepemilikan perangkat.
- Memvalidasi timestamp, nilai, dan satuan.
- Mencegah penyimpanan pesan duplikat.
- Menyimpan data pengukuran dan waktu penerimaan.
- Menandai data anomali.
- Menyediakan data terbaru dan riwayat telemetri.
- Mendukung filter waktu, pagination, dan sorting.

Data telemetri bersifat append-only.

### 5.6 MQTT Integration

Topik MQTT:

| Topic | Arah |
|---|---|
| `devices/{device_code}/telemetry` | ESP32 → Backend |
| `devices/{device_code}/status` | ESP32 → Backend |
| `devices/{device_code}/commands` | Backend → ESP32 |
| `devices/{device_code}/command-ack` | ESP32 → Backend |
| `devices/{device_code}/config` | Backend → ESP32 |
| `devices/{device_code}/config-ack` | ESP32 → Backend |

Ketentuan:
- QoS 1 untuk seluruh topik.
- Pesan menggunakan identifier unik untuk idempotensi.
- Retained message hanya digunakan pada topik config.
- ESP32 menggunakan Last Will and Testament (LWT).
- Status perangkat diperbarui berdasarkan komunikasi MQTT.
- Perintah tidak boleh dieksekusi dua kali akibat pengiriman ulang.

### 5.7 Irrigation Management

Backend mengelola identitas pintu irigasi dan perintah pengoperasiannya.

Jenis perintah:
- OPEN: membuka 100%.
- CLOSE: menutup 0%.
- SET_PERCENTAGE: mengatur persentase tertentu.

Alur perintah:

`PENDING → APPROVED → SENT → EXECUTED / FAILED / TIMEOUT`

Perintah PENDING dapat menjadi CANCELLED.

Ketentuan:
- ADMIN dan PETUGAS_LAPANGAN dapat membuat serta menyetujui perintah.
- PENGELOLA hanya dapat melihat.
- Pembuat perintah boleh menyetujui perintahnya sendiri.
- Pembuat dapat membatalkan perintah pending miliknya.
- Admin dapat membatalkan seluruh perintah pending.
- Pengiriman perintah dilakukan setelah persetujuan.
- ACK penerimaan bukan bukti keberhasilan operasi.
- Keberhasilan harus dikonfirmasi ESP32.
- Kegagalan pengiriman dan kegagalan eksekusi dibedakan.
- Retry menggunakan command_id yang sama.
- Riwayat peristiwa perintah disimpan secara append-only.

### 5.8 Early Warning System (EWS)

Jenis peringatan:

- ACTUAL: berdasarkan pembacaan sensor aktual.
- PREDICTION: berdasarkan prediksi AI.

Tingkat risiko:

- NORMAL
- LOW
- MEDIUM
- HIGH
- CRITICAL

Status peringatan:

- ACTIVE
- ACKNOWLEDGED
- RESOLVED

Ketentuan:
- Backend mengevaluasi pembacaan aktual berdasarkan warning rules.
- Backend menyimpan prediksi dari AI Service.
- Backend mengevaluasi hasil prediksi untuk menghasilkan warning.
- Peringatan yang masih berlangsung diperbarui, bukan dibuat berulang.
- Peringatan yang telah resolved menjadi riwayat.
- Kejadian risiko baru menghasilkan record warning baru.
- Admin mengelola warning rules.
- Admin dan Petugas Lapangan dapat acknowledge warning.

### 5.9 Recommendation Management

Backend meminta rekomendasi bukaan pintu dari AI Service secara berkala.

Data rekomendasi mencakup:
- Gate ID.
- Current opening.
- Recommended opening.
- Reason.
- Supporting data.
- Status.
- Reviewer.
- Waktu pembuatan dan kedaluwarsa.

Status:
- PENDING
- APPROVED
- REJECTED
- EXPIRED

Ketentuan:
- Rekomendasi dibuat oleh sistem berdasarkan hasil AI Service.
- Admin dan Petugas Lapangan dapat menyetujui atau menolak.
- Pengelola hanya dapat melihat.
- Rekomendasi memiliki expires_at.
- Rekomendasi pending otomatis expired setelah batas waktu.
- Status akhir tidak dapat diubah kembali.
- Perubahan konfigurasi masa berlaku hanya berlaku untuk rekomendasi baru.
- Rekomendasi yang disetujui dapat menghasilkan gate command.
- Jika current opening sama dengan recommended opening, rekomendasi tetap disimpan tetapi tidak menghasilkan command.

### 5.10 Audit Log

Mencatat aktivitas penting, meliputi:
- Authentication.
- User management.
- Device management.
- Sensor management.
- Warning rule changes.
- Recommendation review.
- Gate command dan hasil operasi.
- Runtime configuration changes.

Ketentuan:
- Bersifat append-only.
- Hanya Admin yang dapat melihat.
- Tidak menyimpan password, token, secret, atau API key.
- Aktivitas sistem dapat memiliki user_id NULL.

### 5.11 Runtime Configuration

Admin dapat mengubah konfigurasi operasional melalui backend.

Contoh:
- Interval pemrosesan EWS.
- Interval pembuatan rekomendasi.
- Batas waktu rekomendasi.
- MQTT retry interval.
- MQTT retry limit.
- Timeout komunikasi.

Secret dan kredensial tidak boleh disimpan dalam runtime_configs. Data rahasia disimpan dalam environment configuration.

---

## 6. Integrasi AI Service

AI Service menggunakan Python dan FastAPI, terpisah dari Main Backend.

Endpoint awal:

| Method | Endpoint | Fungsi |
|---|---|---|
| POST | `/api/v1/ews/predict` | Meminta prediksi EWS |
| POST | `/api/v1/recommendations/generate` | Meminta rekomendasi bukaan pintu |

Ketentuan:
- Autentikasi antarlayanan menggunakan API Key.
- API Key disimpan di environment.
- Backend memiliki timeout dan retry terbatas.
- Kegagalan AI Service dicatat.
- Backend tidak membuat hasil prediksi atau rekomendasi palsu saat AI Service gagal.
- Hasil yang berhasil diterima disimpan di PostgreSQL.

Detail payload request dan response akan ditetapkan dalam dokumen API Contract tersendiri.

---

## 7. REST API Standards

Semua endpoint menggunakan prefix:

`/api/v1/`

Format response berhasil:

```json
{
  "success": true,
  "message": "Data berhasil diambil",
  "data": {}
}
```

Format response gagal:

```json
{
  "success": false,
  "message": "Perangkat tidak ditemukan",
  "error": {
    "code": "DEVICE_NOT_FOUND"
  }
}
```

Ketentuan:
- Menggunakan HTTP status code yang sesuai.
- Validasi request menggunakan Zod.
- Pagination menggunakan page dan limit.
- Limit maksimal awal 100.
- Filter dan sorting harus divalidasi.
- Error ditangani melalui centralized error middleware.

---

## 8. Non-Functional Requirements

### 8.1 Security
- Password menggunakan Argon2.
- Access dan refresh token dikelola secara aman.
- Device credential terpisah dari autentikasi pengguna.
- RBAC diterapkan pada endpoint.
- Menggunakan Helmet, CORS, dan rate limiting.
- Secret tidak boleh masuk ke log.
- Input divalidasi sebelum diproses.

### 8.2 Reliability
- Pesan MQTT menggunakan mekanisme idempotensi.
- Data telemetri tidak ditimpa.
- Kegagalan integrasi dicatat.
- Perintah pintu memiliki timeout dan retry.
- Scheduler mencegah job yang sama berjalan tumpang tindih.

### 8.3 Maintainability
- Menggunakan Modular Monolith.
- TypeScript strict mode.
- Struktur modul dipisahkan berdasarkan domain.
- Menggunakan ESLint dan Prettier.
- Environment configuration dipisahkan dari source code.

### 8.4 Testing
- Unit testing menggunakan Vitest.
- Integration testing menggunakan Vitest.
- API testing menggunakan Supertest.
- Pengujian manual menggunakan Postman.

---

## 9. Database

Database menggunakan PostgreSQL dan Prisma ORM.

Rancangan awal terdiri dari 18 tabel:

1. users
2. auth_accounts
3. sessions
4. invitations
5. devices
6. device_credentials
7. sensors
8. telemetry_readings
9. gates
10. gate_commands
11. gate_operation_logs
12. gate_command_events
13. predictions
14. warnings
15. warning_rules
16. recommendations
17. audit_logs
18. runtime_configs

Ketentuan database:
- Primary key menggunakan UUID.
- Timestamp menggunakan TIMESTAMPTZ.
- ENUM menggunakan UPPER_SNAKE_CASE.
- Relasi menggunakan foreign key.
- Constraint dan index diterapkan untuk menjaga integritas.
- Data historis penting tidak dihapus secara fisik.
- Waktu disimpan dalam UTC dan ditampilkan menggunakan zona waktu Asia/Jakarta.

Detail ERD, kolom, relasi, constraint, dan index ditetapkan dalam dokumen Database Schema.

---

## 10. Scheduler dan Background Processing

Menggunakan node-cron untuk:
- Pemrosesan prediksi dan EWS.
- Pembuatan rekomendasi.
- Pemeriksaan rekomendasi kedaluwarsa.
- Pemeriksaan timeout perintah pintu.
- Proses operasional berkala lainnya.

Interval dibuat dapat dikonfigurasi melalui runtime_configs jika termasuk konfigurasi operasional.

Pada prototipe, scheduler berjalan dalam satu instance backend dan mencegah overlap job yang sama.

---

## 11. Batasan dan Hal yang Belum Final

Hal berikut belum ditetapkan secara menyeluruh:

1. Detail deduplikasi warning berdasarkan identitas kejadian.
2. Batas nilai normal dan anomali setiap sensor.
3. Kontrak payload MQTT final.
4. Detail autentikasi perangkat pada Mosquitto.
5. Kontrak request dan response AI Service.
6. Detail retry dan timeout setiap integrasi.
7. Kondisi dan frekuensi pembuatan rekomendasi.
8. Kebijakan retensi dan pengarsipan telemetri.
9. Detail pengaitan akun Google dan mekanisme invitation pada implementasi.
10. Penanganan konflik beberapa perintah untuk satu pintu.

Hal-hal tersebut akan diselesaikan pada tahap Database Schema, API Contract, dan implementasi modul terkait.

---

## 12. Kriteria Penerimaan

Main Backend dinyatakan memenuhi kebutuhan awal apabila:

- Pengguna dapat login sesuai role.
- Admin dapat mengelola akun dan perangkat.
- Perangkat dapat mengirim telemetri melalui MQTT.
- Telemetri tersimpan dan dapat diakses melalui REST API.
- Sistem dapat menghasilkan dan mengelola warning.
- Backend dapat berkomunikasi dengan AI Service.
- Rekomendasi AI dapat disimpan dan ditinjau.
- Perintah pintu dapat dikirim melalui MQTT setelah persetujuan.
- Status operasi diperbarui berdasarkan konfirmasi perangkat.
- Audit log merekam aktivitas penting.
- Seluruh endpoint menerapkan validasi dan otorisasi.
- Pengujian unit dan integrasi utama berhasil.
