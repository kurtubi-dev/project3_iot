# Business Rules — Main Backend

Dokumen ini memuat aturan operasional yang harus diimplementasikan pada service layer dan/atau database. Jangan mengubah aturan berstatus DISEPAKATI tanpa persetujuan pemilik proyek.

Label:
- **DISEPAKATI**: sudah diputuskan.
- **ASUMSI**: rancangan sementara untuk memudahkan implementasi.
- **PERLU DIKONFIRMASI**: belum final.

## 1. Role dan Akses

| Fitur | ADMIN | PETUGAS_LAPANGAN | PENGELOLA |
|---|---:|---:|---:|
| Melihat telemetry | Ya | Ya | Ya |
| Mengelola user | Ya | Tidak | Tidak |
| Mengelola device/sensor | Ya | Read-only | Read-only |
| Melihat warning | Ya | Ya | Ya |
| Acknowledge warning | Ya | Ya | Tidak |
| Mengelola warning rules | Ya | Tidak | Tidak |
| Melihat recommendation | Ya | Ya | Ya |
| Approve/reject recommendation | Ya | Ya | Tidak |
| Membuat gate command | Ya | Ya | Tidak |
| Approve gate command | Ya | Ya | Tidak |
| Melihat operation history | Ya | Ya | Ya |
| Mengelola runtime config | Ya | Tidak | Tidak |
| Melihat audit log | Ya | Tidak | Tidak |

## 2. Authentication dan Session

**DISEPAKATI**
- Tidak ada registrasi publik.
- Admin membuat akun melalui invitation pada production.
- Development boleh memakai seed/test account; mekanisme ini tidak boleh tersedia di production.
- Google login hanya untuk email yang sudah terdaftar dan terverifikasi.
- Google login tidak membuat akun otomatis.
- Linking Google dilakukan setelah user login ke akun lokal dan menyelesaikan autentikasi Google.
- Google identity yang telah terhubung ke akun lain harus ditolak.
- Access token 15 menit.
- Refresh token 7 hari.
- Refresh token disimpan hash dan menggunakan rotation.
- Multi-session.
- Logout mencabut sesi saat ini.
- Admin dapat revoke semua sesi user.
- User INACTIVE tidak dapat login/refresh; sesi aktif dicabut ketika dinonaktifkan.

**PERLU DIKONFIRMASI**
- Reuse detection untuk refresh token lama dan kebijakan revoke seluruh token family.
- Detail invitation resend, pembatalan, dan undangan aktif ganda.

## 3. Device Credential

**DISEPAKATI**
- Device credential terpisah dari user JWT.
- Raw secret hanya ditampilkan saat dibuat/dirotasi.
- Database hanya menyimpan hash.
- Rotasi mencabut credential sebelumnya.
- Satu credential aktif per device.
- Device inactive tidak boleh mengirim telemetry operasional.
- Riwayat credential dipertahankan.

**PERLU DIKONFIRMASI**
- Mekanisme autentikasi device ke Mosquitto: username/password per device, client certificate, atau mekanisme broker ACL lain.
- Apakah secret yang sama dipakai untuk provisioning HTTP dan MQTT atau dipisah.

## 4. Telemetry

**DISEPAKATI**
- Payload membawa message_id, device_code, sensor_code, timestamp, value, unit.
- message_id unik dan digunakan untuk idempotensi.
- measured_at berasal dari timestamp device.
- received_at dibuat backend.
- Device dan sensor harus cocok.
- Malformed payload, device/sensor tidak dikenal, inactive device/sensor, dan mismatch ditolak.
- Data valid secara format tetapi tidak wajar dapat disimpan sebagai ANOMALY.
- Data ANOMALY tidak menjadi input AI sampai dinyatakan layak.
- Data append-only.

**PERLU DIKONFIRMASI**
- Batas rentang fisik dan batas anomali untuk tiap sensor.
- Toleransi clock drift timestamp ESP32.
- Kebijakan data terlambat/out-of-order.
- Retensi, partisi, dan arsip telemetry.
- Apakah unit harus selalu sama dengan master sensor atau boleh dikonversi.

## 5. MQTT

**DISEPAKATI**
- QoS 1 untuk enam topik.
- Retained hanya pada config.
- Command tidak retained.
- LWT device untuk OFFLINE.
- Device publish ONLINE setelah reconnect.
- Command memakai command_id yang stabil saat retry.
- ESP32 harus idempotent terhadap command_id.
- Config retained agar perangkat mendapat konfigurasi terbaru setelah reconnect.

**PERLU DIKONFIRMASI**
- Format payload final.
- Broker ACL dan mapping device credential.
- Heartbeat interval dan offline timeout.
- Message expiry/session expiry bila digunakan.
- Skema versioning config.

## 6. Gate dan Command

**DISEPAKATI**
- Gate dan device adalah entitas terpisah.
- Relasi awal satu device untuk satu gate.
- actual_opening adalah laporan perangkat; target_opening adalah target command.
- OPEN = 100%, CLOSE = 0%, SET_PERCENTAGE = nilai 0–100%.
- Admin/Petugas Lapangan membuat dan menyetujui.
- Pengelola read-only.
- Creator boleh approve command sendiri.
- Creator boleh cancel command PENDING miliknya.
- Admin boleh cancel command PENDING siapa pun.
- Setelah approval, backend mengirim MQTT.
- ACK penerimaan bukan execution success.
- ESP32 melaporkan MOVING dan hasil akhir.
- Delivery failure berbeda dari execution failure.
- Retry memakai command_id sama.
- Retry/timeouts configurable.
- Event command append-only.
- Terminal state tidak boleh kembali ke state sebelumnya.

State:
```text
PENDING -> APPROVED -> SENT -> EXECUTED
                            -> FAILED
                            -> TIMEOUT
PENDING -> CANCELLED
```

**PERLU DIKONFIRMASI**
- Apakah satu gate boleh memiliki lebih dari satu command non-terminal sekaligus.
- Apakah command baru otomatis menolak/menunggu command lama.
- Detail state saat delivery gagal tetapi retry masih tersedia.
- Apakah TIMEOUT dapat terjadi setelah ACK tetapi tidak ada hasil eksekusi.
- Definisi `started_at` dan kapan operation log dibuat.

## 7. Warning / EWS

**DISEPAKATI**
- ACTUAL berasal dari sensor aktual.
- PREDICTION berasal dari AI.
- Backend mengevaluasi threshold rules untuk data aktual dan prediksi.
- Risk: NORMAL, LOW, MEDIUM, HIGH, CRITICAL.
- Status: ACTIVE, ACKNOWLEDGED, RESOLVED.
- Admin mengelola rules.
- Admin/Petugas Lapangan acknowledge/update status.
- Pengelola read-only.
- Warning sama saat kejadian berlangsung diperbarui, bukan dibuat berulang.
- Warning resolved menjadi histori; kejadian berulang setelah resolved membuat record baru.
- Jika warning acknowledged dan risiko berlanjut, status tetap ACKNOWLEDGED sambil memperbarui detail/timestamp.

State:
```text
ACTIVE -> ACKNOWLEDGED -> RESOLVED
ACTIVE ----------------> RESOLVED
```

**PERLU DIKONFIRMASI**
- Event identity untuk deduplikasi: kombinasi sensor/parameter/rule/risk band atau event key lain.
- Hysteresis dan kondisi resolusi.
- Ambang batas tiap parameter.
- Apakah risk level NORMAL disimpan sebagai warning atau hanya menandai resolusi.

## 8. Recommendation

**DISEPAKATI**
- AI Service menghasilkan recommendation; Main Backend menyimpan dan mengelolanya.
- Admin/Petugas Lapangan approve/reject.
- Pengelola read-only.
- Recommendation memiliki expires_at.
- Pending otomatis EXPIRED setelah lewat expires_at.
- APPROVED, REJECTED, EXPIRED adalah status akhir.
- Perubahan expiry berlaku untuk recommendation baru.
- Recommendation approved dapat menghasilkan maksimal satu gate command.
- Jika current_opening sama dengan recommended_opening, recommendation disimpan tanpa command.
- Approval recommendation tidak berarti gate berhasil bergerak; hasilnya ditentukan command lifecycle.

**PERLU DIKONFIRMASI**
- Kondisi/frekuensi generate recommendation.
- Apakah reviewer dapat mengubah recommended percentage sebelum approve.
- Apakah recommendation lama otomatis expired saat recommendation baru muncul.
- Apakah approval harus ditolak jika kondisi gate/telemetry berubah sejak recommendation dibuat.

## 9. AI Service

**DISEPAKATI**
- Service terpisah dengan FastAPI.
- Main Backend memanggil melalui HTTP REST.
- API Key dari environment.
- Timeout dan retry terbatas.
- Kegagalan dicatat.
- Tidak membuat prediksi/recommendation palsu saat AI gagal.
- Job EWS dan recommendation independen.
- Job sama tidak boleh overlap pada satu instance.

**PERLU DIKONFIRMASI**
- Request/response schema.
- Timeout, retry, dan backoff.
- Idempotency key untuk request generate.
- Model version dan confidence/metadata yang disimpan.

## 10. Audit dan Runtime Config

**DISEPAKATI**
- Audit log append-only.
- Admin only untuk melihat.
- Mencatat aktivitas penting.
- Tidak menyimpan credential/secret.
- Runtime config menyimpan pengaturan operasional non-secret.
- Perubahan config dan warning rules diaudit.
- Secret berada di environment.

**PERLU DIKONFIRMASI**
- Retensi audit log.
- Daftar key config final dan validasi tipe/rentang tiap value.
