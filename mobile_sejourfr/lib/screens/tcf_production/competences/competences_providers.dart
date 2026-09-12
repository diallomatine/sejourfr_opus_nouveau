import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/repositories.dart';
import '../../../core/api/skill_repository.dart';
import '../../../core/models/skill_models.dart';
import '../../plan/learning_plan_provider.dart';
import '../../../core/utils/submission_key.dart';

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

/// Les **24 compétences d'une épreuve** (3 tâches × 8) + la progression du
/// user, en **un seul appel** (`GET /api/skills?section=EE|EO`).
///
/// Gardé en vie pour la session (`ref.keepAlive`) : c'est du contenu éditorial
/// stable, la seule part volatile est la progression — invalidée explicitement
/// par [invalidateSkillsSection] après une soumission ou une analyse. Sans ce
/// cache, changer de tâche ou de mode refetchait la liste à chaque fois.
///
/// L'échec n'est **pas** mis en cache (`link.close()`) : un « Réessayer » doit
/// pouvoir repartir sur un appel neuf.
final skillsSectionProvider = FutureProvider.autoDispose
    .family<List<SkillDto>, SkillSection>((ref, section) async {
  // 🛑 **Il porte de la donnée de COMPTE** (les productions du candidat) :
  // observer l'identité recrée le cache dès qu'on change de compte. Sans ça,
  // une reconnexion sans redémarrage montrait la progression du précédent.
  ref.watch(compteIdProvider);
  final link = ref.keepAlive();
  try {
    return await _loadSection(ref.watch(skillRepositoryProvider), section);
  } catch (_) {
    link.close();
    rethrow;
  }
});

/// Charge l'épreuve entière. Repli sur les trois `taskCode` tant que le filtre
/// `section` n'est pas déployé côté backend — **en une passe parallèle**, pas
/// un appel par bascule de pastille : le contrat « une donnée déjà chargée ne
/// se recharge pas » tient dans les deux cas.
Future<List<SkillDto>> _loadSection(
  SkillRepository repo,
  SkillSection section,
) async {
  try {
    final all = await repo.listSkillsBySection(section.wire);
    if (all.isNotEmpty) return all;
  } on ApiException catch (e) {
    // Un paramètre inconnu se traduit par un 400 (validation) ou un 404 : tout
    // le reste (401, 403, réseau) est une vraie erreur, qui doit remonter.
    if (!e.isValidation && !e.isNotFound) rethrow;
  }
  final byTask = await Future.wait(
    [for (var t = 1; t <= 3; t++) repo.listSkills(section.taskCode(t))],
  );
  return [for (final list in byTask) ...list];
}

/// Les 8 compétences d'une tâche : **filtre local** sur l'épreuve déjà
/// chargée, aucun réseau. Provider synchrone (et non `FutureProvider`) pour
/// qu'une bascule de pastille rende les données au premier frame, sans passer
/// par un état de chargement.
final skillsListProvider = Provider.autoDispose
    .family<AsyncValue<List<SkillDto>>, SkillsKey>((ref, key) {
  return ref.watch(skillsSectionProvider(key.section)).whenData((all) {
    final list = all.where((s) => s.taskCode == key.taskCode).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return list;
  });
});

/// Recharge la progression de l'épreuve. À appeler **après une soumission ou
/// une analyse** : `attemptedCount` vient de changer, laisser le cache en état
/// afficherait un « 6/20 sujets traités » périmé.
void invalidateSkillsSection(WidgetRef ref, SkillSection section) =>
    ref.invalidate(skillsSectionProvider(section));

/// Une compétence + ses 15 petits sujets avec statut.
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
  SkillSubmissionController(
    this._repo,
    this._promptId, {
    void Function()? onPlanChanged,
  })  : _onPlanChanged = onPlanChanged ?? _noop,
        super(const AsyncValue.data(SkillSubmissionState()));

  final SkillRepository _repo;
  final String _promptId;
  final void Function() _onPlanChanged;

  /// Une cle par visite du sujet. Le notifier est `autoDispose.family` : quitter
  /// l'ecran puis y revenir pour REFAIRE le sujet en tire une nouvelle, tandis
  /// qu'un renvoi apres coupure, sur le meme ecran, garde la meme — donc ne
  /// consomme pas une seconde des analyses offertes.
  final SubmissionKeys _keys = SubmissionKeys();

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
            clientSubmissionId: _keys.keyFor(_promptId),
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
            clientSubmissionId: _keys.keyFor(_promptId),
          ));

  Future<SkillAttemptDto?> _run(Future<SkillAttemptDto> Function() call) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final attempt = await call();
      _onPlanChanged();
      return SkillSubmissionState(attempt: attempt);
    });
    return state.valueOrNull?.attempt;
  }
}

final skillSubmissionProvider = StateNotifierProvider.autoDispose.family<
    SkillSubmissionController, AsyncValue<SkillSubmissionState>, String>(
  (ref, promptId) => SkillSubmissionController(
    ref.watch(skillRepositoryProvider),
    promptId,
    onPlanChanged: () =>
        ref.read(learningPlanRevisionProvider.notifier).state++,
  ),
);

void _noop() {}
