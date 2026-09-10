import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Production locale d'un diagnostic commencé **sans compte**.
///
/// Le texte vit dans `SharedPreferences`, l'audio dans le dossier de l'app :
/// les deux survivent à la fermeture de l'application, au détour par
/// Google/Apple sign-in et à la reconstruction des providers `autoDispose`
/// quand l'état d'authentification bascule. C'est la seule copie du travail du
/// visiteur tant que le serveur n'a pas accusé réception des deux productions.
class DiagnosticDraft {
  const DiagnosticDraft({
    required this.diagnosticCode,
    required this.diagnosticVersion,
    this.writtenTaskId,
    this.writtenText,
    this.oralTaskId,
    this.audioFileName,
    this.audioMime,
    this.savedAt,
    this.oralRequired = true,
  });

  final String diagnosticCode;
  final int diagnosticVersion;
  final String? writtenTaskId;
  final String? writtenText;
  final String? oralTaskId;

  /// **Nom** du fichier, jamais son chemin absolu : sur iOS le conteneur de
  /// l'app change d'identifiant entre deux lancements et une mise à jour, un
  /// chemin mémorisé tel quel devient introuvable.
  final String? audioFileName;
  final String? audioMime;
  final DateTime? savedAt;

  /// Ce diagnostic comportait-il une étape orale ? (L3)
  ///
  /// 🛑 **La FORME du parcours est enregistrée AVEC la production**, jamais
  /// relue sur la configuration du moment. Un brouillon écrit sous le
  /// diagnostic à deux productions doit rester incomplet tant que son oral
  /// manque, même si le serveur a basculé entre-temps sur le diagnostic
  /// rapide — sinon on enverrait une session que le serveur refuserait.
  ///
  /// Absent des brouillons antérieurs à L3 ⇒ `true` : ils ont tous été faits
  /// sous la paire écrit + oral.
  final bool oralRequired;

  bool get hasWritten =>
      (writtenTaskId?.isNotEmpty ?? false) &&
      (writtenText?.trim().isNotEmpty ?? false);

  bool get hasOral =>
      (oralTaskId?.isNotEmpty ?? false) && (audioFileName?.isNotEmpty ?? false);

  /// Tout ce que CE diagnostic demandait est là.
  ///
  /// 🛑 Sur le diagnostic rapide, l'écrit seul suffit : exiger un audio
  /// laisserait le visiteur bloqué sur une étape qu'on ne lui demande pas.
  bool get isComplete => hasWritten && (!oralRequired || hasOral);

  bool get isEmpty => !hasWritten && !hasOral;

  bool matches(String code, int version) =>
      diagnosticCode == code && diagnosticVersion == version;

  DiagnosticDraft copyWith({
    String? diagnosticCode,
    int? diagnosticVersion,
    String? writtenTaskId,
    String? writtenText,
    String? oralTaskId,
    String? audioFileName,
    String? audioMime,
    DateTime? savedAt,
    bool? oralRequired,
    bool clearOral = false,
  }) =>
      DiagnosticDraft(
        diagnosticCode: diagnosticCode ?? this.diagnosticCode,
        diagnosticVersion: diagnosticVersion ?? this.diagnosticVersion,
        writtenTaskId: writtenTaskId ?? this.writtenTaskId,
        writtenText: writtenText ?? this.writtenText,
        oralTaskId: clearOral ? null : (oralTaskId ?? this.oralTaskId),
        audioFileName:
            clearOral ? null : (audioFileName ?? this.audioFileName),
        audioMime: clearOral ? null : (audioMime ?? this.audioMime),
        savedAt: savedAt ?? this.savedAt,
        oralRequired: oralRequired ?? this.oralRequired,
      );
}

/// Persistance sur disque de la production du visiteur.
///
/// Même patron que `EeDraftService` pour le texte ; l'audio est **recopié**
/// depuis le dossier temporaire de l'enregistreur vers le dossier de
/// l'application, que le système ne purge pas.
class DiagnosticDraftStore {
  static const _kCode = 'diagnostic_draft_code';
  static const _kVersion = 'diagnostic_draft_version';
  static const _kWrittenTask = 'diagnostic_draft_written_task';
  static const _kWrittenText = 'diagnostic_draft_written_text';
  static const _kOralTask = 'diagnostic_draft_oral_task';
  static const _kAudioName = 'diagnostic_draft_audio_name';
  static const _kAudioMime = 'diagnostic_draft_audio_mime';
  static const _kSavedAt = 'diagnostic_draft_saved_at';
  static const _kOralRequired = 'diagnostic_draft_oral_required';

  static const _folder = 'diagnostic';

  /// Relit la production locale. L'audio n'est annoncé que si le fichier
  /// existe encore : mieux vaut redemander un enregistrement que promettre un
  /// envoi impossible.
  Future<DiagnosticDraft?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kCode);
    if (code == null) return null;
    final audioName = prefs.getString(_kAudioName);
    final audioExists = audioName != null && await _exists(audioName);
    final savedAt = prefs.getString(_kSavedAt);
    return DiagnosticDraft(
      diagnosticCode: code,
      diagnosticVersion: prefs.getInt(_kVersion) ?? 0,
      writtenTaskId: prefs.getString(_kWrittenTask),
      writtenText: prefs.getString(_kWrittenText),
      oralTaskId: audioExists ? prefs.getString(_kOralTask) : null,
      audioFileName: audioExists ? audioName : null,
      audioMime: audioExists ? prefs.getString(_kAudioMime) : null,
      savedAt: savedAt == null ? null : DateTime.tryParse(savedAt),
      // Absent = brouillon d'avant L3, donc fait sous la paire écrit + oral.
      oralRequired: prefs.getBool(_kOralRequired) ?? true,
    );
  }

  Future<DiagnosticDraft> saveWritten({
    required String diagnosticCode,
    required int diagnosticVersion,
    required String taskId,
    required String text,
    required bool oralRequired,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString(_kCode, diagnosticCode);
    await prefs.setInt(_kVersion, diagnosticVersion);
    await prefs.setString(_kWrittenTask, taskId);
    await prefs.setString(_kWrittenText, text);
    await prefs.setBool(_kOralRequired, oralRequired);
    await prefs.setString(_kSavedAt, now.toIso8601String());
    final current = await read();
    return (current ??
            DiagnosticDraft(
              diagnosticCode: diagnosticCode,
              diagnosticVersion: diagnosticVersion,
            ))
        .copyWith(
      writtenTaskId: taskId,
      writtenText: text,
      oralRequired: oralRequired,
      savedAt: now,
    );
  }

  /// Recopie [source] dans le dossier de l'app puis mémorise son nom. Le
  /// fichier d'origine (dossier temporaire de l'enregistreur) peut ensuite
  /// être supprimé sans conséquence.
  Future<DiagnosticDraft> saveOral({
    required String diagnosticCode,
    required int diagnosticVersion,
    required String taskId,
    required File source,
    String? mimeType,
  }) async {
    final directory = await _directory();
    final name = 'diagnostic_eo_${DateTime.now().millisecondsSinceEpoch}'
        '${_extension(source.path)}';
    final destination = File('${directory.path}/$name');
    await source.copy(destination.path);

    final prefs = await SharedPreferences.getInstance();
    final previous = prefs.getString(_kAudioName);
    final now = DateTime.now();
    await prefs.setString(_kCode, diagnosticCode);
    await prefs.setInt(_kVersion, diagnosticVersion);
    await prefs.setString(_kOralTask, taskId);
    await prefs.setString(_kAudioName, name);
    if (mimeType != null) await prefs.setString(_kAudioMime, mimeType);
    await prefs.setString(_kSavedAt, now.toIso8601String());
    // L'ancien enregistrement n'est effacé qu'une fois le nouveau écrit et
    // référencé : à aucun instant le visiteur n'est sans production.
    if (previous != null && previous != name) await _delete(previous);

    final current = await read();
    return (current ??
            DiagnosticDraft(
              diagnosticCode: diagnosticCode,
              diagnosticVersion: diagnosticVersion,
            ))
        .copyWith(
      oralTaskId: taskId,
      audioFileName: name,
      audioMime: mimeType,
      savedAt: now,
    );
  }

  /// Fichier audio prêt à être envoyé, ou `null` s'il a disparu.
  Future<File?> audioFile(DiagnosticDraft draft) async {
    final name = draft.audioFileName;
    if (name == null) return null;
    final file = File('${(await _directory()).path}/$name');
    return await file.exists() ? file : null;
  }

  /// N'est appelé qu'**après** l'accusé de réception des deux soumissions, ou
  /// sur demande explicite du candidat.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final audioName = prefs.getString(_kAudioName);
    if (audioName != null) await _delete(audioName);
    for (final key in const [
      _kCode,
      _kVersion,
      _kWrittenTask,
      _kWrittenText,
      _kOralTask,
      _kAudioName,
      _kAudioMime,
      _kSavedAt,
    ]) {
      await prefs.remove(key);
    }
  }

  Future<Directory> _directory() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/$_folder');
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<bool> _exists(String name) async {
    try {
      return File('${(await _directory()).path}/$name').exists();
    } catch (_) {
      return false;
    }
  }

  Future<void> _delete(String name) async {
    try {
      final file = File('${(await _directory()).path}/$name');
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Un fichier résiduel ne doit jamais bloquer le parcours.
    }
  }

  static String _extension(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    return dot <= 0 ? '.wav' : name.substring(dot);
  }
}

final diagnosticDraftStoreProvider =
    Provider<DiagnosticDraftStore>((_) => DiagnosticDraftStore());
