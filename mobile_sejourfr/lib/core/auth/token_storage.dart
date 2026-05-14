import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_models.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kAccess = 'sejourfr.accessToken';
  static const _kRefresh = 'sejourfr.refreshToken';
  static const _kUser = 'sejourfr.user';

  Future<String?> readAccess() => _storage.read(key: _kAccess);
  Future<String?> readRefresh() => _storage.read(key: _kRefresh);

  Future<AuthUser?> readUser() async {
    final raw = await _storage.read(key: _kUser);
    if (raw == null) return null;
    try {
      return AuthUser.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required AuthUser user,
  }) async {
    await _storage.write(key: _kAccess, value: accessToken);
    await _storage.write(key: _kRefresh, value: refreshToken);
    await _storage.write(key: _kUser, value: json.encode(user.toJson()));
  }

  /// Met à jour uniquement la copie persistée du user (sans toucher aux tokens).
  Future<void> saveUser(AuthUser user) async {
    await _storage.write(key: _kUser, value: json.encode(user.toJson()));
  }

  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kUser);
  }
}
