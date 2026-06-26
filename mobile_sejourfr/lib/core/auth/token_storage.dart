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
  static const _kSavedEmail = 'sejourfr.savedEmail';
  static const _kSavedPassword = 'sejourfr.savedPassword';

  /// Lecture défensive du secure storage. Une valeur chiffrée par une ancienne
  /// version (clé Android Keystore invalidée par la mise à jour, format de
  /// chiffrement changé entre deux versions du plugin, backup/restore…) fait
  /// lever `read()` au lieu de renvoyer null. On dégrade alors en « pas de
  /// valeur » : sans ça, l'exception remonterait jusqu'au bootstrap et l'app
  /// resterait figée sur le splash (état AuthLoading jamais résolu).
  Future<String?> _read(String key) async {
    try {
      // Timeout indispensable : sur certains appareils (Keystore matériel /
      // ROM OEM, observé Android 15 en build release) le premier `read()` ne
      // revient JAMAIS — le canal natif se bloque sans lever. Un await gelé ici
      // laissait l'app figée sur le splash. On dégrade alors en « pas de
      // valeur » au bout de 5 s plutôt que de bloquer le boot indéfiniment.
      return await _storage
          .read(key: key)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      return null;
    }
  }

  Future<String?> readAccess() => _read(_kAccess);
  Future<String?> readRefresh() => _read(_kRefresh);

  Future<AuthUser?> readUser() async {
    final raw = await _read(_kUser);
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

  // --------------------------------------------------------------------------
  // « Enregistrer mes identifiants » (option de l'écran de connexion).
  // Stockés à part de la session : un logout vide les tokens mais conserve les
  // identifiants enregistrés (l'utilisateur peut se reconnecter sans retaper).
  // Chiffrés au repos (Keychain iOS / EncryptedSharedPreferences Android).
  // --------------------------------------------------------------------------

  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _kSavedEmail, value: email);
    await _storage.write(key: _kSavedPassword, value: password);
  }

  Future<({String email, String password})?> readCredentials() async {
    final email = await _read(_kSavedEmail);
    final password = await _read(_kSavedPassword);
    if (email == null || password == null) return null;
    return (email: email, password: password);
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: _kSavedEmail);
    await _storage.delete(key: _kSavedPassword);
  }
}
