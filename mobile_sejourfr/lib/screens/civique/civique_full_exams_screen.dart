import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/analytics/analytics.dart';
import '../../core/api/repositories.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/attempt_summary.dart';
import '../../core/models/enums.dart';
import '../../core/models/exam_slots.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/civique_examen.dart';
import '../../core/utils/selected_module.dart';
import '../../core/utils/start_failure.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import '../../core/widgets/stat_value_card.dart';
import '../module_detail/civique_exam_briefing_sheet.dart';
import '../module_detail/exam_slots_data.dart';
import '../module_detail/full_exams_labels.dart';
import '../progression/progression_labels.dart';
import '../module_detail/widgets/exam_done_sheet.dart';
import '../tcf_production/widgets/exam_info_chips.dart';

/// Historique des examens blancs civique GLOBAUX (40 Q tous thèmes). On
/// charge tous les `MOCK_EXAM module=CIVIQUE` puis on filtre côté client
/// pour ne garder QUE les globaux (`!isThemeScoped`, c.-à-d. `lotThemeId`
/// null). Le backend ne sait pas filtrer « globaux uniquement » en un
/// paramètre — l'inverse `themeId=` filtre par thème, ici on veut le
/// complément.
final civiqueGlobalExamsProvider =
    FutureProvider.autoDispose<List<AttemptSummary>>((ref) async {
  final all = await ref.read(attemptsRepositoryProvider).listMine(
        type: AttemptType.mockExam,
        module: AppModule.civique,
        limit: 50,
      );
  return all.where((a) => !a.isThemeScoped).toList();
});

/// **Segment « Examens » du module Civique** (Navigation v2, phase 4b) — les
/// examens blancs civiques GLOBAUX. Maquette `#civique-examens` : hero rouge
/// « Examen blanc civique » (format légal lu sur `CivicExamFormat`, nombre de
/// thèmes servi), puis « Historique » — la grille SERVIE en [SfExamRow].
///
/// Gardés, hors maquette : les 3 tuiles, les repères de l'examen, la grille
/// repliée, la feuille d'introduction et le paywall.
///
/// 🛑 Nombre de créneaux = la grille servie (`slots.length`), verrou SERVI
/// par créneau ; « réussi » n'est jamais déduit d'un score (aucun
/// `seuilAtteint` n'est servi sur cette liste, donc rien n'est dit).
class CiviqueFullExamsView extends ConsumerStatefulWidget {
  const CiviqueFullExamsView({super.key});

  @override
  ConsumerState<CiviqueFullExamsView> createState() =>
      _CiviqueFullExamsViewState();
}

class _CiviqueFullExamsViewState extends ConsumerState<CiviqueFullExamsView> {
  bool _showAll = false;
  bool _starting = false;

  /// 🛑 **Le verrou est SERVI** créneau par créneau ([examSlotsProvider],
  /// grille `CIVIQUE`) et opposable (403) : l'écran le lit, il ne le déduit
  /// jamais du rang ni de l'historique. Le `build` l'observe en `watch` (le
  /// paywall est poussé AU-DESSUS de cet écran, qui reste monté) ; ce geste le
  /// relit au moment du tap. Le slot offert est rejouable : c'est le gabarit
  /// gratuit `civique-decouverte`, que le serveur joue pour un compte sans
  /// accès.
  bool _isLocked(int slot) =>
      ref
          .read(examSlotsProvider(EpreuveType.civique))
          .valueOrNull
          ?.isLocked(slot) ??
      true;

  Future<void> _startExam({required int slotNumber}) async {
    if (_starting) return;
    setState(() => _starting = true);
    ref.read(selectedModuleProvider.notifier).state = AppModule.civique;
    try {
      final attempt = await ref.read(attemptsRepositoryProvider).start(
            StartAttemptRequest(
              type: AttemptType.mockExam,
              module: AppModule.civique,
              slotNumber: slotNumber,
            ),
          );
      if (!mounted) return;
      ref.invalidate(civiqueGlobalExamsProvider);
      context.push(AppRoutes.runner.replaceFirst(':attemptId', attempt.id));
    } catch (e) {
      if (!mounted) return;
      showPaywallOrError(context, e,
          ctaLocation: AnalyticsCtaLocation.mockExam);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _openBriefing({required int slotNumber}) {
    if (_starting) return;
    if (_isLocked(slotNumber)) {
      showPaywallSheet(
        context,
        ref: ref,
        ctaLocation: AnalyticsCtaLocation.mockExam,
      );
      return;
    }
    showCiviqueExamBriefingSheet(
      context,
      onStart: () => _startExam(slotNumber: slotNumber),
    );
  }

  /// Pousse le rapport Q-par-Q (`ExamReportScreen`) — même destination
  /// que « Voir le détail » des autres pages d'examens.
  void _openExamReport(AttemptSummary attempt) {
    context.push(AppRoutes.examReport.replaceFirst(':attemptId', attempt.id));
  }

  void _showExamSheet(AttemptSummary attempt, int slot) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => ExamDoneSheet(
        title: civiqueExamsRowTitle(slot),
        detailLabel: kExamsDoneDetail,
        resumeLabel: kExamsDoneResume,
        accent: AppColors.moduleCivique,
        onViewDetail: () {
          Navigator.of(sheetCtx).pop();
          _openExamReport(attempt);
        },
        onResume: () {
          Navigator.of(sheetCtx).pop();
          _openBriefing(slotNumber: slot);
        },
      ),
    );
  }

  Future<void> _reload() async {
    ref.invalidate(civiqueGlobalExamsProvider);
    ref.invalidate(examSlotsProvider(EpreuveType.civique));
    await ref.read(civiqueGlobalExamsProvider.future);
  }

  void _paywall() => showPaywallSheet(
        context,
        ref: ref,
        ctaLocation: AnalyticsCtaLocation.mockExam,
      );

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(civiqueGlobalExamsProvider);
    final grilleAsync = ref.watch(examSlotsProvider(EpreuveType.civique));
    final grille = grilleAsync.valueOrNull;
    final themes = ref.watch(dashboardProvider).valueOrNull?.civique.length;
    final history = async.valueOrNull;
    final bySlot = history == null ? null : _parCreneau(history);

    final Widget grilleBloc;
    if (bySlot != null && grille != null) {
      grilleBloc = _slots(grille, bySlot);
    } else if (async.hasError || grilleAsync.hasError) {
      grilleBloc = SfBlockError(
        message: kExamsBlockError,
        retryLabel: kExamsRetry,
        onRetry: () => unawaited(_reload()),
      );
    } else {
      grilleBloc = const SfBlockSkeleton(height: 420);
    }

    return RefreshIndicator(
      color: AppColors.moduleCivique,
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _hero(grille, bySlot, themes),
          const SizedBox(height: 14),
          _stats(history ?? const [], bySlot ?? const {}, grille),
          const SizedBox(height: 14),
          const ExamInfoChips(
            accent: AppColors.moduleCivique,
            soft: AppColors.moduleCiviqueLight,
            items: [
              (icon: LucideIcons.zap, label: kExamsChipConditions),
              (
                icon: LucideIcons.clock,
                label: '${CivicExamFormat.dureeMinutes} minutes'
              ),
              (
                icon: LucideIcons.target,
                label:
                    'Seuil ${CivicExamFormat.seuil}/${CivicExamFormat.questions}'
              ),
              (
                icon: LucideIcons.fileText,
                label: '${CivicExamFormat.questions} questions'
              ),
            ],
          ),
          const SizedBox(height: 22),
          const SfSectionTitle(kCiviqueExamsSectionTitle,
              flush: true, lead: true),
          grilleBloc,
        ],
      ),
    );
  }

  /// Le dernier essai FINI par créneau (V110) : historique chrono DESC, donc
  /// le premier rencontré par créneau est le bon.
  Map<int, AttemptSummary> _parCreneau(List<AttemptSummary> history) {
    final bySlot = <int, AttemptSummary>{};
    for (final a in history) {
      if (!a.isFinished || a.slotNumber == null) continue;
      bySlot.putIfAbsent(a.slotNumber!, () => a);
    }
    return bySlot;
  }

  /// **Le hero rouge** : CTA vers le premier créneau libre et ouvert de la
  /// grille servie, sinon (créneaux libres tous verrouillés) l'offre ; grille
  /// pas encore lue ou plus rien à faire ⇒ pas de bouton.
  Widget _hero(
    ExamSlots? grille,
    Map<int, AttemptSummary>? bySlot,
    int? themes,
  ) {
    VoidCallback? geste;
    var cta = kCiviqueExamsCta;
    if (grille != null && bySlot != null) {
      final libres = [
        for (var s = 1; s <= grille.locks.length; s++)
          if (!bySlot.containsKey(s)) s,
      ];
      final ouvert = libres.where((s) => !grille.isLocked(s)).firstOrNull;
      if (ouvert != null) {
        geste = () => _openBriefing(slotNumber: ouvert);
      } else if (libres.isNotEmpty) {
        geste = _paywall;
        cta = kCiviqueExamsHeroPass;
      }
    }
    return SfHero(
      civique: true,
      label: kCiviqueExamsHeroLabel,
      title: kCiviqueExamsHeroTitle,
      sub: civiqueExamsHeroSub(
        questions: CivicExamFormat.questions,
        seuil: CivicExamFormat.seuil,
        themes: themes,
      ),
      stat: (
        value: '${CivicExamFormat.questions}',
        label: kCiviqueExamsQuestionsStat,
      ),
      cta: cta,
      onPressed: geste,
    );
  }

  /// Les 3 tuiles. ⚠️ La 3ᵉ disait « Progression » en % de créneaux faits sur
  /// 20 : un second pourcentage civique, qui n'est pas l'avancement du
  /// parcours (`avancementSeriesCivique`). Elle compte désormais les examens
  /// terminés sur les créneaux servis, comme la tuile TCF.
  Widget _stats(
    List<AttemptSummary> history,
    Map<int, AttemptSummary> bySlot,
    ExamSlots? grille,
  ) {
    final scores = bySlot.values
        .where((a) => a.score != null && a.totalQuestions > 0)
        .toList();
    final bestScore = scores.isEmpty
        ? null
        : scores.map((a) => a.score!).reduce((a, b) => a > b ? a : b);
    final maxPossible = scores.isEmpty
        ? CivicExamFormat.questions
        : scores.first.totalQuestions;
    // Historique trié chrono DESC → le premier fini = dernier examen passé.
    final lastScore = history
        .where((a) => a.isFinished && a.score != null && a.totalQuestions > 0)
        .map((a) => a.score!)
        .firstOrNull;
    return Row(
      children: [
        Expanded(
          child: StatValueCard(
            value: bestScore == null ? '—' : '$bestScore/$maxPossible',
            label: 'Meilleur score',
            color: AppColors.moduleCivique,
            valueSize: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatValueCard(
            value: lastScore == null ? '—' : '$lastScore/$maxPossible',
            label: 'Dernier examen',
            valueSize: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatValueCard(
            value: examsDoneValue(bySlot.length, grille?.locks.length),
            label: kExamsDoneLabel,
            color: AppColors.moduleCivique,
            valueSize: 20,
          ),
        ),
      ],
    );
  }

  /// « Historique » : la grille servie, créneau par créneau.
  Widget _slots(ExamSlots grille, Map<int, AttemptSummary> bySlot) {
    final total = grille.locks.length;
    final visibleCount =
        examsVisibles(total, bySlot.length, deplie: _showAll);
    int? prochain;
    for (var s = 1; s <= total; s++) {
      if (!bySlot.containsKey(s) && !grille.isLocked(s)) {
        prochain = s;
        break;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 1; i <= visibleCount; i++) ...[
          if (i > 1) const SizedBox(height: 10),
          _buildSlot(i, bySlot, grille, prochain),
        ],
        if (visibleCount < total)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: TextButton.icon(
              onPressed: () => setState(() => _showAll = true),
              icon: Text(
                examsShowMoreLabel(visibleCount + 1, total),
                style: AppFonts.ui(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppColors.moduleCivique,
                ),
              ),
              label: const Icon(LucideIcons.chevronDown,
                  size: 16, color: AppColors.moduleCivique),
            ),
          ),
      ],
    );
  }

  Widget _buildSlot(
    int number,
    Map<int, AttemptSummary> bySlot,
    ExamSlots grille,
    int? prochain,
  ) {
    final attempt = bySlot[number];
    final done = attempt != null;
    final lockedEmpty = !done && grille.isLocked(number);

    // Miroir des mots du web (`lib/examens-blancs.ts`). 🛑 Un créneau ouvert
    // se dit « Disponible » : l'examen offert se lit sur le verrou SERVI,
    // jamais sur le rang 1.
    final String subtitle = done
        ? examsMetaCiviqueTermine(attempt.score == null
            ? kProgressionVide
            : '${attempt.score}/${attempt.totalQuestions > 0 ? attempt.totalQuestions : CivicExamFormat.questions}')
        : lockedEmpty
            ? examsMetaLocked(integral: false)
            : kExamsMetaOpen;

    final (SfExamStatus status, String label) = done
        ? (SfExamStatus.done, kExamsStatusDone)
        : lockedEmpty
            ? (SfExamStatus.locked, kExamsStatusLocked)
            : (
                number == prochain ? SfExamStatus.go : SfExamStatus.neutral,
                kExamsStatusStart,
              );

    return SfExamRow(
      civique: true,
      number: number,
      title: civiqueExamsRowTitle(number),
      meta: subtitle,
      status: status,
      statusLabel: label,
      onTap: done
          ? () => _showExamSheet(attempt, number)
          : () => lockedEmpty ? _paywall() : _openBriefing(slotNumber: number),
    );
  }
}
