import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/analytics/analytics.dart';
import '../../core/api/repositories.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/models/enums.dart';
import '../../core/models/exam_slots.dart';
import '../../core/models/full_tcf_exam.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/epreuve_duration.dart';
import '../../core/utils/selected_module.dart';
import '../../core/utils/start_failure.dart';
import '../../core/widgets/paywall_sheet.dart';
import '../../core/widgets/premium_lock.dart';
import '../../core/widgets/sejour/sejour_kit.dart';
import '../../core/widgets/stat_value_card.dart';
import '../tcf_production/widgets/exam_info_chips.dart';
import 'exam_slots_data.dart';
import '../progression/progression_labels.dart';
import 'full_exams_labels.dart';
import 'tcf_full_exam_briefing_sheet.dart';
import 'widgets/exam_done_sheet.dart';

/// Liste des examens blancs TCF complets de l'utilisateur. Chaque examen
/// passé est affiché avec son niveau CECRL plancher, sa date et son statut.
/// Tap :
/// - {@code COMPLETED} / {@code PENDING_EVALUATIONS} → petite modale
///   (Refaire / Voir le détail), comme les examens module et les séries
/// - {@code IN_PROGRESS} → reprend l'examen sur le hub de progression
/// - créneau vide → briefing modal + POST `/api/full-tcf-exams`
///
/// **Distinction backend** : ces examens sont conceptuellement séparés des
/// examens module (CO seul / CE seul) — `attempts.epreuve = TCF_COMPLET`
/// vs `attempts.module_exam_question_type`. L'historique ne se mélange jamais.
final fullExamsHistoryProvider =
    FutureProvider.autoDispose<List<FullTcfExamSummary>>((ref) {
  return ref.watch(fullTcfExamRepositoryProvider).listMine(limit: 50);
});

/// Nombre de créneaux affichés d'emblée (plafond d'AFFICHAGE). Au-delà, un
/// bouton « Voir les examens X à Y » déplie le reste de la grille servie.

/// **Segment « Examens » du module TCF** (Navigation v2, phase 4b). Maquette
/// `#tcf-examens` : hero « Examen blanc complet » (épreuves lues sur le
/// miroir, durée de `epreuve_duration`, CTA vers le prochain créneau servi),
/// puis « Mes examens » — la grille SERVIE en [SfExamRow].
///
/// Gardés, hors maquette : les 3 tuiles de résultats, les repères de
/// l'examen, la grille repliée, le briefing, le paywall et la mention de
/// l'examen offert.
///
/// 🛑 **Le nombre de créneaux est celui de la grille servie**
/// (`examSlotsProvider`, `slots.length`) et le verrou de chacun est SERVI —
/// jamais une constante, jamais un rang (R7, `docs/regles/freemium.md`).
class TcfFullExamsView extends ConsumerWidget {
  const TcfFullExamsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(fullExamsHistoryProvider);
    // `watch` : la grille se relit après un achat (`accesRevisionProvider`).
    final grilleAsync = ref.watch(examSlotsProvider(EpreuveType.tcfComplet));
    final grille = grilleAsync.valueOrNull;
    bool isLocked(int slot) => grille?.isLocked(slot) ?? true;

    Future<void> startNew(int slot) async {
      // Relu au moment du geste : l'accès a pu s'ouvrir depuis le dernier
      // rendu (paywall fermé juste avant).
      final isPremium = ref.read(accesModuleProvider(AppModule.tcf));
      ref.read(selectedModuleProvider.notifier).state = AppModule.tcf;
      // Slot verrouillé (servi) → l'offre. Le slot offert reste rejouable
      // (EE/EO verrouillées au refaire, géré côté backend).
      if (isLocked(slot)) {
        showPaywallSheet(
          context,
          ref: ref,
          ctaLocation: AnalyticsCtaLocation.mockExam,
        );
        return;
      }
      showTcfFullExamBriefingSheet(
        context,
        slot: slot,
        isFreeAccount: !isPremium,
        onStart: () async {
          try {
            final exam = await ref
                .read(fullTcfExamRepositoryProvider)
                .start(slotNumber: slot);
            if (!context.mounted) return;
            ref.invalidate(fullExamsHistoryProvider);
            context.go(
              AppRoutes.tcfFullExamProgress.replaceFirst(':parentId', exam.id),
            );
          } catch (e) {
            if (!context.mounted) return;
            // Le backend applique le verrou des slots : un 403 ouvre le
            // paywall au lieu d'une erreur technique.
            showPaywallOrError(context, e,
                ctaLocation: AnalyticsCtaLocation.mockExam);
          }
        },
      );
    }

    void resume(FullTcfExamSummary exam) => context.go(
          AppRoutes.tcfFullExamProgress.replaceFirst(':parentId', exam.id),
        );

    final history = historyAsync.valueOrNull;
    final bySlot = history == null ? null : _parCreneau(history);

    Future<void> reload() async {
      ref.invalidate(fullExamsHistoryProvider);
      ref.invalidate(examSlotsProvider(EpreuveType.tcfComplet));
      await ref.read(fullExamsHistoryProvider.future);
    }

    final Widget grilleBloc;
    if (bySlot != null && grille != null) {
      grilleBloc = _SlotsSection(
        grille: grille,
        bySlot: bySlot,
        onTapDone: (exam) => _openExam(context, exam, startNew),
        onTapEmpty: startNew,
      );
    } else if (historyAsync.hasError || grilleAsync.hasError) {
      grilleBloc = SfBlockError(
        message: kExamsBlockError,
        retryLabel: kExamsRetry,
        onRetry: () => unawaited(reload()),
      );
    } else {
      grilleBloc = const SfBlockSkeleton(height: 420);
    }

    return RefreshIndicator(
      color: AppColors.moduleTcf,
      onRefresh: reload,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _Hero(
            bySlot: bySlot,
            grille: grille,
            onStart: startNew,
            onResume: resume,
            onLocked: () => showPaywallSheet(
              context,
              ref: ref,
              ctaLocation: AnalyticsCtaLocation.mockExam,
            ),
          ),
          const SizedBox(height: 14),
          _ResultStats(
            history: history ?? const [],
            total: grille?.locks.length,
          ),
          const SizedBox(height: 14),
          ExamInfoChips(
            accent: AppColors.moduleTcf,
            soft: AppColors.moduleTcfLight,
            items: [
              (icon: LucideIcons.zap, label: kExamsChipConditions),
              // Ordre de grandeur, pas un décompte : chaque épreuve porte son
              // propre chrono. La somme vient de `kExamenCompletSecondes`.
              (
                icon: LucideIcons.clock,
                label: '≈ ${epreuveDurationLabel(kExamenCompletSecondes) ?? ''}'
              ),
              (icon: LucideIcons.layoutGrid, label: tcfExamsEpreuvesChip()),
              (icon: LucideIcons.graduationCap, label: kTcfExamsChipCecrl),
            ],
          ),
          const SizedBox(height: 22),
          const SfSectionTitle(kTcfExamsSectionTitle, flush: true, lead: true),
          grilleBloc,
        ],
      ),
    );
  }

  void _openExam(
    BuildContext context,
    FullTcfExamSummary exam,
    void Function(int slot) startNew,
  ) {
    // En cours : on reprend directement le hub de progression (ce n'est pas
    // un examen « déjà fait »).
    if (exam.status == FullTcfExamStatus.inProgress) {
      context.go(
        AppRoutes.tcfFullExamProgress.replaceFirst(':parentId', exam.id),
      );
      return;
    }
    // Terminé / éval IA en cours : Refaire (nouvelle session sur le slot) ou
    // Voir le détail (bilan).
    final slot = exam.slotNumber;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => ExamDoneSheet(
        title: slot != null ? tcfExamsRowTitle(slot) : kTcfExamsHeroTitle,
        detailLabel: kExamsDoneDetail,
        resumeLabel: kExamsDoneResume,
        accent: AppColors.moduleTcf,
        onViewDetail: () {
          Navigator.of(sheetCtx).pop();
          // push (pas go) : le bilan se pose au-dessus de la liste.
          context.push(
            AppRoutes.tcfFullExamBilan.replaceFirst(':parentId', exam.id),
          );
        },
        onResume: () {
          Navigator.of(sheetCtx).pop();
          if (slot != null) startNew(slot);
        },
      ),
    );
  }
}

/// Le dernier essai par créneau (cf. V110) : historique trié chrono DESC côté
/// backend, donc le premier rencontré par créneau est le bon.
Map<int, FullTcfExamSummary> _parCreneau(List<FullTcfExamSummary> history) {
  final bySlot = <int, FullTcfExamSummary>{};
  for (final e in history) {
    final slot = e.slotNumber;
    if (slot == null) continue;
    bySlot.putIfAbsent(slot, () => e);
  }
  return bySlot;
}

/// La méta d'un créneau — miroir des mots du web (`lib/examens-blancs.ts`).
/// 🛑 L'examen offert se lit sur le verrou SERVI : un créneau ouvert se dit
/// « Disponible », jamais « Offert » sur la foi de son rang.
String _meta(FullTcfExamSummary? e, {required bool locked}) {
  if (e != null) {
    return switch (e.status) {
      FullTcfExamStatus.inProgress => kExamsMetaInProgress,
      FullTcfExamStatus.pendingEvaluations => kExamsMetaPending,
      // « partiel » : le niveau ne porte pas sur les 4 épreuves.
      FullTcfExamStatus.completed => examsMetaTcfTermine(
          e.finalCecrlLevel?.shortName ?? kProgressionVide,
          partiel: e.finalLevelPartial,
        ),
    };
  }
  return locked ? examsMetaLocked(integral: true) : kExamsMetaOpen;
}

/// **Le hero « Examen blanc complet »** : épreuves (miroir), durée, et le CTA
/// vers le créneau que la grille servie désigne — l'examen en cours à
/// reprendre, sinon le premier créneau libre et ouvert, sinon (créneaux
/// libres tous verrouillés) l'offre. Grille ou historique pas encore lus, ou
/// plus rien à faire ⇒ pas de bouton.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.bySlot,
    required this.grille,
    required this.onStart,
    required this.onResume,
    required this.onLocked,
  });

  final Map<int, FullTcfExamSummary>? bySlot;
  final ExamSlots? grille;
  final void Function(int slot) onStart;
  final void Function(FullTcfExamSummary exam) onResume;
  final VoidCallback onLocked;

  @override
  Widget build(BuildContext context) {
    String? cta;
    VoidCallback? geste;
    final faits = bySlot;
    final g = grille;
    if (faits != null && g != null) {
      final enCours = faits.values
          .where((e) => e.status == FullTcfExamStatus.inProgress)
          .firstOrNull;
      final libres = [
        for (var s = 1; s <= g.locks.length; s++)
          if (!faits.containsKey(s)) s,
      ];
      final ouvert = libres.where((s) => !g.isLocked(s)).firstOrNull;
      if (enCours != null && enCours.slotNumber != null) {
        cta = tcfExamsResumeCta(enCours.slotNumber!);
        geste = () => onResume(enCours);
      } else if (ouvert != null) {
        cta = tcfExamsStartCta(ouvert);
        geste = () => onStart(ouvert);
      } else if (libres.isNotEmpty) {
        cta = kPremiumLockCta;
        geste = onLocked;
      }
    }
    return SfHero(
      civique: false,
      label: kTcfExamsHeroLabel,
      title: kTcfExamsHeroTitle,
      sub: tcfExamsHeroSub(epreuveDurationLabel(kExamenCompletSecondes)),
      cta: cta,
      onPressed: geste,
    );
  }
}

/// 3 tuiles de résultats : meilleur niveau, dernier examen, examens terminés
/// (sur le nombre de créneaux SERVI).
class _ResultStats extends StatelessWidget {
  const _ResultStats({required this.history, required this.total});

  final List<FullTcfExamSummary> history;
  final int? total;

  @override
  Widget build(BuildContext context) {
    // Un bilan PARTIEL ne porte pas sur les 4 épreuves : il n'alimente ni un
    // « meilleur niveau », ni un « dernier examen ».
    final completed = history
        .where((e) =>
            e.status == FullTcfExamStatus.completed &&
            e.finalCecrlLevel != null &&
            !e.finalLevelPartial)
        .toList();
    NiveauCecrl? best;
    for (final e in completed) {
      final l = e.finalCecrlLevel!;
      if (best == null || l.scaleIndex > best.scaleIndex) best = l;
    }
    final last = completed.isEmpty ? null : completed.first.finalCecrlLevel;
    final doneSlots = history.map((e) => e.slotNumber).whereType<int>().toSet();

    return Row(
      children: [
        Expanded(
          child: StatValueCard(
            value: best?.shortName ?? '—',
            label: 'Meilleur niveau',
            color: AppColors.moduleTcf,
            valueSize: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatValueCard(
            value: last?.shortName ?? '—',
            label: 'Dernier examen',
            valueSize: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatValueCard(
            value: examsDoneValue(doneSlots.length, total),
            label: kExamsDoneLabel,
            color: AppColors.moduleTcf,
            valueSize: 20,
          ),
        ),
      ],
    );
  }
}

/// « Mes examens » : la grille servie, créneau par créneau, en [SfExamRow].
/// Le dernier essai occupe son créneau ; un créneau libre se lance (ou ouvre
/// l'offre s'il est verrouillé).
class _SlotsSection extends StatefulWidget {
  const _SlotsSection({
    required this.grille,
    required this.bySlot,
    required this.onTapDone,
    required this.onTapEmpty,
  });

  final ExamSlots grille;
  final Map<int, FullTcfExamSummary> bySlot;
  final void Function(FullTcfExamSummary) onTapDone;
  final void Function(int slot) onTapEmpty;

  @override
  State<_SlotsSection> createState() => _SlotsSectionState();
}

class _SlotsSectionState extends State<_SlotsSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final total = widget.grille.locks.length;
    final visibleCount =
        examsVisibles(total, widget.bySlot.length, deplie: _showAll);
    final enCours = widget.bySlot.values
        .any((e) => e.status == FullTcfExamStatus.inProgress);
    // Le créneau mis en avant : le premier libre et ouvert, sauf si un examen
    // est déjà en cours (c'est lui qu'on reprend).
    int? prochain;
    if (!enCours) {
      for (var s = 1; s <= total; s++) {
        if (!widget.bySlot.containsKey(s) && !widget.grille.isLocked(s)) {
          prochain = s;
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 1; i <= visibleCount; i++) ...[
          if (i > 1) const SizedBox(height: 10),
          _row(i, prochain),
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
                  color: AppColors.moduleTcf,
                ),
              ),
              label: const Icon(LucideIcons.chevronDown,
                  size: 16, color: AppColors.moduleTcf),
            ),
          ),
      ],
    );
  }

  Widget _row(int slot, int? prochain) {
    final exam = widget.bySlot[slot];
    final locked = exam == null && widget.grille.isLocked(slot);
    final (SfExamStatus status, String label) = switch (exam?.status) {
      FullTcfExamStatus.completed => (SfExamStatus.done, kExamsStatusDone),
      FullTcfExamStatus.inProgress => (SfExamStatus.go, kExamsStatusResume),
      FullTcfExamStatus.pendingEvaluations => (
          SfExamStatus.done,
          kExamsStatusDone
        ),
      null when locked => (SfExamStatus.locked, kExamsStatusLocked),
      null => (
          slot == prochain ? SfExamStatus.go : SfExamStatus.neutral,
          kExamsStatusStart,
        ),
    };
    return SfExamRow(
      number: slot,
      title: tcfExamsRowTitle(slot),
      meta: _meta(exam, locked: locked),
      status: status,
      statusLabel: label,
      onTap: exam != null
          ? () => widget.onTapDone(exam)
          : () => widget.onTapEmpty(slot),
    );
  }
}
