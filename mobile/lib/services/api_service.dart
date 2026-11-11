import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../mock_db.dart';

class ApiService {
  static const String _tokenKey = 'auth_sanctum_token';
  static const String _userKey = 'auth_user_data';

  /// Mendapatkan Base URL sesuai platform target (Web/Desktop/Android Emulator/HP)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // 10.0.2.2 adalah alias localhost host machine untuk emulator Android
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  /// Autentikasi Login terintegrasi ke Laravel Sanctum dengan fallback offline
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': cleanEmail,
              'password': cleanPassword,
            }),
          )
          .timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        if (data['token'] != null) {
          await prefs.setString(_tokenKey, data['token']);
        }
        if (data['user'] != null) {
          await prefs.setString(_userKey, jsonEncode(data['user']));
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Login berhasil.',
          'user': data['user'],
          'is_online': true,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Kredensial tidak valid.',
          'is_online': true,
        };
      }
    } catch (e) {
      debugPrint('Koneksi ke backend Laravel gagal ($e), beralih ke validasi lokal...');
      // Fallback mulus ke MockDB lokal jika backend Laravel sedang tidak aktif
      final savedEmail = await MockDB.getEmail();
      final savedPassword = await MockDB.getPassword();

      final isEmailOk = MockDB.isEmailValid(cleanEmail, savedEmail);
      final isPasswordOk = MockDB.isPasswordValid(cleanPassword, savedPassword);

      if (isEmailOk && isPasswordOk) {
        return {
          'success': true,
          'message': 'Login berhasil (Mode Mandiri/Offline)',
          'user': {
            'name': 'Petugas Lapangan SDA Subang',
            'email': cleanEmail,
            'role': cleanEmail.contains('admin') ? 'admin' : 'petugas',
            'jabatan': 'Operator Telemetri & Pintu Air',
          },
          'is_online': false,
        };
      } else {
        return {
          'success': false,
          'message': 'Email atau kata sandi tidak sesuai.',
          'is_online': false,
        };
      }
    }
  }

  /// Sinkronisasi kendali pintu air bendung ke Database Laravel
  static Future<bool> syncGateStatus(int deviceId, bool isOpen) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/devices/$deviceId/toggle-gate'),
            headers: headers,
            body: jsonEncode({
              'gate_is_open': isOpen,
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        debugPrint('Sinkronisasi pintu air bendung ID $deviceId ke backend berhasil.');
        return true;
      }
    } catch (e) {
      debugPrint('Gagal sync pintu air ke backend: $e (status tetap tersimpan lokal).');
    }
    return false;
  }

  /// Ambil profil petugas yang tersimpan
  static Future<Map<String, dynamic>?> getSavedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(_userKey);
      if (userStr != null) {
        return jsonDecode(userStr);
      }
    } catch (e) {
      debugPrint('Error getSavedUser: $e');
    }
    return null;
  }

  /// Logout dan hapus sesi token
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      if (token != null) {
        await http
            .post(
              Uri.parse('$baseUrl/logout'),
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 2));
      }

      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (e) {
      debugPrint('Logout backend error: $e');
    }
  }
}

