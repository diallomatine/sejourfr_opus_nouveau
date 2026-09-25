import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/client_context.dart';
import '../api/app_config_repository.dart';
import '../auth/auth_controller.dart';
import '../config/env.dart';

/// **Version minimale (contrôle G-a)** — la seule autorité du blocage « mettre
/// à jour » de l'app.
///
/// 🛑 **Ne bloque jamais sur un doute** : réseau injoignable, réponse
/// illisible, valeur `null` servie, version courante ou minimale non
/// numérique ⇒ l'app s'ouvre normalement. Seul un « courante < minimale »
/// **lu sans ambiguïté** bloque. La valeur initiale du serveur (`null`) est
/// sans effet.

final appConfigRepositoryProvider = Provider<AppConfigRepository>(
  (ref) => AppConfigRepository(ref.watch(apiClientProvider)),
);

/// Lu **une fois par lancement**, en arrière-plan : tant qu'il n'a pas
/// répondu, l'app s'utilise normalement (`valueOrNull ?? false`).
final updateRequiredProvider = FutureProvider<bool>((ref) async {
  try {
    final platform = ClientContext.platform;
    if (platform == null) return false;
    final current = await ClientContext.appVersion();
    if (current == null) return false;
    final minimum = await ref
        .read(appConfigRepositoryProvider)
        .minSupportedVersion(platform);
    if (minimum == null) return false;
    return isVersionBelow(current, minimum) ?? false;
  } catch (_) {
    return false;
  }
});

/// `true` si [current] est **strictement** inférieure à [minimum], comparées
/// composant par composant, numériquement (`0.1.10` > `0.1.9`), un composant
/// absent valant 0. Le numéro de build (`+19`) de [current] est ignoré.
/// `null` si l'une des deux n'est pas une version numérique : l'appelant ne
/// bloque pas.
bool? isVersionBelow(String current, String minimum) {
  final a = _parse(current.split('+').first);
  final b = _parse(minimum.split('+').first);
  if (a == null || b == null) return null;
  final n = a.length > b.length ? a.length : b.length;
  for (var i = 0; i < n; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x < y;
  }
  return false;
}

List<int>? _parse(String version) {
  final parts = version.trim().split('.');
  if (parts.isEmpty || parts.length > 4) return null;
  final out = <int>[];
  for (final part in parts) {
    final value = int.tryParse(part);
    if (value == null || value < 0) return null;
    out.add(value);
  }
  return out;
}

/// Les fiches de l'app dans les stores, en `.env` : l'identifiant numérique
/// App Store n'est connu qu'au moment de la publication (`APPLE_APP_ID`).
/// Repli iOS : la recherche App Store ; repli Android : la fiche du package
/// `com.sejourfr.app`.
class StoreLinks {
  StoreLinks._();

  static String get appStore => Env.read(
        'IOS_APP_STORE_URL',
        fallback: 'https://apps.apple.com/fr/search?term=SejourFR',
      );

  static String get playStore => Env.read(
        'ANDROID_PLAY_STORE_URL',
        fallback:
            'https://play.google.com/store/apps/details?id=com.sejourfr.app',
      );
}
