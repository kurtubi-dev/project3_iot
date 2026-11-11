import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
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

  // Kunci penyimpanan persisten SharedPreferences (tersimpan permanen di perangkat)
  static const String _keyBendungSukamelang = 'sda_bendung_sukamelang_open';
  static const String _keyBendungGadung = 'sda_bendung_gadung_open';
  static const String _keySensorCiasem = 'sda_sensor_ciasem_active';
  static const String _keySensorCipunagara = 'sda_sensor_cipunagara_active';
  static const String _keyArrPagaden = 'sda_arr_pagaden_active';
  static const String _keyArrKasomalang = 'sda_arr_kasomalang_active';

  // State status pintu air dan telemetri bendung
  bool isBendungSukamelangOpen = true;
  bool isBendungGadungOpen = false;
  bool isSensorCiasemActive = true;
  bool isSensorCipunagaraActive = true;
  bool isArrPagadenActive = true;
  bool isArrKasomalangActive = true;

  // Data profil petugas yang sedang login
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadDeviceStates();
    _loadUserProfile();
  }

  /// Memuat profil petugas yang tersimpan dari sesi login
  Future<void> _loadUserProfile() async {
    try {
      final user = await ApiService.getSavedUser();
      if (user != null && mounted) {
        setState(() => _currentUser = user);
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  /// Memuat status terakhir setiap sensor dan pintu air yang telah diatur oleh petugas
  Future<void> _loadDeviceStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        isBendungSukamelangOpen = prefs.getBool(_keyBendungSukamelang) ?? true;
        isBendungGadungOpen = prefs.getBool(_keyBendungGadung) ?? false;
        isSensorCiasemActive = prefs.getBool(_keySensorCiasem) ?? true;
        isSensorCipunagaraActive = prefs.getBool(_keySensorCipunagara) ?? true;
        isArrPagadenActive = prefs.getBool(_keyArrPagaden) ?? true;
        isArrKasomalangActive = prefs.getBool(_keyArrKasomalang) ?? true;
      });
    } catch (e) {
      debugPrint('Error loading saved device states: $e');
    }
  }

  /// Menyimpan status secara permanen agar tidak berubah sendiri saat keluar aplikasi
  Future<void> _setDeviceState(
    String key,
    bool val,
    VoidCallback updateLocal,
    String deviceName,
  ) async {
    HapticFeedback.lightImpact();
    setState(updateLocal);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, val);
    } catch (e) {
      debugPrint('Error saving device state ($key): $e');
    }

    // Sinkronisasi kendali pintu air bendung ke Database Laravel
    if (key == _keyBendungSukamelang) {
      ApiService.syncGateStatus(1, val);
    } else if (key == _keyBendungGadung) {
      ApiService.syncGateStatus(4, val);
    }

    if (!mounted) return;
    _showStatusPopup(deviceName: deviceName, isActive: val);
  }

  /// Pop-up notifikasi futuristik bergaya Smart IoT HUD & Glassmorphism (Proporsional Layar HP)
  void _showStatusPopup({
    required String deviceName,
    required bool isActive,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 76),
        padding: EdgeInsets.zero,
        duration: const Duration(milliseconds: 2800),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isActive
                      ? [
                          const Color(0xFF063328).withValues(alpha: 0.95),
                          const Color(0xFF0C1F38).withValues(alpha: 0.95),
                        ]
                      : [
                          const Color(0xFF380E14).withValues(alpha: 0.95),
                          const Color(0xFF0C1F38).withValues(alpha: 0.95),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF10B981).withValues(alpha: 0.75)
                      : const Color(0xFFEF4444).withValues(alpha: 0.75),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isActive
                        ? const Color(0xFF10B981).withValues(alpha: 0.3)
                        : const Color(0xFFEF4444).withValues(alpha: 0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Ikon Status Melingkar
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isActive
                            ? [
                                const Color(0xFF10B981).withValues(alpha: 0.4),
                                const Color(0xFF064E3B).withValues(alpha: 0.15),
                              ]
                            : [
                                const Color(0xFFEF4444).withValues(alpha: 0.4),
                                const Color(0xFF7F1D1D).withValues(alpha: 0.15),
                              ],
                      ),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF34D399)
                            : const Color(0xFFF87171),
                        width: 1.3,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isActive
                            ? Icons.sensors_rounded
                            : Icons.power_settings_new_rounded,
                        color: isActive
                            ? const Color(0xFF34D399)
                            : const Color(0xFFF87171),
                        size: 19,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Keterangan & Judul Perangkat
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                deviceName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF10B981).withValues(alpha: 0.25)
                                    : const Color(0xFFEF4444).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: isActive
                                      ? const Color(0xFF34D399).withValues(alpha: 0.7)
                                      : const Color(0xFFF87171).withValues(alpha: 0.7),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                isActive ? 'AKTIF' : 'NONAKTIF',
                                style: TextStyle(
                                  color: isActive
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFFF87171),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isActive
                              ? 'Node telemetri diaktifkan • Tersimpan'
                              : 'Node dinonaktifkan • Tersimpan',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Tombol Tutup Cepat
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white60,
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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

          // 4. Konten Utama Sesuai Tab yang Dipilih
          SafeArea(
            bottom: false,
            child: _buildCurrentTabContent(),
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

  /// Menampilkan konten halaman dinamis berdasarkan tab navigasi bawah
  Widget _buildCurrentTabContent() {
    switch (_activeNavIndex) {
      case 0:
        return _buildMonitoringTab();
      case 1:
        return _buildBendungTab();
      case 2:
        return _buildHidrologiTab();
      case 3:
        return _buildPetugasTab();
      default:
        return _buildMonitoringTab();
    }
  }

  /// Tab 0: Monitoring Utama (Semua Node Telemetri SDA - Proporsional HP)
  Widget _buildMonitoringTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header Profil Petugas SDA & Logo Resmi PUPR
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: _buildTopHeader(),
          ),
        ),

        // Kartu Ringkasan Cuaca & Hidrologi Subang
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildHydrologySummaryCard(),
          ),
        ),

        // Filter Kategori Sensor SDA (Semua, Bendung, TMA, ARR)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: _buildFilterChips(),
          ),
        ),

        // Label Judul Grid Sensor
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Node Telemetri Aktif',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${[isBendungSukamelangOpen, isBendungGadungOpen, isSensorCiasemActive, isSensorCipunagaraActive, isArrPagadenActive, isArrKasomalangActive].where((x) => x).length} / 6 Node Aktif',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: _buildSensorGrid(),
        ),

        // Ruang ekstra bawah agar tidak tertutup bottom bar
        const SliverToBoxAdapter(
          child: SizedBox(height: 96),
        ),
      ],
    );
  }

  /// Tab 1: Khusus Pemantauan & Operasional Pintu Air Bendung Subang (Proporsional Layar HP)
  Widget _buildBendungTab() {
    final double totalDebit = (isBendungSukamelangOpen ? 5.4 : 0.0) +
        (isBendungGadungOpen ? 3.1 : 0.0);
    final int openGatesCount =
        (isBendungSukamelangOpen ? 1 : 0) + (isBendungGadungOpen ? 1 : 0);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header Khusus Bendung
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFF0284C7),
                      width: 1.3,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.asset(
                      'assets/images/logo_pupr.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KENDALI BENDUNG & IRIGASI',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Pintu Air SDA Subang',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Kartu Ringkasan Debit Aliran Total
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A2E5C), Color(0xFF071B36)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.5),
                  width: 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.22),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Debit Irigasi Mengalir',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${totalDebit.toStringAsFixed(1)} m³/s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            openGatesCount > 0
                                ? Icons.check_circle_rounded
                                : Icons.info_outline_rounded,
                            size: 12,
                            color: openGatesCount > 0
                                ? const Color(0xFF34D399)
                                : const Color(0xFFF87171),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            openGatesCount > 0
                                ? 'Aliran aktif ke saluran irigasi'
                                : 'Seluruh pintu tertutup rapat',
                            style: TextStyle(
                              color: openGatesCount > 0
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFFF87171),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF0C2444)],
                      ),
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                        width: 1.3,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.flood_rounded,
                        color: Color(0xFF38BDF8),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 14)),

        // Judul Section
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Aktuator Pintu Air Fisik',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 10)),

        // Bendung 1: Sukamelang
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildBendungControlCard(
              code: 'BND-SKM-01',
              name: 'Bendung Sukamelang',
              location: 'Kec. Subang Kota • Pengendali Banjir',
              elevation: '3.8 m',
              discharge: isBendungSukamelangOpen ? '5.4 m³/s' : '0.0 m³/s',
              isOpen: isBendungSukamelangOpen,
              onToggle: (val) => _setDeviceState(
                _keyBendungSukamelang,
                val,
                () => isBendungSukamelangOpen = val,
                'Bendung Sukamelang',
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 10)),

        // Bendung 2: Gadung
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildBendungControlCard(
              code: 'BND-GDG-02',
              name: 'Bendung Gadung',
              location: 'Irigasi Sekunder Binong - Pagaden',
              elevation: '2.4 m',
              discharge: isBendungGadungOpen ? '3.1 m³/s' : '0.0 m³/s',
              isOpen: isBendungGadungOpen,
              onToggle: (val) => _setDeviceState(
                _keyBendungGadung,
                val,
                () => isBendungGadungOpen = val,
                'Bendung Gadung',
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Audit Trail Operasional Pintu Air
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildGateOperationLogs(),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }

  /// Tab 2: Pusat Analisis Hidrologi & Peringatan Dini Banjir (Proporsional Layar HP)
  Widget _buildHidrologiTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header Hidrologi
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFF59E0B),
                      width: 1.3,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.asset(
                      'assets/images/logo_pupr.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EARLY WARNING SYSTEM (EWS)',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Analitika Hidrologi Subang',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Kartu Status TMA Sungai Ciasem
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildTmaRiverCard(
              riverName: 'TMA Sungai Ciasem',
              location: 'Pos Pantau Ciasem Hulu',
              currentLevel: isSensorCiasemActive ? 142.0 : 0.0,
              safeLimit: 180.0,
              warningLimit: 200.0,
              dangerLimit: 250.0,
              isActive: isSensorCiasemActive,
              onToggle: (val) => _setDeviceState(
                _keySensorCiasem,
                val,
                () => isSensorCiasemActive = val,
                'TMA Sungai Ciasem',
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 10)),

        // Kartu Status TMA Sungai Cipunagara
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildTmaRiverCard(
              riverName: 'TMA Sungai Cipunagara',
              location: 'Jembatan Pamanukan (Rawan Luapan)',
              currentLevel: isSensorCipunagaraActive ? 215.0 : 0.0,
              safeLimit: 180.0,
              warningLimit: 200.0,
              dangerLimit: 250.0,
              isActive: isSensorCipunagaraActive,
              onToggle: (val) => _setDeviceState(
                _keySensorCipunagara,
                val,
                () => isSensorCipunagaraActive = val,
                'TMA Cipunagara',
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 14)),

        // Grafik Tren Ketinggian Muka Air 24 Jam
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildTmaHourlyChart(),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 14)),

        // Ringkasan Pos Curah Hujan (ARR)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildArrWeatherCard(),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }

  /// Tab 3: Profil Petugas & Administrasi SDA Dinas PUPR Subang (Proporsional Layar HP)
  Widget _buildPetugasTab() {
    final userName = _currentUser?['name'] ?? 'Petugas Lapangan SDA Subang';
    final userEmail = _currentUser?['email'] ?? 'petugas.sda@subang.go.id';
    final userNip = _currentUser?['nip'] ?? '19890412 201503 1 002';
    final userJabatan = _currentUser?['jabatan'] ?? 'Operator Telemetri & Pintu Air';
    final userRole = (_currentUser?['role'] ?? 'petugas').toString().toUpperCase();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header Halaman Petugas
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DINAS PUPR KABUPATEN SUBANG',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'Identitas Petugas SDA',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _showLogoutDialog,
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                  tooltip: 'Keluar Akun',
                ),
              ],
            ),
          ),
        ),

        // Digital ID Card Petugas SDA Subang (PUPR Signature Executive Badge)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0E2342), Color(0xFF081426)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                  width: 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris Atas ID Card: Logo PUPR + Status Operasional
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              'assets/images/logo_pupr.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DINAS PUPR SUBANG',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              Text(
                                'Bidang Sumber Daya Air',
                                style: TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                        ),
                        child: Text(
                          userRole,
                          style: const TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Avatar & Data Pokok
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          ),
                          border: Border.all(color: Colors.white, width: 1.8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_rounded,
                            color: Color(0xFF071224),
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userJabatan,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 1.5),
                            Text(
                              'NIP. $userNip',
                              style: TextStyle(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Container(height: 1, color: Colors.white12),
                  const SizedBox(height: 10),

                  // Email & Status Penugasan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, color: Colors.white60, size: 13),
                          const SizedBox(width: 5),
                          Text(
                            userEmail,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF34D399),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Siaga Lapangan',
                            style: TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 14)),

        // Informasi Kedinasan & Wilayah Kerja
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0C1F38).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Penugasan Wilayah',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildProfileRow(Icons.map_rounded, 'Wilayah Sungai', 'DAS Ciasem - Cilamaya - Cipunagara'),
                  _buildProfileRow(Icons.home_work_rounded, 'Posko Komando', 'Jl. Mayjen Sutoyo No. 12 Subang'),
                  _buildProfileRow(Icons.dns_rounded, 'Server Backend', 'Laravel 12 (127.0.0.1:8000) • Siaga'),
                  _buildProfileRow(Icons.phone_in_talk_rounded, 'Hotline Bencana', '(0260) 411-PUPR / 0812-SDA-SBNG'),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 14)),

        // Tombol Keluar Sesi
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _showLogoutDialog,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text(
                  'Keluar dari Sesi Aplikasi',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7F1D1D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFEF4444), width: 1.1),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }

  // --- Helper Widgets untuk Tab Khusus (Proporsional Layar HP) ---

  Widget _buildBendungControlCard({
    required String code,
    required String name,
    required String location,
    required String elevation,
    required String discharge,
    required bool isOpen,
    required ValueChanged<bool> onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E38).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOpen ? const Color(0xFF0284C7).withValues(alpha: 0.6) : Colors.white12,
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: isOpen ? const Color(0xFF0284C7).withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          code,
                          style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOpen
                                ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                : const Color(0xFFEF4444).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isOpen ? 'PINTU DIBUKA' : 'PINTU DITUTUP',
                            style: TextStyle(
                              color: isOpen ? const Color(0xFF34D399) : const Color(0xFFF87171),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      location,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.82,
                child: Switch(
                  value: isOpen,
                  onChanged: onToggle,
                  activeThumbColor: const Color(0xFF38BDF8),
                  activeTrackColor: const Color(0xFF0284C7).withValues(alpha: 0.4),
                  inactiveThumbColor: Colors.white38,
                  inactiveTrackColor: Colors.white12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF06101E).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCardParam(label: 'Debit Air', value: discharge, color: const Color(0xFF38BDF8)),
                Container(width: 1, height: 20, color: Colors.white10),
                _buildCardParam(label: 'Elevasi Mercu', value: elevation, color: const Color(0xFFF59E0B)),
                Container(width: 1, height: 20, color: Colors.white10),
                _buildCardParam(label: 'Aktuator', value: 'Servo Ready', color: const Color(0xFF34D399)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              onPressed: () => onToggle(!isOpen),
              icon: Icon(isOpen ? Icons.lock_outline_rounded : Icons.lock_open_rounded, size: 16),
              label: Text(
                isOpen ? 'Perintahkan Tutup Pintu Air' : 'Perintahkan Buka Pintu Air',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isOpen ? const Color(0xFFB91C1C) : const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGateOperationLogs() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1F38).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Jejak Audit Kendali Pintu Air',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  'TERCATAT DATABASE',
                  style: TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLogItem('Baru Saja', 'BND-SKM-01', 'Pintu Air Bendung Sukamelang disesuaikan petugas', const Color(0xFF38BDF8)),
          _buildLogItem('08:30 WIB', 'BND-GDG-02', 'Debit irigasi sekunder Pagaden diverifikasi normal', const Color(0xFF34D399)),
          _buildLogItem('06:00 WIB', 'SISTEM', 'Sinkronisasi telemetri node IoT Subang berhasil', const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _buildLogItem(String time, String tag, String desc, Color tagColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: tagColor.withValues(alpha: 0.5), width: 0.6),
            ),
            child: Text(
              tag,
              style: TextStyle(color: tagColor, fontSize: 8.5, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTmaRiverCard({
    required String riverName,
    required String location,
    required double currentLevel,
    required double safeLimit,
    required double warningLimit,
    required double dangerLimit,
    required bool isActive,
    required ValueChanged<bool> onToggle,
  }) {
    final statusColor = !isActive
        ? Colors.white38
        : (currentLevel >= dangerLimit
            ? const Color(0xFFEF4444)
            : (currentLevel >= warningLimit
                ? const Color(0xFFEAB308)
                : const Color(0xFF10B981)));

    final statusLabel = !isActive
        ? 'SENSOR NONAKTIF'
        : (currentLevel >= dangerLimit
            ? 'SIAGA 1 (BAHAYA)'
            : (currentLevel >= warningLimit
                ? 'SIAGA 3 (WASPADA)'
                : 'SIAGA 4 (AMAN)'));

    final double progress = !isActive ? 0.0 : (currentLevel / dangerLimit).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E38).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? statusColor.withValues(alpha: 0.6) : Colors.white12,
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      riverName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      location,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.82,
                child: Switch(
                  value: isActive,
                  onChanged: onToggle,
                  activeThumbColor: const Color(0xFF38BDF8),
                  activeTrackColor: const Color(0xFF0284C7).withValues(alpha: 0.4),
                  inactiveThumbColor: Colors.white38,
                  inactiveTrackColor: Colors.white12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tinggi Muka Air (TMA)',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isActive ? '${currentLevel.toStringAsFixed(0)} cm' : 'Sensor Off',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white38,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor, width: 0.8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress Bar Level Air
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Aman: <${safeLimit.toInt()}cm', style: const TextStyle(color: Colors.white38, fontSize: 8.5)),
              Text('Waspada: ${warningLimit.toInt()}cm', style: const TextStyle(color: Colors.white38, fontSize: 8.5)),
              Text('Bahaya: >${dangerLimit.toInt()}cm', style: const TextStyle(color: Colors.white38, fontSize: 8.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTmaHourlyChart() {
    final List<int> values = [120, 125, 130, 138, 142, 140, 145, 142];
    final List<String> hours = ['00', '03', '06', '09', '12', '15', '18', '21'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1F38).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tren Level Air Sungai 24 Jam',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              Text(
                'DAS Subang',
                style: TextStyle(
                  color: const Color(0xFFF59E0B),
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(values.length, (i) {
              final h = (values[i] / 200.0) * 62.0;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${values[i]}',
                    style: const TextStyle(color: Colors.white54, fontSize: 8.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 18,
                    height: h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF38BDF8),
                          const Color(0xFF0284C7).withValues(alpha: 0.4),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${hours[i]}:00',
                    style: const TextStyle(color: Colors.white38, fontSize: 8.5),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildArrWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1F38).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pos Curah Hujan Otomatis (ARR)',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06101E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pos Hujan Pagaden', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(isArrPagadenActive ? '18.4 mm/j' : 'Nonaktif', style: TextStyle(color: isArrPagadenActive ? const Color(0xFFF59E0B) : Colors.white38, fontSize: 14.5, fontWeight: FontWeight.w900)),
                      Text('Harian: 32 mm', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 9.5)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06101E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pos Hujan Kasomalang', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(isArrKasomalangActive ? '0.0 mm/j' : 'Nonaktif', style: TextStyle(color: isArrKasomalangActive ? const Color(0xFF10B981) : Colors.white38, fontSize: 14.5, fontWeight: FontWeight.w900)),
                      Text('Harian: 4 mm', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 9.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF38BDF8), size: 15),
          const SizedBox(width: 8),
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardParam({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
      ],
    );
  }

  // Header Dashboard: Logo PUPR + Info Petugas SDA + Tombol Logout (Proporsional Layar HP)
  Widget _buildTopHeader() {
    final userName = _currentUser?['name'] ?? 'Petugas SDA Subang';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              // Logo Resmi PUPR
              Container(
                width: 38,
                height: 38,
                padding: const EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
                    width: 1.3,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.asset(
                    'assets/images/logo_pupr.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Tombol Aksi Keluar / Logout
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showLogoutDialog,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(7.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFF59E0B),
                size: 17,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Kartu Ringkasan Cuaca & Hidrologi Subang (Proporsional Layar HP)
  Widget _buildHydrologySummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2648).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 5),
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
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Wilayah Sungai Subang',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
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
                      size: 10,
                      color: Color(0xFF34D399),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'STATUS NORMAL',
                      style: TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

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
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        '28°C',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Hujan Ringan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(9),
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
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Baris Bawah: Parameter Hidrologi Rata-rata
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF081426),
              borderRadius: BorderRadius.circular(10),
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
                  value: (!isSensorCiasemActive && !isSensorCipunagaraActive)
                      ? 'Off'
                      : (isSensorCiasemActive && isSensorCipunagaraActive
                          ? '178 cm'
                          : (isSensorCiasemActive ? '142 cm' : '215 cm')),
                  color: const Color(0xFF38BDF8),
                ),
                Container(width: 1, height: 20, color: Colors.white12),
                _buildSummaryParam(
                  icon: Icons.flood_rounded,
                  label: 'Debit Irigasi',
                  value: '${((isBendungSukamelangOpen ? 5.4 : 0.0) + (isBendungGadungOpen ? 3.1 : 0.0)).toStringAsFixed(1)} m³/s',
                  color: const Color(0xFF0284C7),
                ),
                Container(width: 1, height: 20, color: Colors.white12),
                _buildSummaryParam(
                  icon: Icons.grain_rounded,
                  label: 'Curah Hujan',
                  value: (!isArrPagadenActive && !isArrKasomalangActive)
                      ? 'Off'
                      : (isArrPagadenActive ? '18.4 mm' : '0.0 mm'),
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
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 9,
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
            padding: const EdgeInsets.only(right: 6.0),
            child: ChoiceChip(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              avatar: Icon(
                filters[index]['icon'] as IconData,
                size: 13,
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
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
          onToggle: (val) => _setDeviceState(
            _keyBendungSukamelang,
            val,
            () => isBendungSukamelangOpen = val,
            'Bendung Sukamelang',
          ),
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
          onToggle: (val) => _setDeviceState(
            _keySensorCiasem,
            val,
            () => isSensorCiasemActive = val,
            'TMA Sungai Ciasem',
          ),
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
          onToggle: (val) => _setDeviceState(
            _keyArrPagaden,
            val,
            () => isArrPagadenActive = val,
            'Pos Hujan Pagaden',
          ),
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
          onToggle: (val) => _setDeviceState(
            _keyBendungGadung,
            val,
            () => isBendungGadungOpen = val,
            'Bendung Gadung',
          ),
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
          onToggle: (val) => _setDeviceState(
            _keySensorCipunagara,
            val,
            () => isSensorCipunagaraActive = val,
            'TMA Cipunagara',
          ),
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
          onToggle: (val) => _setDeviceState(
            _keyArrKasomalang,
            val,
            () => isArrKasomalangActive = val,
            'Pos Kasomalang',
          ),
          accentColor: const Color(0xFF10B981),
          badgeText: '4mm/hari',
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.69,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => cards[index],
        childCount: cards.length,
      ),
    );
  }

  // Kartu Perangkat Sensor SDA Modern (Proporsional Layar HP)
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOn
              ? accentColor.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isOn
                ? accentColor.withValues(alpha: 0.16)
                : Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Baris Atas: Ikon + Switch Kendali
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isOn
                      ? accentColor.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isOn
                        ? accentColor.withValues(alpha: 0.6)
                        : Colors.white12,
                    width: 1.0,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isOn ? accentColor : Colors.white38,
                  size: 18,
                ),
              ),
              Transform.scale(
                scale: 0.78,
                child: Switch(
                  value: isOn,
                  onChanged: onToggle,
                  activeThumbColor: accentColor,
                  activeTrackColor: accentColor.withValues(alpha: 0.35),
                  inactiveThumbColor: Colors.white38,
                  inactiveTrackColor: Colors.white12,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
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
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: isOn ? accentColor : Colors.white38,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ),

          // Baris Bawah: Nilai Metrik & Status Telemetri
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF06101E).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(9),
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
                          fontSize: 8.5,
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
                          fontSize: 8.5,
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
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  statusText,
                  style: TextStyle(
                    color: isOn ? const Color(0xFF34D399) : Colors.white24,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bottom Navigation Bar (Proporsional Layar HP)
  Widget _buildBottomNav() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0C1F38).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 6),
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
        HapticFeedback.lightImpact();
        setState(() => _activeNavIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF59E0B) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF071224) : Colors.white60,
              size: 18,
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF071224),
                  fontSize: 11,
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
