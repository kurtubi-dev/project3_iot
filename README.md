# Main Backend Documentation Pack

Dokumentasi acuan untuk AI coding agent dan pengembang Main Backend.

## Isi
- `docs/PRD.md` — kebutuhan produk dan ruang lingkup.
- `docs/DATABASE_SCHEMA.md` — rancangan 18 tabel, kolom, constraint, dan index.
- `docs/DATABASE_RELATIONS.md` — relasi dan ERD Mermaid.
- `docs/BUSINESS_RULES.md` — aturan operasional dan status.
- `docs/API_SPECIFICATION.md` — rancangan endpoint REST.
- `docs/MQTT_AI_INTEGRATION.md` — integrasi MQTT dan AI Service.

## Cara menggunakan dengan AI coding agent
1. Berikan seluruh folder `docs/` sebagai konteks proyek.
2. Minta agent membaca semua dokumen sebelum mengubah kode.
3. Minta agent mengidentifikasi konflik/ketidakjelasan terlebih dahulu.
4. Jangan izinkan agent mengubah keputusan berstatus DISEPAKATI tanpa konfirmasi.
5. Untuk hal PERLU DIKONFIRMASI, agent harus menandai asumsi dan bertanya sebelum mengunci implementasi.
6. Buat `schema.prisma` dari `DATABASE_SCHEMA.md` dan `DATABASE_RELATIONS.md`.
7. Jalankan validasi Prisma dan review custom SQL migration sebelum migrasi database.

## Prompt awal untuk AI coding agent

Baca seluruh dokumentasi di folder `docs/` terlebih dahulu. Kamu bertugas mengembangkan Main Backend sesuai dokumen. Pertahankan semua keputusan yang telah disepakati. Jangan mengarang business rule, field, endpoint, atau integrasi yang belum ditentukan. Laporkan konflik dan hal yang belum jelas sebelum implementasi. Gunakan TypeScript strict, Express.js, Prisma, PostgreSQL, Zod, dan struktur Modular Monolith. Jangan membuat frontend, firmware ESP32, atau model AI dalam repository Main Backend. Untuk tahap pertama, review dokumen dan usulkan struktur project serta daftar keputusan yang masih perlu dikonfirmasi. Jangan langsung membuat seluruh aplikasi sekaligus.

## Catatan status
Dokumen ini adalah draft teknis awal. Contoh payload dan beberapa kebijakan integrasi masih ilustratif. Database schema harus direview sebelum migration final.
