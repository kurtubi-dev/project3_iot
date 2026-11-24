# API Specification — Main Backend

- Base path: `/api/v1`
- Format: JSON
- Status: Draft; daftar endpoint awal, kontrak payload rinci belum final.

## 1. Standar Response

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
  "error": {
    "code": "DEVICE_NOT_FOUND"
  }
}
```

Paginated response dapat menyertakan:
```json
{
  "success": true,
  "message": "Data berhasil diambil",
  "data": [],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

## 2. Aturan Umum

- Prefix semua endpoint `/api/v1/`.
- Validasi request menggunakan Zod.
- `page` mulai dari 1.
- `limit` maksimal 100 (nilai awal; dapat dikonfigurasi).
- Filter dan sort harus memakai allowlist.
- Terapkan authentication dan role authorization sesuai endpoint.
- Jangan mengembalikan hash password, refresh token hash, device secret hash, atau API key.
- Gunakan HTTP status code yang tepat.
- Centralized error handler mengubah error internal menjadi format standar.

## 3. Endpoint Awal

### Auth
| Method | Endpoint | Akses | Fungsi |
|---|---|---|---|
| POST | `/auth/login` | Public | Login lokal |
| POST | `/auth/google` | Public | Login Google untuk akun terdaftar |
| POST | `/auth/refresh` | Refresh token | Rotasi refresh token |
| POST | `/auth/logout` | Authenticated | Logout sesi aktif |
| POST | `/auth/change-password` | Authenticated | Ganti password |
| POST | `/auth/google/link` | Authenticated | Menghubungkan akun Google |

Tidak ada endpoint public register.

### Users
| Method | Endpoint | Akses | Fungsi |
|---|---|---|---|
| GET | `/users` | ADMIN | Daftar user |
| GET | `/users/:id` | ADMIN | Detail user |
| PATCH | `/users/:id` | ADMIN | Ubah profil/role |
| PATCH | `/users/:id/status` | ADMIN | Aktif/nonaktif |
| POST | `/users/invitations` | ADMIN | Buat invitation |
| POST | `/users/invitations/:id/resend` | ADMIN | Kirim ulang invitation |

Endpoint acceptance invitation perlu ditetapkan terpisah, misalnya `POST /auth/accept-invitation`.

### Devices
| Method | Endpoint | Akses | Fungsi |
|---|---|---|---|
| GET | `/devices` | Semua role | Daftar device |
| GET | `/devices/:id` | Semua role | Detail device |
| POST | `/devices` | ADMIN | Registrasi device |
| PATCH | `/devices/:id` | ADMIN | Ubah device |
| PATCH | `/devices/:id/status` | ADMIN | Aktif/nonaktif |
| POST | `/devices/:id/credentials/rotate` | ADMIN | Rotasi credential |

### Sensors
| Method | Endpoint | Akses | Fungsi |
|---|---|---|---|
| GET | `/sensors` | Semua role | Daftar sensor |
| GET | `/sensors/:id` | Semua role | Detail sensor |
| POST | `/sensors` | ADMIN | Registrasi sensor |
| PATCH | `/sensors/:id` | ADMIN | Ubah sensor |
| PATCH | `/sensors/:id/status` | ADMIN | Aktif/nonaktif |

### Telemetry
| Method | Endpoint | Akses | Fungsi |
|---|---|---|---|
| GET | `/telemetry` | Semua role | Daftar telemetri |
| GET | `/telemetry/latest` | Semua role | Data terbaru |
| GET | `/telemetry/:id` | Semua role | Detail pembacaan |
| GET | `/telemetry/history` | Semua role | Histori dengan filter |

Telemetry inbound diterima melalui MQTT, bukan endpoint publik di tabel ini.

### Irrigation
| Method | Endpoint | Akses | Fungsi |
|---|---|---|---|
| GET | `/gates` | Semua role | Daftar gate |
| GET | `/gates/:id` | Semua role | Detail gate |
| GET | `/gate-commands` | Semua role | Daftar command |
| GET | `/gate-commands/:id` | Semua role | Detail command dan event |
| POST | `/gate-commands` | ADMIN, PETUGAS_LAPANGAN | Buat command |
| POST | `/gate-commands/:id/approve` | ADMIN, PETUGAS_LAPANGAN | Approve command |
| POST | `/gate-commands/:id/cancel` | Creator atau ADMIN | Cancel pending |
| GET | `/gate-operation-logs` | Semua role | Histori operasi |

### Warnings
| Method | Endpoint | Akses | Fungsi |
|---|---|---|---|
| GET | `/warnings` | Semua role | Daftar warning |
| GET | `/warnings/:id` | Semua role | Detail warning |
| PATCH | `/warnings/:id/acknowledge` | ADMIN, PETUGAS_LAPANGAN | Acknowledge |
| PATCH | `/warnings/:id/resolve` | ADMIN, PETUGAS_LAPANGAN | Resolve jika diizinkan business rule |
| GET | `/warning-rules` | ADMIN | Daftar rules |
| POST | `/warning-rules` | ADMIN | Buat rule |
| PATCH | `/warning-rules/:id` | ADMIN | Ubah rule |
| PATCH | `/warning-rules/:id/status` | ADMIN | Aktif/nonaktif |

### Recommendations
| Method | Endpoint | Akses | Fungsi |
|---|---|---|---|
| GET | `/recommendations` | Semua role | Daftar recommendation |
| GET | `/recommendations/:id` | Semua role | Detail recommendation |
| POST | `/recommendations/:id/approve` | ADMIN, PETUGAS_LAPANGAN | Approve |
| POST | `/recommendations/:id/reject` | ADMIN, PETUGAS_LAPANGAN | Reject |

Recommendation dibuat oleh backend melalui integrasi AI, bukan endpoint publik biasa.

### Audit Logs
| Method | Endpoint | Akses | Fungsi |
|---|---|---|---|
| GET | `/audit-logs` | ADMIN | Daftar audit log |
| GET | `/audit-logs/:id` | ADMIN | Detail audit log |

### Runtime Config
| Method | Endpoint | Akses | Fungsi |
|---|---|---|---|
| GET | `/runtime-configs` | ADMIN | Daftar config |
| PATCH | `/runtime-configs/:key` | ADMIN | Ubah config |

## 4. Catatan

- Endpoint di atas adalah rancangan awal, bukan kontrak final.
- Nama endpoint, payload, query, response, dan status code perlu dirinci sebelum implementasi masing-masing modul.
- Jangan menambahkan endpoint yang membuka operasi perangkat tanpa autentikasi device atau user sesuai konteks.
- Endpoint status device dan gate harus dibedakan.
- Operasi approval harus memakai transaksi dan validasi status terkini.
