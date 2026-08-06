import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/repositories.dart';
import '../../../core/api/skill_repository.dart';
import '../../../core/models/skill_models.dart';

/// Clé value-object du provider de liste : une tâche = (épreuve, numéro).
/// `==`/`hashCode` manuels, comme partout dans le repo — sinon chaque rebuild
/// crée une nouvelle famille et refetch.
class SkillsKey {
  const SkillsKey({required this.section, required this.tacheNumero});

  final SkillSection section;
  final int tacheNumero;

  String get taskCode => section.taskCode(tacheNumero);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillsKey &&
          other.section == section &&
          other.tacheNumero == tacheNumero;

  @override
  int get hashCode => Object.hash(section, tacheNumero);
}

/// Les 8 compétences d'une tâche + la progression du user.
final skillsListProvider =
    FutureProvider.autoDispose.family<List<SkillDto>, SkillsKey>(
  (ref, key) => ref.watch(skillRepositoryProvider).listSkills(key.taskCode),
);

/// Une compétence + ses 5 petits sujets avec statut.
final skillDetailProvider =
    FutureProvider.autoDispose.family<SkillDetail, String>(
  (ref, skillId) => ref.watch(skillRepositoryProvider).getSkillDetail(skillId),
);

/// Le sujet complet (sans les références).
final skillPromptProvider =
    FutureProvider.autoDispose.family<SkillPromptDto, String>(
  (ref, promptId) => ref.watch(skillRepositoryProvider).getPrompt(promptId),
);

/// Les 3 références comparatives. 403 tant qu'aucune production n'existe.
final skillReferencesProvider =
    FutureProvider.autoDispose.family<List<SkillReferenceDto>, String>(
  (ref, promptId) => ref.watch(skillRepositoryProvider).getReferences(promptId),
);

/// Une tentative (polling du résultat).
final skillAttemptProvider =
    FutureProvider.autoDispose.family<SkillAttemptDto, String>(
  (ref, attemptId) => ref.watch(skillRepositoryProvider).getAttempt(attemptId),
);

/// Quota d'analyses IA du compte courant.
final skillAnalysisQuotaProvider =
    FutureProvider.autoDispose<SkillAnalysisQuotaDto>(
  (ref) => ref.watch(skillRepositoryProvider).analysisQuota(),
);

/// État immuable du controller de soumission d'un petit sujet.
class SkillSubmissionState {
  const SkillSubmissionState({this.attempt});

  /// La tentative créée par la dernière soumission acquittée.
  final SkillAttemptDto? attempt;

  SkillSubmissionState copyWith({SkillAttemptDto? attempt}) =>
      SkillSubmissionState(attempt: attempt ?? this.attempt);
}

/// Controller de soumission (texte ou audio) d'un petit sujet. Une instance
/// par sujet : l'écran de production en lit l'état pour son bouton et son
/// message d'erreur, et navigue vers le résultat sur la tentative renvoyée.
class SkillSubmissionController
    extends StateNotifier<AsyncValue<SkillSubmissionState>> {
  SkillSubmissionController(this._repo, this._promptId)
      : super(const AsyncValue.data(SkillSubmissionState()));

  final SkillRepository _repo;
  final String _promptId;

  Future<SkillAttemptDto?> submitText({
    required String texte,
    required bool requestAnalysis,
    SkillSelfEvaluation? selfEvaluation,
  }) =>
      _run(() => _repo.submitText(
            skillPromptId: _promptId,
            texte: texte,
            requestAnalysis: requestAnalysis,
            selfEvaluation: selfEvaluation,
          ));

  Future<SkillAttemptDto?> submitAudio({
    required File audioFile,
    required int durationSec,
    required bool requestAnalysis,
    SkillSelfEvaluation? selfEvaluation,
    String? mimeType,
  }) =>
      _run(() => _repo.submitAudio(
            skillPromptId: _promptId,
            audioFile: audioFile,
            durationSec: durationSec,
            requestAnalysis: requestAnalysis,
            selfEvaluation: selfEvaluation,
            mimeType: mimeType,
          ));

  Future<SkillAttemptDto?> _run(Future<SkillAttemptDto> Function() call) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final attempt = await call();
      return SkillSubmissionState(attempt: attempt);
    });
    return state.valueOrNull?.attempt;
  }
}

final skillSubmissionProvider = StateNotifierProvider.autoDispose.family<
    SkillSubmissionController, AsyncValue<SkillSubmissionState>, String>(
  (ref, promptId) =>
      SkillSubmissionController(ref.watch(skillRepositoryProvider), promptId),
);
