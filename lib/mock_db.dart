import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class MockDB {
  static const String _emailKey = 'email_key';
  static const String _passwordKey = 'password_key';

  // Fallback memory state in case SharedPreferences belum di-build dengan benar
  static const String _fallbackEmail = 'admingacorr@gmail.com';
  static String _fallbackPassword = 'admin123*#';

  static Future<String> getEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_emailKey) ?? _fallbackEmail;
    } catch (e) {
      debugPrint("SharedPreferences error: $e");
      return _fallbackEmail;
    }
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
