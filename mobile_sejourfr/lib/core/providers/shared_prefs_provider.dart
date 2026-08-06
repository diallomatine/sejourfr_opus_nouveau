import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Instance synchrone de SharedPreferences. Préchargée dans main.dart et
/// injectée via `ProviderScope.overrides`. Lire ce provider sans override
/// lèvera une erreur (volontaire : on veut un état toujours disponible
/// dès le premier frame).
///
/// Vit dans `core/` parce que deux domaines s'en servent : l'onboarding
/// (« déjà vu ») et le parcours TCF EE/EO (l'info one-time sur l'essai
/// gratuit). Un provider transverse n'a pas à être importé depuis l'écran
/// qui l'a introduit.
final sharedPrefsProvider = Provider<SharedPreferences>((_) {
  throw UnimplementedError(
    'sharedPrefsProvider doit être overridé dans main.dart',
  );
});
