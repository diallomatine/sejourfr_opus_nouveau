import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Acces centralise aux variables d'env runtime chargees depuis `.env`.
///
/// `Env.init()` doit etre appele AVANT `runApp(...)` dans `main.dart`. Tant
/// que ce n'est pas fait, [read] retourne la chaine vide (pas d'exception)
/// pour ne pas casser les tests qui ne chargent pas dotenv.
class Env {
  Env._();

  static bool _loaded = false;

  /// Charge le fichier `.env` declare en asset dans `pubspec.yaml`. Tolerant
  /// a l'absence du fichier : en cas d'erreur, on continue avec un store vide
  /// — les accesseurs types retomberont sur leur defaut.
  static Future<void> init({String fileName = '.env'}) async {
    try {
      await dotenv.load(fileName: fileName);
      _loaded = true;
    } catch (_) {
      _loaded = false;
    }
  }

  /// Lit une variable, retourne [fallback] (defaut: '') si absente ou si
  /// dotenv n'a jamais ete initialise.
  static String read(String key, {String fallback = ''}) {
    if (!_loaded) return fallback;
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) return fallback;
    return value;
  }
}
