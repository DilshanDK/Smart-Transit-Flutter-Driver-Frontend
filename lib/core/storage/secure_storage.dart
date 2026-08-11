import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyOfflineTaps = 'offline_taps';

  static Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }

  static Future<List<Map<String, dynamic>>> getOfflineTaps() async {
    try {
      final jsonStr = await _storage.read(key: _keyOfflineTaps);
      if (jsonStr == null) return [];
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveOfflineTaps(List<Map<String, dynamic>> taps) async {
    await _storage.write(key: _keyOfflineTaps, value: json.encode(taps));
  }

  static Future<void> addOfflineTap(Map<String, dynamic> tap) async {
    final taps = await getOfflineTaps();
    taps.add(tap);
    await saveOfflineTaps(taps);
  }

  static Future<void> clearOfflineTaps() async {
    await _storage.delete(key: _keyOfflineTaps);
  }

  // Generic helpers for other features (e.g. theme preference)
  static Future<String?> readValue(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> writeValue(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
}
