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
  // Ancienne clé : le mot de passe était persisté pour « Enregistrer mes
  // identifiants ». On ne le stocke plus (un mot de passe réutilisable est plus
  // risqué qu'un refresh token révocable — MOB-02). La constante reste pour
  // PURGER la valeur héritée sur les installs existants.
  static const _kLegacySavedPassword = 'sejourfr.savedPassword';

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
  // « Se souvenir de mon email » (option de l'écran de connexion).
  // On ne persiste QUE l'email (préremplissage) — jamais le mot de passe. Stocké
  // à part de la session : un logout vide les tokens mais conserve l'email
  // mémorisé. Chiffré au repos (Keychain iOS / EncryptedSharedPreferences).
  // --------------------------------------------------------------------------

  Future<void> saveEmail(String email) async {
    await _storage.write(key: _kSavedEmail, value: email);
    // Purge un éventuel mot de passe stocké par une ancienne version.
    await _storage.delete(key: _kLegacySavedPassword);
  }

  Future<String?> readSavedEmail() => _read(_kSavedEmail);

  Future<void> clearCredentials() async {
    await _storage.delete(key: _kSavedEmail);
    await _storage.delete(key: _kLegacySavedPassword);
  }
}
