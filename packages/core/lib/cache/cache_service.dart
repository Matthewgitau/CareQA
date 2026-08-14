import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  Future<void> setObject(String key, Map<String, dynamic> value) async {
    await _prefs?.setString(key, jsonEncode(value));
  }

  Future<void> setList(String key, List<dynamic> value) async {
    await _prefs?.setString(key, jsonEncode(value));
  }

  String? getString(String key) => _prefs?.getString(key);

  Map<String, dynamic>? getObject(String key) {
    final json = _prefs?.getString(key);
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  List<dynamic>? getList(String key) {
    final json = _prefs?.getString(key);
    if (json == null) return null;
    return jsonDecode(json) as List<dynamic>;
  }

  Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  Future<void> clear() async {
    await _prefs?.clear();
  }

  // Cache with TTL
  Future<void> setWithTTL(String key, String value, Duration ttl) async {
    final expiry = DateTime.now().add(ttl).millisecondsSinceEpoch;
    final data = {
      'value': value,
      'expiry': expiry,
    };
    await _prefs?.setString(key, jsonEncode(data));
  }

  String? getWithTTL(String key) {
    final json = _prefs?.getString(key);
    if (json == null) return null;
    final data = jsonDecode(json) as Map<String, dynamic>;
    final expiry = data['expiry'] as int;
    if (DateTime.now().millisecondsSinceEpoch > expiry) {
      // Expired
      _prefs?.remove(key);
      return null;
    }
    return data['value'] as String;
  }
}