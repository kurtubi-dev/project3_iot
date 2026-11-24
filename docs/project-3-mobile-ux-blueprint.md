# Rencana UX Blueprint — Project 3 Mobile

## Catatan Revisi Terbatas

Revisi ini tidak mengubah tujuan, konsep utama, navigasi, ataupun flow lain yang sudah sesuai. Perubahan hanya dilakukan pada:

1. **Bagian 2 — Keputusan produk:** memperjelas role Petugas Lapang dan status jumlah pintu yang belum ditetapkan.
2. **Bagian 5 — Arsitektur Informasi:** memperjelas tiga pilihan keputusan terhadap rekomendasi AI tanpa mengubah destinasi navigasi.
3. **Bagian 6 — Inventaris Layar:** menambahkan state keputusan rekomendasi dan memperjelas akses Petugas Lapang.
4. **Bagian 7 — User Flow:** merinci tiga cabang keputusan petugas serta menegaskan bahwa keputusan rekomendasi tidak mengeksekusi kendali.
5. **Bagian 8 — State dan Aturan Interaksi:** menambahkan status keputusan rekomendasi dan aturan hak akses.
6. **Bagian 9 — Kebutuhan Informasi:** menambahkan status keputusan petugas pada data rekomendasi.
7. **Bagian 12 — Kriteria Penerimaan:** menambahkan validasi ketiga cabang keputusan AI, kesetaraan hak Petugas Lapang, dan fleksibilitas jumlah pintu.

### Keputusan yang kini dikunci

- Pengguna aplikasi mobile adalah **Petugas Lapang**.
- Setiap Petugas Lapang dengan akun valid dan sesi login aktif memiliki hak operasional yang sama di dalam aplikasi mobile.
- Tidak ada pembatasan kendali berdasarkan identitas Petugas Lapang tertentu.
- Petugas dapat **menerapkan**, **memodifikasi**, atau **tidak menerapkan** rekomendasi AI.
- Keputusan terhadap rekomendasi AI tidak pernah otomatis mengirim perintah kendali.
- Modifikasi yang berbeda signifikan dari rekomendasi mewajibkan alasan.
- Struktur UX mendukung lebih dari satu pintu, tetapi jumlah pintu pada prototipe Project 3 belum ditetapkan dan tidak diasumsikan.

## 1. Ringkasan

Menyusun UX blueprint dan user flow untuk aplikasi mobile monitoring telemetri curah hujan, tinggi muka air, rekomendasi bukaan pintu berbasis AI, dan kendali pintu irigasi bagi Petugas Lapang PUPR Bidang Sumber Daya Air.

Tahap ini berfokus pada struktur pengalaman pengguna, alur operasional, informasi yang dibutuhkan, state sistem, dan aturan keselamatan. Tahap ini tidak mencakup desain visual final, implementasi frontend/backend, integrasi perangkat IoT, atau model AI.

## 2. Kondisi Awal dan Keputusan yang Sudah Dikunci

### Kondisi repository

- Aplikasi saat ini adalah scaffold React 19 + Vite + Tailwind CSS v4.
- `src/App.tsx` masih kosong dan belum memiliki pola navigasi, komponen, data, maupun integrasi.
- Blueprint ini akan menjadi dasar untuk tahap desain/prototype berikutnya, bukan langsung diimplementasikan pada tahap ini.

### Keputusan produk

- Target utama: mobile portrait generik untuk penggunaan petugas di lapangan.
- Cakupan: seluruh aplikasi, dengan kedalaman utama pada alur monitoring → rekomendasi AI → pengambilan keputusan → kendali → hasil/riwayat.
- Terdapat dua stasiun telemetri tetap:
  - Node 1 — Hulu.
  - Node 2 — Hilir.
- Struktur UX harus fleksibel untuk mendukung lebih dari satu pintu, tetapi jumlah pintu pada prototipe Project 3 belum ditetapkan. Blueprint tidak mengunci atau mengasumsikan jumlah perangkat fisik.
- Rekomendasi AI dibuat per pintu berdasarkan data dari kedua node.
- Aplikasi mobile ditujukan untuk role Petugas Lapang.
- Setiap Petugas Lapang dengan akun valid dan berhasil login memiliki hak yang sama untuk melihat dashboard, monitoring, data Node Hulu/Hilir, rekomendasi AI, kendali pintu, riwayat aktivitas, dan hasil pengendalian.
- Tidak ada pembatasan akses kendali berdasarkan identitas Petugas Lapang tertentu.
- AI adalah pendukung keputusan, bukan eksekutor otomatis.
- Untuk setiap rekomendasi AI, Petugas Lapang dapat menerapkan target yang disarankan, memodifikasi target secara manual, atau tidak menerapkan rekomendasi.
- Pilihan keputusan terhadap rekomendasi tidak otomatis menjalankan kendali pintu; eksekusi selalu melalui penentuan target, konfirmasi, pengiriman perintah, dan hasil.
- Target bukaan dipilih melalui preset dan input persentase.
- Jika keputusan berbeda secara signifikan dari rekomendasi AI, alasan penyimpangan wajib dicatat.
- Bila AI tidak tersedia atau rekomendasi kedaluwarsa, kendali manual tetap dapat dilakukan dengan peringatan.
- Saat aplikasi atau perangkat tidak memiliki koneksi yang memadai:
  - Data terakhir tetap dapat dilihat beserta waktu pembaruannya.
  - Fungsi kendali menjadi read-only/dinonaktifkan.
  - Perintah tidak boleh diantrikan untuk dikirim otomatis setelah koneksi pulih.
- Peringatan kritis harus diakui/dikonfirmasi telah dibaca oleh petugas, tetapi tidak boleh mengendalikan pintu secara otomatis.
- Riwayat disajikan dalam satu pusat riwayat dengan filter.

## 3. Tujuan UX

1. Memungkinkan petugas memahami kondisi sistem terkini dalam beberapa detik.
2. Menjaga konteks node dan pintu agar pengguna tidak mengirim perintah ke objek yang salah.
3. Memisahkan dengan jelas:
   - Fakta sensor.
   - Analisis/rekomendasi AI.
   - Keputusan manusia.
   - Hasil eksekusi perangkat.
4. Membuat waktu pembaruan, satuan, kualitas/ketersediaan data, dan status koneksi selalu terlihat.
5. Mencegah perintah tidak sengaja melalui validasi dan konfirmasi yang proporsional.
6. Tetap berguna dalam kondisi koneksi buruk tanpa memberi kesan bahwa data lama adalah data real-time.
7. Menghasilkan jejak audit yang dapat menjelaskan siapa melakukan apa, pada pintu mana, kapan, berdasarkan rekomendasi apa, dan dengan hasil apa.

## 4. Prinsip Pengalaman

- **Status sebelum aksi:** kondisi pintu, koneksi, waktu pembaruan, dan target harus terlihat sebelum kontrol aktif.
- **Label selain warna:** normal, waspada, kritis, online, offline, gangguan, tertunda, berhasil, dan gagal harus memakai teks/ikon selain warna.
- **Konteks objek selalu melekat:** nama/lokasi pintu tetap terlihat selama detail rekomendasi, pengaturan target, konfirmasi, dan hasil eksekusi.
- **AI dapat dijelaskan:** rekomendasi menampilkan target, tingkat kewaspadaan, waktu analisis, data pendukung, dan alasan ringkas.
- **Tidak ada otomatisasi tersembunyi:** membuka rekomendasi atau memilih preset tidak pernah langsung mengirim perintah.
- **Data lama tidak disamarkan:** tampilkan “diperbarui X menit lalu” dan status “kedaluwarsa” sesuai metadata server.
- **Kegagalan dapat dipulihkan:** setiap kegagalan menyediakan sebab yang dapat dipahami dan tindakan berikutnya yang aman.
- **Lapangan terlebih dahulu:** target sentuh besar, informasi utama ringkas, istilah konsisten, dan angka penting tidak bergantung pada grafik.

## 5. Arsitektur Informasi

### Navigasi utama

Gunakan lima destinasi utama:

1. **Beranda**
   - Ringkasan kondisi keseluruhan.
   - Peringatan aktif.
   - Kondisi Node Hulu dan Hilir.
   - Ringkasan pintu.
   - Rekomendasi AI terbaru yang perlu perhatian.
2. **Monitoring**
   - Daftar/ringkasan kedua node.
   - Detail node.
   - Data sensor terkini.
   - Grafik dan riwayat sensor.
   - Status perangkat dan konektivitas.
3. **Rekomendasi AI**
   - Daftar rekomendasi per pintu.
   - Detail rekomendasi dan data pendukung.
   - Pilihan keputusan petugas: terapkan, modifikasi target, atau tidak terapkan.
   - Riwayat rekomendasi.
   - Jalur menuju kontrol pintu terkait.
4. **Kendali**
   - Daftar pintu.
   - Status dan posisi terkini.
   - Detail pintu.
   - Pengaturan target, konfirmasi, progres, dan hasil.
5. **Riwayat**
   - Riwayat terpadu.
   - Filter jenis, node/pintu, tingkat/status, dan rentang tanggal.
   - Detail setiap catatan.

### Navigasi sekunder

- **Notifikasi:** ikon di header dengan badge jumlah belum dibaca/kritis.
- **Profil:** akses dari header atau menu akun; memuat identitas, peran, pengaturan, dan logout.
- **Konteks pintu:** pemilih pintu pada modul Rekomendasi dan Kendali jika diperlukan, tanpa menghilangkan nama pintu pada layar turunannya.

## 6. Inventaris Layar

### A. Autentikasi

1. Splash/session check.
2. Login.
3. State login gagal.
4. State sesi berakhir dengan jalur login ulang.

### B. Beranda

1. Dashboard kondisi normal.
2. Dashboard dengan peringatan aktif.
3. Dashboard dengan data sebagian/kedensitasan berbeda.
4. Dashboard offline yang menampilkan snapshot terakhir.

Konten minimum:

- Sapaan dan identitas singkat petugas.
- Status sinkronisasi aplikasi.
- Ringkasan tingkat kewaspadaan tertinggi.
- Ringkasan curah hujan serta tinggi muka air Node Hulu/Hilir.
- Jumlah node online/offline/gangguan.
- Jumlah pintu dan status utamanya.
- Rekomendasi AI terbaru per pintu yang perlu tindakan.
- Peringatan kritis yang belum diakui.

### C. Monitoring

1. Ringkasan Node Hulu dan Hilir.
2. Detail node.
3. Detail metrik curah hujan.
4. Detail metrik tinggi muka air.
5. Grafik/riwayat sensor dengan pemilih periode.
6. Detail status perangkat.

Konten minimum setiap node:

- Nama dan lokasi.
- Online/offline/gangguan.
- Waktu data terakhir diterima.
- Curah hujan beserta satuan.
- Tinggi muka air beserta satuan.
- Tingkat kondisi tiap metrik.
- Kualitas/ketersediaan data bila disediakan sistem.
- Grafik sebagai pelengkap, bukan satu-satunya cara membaca angka.

### D. Rekomendasi AI

1. Daftar rekomendasi per pintu.
2. Detail rekomendasi.
3. State pemilihan keputusan: terapkan, modifikasi, atau tidak terapkan.
4. State keputusan “tidak diterapkan”.
5. State rekomendasi kedaluwarsa.
6. State AI tidak tersedia.
7. Riwayat rekomendasi.

Konten minimum detail:

- Nama pintu.
- Target bukaan yang direkomendasikan.
- Posisi pintu saat ini untuk perbandingan.
- Tingkat kewaspadaan.
- Waktu rekomendasi dibuat dan masa berlaku/status freshness.
- Ringkasan alasan.
- Snapshot data Node Hulu dan Hilir yang digunakan.
- Penegasan bahwa keputusan tetap berada pada petugas.
- Tiga tindakan yang jelas:
  - “Terapkan rekomendasi” untuk membawa target AI ke tahap penentuan target.
  - “Ubah target” untuk membuka penentuan target manual dengan rekomendasi sebagai pembanding.
  - “Tidak terapkan” untuk mencatat bahwa rekomendasi tidak dilanjutkan ke kendali.
- Tindakan “Terapkan rekomendasi” dan “Ubah target” hanya membawa konteks ke modul Kendali; keduanya tidak langsung mengirim perintah.

### E. Kendali Pintu

1. Daftar pintu.
2. Detail pintu.
3. Form target bukaan.
4. Form alasan penyimpangan bila diperlukan.
5. Konfirmasi perintah.
6. Pengiriman/progres perintah.
7. Hasil berhasil.
8. Hasil gagal/timeout/ditolak perangkat.
9. State read-only karena offline/gangguan.

Konten minimum detail pintu:

- Nama/lokasi pintu.
- Status koneksi dan kesehatan perangkat.
- Posisi aktual.
- Target aktif bila ada.
- Waktu pembaruan terakhir.
- Rekomendasi AI terbaru dan status freshness.
- Preset target, misalnya 0%, 25%, 50%, 75%, 100%.
- Input persentase dengan batas 0–100.
- Perbandingan posisi sekarang → target petugas → rekomendasi AI.

### F. Notifikasi

1. Daftar notifikasi.
2. Detail notifikasi.
3. Acknowledgement peringatan kritis.
4. Filter status/tingkat/jenis.

Jenis minimum:

- Kondisi sensor/lingkungan.
- Node offline atau gangguan.
- AI tidak tersedia/rekomendasi kedaluwarsa.
- Perintah berhasil, gagal, atau timeout.
- Pintu tidak mencapai target.

### G. Riwayat

1. Daftar terpadu.
2. Filter.
3. Detail monitoring.
4. Detail rekomendasi AI.
5. Detail kendali.
6. Empty state dan error state.

Detail kendali minimum:

- Petugas.
- Pintu.
- Waktu dibuat/dikirim/selesai.
- Posisi awal, target, dan posisi akhir.
- Rekomendasi AI saat keputusan dibuat.
- Alasan penyimpangan, bila ada.
- Status dan pesan hasil perangkat.
- ID referensi yang dapat digunakan untuk pelacakan insiden.

### H. Profil

1. Informasi akun.
2. Informasi peran.
3. Pengaturan dasar yang relevan.
4. Konfirmasi logout.

Semua layar operasional pada bagian Beranda, Monitoring, Rekomendasi AI, Kendali, Notifikasi, dan Riwayat dapat diakses oleh setiap Petugas Lapang yang memiliki akun valid dan sesi login aktif.

## 7. User Flow Utama

### Flow 1 — Login dan orientasi kondisi

1. Aplikasi memeriksa sesi.
2. Bila tidak valid, pengguna masuk ke Login.
3. Pengguna memasukkan kredensial.
4. Sistem memvalidasi dan membuka Beranda.
5. Beranda memprioritaskan:
   - Peringatan kritis belum diakui.
   - Status offline/gangguan.
   - Kondisi air/hujan berisiko.
   - Rekomendasi yang memerlukan perhatian.
6. Jika pemuatan sebagian gagal, bagian lain tetap tampil dan modul gagal memiliki aksi coba lagi.

### Flow 2 — Memeriksa kondisi dua node

1. Dari Beranda atau Monitoring, pengguna membuka Node Hulu/Hilir.
2. Pengguna melihat nilai terkini, unit, waktu pembaruan, dan status perangkat.
3. Pengguna memilih metrik atau periode untuk melihat tren.
4. Pengguna dapat membandingkan konteks kedua node tanpa kehilangan identitas node aktif.
5. Jika data lama/offline, aplikasi menandai freshness dan tidak menyebutnya real-time.

### Flow 3 — Meninjau dan memutuskan rekomendasi AI

1. Pengguna membuka Rekomendasi AI.
2. Sistem menampilkan rekomendasi per pintu, diurutkan berdasarkan urgensi lalu waktu.
3. Pengguna memilih satu pintu.
4. Detail menampilkan target AI, alasan, kewaspadaan, data kedua node, dan waktu analisis.
5. Petugas memilih salah satu dari tiga keputusan:
   - **Terapkan rekomendasi AI:** target yang disarankan dibawa ke tahap penentuan target pada modul Kendali.
   - **Modifikasi target:** modul Kendali dibuka untuk pintu yang sama; petugas menentukan target manual dengan target AI tetap terlihat sebagai pembanding.
   - **Tidak menerapkan rekomendasi AI:** keputusan dicatat pada rekomendasi dan alur berhenti tanpa membuka atau menjalankan kendali. Catatan tambahan dapat disediakan, tetapi tidak diwajibkan oleh blueprint ini.
6. Pada cabang “Terapkan” atau “Modifikasi”, aplikasi membuka detail Kendali untuk pintu yang sama dan membawa referensi rekomendasi.
7. Tidak satu pun dari tiga keputusan mengirim perintah secara otomatis.
8. Perintah hanya dapat dikirim setelah petugas melewati penentuan target, validasi, konfirmasi, eksekusi, dan hasil pada flow Kendali.

### Flow 4 — Menentukan target dan mengirim perintah sesuai rekomendasi

1. Pengguna berada pada detail pintu.
2. Sistem memastikan:
   - Aplikasi online.
   - Pintu online dan tidak berstatus gangguan yang memblokir kontrol.
   - Posisi aktual tersedia dan cukup baru.
3. Target rekomendasi telah dibawa dari Flow 3, tetapi tetap ditampilkan sebagai target yang harus ditinjau petugas dan belum menjadi perintah.
4. Pengguna dapat mempertahankan target rekomendasi melalui preset/input persentase.
5. Target sesuai/tidak menyimpang signifikan dari rekomendasi; alasan tambahan tidak wajib.
6. Aplikasi menampilkan layar konfirmasi dengan:
   - Nama pintu.
   - Posisi saat ini.
   - Target.
   - Rekomendasi AI.
   - Dampak/perubahan persentase.
7. Pengguna mengonfirmasi.
8. Sistem mengirim satu perintah dengan idempotency/reference ID.
9. UI masuk ke state “Mengirim/Menunggu perangkat” dan mencegah pengiriman ganda.
10. Sistem menampilkan hasil:

- Berhasil dan posisi akhir.
- Gagal beserta sebab.
- Timeout/status belum diketahui dengan instruksi verifikasi.

11. Catatan masuk ke Riwayat.

### Flow 5 — Memodifikasi target rekomendasi AI

1. Dari keputusan “Ubah target” pada Flow 3, pengguna memilih preset atau memasukkan persentase target manual.
2. Sistem selalu menampilkan perbandingan target petugas dengan target AI.
3. Jika perbedaannya tidak signifikan, alasan tambahan tidak diwajibkan.
4. Jika target melewati ambang penyimpangan signifikan, pengguna wajib memilih alasan terstruktur dan dapat menambahkan catatan.
5. Setelah target dan alasan yang diwajibkan valid, pengguna masuk ke konfirmasi.
6. Konfirmasi, pengiriman, eksekusi, dan hasil mengikuti tahap yang sama pada Flow 4.
7. Riwayat menyimpan target AI, target petugas, alasan bila diwajibkan, identitas Petugas Lapang, dan hasil.

Catatan: nilai ambang “penyimpangan signifikan” ditetapkan oleh aturan sistem/server dan dikirim sebagai metadata; UX tidak mengunci angka bisnis yang belum disepakati.

### Flow 5A — Tidak menerapkan rekomendasi AI

1. Dari detail rekomendasi, pengguna memilih “Tidak terapkan”.
2. Sistem menampilkan konfirmasi ringan bahwa pilihan ini tidak akan mengubah posisi pintu dan tidak akan mengirim perintah.
3. Pengguna mengonfirmasi keputusan.
4. Status rekomendasi diperbarui menjadi “Tidak diterapkan”.
5. Alur berhenti pada modul Rekomendasi; modul Kendali tidak dibuka dan tidak ada perintah yang dibuat.
6. Keputusan tersimpan pada riwayat rekomendasi dengan identitas Petugas Lapang dan waktu keputusan.
7. Alasan untuk tidak menerapkan tidak diwajibkan pada blueprint ini, kecuali SOP kemudian menetapkannya.

### Flow 6 — AI tidak tersedia/kedaluwarsa

1. Detail pintu menampilkan peringatan jelas bahwa AI tidak tersedia atau rekomendasi sudah kedaluwarsa.
2. Data sensor dan status pintu tetap ditampilkan dengan freshness masing-masing.
3. Kendali manual tetap aktif hanya jika prasyarat koneksi/perangkat/data posisi terpenuhi.
4. Pengguna wajib mengakui peringatan dan memberikan alasan keputusan manual sebelum konfirmasi.
5. Riwayat menandai bahwa perintah dibuat tanpa rekomendasi AI valid.

### Flow 7 — Kondisi offline/read-only

1. Aplikasi mendeteksi koneksi aplikasi, node, atau pintu tidak memenuhi syarat.
2. Snapshot terakhir tetap dapat dibaca beserta waktu pembaruannya.
3. Kontrol dinonaktifkan dengan alasan spesifik.
4. Tidak ada perintah yang disimpan sebagai antrean.
5. Saat koneksi kembali, data/status harus disegarkan sebelum kontrol diaktifkan kembali.

### Flow 8 — Peringatan kritis

1. Peringatan muncul pada banner/dashboard, pusat notifikasi, dan push bila kanal tersedia.
2. Pengguna membuka detail.
3. Detail menjelaskan sumber, tingkat, waktu, node/pintu terkait, data pendukung, dan tindakan yang disarankan.
4. Pengguna menandai peringatan sudah dibaca/diakui.
5. Acknowledgement disimpan dengan identitas dan waktu.
6. Acknowledgement tidak otomatis menutup masalah dan tidak mengeksekusi kontrol.

### Flow 9 — Menelusuri riwayat

1. Pengguna membuka Riwayat.
2. Pengguna memfilter jenis:
   - Monitoring.
   - Rekomendasi.
   - Kendali.
3. Filter tambahan: node/pintu, status/tingkat, rentang tanggal.
4. Pengguna membuka detail untuk audit dan korelasi.
5. Dari detail kendali, pengguna dapat melihat rekomendasi dan snapshot sensor yang menjadi konteks keputusan.

## 8. State dan Aturan Interaksi

### Status konektivitas

- Online.
- Offline.
- Gangguan.
- Menghubungkan/memuat ulang.
- Status tidak diketahui.

### Freshness data

- Terkini.
- Terlambat.
- Kedaluwarsa.
- Belum ada data.

Ambang waktunya berasal dari konfigurasi/server dan tidak dihardcode sebagai keputusan UX.

### Tingkat kewaspadaan

- Normal.
- Waspada.
- Siaga/kritis.
- Tidak diketahui.

Terminologi final harus diselaraskan dengan SOP PUPR sebelum desain visual final.

### Status perintah

- Draft/belum dikirim.
- Mengirim.
- Diterima server.
- Diterima perangkat.
- Sedang bergerak.
- Berhasil/mencapai target.
- Gagal.
- Timeout.
- Dibatalkan bila backend mendukung pembatalan sebelum eksekusi.
- Status tidak diketahui.

### Status keputusan rekomendasi

- Belum diputuskan.
- Diterapkan sesuai rekomendasi.
- Dimodifikasi oleh Petugas Lapang.
- Tidak diterapkan.
- Kedaluwarsa sebelum diputuskan.

Status keputusan rekomendasi berbeda dari status perintah. “Diterapkan” atau “Dimodifikasi” menunjukkan pilihan petugas untuk melanjutkan ke flow Kendali, bukan bukti bahwa perintah sudah dikirim atau berhasil dieksekusi.

### Hak akses Petugas Lapang

- Setiap Petugas Lapang dengan akun valid dan sesi aktif dapat mengakses seluruh fungsi operasional aplikasi mobile.
- Semua Petugas Lapang memiliki hak yang sama untuk melakukan kendali pintu.
- Identitas petugas tetap dicatat untuk audit, tetapi tidak digunakan untuk membatasi pintu tertentu atau tindakan kendali tertentu.
- Autentikasi, validasi state perangkat, dan konfirmasi sebelum eksekusi tetap wajib.

### Aturan enable/disable kendali

Kontrol hanya aktif bila:

- Pengguna memiliki sesi valid.
- Aplikasi online.
- Pintu yang dipilih online dan dapat dikendalikan.
- Posisi pintu tersedia serta belum kedaluwarsa.
- Tidak ada perintah aktif yang konflik untuk pintu yang sama.
- Target valid 0–100 dan berbeda secara bermakna dari posisi/target aktif.
- Pengguna telah memenuhi acknowledgement/alasan yang diwajibkan.

### Pencegahan kesalahan

- Jangan mengandalkan slider saja; selalu sediakan angka eksplisit.
- Jangan mengirim saat memilih preset.
- Konfirmasi terakhir menampilkan nama pintu secara menonjol.
- Setelah submit, nonaktifkan submit ulang sampai status pertama diterima.
- Timeout tidak boleh langsung dianggap gagal aman; tampilkan status “belum diketahui” dan minta verifikasi ulang.
- Refresh posisi/status setelah hasil eksekusi.

## 9. Kebutuhan Informasi dan Kontrak Data untuk Tahap Berikutnya

Blueprint mengasumsikan backend kelak menyediakan bentuk data konseptual berikut:

- **User:** id, nama, peran, status sesi.
- **Node:** id, nama, lokasi, status koneksi, waktu pembaruan, kesehatan perangkat.
- **Sensor reading:** node, tipe metrik, nilai, satuan, timestamp, status kualitas/freshness, tingkat kondisi.
- **Gate:** id, nama, lokasi, posisi aktual, target aktif, status koneksi, status gerak/kesehatan, timestamp.
- **AI recommendation:** id, gate id, target persen, tingkat kewaspadaan, alasan ringkas, faktor/data pendukung, dibuat pada, berlaku sampai, versi/model bila diperlukan audit, status keputusan petugas, petugas yang memutuskan, dan waktu keputusan.
- **Control command:** id/reference ID, gate id, user id, posisi awal, target, recommendation id opsional, alasan penyimpangan, status, timeline, posisi akhir, pesan perangkat.
- **Alert:** id, tipe, tingkat, node/gate terkait, timestamp, status aktif/selesai, acknowledgement user dan waktu.
- **History event:** tipe, objek terkait, actor, timestamp, payload ringkas, reference ID.

Aturan backend yang harus dapat dikonfigurasi:

- Ambang status sensor dan kewaspadaan.
- Ambang data terlambat/kedaluwarsa.
- Ambang penyimpangan signifikan dari rekomendasi AI.
- Preset bukaan pintu.
- Batas perubahan target bila ada SOP keselamatan.
- Timeout perintah.

## 10. Prioritas Rancangan

### Prioritas 1 — Alur keselamatan operasional

- Beranda ringkas.
- Monitoring dua node.
- Rekomendasi per pintu.
- Detail pintu dan kontrol.
- Konfirmasi, progres, hasil, dan failure states.
- Offline/read-only.

### Prioritas 2 — Audit dan respons

- Pusat notifikasi.
- Acknowledgement peringatan kritis.
- Riwayat terpadu dan detail audit.

### Prioritas 3 — Pendukung akun

- Login/session expiry.
- Profil, pengaturan dasar, dan logout.

## 11. Deliverable Tahap Blueprint

Tahap desain berikutnya harus menghasilkan:

1. Sitemap/navigasi aplikasi.
2. Diagram seluruh user flow dan cabang keputusan di atas.
3. Matriks layar × state untuk normal, loading, empty, offline, stale, partial error, dan failed command.
4. Low-fidelity wireframe layar prioritas:
   - Login.
   - Beranda.
   - Monitoring ringkas dan detail node.
   - Daftar dan detail rekomendasi.
   - Daftar dan detail pintu.
   - Pengaturan target.
   - Alasan penyimpangan.
   - Konfirmasi.
   - Progres dan hasil perintah.
   - Notifikasi kritis.
   - Riwayat dan detail kendali.
5. Kamus istilah dan status operasional.
6. Daftar asumsi yang perlu divalidasi dengan pemilik SOP/teknis.

## 12. Validasi dan Kriteria Penerimaan

Blueprint dianggap siap masuk ke desain visual/prototype bila:

- Seluruh fitur brief memiliki lokasi yang jelas pada arsitektur informasi.
- Detail rekomendasi menyediakan tiga keputusan yang eksplisit: terapkan, modifikasi, atau tidak terapkan.
- Tidak satu pun keputusan rekomendasi langsung mengeksekusi kendali; target, konfirmasi, eksekusi, dan hasil tetap menjadi tahap terpisah.
- Keputusan “Tidak terapkan” berhenti tanpa membuat perintah kendali.
- Modifikasi signifikan mewajibkan alasan, sedangkan ambangnya tetap berasal dari aturan sistem.
- Semua Petugas Lapang dengan akun valid memiliki akses operasional yang sama; identitas hanya digunakan untuk sesi dan audit, bukan pembatasan kendali.
- Struktur daftar/detail pintu tetap berfungsi tanpa mengunci jumlah pintu prototipe atau jumlah perangkat fisik.
- Pengguna dapat berpindah dari peringatan atau rekomendasi ke pintu yang benar tanpa memilih ulang objek secara ambigu.
- Tidak ada jalur yang mengeksekusi kontrol tanpa konfirmasi.
- Offline, AI tidak tersedia, data kedaluwarsa, perangkat gangguan, timeout, dan hasil gagal memiliki alur yang eksplisit.
- AI selalu diposisikan sebagai rekomendasi, bukan keputusan otomatis.
- Setiap angka sensor memiliki satuan dan timestamp.
- Setiap perintah dapat diaudit dari keputusan sampai hasil.
- Penyimpangan dari rekomendasi dan tindakan tanpa AI valid mencatat alasan.
- Peringatan kritis dapat diakui tanpa dianggap menyelesaikan kondisi.
- Grafik bukan satu-satunya media penyampaian nilai/status.
- Uji walkthrough dengan skenario berikut dapat diselesaikan tanpa pertanyaan navigasi:
  1. Melihat kondisi dua node.
  2. Menjalankan rekomendasi pada pintu tertentu.
  3. Memilih target berbeda dan mencatat alasan.
  4. Memilih tidak menerapkan rekomendasi tanpa membuat perintah.
  5. Mengendalikan saat AI tidak tersedia tetapi perangkat online.
  6. Gagal mengendalikan saat offline.
  7. Menangani timeout perintah.
  8. Mengakui peringatan kritis.
  9. Menelusuri bukti keputusan dari riwayat.

## 13. Validasi dengan Stakeholder Sebelum Visual Final

Hal berikut tidak menghalangi blueprint, tetapi wajib dikonfirmasi dengan pemilik proses/SOP sebelum prototype high-fidelity:

- Istilah resmi tingkat kewaspadaan PUPR.
- Satuan dan format angka resmi untuk curah hujan serta tinggi muka air.
- Ambang normal/warning/kritis dan freshness.
- Preset serta batas perubahan bukaan.
- Definisi “penyimpangan signifikan” dari rekomendasi.
- Kondisi perangkat yang wajib memblokir kendali.
- Mekanisme backend/perangkat dalam melaporkan accepted, moving, reached target, failed, dan timeout.
- Apakah satu perintah aktif per pintu menjadi aturan mutlak.
- Kanal notifikasi yang tersedia.
- Kebutuhan ekspor atau retensi riwayat.

## 14. Di Luar Cakupan Tahap Ini

- Desain visual final, design tokens, ilustrasi, atau pemilihan gaya grafis.
- Implementasi React/Tailwind.
- Backend, autentikasi nyata, database, push notification, dan API.
- Integrasi sensor, aktuator pintu, protokol IoT, atau komunikasi real-time.
- Pelatihan dan evaluasi model AI.
- Penetapan ambang operasional yang merupakan kewenangan domain/SOP.
- Dashboard admin/web untuk pengelolaan pengguna, perangkat, threshold, atau konfigurasi.
