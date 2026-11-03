import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../mock_db.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0; // 0: Email, 1: OTP, 2: New Password
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();
  final _otpController = TextEditingController();
  final _otpFocus = FocusNode();
  final _newPasswordController = TextEditingController();
  final _newPasswordFocus = FocusNode();
  final _confirmPasswordController = TextEditingController();
  final _confirmPasswordFocus = FocusNode();

  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _floatController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    // Animasi Muncul (Fade In)
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Animasi Detak (Pulsing background & logo)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Animasi Melayang (Floating card)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _fadeController.forward();

    // Rebuild saat input text difokuskan untuk efek menyala
    _emailFocus.addListener(() => setState(() {}));
    _otpFocus.addListener(() => setState(() {}));
    _newPasswordFocus.addListener(() => setState(() {}));
    _confirmPasswordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    _emailController.dispose();
    _emailFocus.dispose();
    _otpController.dispose();
    _otpFocus.dispose();
    _newPasswordController.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordController.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
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
      backgroundColor: const Color(0xFF040B16),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Efek Cahaya Latar (Mesh Gradients)
          Positioned(
            top: -100,
            left: -100,
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: _buildGlowBlob(const Color(0xFF00F2FE), 300),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: _buildGlowBlob(const Color(0xFF4FACFE), 400),
            ),
          ),
          Positioned(
            top: 250,
            right: -50,
            child: _buildGlowBlob(const Color(0xFF8A2387), 250),
          ),

          // Efek Kaca Buram Full Screen
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: const SizedBox(),
            ),
          ),

          // Konten Utama
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: child,
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Ikon Gembok Berdenyut
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00F2FE)
                                              .withValues(
                                                alpha:
                                                    0.3 *
                                                    (_pulseAnimation.value -
                                                        0.9),
                                              ),
                                          blurRadius: 30,
                                          spreadRadius: 10,
                                        ),
                                      ],
                                      border: Border.all(
                                        color: const Color(0xFF00F2FE)
                                            .withValues(alpha: 0.5),
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.lock_reset,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),

                              // Judul
                              Text(
                                _currentStep == 0 
                                    ? 'LUPA PASSWORD' 
                                    : _currentStep == 1 
                                        ? 'VERIFIKASI OTP' 
                                        : 'UBAH PASSWORD',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Deskripsi
                              Text(
                                _currentStep == 0
                                    ? 'Silakan masukkan alamat email kamu. Kode OTP akan dikirimkan ke email tersebut.'
                                    : _currentStep == 1
                                        ? 'Silakan masukkan kode OTP yang telah dikirimkan ke email:\n${_emailController.text}'
                                        : 'Silakan buat kata sandi baru untuk akun Anda.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  letterSpacing: 1.0,
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 40),

                              // Input Field
                              if (_currentStep == 0)
                                _buildTextField(
                                  controller: _emailController,
                                  focusNode: _emailFocus,
                                  icon: Icons.alternate_email,
                                  hintText: 'Alamat Email',
                                  keyboardType: TextInputType.emailAddress,
                                )
                              else if (_currentStep == 1)
                                _buildTextField(
                                  controller: _otpController,
                                  focusNode: _otpFocus,
                                  icon: Icons.password,
                                  hintText: 'Kode OTP',
                                  keyboardType: TextInputType.number,
                                )
                              else
                                Column(
                                  children: [
                                    _buildTextField(
                                      controller: _newPasswordController,
                                      focusNode: _newPasswordFocus,
                                      icon: Icons.lock_outline,
                                      hintText: 'Kata Sandi Baru',
                                      obscureText: !_isNewPasswordVisible,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isNewPasswordVisible
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: Colors.white.withValues(alpha: 0.7),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isNewPasswordVisible = !_isNewPasswordVisible;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      controller: _confirmPasswordController,
                                      focusNode: _confirmPasswordFocus,
                                      icon: Icons.lock_outline,
                                      hintText: 'Konfirmasi Kata Sandi Baru',
                                      obscureText: !_isConfirmPasswordVisible,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isConfirmPasswordVisible
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: Colors.white.withValues(alpha: 0.7),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 32),

                              // Tombol Kirim Animasi
                              _buildAnimatedButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomSnackBar(String title, String message, bool isSuccess) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSuccess 
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                  color: isSuccess ? Colors.greenAccent : Colors.redAccent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF1E232C), // Warna dark khas UI
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSuccess 
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.red.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        elevation: 10,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Widget Bola Cahaya
  Widget _buildGlowBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 100,
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }

  // Widget Tombol Utama dengan Efek Berdenyut
  Widget _buildAnimatedButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF00F2FE,
                ).withValues(alpha: 0.3 + (0.2 * (_pulseAnimation.value - 1))),
                blurRadius: 20 + (10 * (_pulseAnimation.value - 1)),
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () async {
              if (_currentStep == 0) {
                if (_emailController.text.isNotEmpty) {
                  // Simulasi kirim OTP
                  setState(() {
                    _currentStep = 1;
                  });
                  _showCustomSnackBar(
                    'Berhasil',
                    'Kode OTP (simulasi) telah dikirim ke ${_emailController.text}',
                    true,
                  );
                } else {
                  _showCustomSnackBar(
                    'Peringatan',
                    'Harap masukkan alamat email kamu terlebih dahulu.',
                    false,
                  );
                }
              } else if (_currentStep == 1) {
                if (_otpController.text.isNotEmpty) {
                  // Simulasi verifikasi OTP sukses
                  setState(() {
                    _currentStep = 2;
                  });
                  _showCustomSnackBar(
                    'Verifikasi Sukses',
                    'Kode OTP valid. Silakan buat kata sandi baru.',
                    true,
                  );
                } else {
                  _showCustomSnackBar(
                    'Peringatan',
                    'Harap masukkan kode OTP untuk melanjutkan.',
                    false,
                  );
                }
              } else {
                // Step 2: Ganti Password
                if (_newPasswordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
                  _showCustomSnackBar(
                    'Peringatan',
                    'Semua kolom kata sandi harus diisi.',
                    false,
                  );
                } else if (_newPasswordController.text != _confirmPasswordController.text) {
                  _showCustomSnackBar(
                    'Peringatan',
                    'Kata sandi dan konfirmasi kata sandi tidak cocok.',
                    false,
                  );
                } else {
                  _showCustomSnackBar(
                    'Berhasil',
                    'Kata sandi Anda telah berhasil diubah!',
                    true,
                  );
                  await MockDB.setPassword(_newPasswordController.text);
                  if (!context.mounted) return;
                  await Future.delayed(const Duration(seconds: 2));
                  if (!context.mounted) return;
                  Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              _currentStep == 0 
                  ? 'KIRIM OTP' 
                  : _currentStep == 1 
                      ? 'VERIFIKASI' 
                      : 'SIMPAN PASSWORD',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2.0,
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget TextField dengan Efek Glowing saat Fokus
  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required String hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    final isFocused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isFocused
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused
              ? const Color(0xFF00F2FE)
              : Colors.white.withValues(alpha: 0.1),
          width: isFocused ? 1.5 : 1.0,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF00F2FE).withValues(alpha: 0.2),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          prefixIcon: Icon(
            icon,
            color: isFocused
                ? const Color(0xFF00F2FE)
                : Colors.white.withValues(alpha: 0.7),
            size: 22,
          ),
          suffixIcon: suffixIcon,
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
