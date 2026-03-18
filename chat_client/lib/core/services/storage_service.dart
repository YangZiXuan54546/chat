import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('chat_app_storage');
  }

  // Auth token
  Future<void> setAuthToken(String token) async {
    await _box.put(AppConfig.tokenKey, token);
  }

  String? getAuthToken() {
    return _box.get(AppConfig.tokenKey);
  }

  Future<void> setRefreshToken(String token) async {
    await _box.put(AppConfig.refreshTokenKey, token);
  }

  String? getRefreshToken() {
    return _box.get(AppConfig.refreshTokenKey);
  }

  Future<void> setUserId(String userId) async {
    await _box.put(AppConfig.userIdKey, userId);
  }

  String? getUserId() {
    return _box.get(AppConfig.userIdKey);
  }

  Future<void> setUserData(String userData) async {
    await _box.put(AppConfig.userDataKey, userData);
  }

  String? getUserData() {
    return _box.get(AppConfig.userDataKey);
  }

  // Clear auth data
  Future<void> clearAuth() async {
    await _box.delete(AppConfig.tokenKey);
    await _box.delete(AppConfig.refreshTokenKey);
    await _box.delete(AppConfig.userIdKey);
    await _box.delete(AppConfig.userDataKey);
  }

  // Check if logged in
  bool isLoggedIn() {
    return getAuthToken() != null;
  }

  // Generic storage
  Future<void> setString(String key, String value) async {
    await _box.put(key, value);
  }

  String? getString(String key) {
    return _box.get(key);
  }

  Future<void> setBool(String key, bool value) async {
    await _box.put(key, value);
  }

  bool? getBool(String key) {
    return _box.get(key);
  }

  Future<void> setObject(String key, dynamic value) async {
    await _box.put(key, value);
  }

  dynamic getObject(String key) {
    return _box.get(key);
  }

  Future<void> remove(String key) async {
    await _box.delete(key);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
