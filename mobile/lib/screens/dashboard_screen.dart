import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'splash_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Filter kategori sensor SDA
  int _selectedFilterIndex = 0; // 0: Semua, 1: Bendung, 2: TMA, 3: Curah Hujan
  int _activeNavIndex = 0; // 0: Beranda, 1: Analitik, 2: Pengaturan

  // State status pintu air dan telemetri bendung (bisa di-toggle interaktif)
  bool isBendungSukamelangOpen = true;
  bool isBendungGadungOpen = false;
  bool isSensorCiasemActive = true;
  bool isSensorCipunagaraActive = true;
  bool isArrPagadenActive = true;
  bool isArrKasomalangActive = true;

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Selamat Pagi,';
    } else if (hour < 15) {
      return 'Selamat Siang,';
    } else if (hour < 18) {
      return 'Selamat Sore,';
    } else {
      return 'Selamat Malam,';
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: const Color(0xFF0B192C),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFF59E0B),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Konfirmasi Keluar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Apakah Anda yakin ingin keluar dari sesi monitoring Petugas SDA Subang?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SplashScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Keluar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
          // 1. Bola Cahaya Latar Ambience (PUPR Gold & Azure)
          Positioned(
            top: -60,
            left: -60,
            child: _buildGlowBlob(const Color(0xFFF59E0B), 280, alpha: 0.28),
          ),
          Positioned(
            top: 260,
            right: -80,
            child: _buildGlowBlob(const Color(0xFF0284C7), 320, alpha: 0.25),
          ),
          Positioned(
            bottom: -50,
            left: 20,
            child: _buildGlowBlob(const Color(0xFF0D9488), 260, alpha: 0.20),
          ),

          // 2. Kaca Buram Menyeluruh
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 85, sigmaY: 85),
              child: const SizedBox(),
            ),
          ),

          // 3. Ornamen Blueprint Grid Teknis PUPR
          Positioned.fill(
            child: CustomPaint(
              painter: _TechBlueprintGridPainter(),
            ),
          ),

          // 4. Konten Utama Dashboard
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header Profil Petugas SDA & Logo Resmi PUPR
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                    child: _buildTopHeader(),
                  ),
                ),

                // Kartu Ringkasan Cuaca & Hidrologi Subang
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: _buildHydrologySummaryCard(),
                  ),
                ),

                // Filter Kategori Sensor SDA (Semua, Bendung, TMA, ARR)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: _buildFilterChips(),
                  ),
                ),

                // Label Judul Grid Sensor
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Node Telemetri Aktif',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
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
                              'Live Data 24/7',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Grid Kartu Sensor IoT Bidang SDA
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: _buildSensorGrid(),
                ),

                // Ruang ekstra bawah agar tidak tertutup bottom bar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 110),
                ),
              ],
            ),
          ),

          // 5. Bottom Navigation Bar Bergaya Glassmorphism
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  // Header Dashboard: Logo PUPR + Info Petugas SDA + Tombol Logout
  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Logo Resmi PUPR
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
                  width: 1.6,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo_pupr.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'Petugas SDA Subang',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Tombol Aksi Keluar / Logout
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showLogoutDialog,
            borderRadius: BorderRadius.circular(25),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0F2544).withValues(alpha: 0.75),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Kartu Ringkasan Cuaca & Hidrologi Subang
  Widget _buildHydrologySummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2648).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Atas: Wilayah & Status Aman
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF38BDF8),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Wilayah Sungai Subang',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 11,
                      color: Color(0xFF34D399),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'STATUS NORMAL',
                      style: TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Baris Tengah: Suhu & Ikon Cuaca
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cuaca DAS Subang',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        '28°C',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Hujan Ringan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF081C38)],
                  ),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.cloudy_snowing,
                  color: Color(0xFF38BDF8),
                  size: 34,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Baris Bawah: Parameter Hidrologi Rata-rata
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF081426),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryParam(
                  icon: Icons.height_rounded,
                  label: 'TMA Rata-rata',
                  value: '142 cm',
                  color: const Color(0xFF38BDF8),
                ),
                Container(width: 1, height: 26, color: Colors.white12),
                _buildSummaryParam(
                  icon: Icons.flood_rounded,
                  label: 'Debit Irigasi',
                  value: '5.2 m³/s',
                  color: const Color(0xFF0284C7),
                ),
                Container(width: 1, height: 26, color: Colors.white12),
                _buildSummaryParam(
                  icon: Icons.grain_rounded,
                  label: 'Curah Hujan',
                  value: '8.4 mm',
                  color: const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryParam({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Filter Kategori (Semua, Bendung, TMA, Curah Hujan)
  Widget _buildFilterChips() {
    final filters = [
      {'title': 'Semua Node', 'icon': Icons.hub_rounded},
      {'title': 'Bendung Irigasi', 'icon': Icons.flood_rounded},
      {'title': 'Level Air (TMA)', 'icon': Icons.height_rounded},
      {'title': 'Curah Hujan (ARR)', 'icon': Icons.grain_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              avatar: Icon(
                filters[index]['icon'] as IconData,
                size: 14,
                color: isSelected ? const Color(0xFF071224) : Colors.white70,
              ),
              label: Text(filters[index]['title'] as String),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedFilterIndex = index);
              },
              selectedColor: const Color(0xFFF59E0B),
              backgroundColor: const Color(0xFF0D1F38),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF071224) : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFFF59E0B)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              showCheckmark: false,
            ),
          );
        }),
      ),
    );
  }

  // Grid Kartu Sensor IoT SDA Subang
  Widget _buildSensorGrid() {
    // Daftar semua sensor yang sesuai bidang SDA
    final List<Widget> cards = [];

    // 1. Bendung Sukamelang (Bendung & Pintu Air)
    if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1) {
      cards.add(
        _buildSdaDeviceCard(
          category: 'BENDUNG & PINTU AIR',
          title: 'Bendung Sukamelang',
          location: 'Kec. Subang Kota',
          metricLabel: 'Debit Aliran',
          metricValue: isBendungSukamelangOpen ? '5.4 m³/s' : '0.0 m³/s',
          statusText: isBendungSukamelangOpen ? 'PINTU TERBUKA' : 'PINTU TERTUTUP',
          icon: Icons.flood_rounded,
          isOn: isBendungSukamelangOpen,
          onToggle: (val) => setState(() => isBendungSukamelangOpen = val),
          accentColor: const Color(0xFF0284C7),
          badgeText: 'Elv: 3.8m',
        ),
      );
    }

    // 2. Sensor TMA Sungai Ciasem (Level Air)
    if (_selectedFilterIndex == 0 || _selectedFilterIndex == 2) {
      cards.add(
        _buildSdaDeviceCard(
          category: 'LEVEL AIR (TMA)',
          title: 'TMA Sungai Ciasem',
          location: 'Pos Pantau Ciasem',
          metricLabel: 'Tinggi Air',
          metricValue: isSensorCiasemActive ? '142 cm' : 'Sensor Off',
          statusText: isSensorCiasemActive ? 'SIAGA AMAN' : 'NONAKTIF',
          icon: Icons.height_rounded,
          isOn: isSensorCiasemActive,
          onToggle: (val) => setState(() => isSensorCiasemActive = val),
          accentColor: const Color(0xFF38BDF8),
          badgeText: '< 180cm',
        ),
      );
    }

    // 3. Pos Hujan ARR Pagaden (Curah Hujan)
    if (_selectedFilterIndex == 0 || _selectedFilterIndex == 3) {
      cards.add(
        _buildSdaDeviceCard(
          category: 'CURAH HUJAN (ARR)',
          title: 'Pos Hujan Pagaden',
          location: 'Stasiun Hidrologi',
          metricLabel: 'Intensitas',
          metricValue: isArrPagadenActive ? '18.4 mm/j' : '0.0 mm',
          statusText: isArrPagadenActive ? 'HUJAN SEDANG' : 'NONAKTIF',
          icon: Icons.grain_rounded,
          isOn: isArrPagadenActive,
          onToggle: (val) => setState(() => isArrPagadenActive = val),
          accentColor: const Color(0xFFF59E0B),
          badgeText: '32mm/hari',
        ),
      );
    }

    // 4. Bendung Gadung Subang (Bendung & Pintu Air 2)
    if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1) {
      cards.add(
        _buildSdaDeviceCard(
          category: 'BENDUNG & PINTU AIR',
          title: 'Bendung Gadung',
          location: 'Irigasi Sekunder',
          metricLabel: 'Debit Aliran',
          metricValue: isBendungGadungOpen ? '3.1 m³/s' : '0.0 m³/s',
          statusText: isBendungGadungOpen ? 'PINTU TERBUKA' : 'PINTU TERTUTUP',
          icon: Icons.water_damage_rounded,
          isOn: isBendungGadungOpen,
          onToggle: (val) => setState(() => isBendungGadungOpen = val),
          accentColor: const Color(0xFF0284C7),
          badgeText: 'Elv: 2.4m',
        ),
      );
    }

    // 5. Sensor TMA Sungai Cipunagara (Level Air 2)
    if (_selectedFilterIndex == 0 || _selectedFilterIndex == 2) {
      cards.add(
        _buildSdaDeviceCard(
          category: 'LEVEL AIR (TMA)',
          title: 'TMA Cipunagara',
          location: 'Jembatan Pamanukan',
          metricLabel: 'Tinggi Air',
          metricValue: isSensorCipunagaraActive ? '215 cm' : 'Sensor Off',
          statusText: isSensorCipunagaraActive ? 'STATUS WASPADA' : 'NONAKTIF',
          icon: Icons.water_rounded,
          isOn: isSensorCipunagaraActive,
          onToggle: (val) => setState(() => isSensorCipunagaraActive = val),
          accentColor: const Color(0xFFEAB308),
          badgeText: '> 200cm',
        ),
      );
    }

    // 6. Pos Hujan ARR Kasomalang (Curah Hujan 2)
    if (_selectedFilterIndex == 0 || _selectedFilterIndex == 3) {
      cards.add(
        _buildSdaDeviceCard(
          category: 'CURAH HUJAN (ARR)',
          title: 'Pos Kasomalang',
          location: 'Hulu Subang Selatan',
          metricLabel: 'Intensitas',
          metricValue: isArrKasomalangActive ? '0.0 mm/j' : '0.0 mm',
          statusText: isArrKasomalangActive ? 'CERAH BERAWAN' : 'NONAKTIF',
          icon: Icons.wb_sunny_rounded,
          isOn: isArrKasomalangActive,
          onToggle: (val) => setState(() => isArrKasomalangActive = val),
          accentColor: const Color(0xFF10B981),
          badgeText: '4mm/hari',
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.74,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => cards[index],
        childCount: cards.length,
      ),
    );
  }

  // Kartu Perangkat Sensor SDA Modern (Glassmorphism & High Contrast)
  Widget _buildSdaDeviceCard({
    required String category,
    required String title,
    required String location,
    required String metricLabel,
    required String metricValue,
    required String statusText,
    required IconData icon,
    required bool isOn,
    required ValueChanged<bool> onToggle,
    required Color accentColor,
    required String badgeText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E38).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isOn
              ? accentColor.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.08),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: isOn
                ? accentColor.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Baris Atas: Ikon + Switch Kendali
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isOn
                      ? accentColor.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isOn
                        ? accentColor.withValues(alpha: 0.6)
                        : Colors.white12,
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isOn ? accentColor : Colors.white38,
                  size: 22,
                ),
              ),
              Switch(
                value: isOn,
                onChanged: onToggle,
                activeThumbColor: accentColor,
                activeTrackColor: accentColor.withValues(alpha: 0.3),
                inactiveThumbColor: Colors.white38,
                inactiveTrackColor: Colors.white12,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),

          // Baris Tengah: Info Lokasi & Kategori
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: isOn ? accentColor : Colors.white38,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),

          // Baris Bawah: Nilai Metrik & Status Telemetri
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF06101E).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        metricLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        badgeText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: isOn ? accentColor : Colors.white38,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  metricValue,
                  style: TextStyle(
                    color: isOn ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: TextStyle(
                    color: isOn ? const Color(0xFF34D399) : Colors.white24,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bottom Navigation Bar
  Widget _buildBottomNav() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0C1F38).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.dashboard_rounded, 'Monitoring'),
              _buildNavItem(1, Icons.water_drop_rounded, 'Bendung'),
              _buildNavItem(2, Icons.analytics_rounded, 'Hidrologi'),
              _buildNavItem(3, Icons.person_rounded, 'Petugas'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _activeNavIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _activeNavIndex = index);
        if (index == 3) {
          _showLogoutDialog();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFF59E0B)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF071224) : Colors.white60,
              size: 20,
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF071224),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Bola Cahaya Latar Ambience
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
class _TechBlueprintGridPainter extends CustomPainter {
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
