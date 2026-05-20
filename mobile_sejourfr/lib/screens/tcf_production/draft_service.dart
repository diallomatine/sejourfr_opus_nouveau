import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistance des brouillons de redaction EE en local.
///
/// On stocke un texte par task_id (les 3 taches d'une session ont leurs
/// propres brouillons). Apres soumission reussie, le brouillon est supprime.
class EeDraftService {
  static const _prefix = 'ee_draft_';
  static const _savedAtSuffix = '_saved_at';

  Future<void> save(String taskId, String text) async {
    final prefs = await SharedPreferences.getInstance();
    if (text.trim().isEmpty) {
      await clear(taskId);
      return;
    }
    await prefs.setString('$_prefix$taskId', text);
    await prefs.setString(
      '$_prefix$taskId$_savedAtSuffix',
      DateTime.now().toIso8601String(),
    );
  }

  Future<String?> load(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefix$taskId');
  }

  Future<DateTime?> savedAt(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString('$_prefix$taskId$_savedAtSuffix');
    return iso == null ? null : DateTime.tryParse(iso);
  }

  Future<void> clear(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$taskId');
    await prefs.remove('$_prefix$taskId$_savedAtSuffix');
  }
}

final eeDraftServiceProvider = Provider<EeDraftService>((_) => EeDraftService());
