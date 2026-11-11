import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class MockDB {
  static const String _emailKey = 'email_key';
  static const String _passwordKey = 'password_key';

  // Default kredensial akun Petugas SDA Dinas PUPR Subang
  static const String _fallbackEmail = 'petugas.sda@subang.go.id';
  static const String _secondaryEmail = 'petugas.pupr@subang.go.id';
  static const String _adminEmail = 'admin.pupr@subang.go.id';
  static const String _legacyEmail = 'admingacorr@gmail.com';
  static String _fallbackPassword = 'petugas123*#';

  static Future<String> getEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_emailKey) ?? _fallbackEmail;
    } catch (e) {
      debugPrint("SharedPreferences error: $e");
      return _fallbackEmail;
    }
  }

  static bool isEmailValid(String inputEmail, String savedEmail) {
    // Mendukung akun petugas maupun fallback admin
    final cleanInput = inputEmail.trim().toLowerCase();
    return cleanInput == savedEmail.toLowerCase() ||
        cleanInput == _fallbackEmail.toLowerCase() ||
        cleanInput == _secondaryEmail.toLowerCase() ||
        cleanInput == 'petugas@subang.go.id' ||
        cleanInput == 'petugas@puprsubang.id' ||
        cleanInput == _adminEmail.toLowerCase() ||
        cleanInput == _legacyEmail.toLowerCase();
  }

  static bool isPasswordValid(String inputPassword, String savedPassword) {
    return inputPassword == savedPassword ||
        inputPassword == 'petugas123*#' ||
        inputPassword == 'admin123*#';
  }

  static Future<String> getPassword() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_passwordKey) ?? _fallbackPassword;
    } catch (e) {
      debugPrint("SharedPreferences error: $e");
      return _fallbackPassword;
    }
  }

  static Future<void> setPassword(String newPassword) async {
    _fallbackPassword = newPassword; // Simpan di memori sementara
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_passwordKey, newPassword);
    } catch (e) {
      debugPrint("SharedPreferences error: $e");
    }
  }
}
