import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// **Les intentions d'achat en attente, indexées par produit du store** (Q12).
///
/// L'identifiant est écrit **avant** d'ouvrir la feuille Apple / Google, et
/// relu au moment de vérifier le reçu — y compris quand le store re-livre
/// l'achat au lancement suivant (crash pendant la feuille, achat en attente,
/// « Ask to Buy »). Il n'est effacé qu'après une vérification réussie.
///
/// 🛑 **Jamais dans `appAccountToken` / `obfuscatedAccountId` /
/// `obfuscatedProfileId`** : ces champs portent l'identité du compte chez le
/// store, pas une mesure. L'intention voyage à côté, dans `verify-receipt`.
///
/// Best-effort : aucune méthode ne lève. Une intention perdue fait
/// simplement un achat `UNKNOWN`, jamais un achat bloqué.
class PurchaseIntentStore {
  static const String _key = 'sejourfr.billing.purchaseIntents';

  /// Au-delà, l'intention est expirée côté serveur (TTL 24 h) et ne ferait
  /// qu'un `UNKNOWN` : on la garde quand même quelques jours pour un achat
  /// « en attente » longtemps, puis on la jette pour que la table ne grossisse
  /// pas.
  static const Duration _keep = Duration(days: 7);

  Future<Map<String, ({String id, DateTime savedAt})>> _read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return {};
      final out = <String, ({String id, DateTime savedAt})>{};
      final limit = DateTime.now().subtract(_keep);
      decoded.forEach((productId, value) {
        if (value is! Map<String, dynamic>) return;
        final id = value['id'] as String?;
        final savedAt = DateTime.tryParse(value['savedAt'] as String? ?? '');
        if (id == null || savedAt == null || savedAt.isBefore(limit)) return;
        out[productId] = (id: id, savedAt: savedAt);
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> _write(Map<String, ({String id, DateTime savedAt})> all) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (all.isEmpty) {
        await prefs.remove(_key);
        return;
      }
      await prefs.setString(
        _key,
        jsonEncode({
          for (final e in all.entries)
            e.key: {'id': e.value.id, 'savedAt': e.value.savedAt.toIso8601String()},
        }),
      );
    } catch (_) {
      // Sans conséquence sur l'achat.
    }
  }

  /// Mémorise l'intention de [productId] — la dernière remplace la précédente.
  Future<void> save(String productId, String purchaseIntentId) async {
    final all = await _read();
    all[productId] = (id: purchaseIntentId, savedAt: DateTime.now());
    await _write(all);
  }

  Future<String?> find(String productId) async => (await _read())[productId]?.id;

  /// Après une vérification **réussie** seulement.
  Future<void> clear(String productId) async {
    final all = await _read();
    if (all.remove(productId) == null) return;
    await _write(all);
  }
}
