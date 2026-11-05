import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Animasi Denyut Cahaya Ambience
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF06101E), // Deep Executive Navy
      body: Stack(
        children: [
          // 1. Bola Cahaya Ambience Latar Belakang (PUPR Gold & Azure)
          Positioned(
            top: -60,
            left: -60,
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: _buildGlowBlob(const Color(0xFFF59E0B), 300, alpha: 0.28),
            ),
          ),
          Positioned(
            top: 350,
            right: -80,
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: _buildGlowBlob(const Color(0xFF0284C7), 350, alpha: 0.24),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -40,
            child: _buildGlowBlob(const Color(0xFF0D9488), 260, alpha: 0.20),
          ),

          // 2. Efek Kaca Buram Menyeluruh
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: const SizedBox(),
            ),
          ),

          // 3. Grid Cetak Biru Garis Rekayasa Teknis PUPR
          Positioned.fill(
            child: CustomPaint(
              painter: _BlueprintGridPainter(),
            ),
          ),

          // 4. Konten Utama Halaman (Scrollable)
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header Bar Atas
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 14.0,
                    ),
                    child: _buildTopHeaderBar(),
                  ),
                ),

                // Hero Banner Dinas PUPR Subang
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ),
                    child: _buildHeroBanner(),
                  ),
                ),

                // Metrik Statistik Real-Time IoT Subang
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 12.0,
                    ),
                    child: _buildQuickMetrics(),
                  ),
                ),

                // Judul Sektor Pelayanan & Monitoring
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
                    child: Text(
                      'Monitoring Bidang Sumber Daya Air',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),

                // Kartu Sektor Pemantauan IoT
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: _buildSectorCards(),
                  ),
                ),

                // Informasi Profil & Kontak Kantor Dinas PUPR
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: _buildOfficeInfoCard(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header Bar Atas
  Widget _buildTopHeaderBar() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.85),
              width: 1.8,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset(
              'assets/images/logo_pupr.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DINAS PUPR SUBANG',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Telemetri SDA Subang',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Hero Banner Utama
  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F2648).withValues(alpha: 0.85),
            const Color(0xFF0B192C).withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag Pemkab Subang
          Row(
            children: [
              const Icon(
                Icons.account_balance_rounded,
                size: 15,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 8),
              Text(
                'PEMERINTAH KABUPATEN SUBANG',
                style: TextStyle(
                  color: const Color(0xFFF59E0B),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Text(
            'Monitoring SDA\nInfrastruktur Air Subang',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          Text(
            'Sistem telemetri cerdas Bidang Sumber Daya Air (SDA) Dinas PUPR Kab. Subang untuk pemantauan bendung irigasi, tinggi level air (TMA), dan data curah hujan secara waktu nyata (real-time).',
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),

          // Slogan & Tombol Aksi Cepat Petugas
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF081426),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: Color(0xFF38BDF8),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Subang Jawara',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _navigateToLogin,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Portal Petugas',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Metrik Cepat IoT SDA Subang
  Widget _buildQuickMetrics() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMetricItem(
            '14 Pos',
            'Bendung & Pintu',
            Icons.flood_rounded,
            const Color(0xFF0284C7),
          ),
          const SizedBox(width: 10),
          _buildMetricItem(
            '28 Titik',
            'Level Air (TMA)',
            Icons.height_rounded,
            const Color(0xFF38BDF8),
          ),
          const SizedBox(width: 10),
          _buildMetricItem(
            '12 Pos',
            'Curah Hujan (ARR)',
            Icons.grain_rounded,
            const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String val, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1E36).withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              val,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                color: Colors.white.withValues(alpha: 0.65),
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Daftar Kartu Sektor Pemantauan IoT Bidang SDA PUPR
  Widget _buildSectorCards() {
    return Column(
      children: [
        _buildSectorTile(
          icon: Icons.flood_rounded,
          iconColor: const Color(0xFF0284C7),
          title: 'Monitoring Bendung & Pintu Air',
          desc: 'Telemetri elevasi mercu, bukaan pintu air otomatis, dan pemantauan debit aliran air irigasi pertanian di wilayah Subang.',
          tag: '14 Pos Bendung',
        ),
        const SizedBox(height: 10),
        _buildSectorTile(
          icon: Icons.height_rounded,
          iconColor: const Color(0xFF38BDF8),
          title: 'Tinggi Level Air (TMA / AWLR)',
          desc: 'Pengukuran otomatis tinggi muka air sungai & saluran pembuang secara real-time untuk deteksi dini risiko banjir dan ketersediaan air.',
          tag: '28 Sensor TMA',
        ),
        const SizedBox(height: 10),
        _buildSectorTile(
          icon: Icons.grain_rounded,
          iconColor: const Color(0xFFF59E0B),
          title: 'Data Curah Hujan (ARR Telemetri)',
          desc: 'Perekaman data intensitas curah hujan otomatis per jam dan kumulatif harian dari pos stasiun hidrologi penakar hujan Subang.',
          tag: '12 Pos Hujan',
        ),
      ],
    );
  }

  Widget _buildSectorTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required String tag,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1D35).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.4),
              ),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.65),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Kartu Informasi Profil & Kontak Kantor Dinas PUPR
  Widget _buildOfficeInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF091629).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kantor Dinas PUPR Subang',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Pusat Komando & Informasi Resmi',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFF59E0B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Alamat
          _buildInfoRow(
            icon: Icons.location_on_rounded,
            title: 'Alamat Kantor',
            value: 'Jl. K.S. Tubun No. 16, Karanganyar, Kec. Subang, Kabupaten Subang, Jawa Barat 41211',
          ),
          const Divider(color: Colors.white12, height: 20),

          // Telepon
          _buildInfoRow(
            icon: Icons.phone_in_talk_rounded,
            title: 'Telepon / Pelayanan',
            value: '(0260) 411043 / (0260) 411045',
          ),
          const Divider(color: Colors.white12, height: 20),

          // Email
          _buildInfoRow(
            icon: Icons.email_rounded,
            title: 'Email Resmi Kedinasan',
            value: 'dpupr@subang.go.id • pupr.subangkab.go.id',
          ),
          const Divider(color: Colors.white12, height: 20),

          // Jam Operasional
          _buildInfoRow(
            icon: Icons.access_time_filled_rounded,
            title: 'Jam Operasional Kantor',
            value: 'Senin – Jumat : 08:00 – 16:00 WIB (Monitoring IoT 24/7)',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: const Color(0xFFF59E0B)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Bola Cahaya Latar
  Widget _buildGlowBlob(Color color, double size, {double alpha = 0.3}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: alpha),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: alpha),
            blurRadius: 100,
            spreadRadius: 40,
          ),
        ],
      ),
    );
  }
}

// Background Painter: Blueprint Grid Teknis PUPR
class _BlueprintGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 1.0;

    const double step = 38.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
