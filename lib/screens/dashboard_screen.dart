import 'dart:ui';

import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Status perangkat dummy
  bool isLightOn = true;
  bool isAcOn = false;
  bool isTvOn = true;
  bool isCctvOn = true;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), // Soft light background
      body: Stack(
        children: [
          // Stunning Background Glow Effects
          Positioned(
            top: -50,
            left: -50,
            child: _buildGlowBlob(const Color(0xFF00C6FF), 250),
          ),
          Positioned(
            top: 250,
            right: -100,
            child: _buildGlowBlob(const Color(0xFFFF7EB3), 300),
          ),
          Positioned(
            bottom: -50,
            left: 20,
            child: _buildGlowBlob(const Color(0xFF7DE2FC), 250),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: const SizedBox(),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF475569), // Slate 600
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A), // Slate 900
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A)
                                  .withValues(alpha: 0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),

                // Info Cuaca / Ringkasan (Glass Card)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _buildWeatherCard(),
                ),
                const SizedBox(height: 32),

                // Perangkat Pintar Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Perangkat Anda',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Grid Perangkat
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.78,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildDeviceCard(
                        title: 'Lampu Utama',
                        icon: Icons.lightbulb_rounded,
                        isOn: isLightOn,
                        onToggle: (val) => setState(() => isLightOn = val),
                        activeColor: const Color(0xFFFF9A44),
                      ),
                      _buildDeviceCard(
                        title: 'AC Ruang',
                        icon: Icons.ac_unit_rounded,
                        isOn: isAcOn,
                        onToggle: (val) => setState(() => isAcOn = val),
                        activeColor: const Color(0xFF00C6FF),
                      ),
                      _buildDeviceCard(
                        title: 'Smart TV',
                        icon: Icons.tv_rounded,
                        isOn: isTvOn,
                        onToggle: (val) => setState(() => isTvOn = val),
                        activeColor: const Color(0xFF8E2DE2),
                      ),
                      _buildDeviceCard(
                        title: 'Kamera CCTV',
                        icon: Icons.videocam_rounded,
                        isOn: isCctvOn,
                        onToggle: (val) => setState(() => isCctvOn = val),
                        activeColor: const Color(0xFFF53844),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home_rounded, true),
            _buildNavItem(Icons.bar_chart_rounded, false),
            _buildNavItem(Icons.settings_rounded, false),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.35),
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 25,
            offset: const Offset(0, 8),
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
                'Suhu Ruangan',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '24°C',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C6FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.water_drop_rounded,
                      color: Color(0xFF0075A0),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Kelembapan 45%',
                      style: TextStyle(
                        color: Color(0xFF0075A0),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard({
    required String title,
    required IconData icon,
    required bool isOn,
    required ValueChanged<bool> onToggle,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: () => onToggle(!isOn),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isOn ? activeColor : Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isOn ? activeColor : Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isOn
                  ? activeColor.withValues(alpha: 0.4)
                  : const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: isOn ? 20 : 15,
              offset: const Offset(0, 8),
              spreadRadius: isOn ? 2 : 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isOn
                        ? Colors.white.withValues(alpha: 0.25)
                        : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isOn ? Colors.white : const Color(0xFF475569),
                    size: 32,
                  ),
                ),
                Switch(
                  value: isOn,
                  onChanged: onToggle,
                  activeThumbColor: activeColor,
                  activeTrackColor: Colors.white,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFCBD5E1),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isOn ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isOn ? 'MENYALA' : 'MATI',
                  style: TextStyle(
                    color: isOn ? Colors.white : const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: isActive
          ? BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(24),
            )
          : null,
      child: Icon(
        icon,
        color: isActive ? Colors.white : const Color(0xFF94A3B8),
        size: 26,
      ),
    );
  }
}
