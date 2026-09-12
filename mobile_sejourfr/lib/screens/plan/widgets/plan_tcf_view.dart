import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/models/diagnostic_models.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/skill_models.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/list_group.dart';
import '../../../core/widgets/premium_lock.dart';
import '../../../core/widgets/paywall_context.dart';
import '../../../core/widgets/sejour/sejour_kit.dart';
import '../plan_actions.dart';
import '../plan_groups.dart';
import '../plan_labels.dart';
import '../plan_milestone_labels.dart';
import '../plan_milestone_launcher.dart';
import '../plan_task_path.dart';

/// **Le plan TCF**, dans l'ordre de la maquette : d'où l'on part, ce qu'on fait
/// maintenant, le parcours de la tâche en cours, les priorités, ce qui est
/// acquis, ce qui a bougé.
///
/// 🛑 **Rien n'est recalculé.** Les priorités sont ordonnées serveur, le
/// groupement « épreuve → tâche » est une vue de `domaines[]`
/// ([planPriorityGroups]), le compteur d'étape est lu sur `domaines[].taches[]`,
/// et chaque verrou vient d'un `locked` **servi** — jamais du rang d'une ligne.
///
/// Deux mises en page, une seule lecture des données : un compte **sans accès
/// TCF** voit son constat entier (objectif, priorités, première étape) et la
/// porte d'abonnement ; un abonné voit en plus ce qu'il peut lancer.
class PlanTcfView extends ConsumerWidget {
  const PlanTcfView({
    super.key,
    required this.plan,
    required this.objective,
    this.trailing = const <Widget>[],
  });

  final LearningPlan plan;
  final TargetLevel? objective;

  /// Ce qui se pose **après** le contenu du Plan, dans le MÊME défilement —
  /// aujourd'hui la carte « Affiner votre Plan ».
  ///
  /// 🛑 Un slot, pas un widget imposé : ce que le Plan **est** ne dépend pas de
  /// ce qui l'accompagne, et deux listes qui recopieraient la même carte
  /// auraient fini par en montrer deux versions. Même motif que les slots
  /// `leading`/`trailing` de `DiagnosticResultView`, pour la même raison : cette
  /// vue **EST** la `ListView`, imbriquer deux scrollables était le risque.
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final hasTcf = auth is AuthAuthenticated && auth.user.hasTcf;

    if (!hasTcf) {
      return Column(
        children: [
          Expanded(child: ListView(children: _free(context, ref))),
          SfStickyBar(
            child: SfButton(
              label: _unlockCta(objective),
              caption: kPlanUnlockCaption,
              onPressed: () => unawaited(showTcfLockPaywall(
                context,
                ref: ref,
                ctaLocation: AnalyticsCtaLocation.lockedPlan,
                origin: PaywallOrigin.plan,
              )),
            ),
          ),
        ],
      );
    }
    return ListView(children: _premium(context, ref));
  }

  /* ------------------------------------------------------------- abonné --- */

  List<Widget> _premium(BuildContext context, WidgetRef ref) {
    final changes = plan.recentChanges;
    final milestone = plan.milestone;

    return <Widget>[
      SfTop(kicker: planTopKicker(objective), title: kPlanTitle),
      const SizedBox(height: 14),
      _goalStrip(context),
      SfSection(
        title: kPlanNowTitle,
        flush: true,
        child: _nowCard(context, ref, free: false),
      ),
      ..._pathSection(),
      ..._prioritiesSection(free: false),
      ..._doneSection(),
      ..._changesSection(changes),
      if (milestone != null) _milestoneSection(context, ref, milestone),
      if (plan.domainesAEvaluer.isNotEmpty) _assessmentSection(context),
      _links(context),
      ...trailing,
      const SizedBox(height: 28),
    ];
  }

  /* -------------------------------------------------------- sans accès ---- */

  List<Widget> _free(BuildContext context, WidgetRef ref) => <Widget>[
        SfTop(kicker: kPlanTopKickerFree, title: planTitleFree(objective)),
        const SizedBox(height: 14),
        _goalStrip(context, engineLine: false),
        ..._prioritiesSection(free: true),
        SfSection(
          title: kPlanFreeFirstStepTitle,
          flush: true,
          child: _nowCard(context, ref, free: true),
        ),
        ..._freePathSection(),
        const SfSection(
          flush: true,
          child: SfUnlockHero(
            title: kPlanUnlockHeroTitle,
            text: kPlanUnlockHeroText,
            checks: kPlanUnlockHeroChecks,
          ),
        ),
        ...trailing,
        const SizedBox(height: 24),
      ];

  /* ------------------------------------------------------------ blocs ----- */

  /// « Niveau actuel → objectif ». Les deux paliers sont **servis** ; absents,
  /// ils s'écrivent « — » : *null = inconnu, jamais mauvais*.
  Widget _goalStrip(BuildContext context, {bool engineLine = true}) {
    final cycle = plan.cycle;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SfGoalStrip(
            current: cycle?.startingLevel?.displayName ?? kPlanGoalUnknown,
            goal: objective?.wire ?? kPlanGoalUnknown,
          ),
          if (objective == null) ...[
            const SizedBox(height: 10),
            SfButton(
              label: kPlanGoalPick,
              variant: SfButtonVariant.line,
              onPressed: () => context.push(AppRoutes.targetPath),
            ),
          ],
          if (engineLine) ...[
            const SizedBox(height: 10),
            const SfTiny(kPlanEngineLine),
            if (cycle != null) ...[
              const SizedBox(height: 6),
              SfTiny(planCycleStateText(cycle.state)),
            ],
          ],
        ],
      ),
    );
  }

  /// La carte d'action. [free] choisit la **mise en page** ; ce qui décide du
  /// bouton ou des cadenas reste le `locked` **servi** sur la priorité et son
  /// exercice.
  Widget _nowCard(BuildContext context, WidgetRef ref, {required bool free}) {
    final priority = plan.currentPriority;
    if (priority == null) {
      return const SfNoteCard(
        icon: LucideIcons.circleCheck,
        title: kPlanNowEmptyTitle,
        child: SfTiny(kPlanSeanceEmpty),
      );
    }

    final exercise = priority.recommendedExercise;
    final epreuve = planEpreuveOfSection(priority.section);
    final task = SkillTaskCode.fromSkillCode(priority.skillCode);
    final level = planSkillTargetLevel(plan, priority.skillId);
    final subtitle = planNowSubtitle(task: task, level: level);
    final lines = planPriorityLines(priority);
    final blocked = priority.locked || (exercise?.locked ?? false);

    final meta = <SfMeta>[];
    if (exercise != null && exercise.estimatedMinutes > 0) {
      meta.add(SfMeta(
        LucideIcons.clock,
        priority.stepPromptCount > 0 &&
                exercise.kind == PlanExerciseKind.microTraining
            ? '${priority.stepPromptCount} sujets · ≈ ${exercise.estimatedMinutes} min'
            : '≈ ${exercise.estimatedMinutes} min',
      ));
    }
    final kind = planExerciseKindLabel(
      exercise?.kind,
      questionCount: exercise?.questionCount,
    );
    if (kind != null) meta.add(SfMeta(LucideIcons.target, kind));

    final card = SfNowCard(
      icon: planDomainIcon(epreuve),
      title: epreuve == null ? priority.title : planDomainLabel(epreuve),
      subtitle: subtitle.isEmpty ? null : subtitle,
      badge: planPriorityRankTag(1),
      objectiveLabel: planNowObjectiveLabel(exercise),
      objective: priority.title,
      meta: meta,
      action: free && blocked
          ? null
          : SfButton(
              label: blocked
                  ? kPlanNowLockedCta
                  : exercise?.kind == PlanExerciseKind.reassessment
                      ? kPlanNowValidateCta
                      : kPlanNowStartCta,
              onPressed: exercise == null
                  ? null
                  : () => unawaited(openPlanExercise(
                        context,
                        ref,
                        exercise,
                        masteryBefore: priority.masteryState,
                      )),
            ),
      caption: lines.isEmpty ? null : lines.join(' '),
    );

    // 🛑 La liste des cadenas ne s'affiche que sur un verrou **servi**. Un
    // compte sans accès dont le serveur ouvre quand même la première étape
    // garde son bouton : on n'invente pas un cadenas à partir d'un statut.
    if (!free || !blocked) return card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        const SizedBox(height: sfGap),
        SfCard(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final label in kPlanFreeStepLocks) SfLockItem(label: label),
            ],
          ),
        ),
      ],
    );
  }

  /// « Votre parcours — Tâche 3 ».
  ///
  /// 🛑 **Le compteur est lu, pas compté** : `observedSkills / totalSkills` du
  /// DTO de la tâche. Sans tâche servie (compréhension, ou code inattendu), le
  /// bloc **disparaît** — on n'invente pas un parcours.
  List<Widget> _pathSection() {
    final steps = _taskSteps();
    if (steps == null) return const <Widget>[];
    return <Widget>[
      SfSection(
        title: planPathSectionTitle(steps.task),
        flush: true,
        child: SfPathCard(
          currentLabel: plan.currentPriority?.title ?? steps.task.title,
          counterLabel: planPathCounter(steps.dto),
          steps: planPathSteps(plan, steps),
        ),
      ),
    ];
  }

  /// Le même parcours pour un compte sans accès : chaque étape **servie comme
  /// verrouillée** porte son cadenas, les autres restent des étapes.
  List<Widget> _freePathSection() {
    final steps = _taskSteps();
    if (steps == null) return const <Widget>[];
    return <Widget>[
      SfSection(
        title: kPlanFreePathTitle,
        flush: true,
        child: SfCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < steps.skills.length; i++)
                if (steps.skills[i].locked)
                  SfLockRow(
                    rank: i + 1,
                    label: steps.skills[i].title,
                    last: i == steps.skills.length - 1,
                  )
                else
                  SfPathRow(
                    label: steps.skills[i].title,
                    state: planSkillStepState(plan, steps.skills[i]),
                  ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _prioritiesSection({required bool free}) {
    final groups = planPriorityGroups(plan);
    if (groups.isEmpty) return const <Widget>[];
    final shown = groups.take(3).toList(growable: false);
    final done = _completedIds();
    return <Widget>[
      SfSection(
        // Un compte sans accès ne lit pas encore un objectif chiffré : son
        // bloc s'appelle simplement « Vos priorités », comme la maquette.
        title: free ? kPlanPrioritiesShort : planPrioritiesSectionTitle(objective),
        child: SfStack(
          children: [
            for (var i = 0; i < shown.length; i++)
              _priorityCard(shown[i], i + 1, done, free: free),
          ],
        ),
      ),
    ];
  }

  Widget _priorityCard(
    PlanPriorityGroup group,
    int rank,
    Set<String> done, {
    required bool free,
  }) {
    final dto = group.task == null ? null : _taskDto(group.task!);
    final statuses = planStatusSummary(group.rows.map((row) => row.status));
    return SfPrio(
      rank: rank,
      tag: planPriorityRankTag(rank),
      title: planPriorityGroupTitle(
        epreuve: group.epreuve,
        task: group.task,
        context: group.context,
      ),
      text: dto != null
          ? planTaskObservedLabel(dto)
          : (statuses.isEmpty ? null : statuses),
      child: free
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dto != null && dto.totalSkills > 0)
                  SfProgressMini(
                    ratio: dto.observedSkills / dto.totalSkills,
                    semanticsLabel: planTaskObservedLabel(dto),
                  ),
                for (final row in group.visibleRows)
                  SfSkillRow(label: row.title, state: _rowState(row, done)),
                if (group.hiddenCount > 0) ...[
                  const SizedBox(height: 6),
                  SfTiny(planGroupMoreLabel(group.hiddenCount)),
                ],
              ],
            ),
    );
  }

  List<Widget> _doneSection() {
    if (plan.completedSteps.isEmpty) return const <Widget>[];
    return <Widget>[
      SfSection(
        title: kPlanDoneTitle,
        flush: true,
        child: SfCard(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final step in plan.completedSteps)
                SfCheckRow(label: planDoneRowLabel(step), large: true),
            ],
          ),
        ),
      ),
    ];
  }

  /// L'encart vert. 🛑 **`recentChanges == null` est le cas normal** : le bloc
  /// disparaît, il ne s'affiche pas vide. Seules les transitions que le serveur
  /// dit **positives** (`progress`) y entrent — une régression n'est pas une
  /// progression détectée.
  List<Widget> _changesSection(PlanRecentChanges? changes) {
    if (changes == null || changes.isEmpty) return const <Widget>[];
    final progress = changes.transitions
        .where((transition) => transition.progress)
        .toList(growable: false);
    final next = planChangesNext(changes);
    if (progress.isEmpty && next == null) return const <Widget>[];
    return <Widget>[
      SfSection(
        flush: true,
        child: SfCard(
          variant: SfCardVariant.ok,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SfLabel(kPlanChangesTitle, color: AppColors.greenDark),
              const SizedBox(height: 4),
              for (final transition in progress)
                SfCheckRow(
                  label:
                      '${transition.title} — ${planTransitionLabel(transition)}',
                  large: true,
                ),
              if (next != null) ...[
                const SizedBox(height: 8),
                SfInsight(next),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  /// Le **jalon** : un examen blanc que le serveur juge mérité. Il n'a aucun
  /// équivalent dans la maquette, et il porte une information qu'elle ne couvre
  /// pas — d'où sa place, en fin d'écran.
  Widget _milestoneSection(
    BuildContext context,
    WidgetRef ref,
    PlanMilestone milestone,
  ) {
    return SfSection(
      title: kPlanMilestoneSectionTitle,
      flush: true,
      child: SfNoteCard(
        icon: LucideIcons.graduationCap,
        title: milestone.displayTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SfTiny(milestone.displayText),
            const SizedBox(height: 4),
            SfTiny(milestone.displayMeta),
            const SizedBox(height: 12),
            SfButton(
              label:
                  milestone.locked ? kPlanMilestoneLockedCta : kPlanMilestoneCta,
              variant: SfButtonVariant.blue,
              onPressed: () => unawaited(
                milestone.locked
                    ? showTcfLockPaywall(
                        context,
                        ref: ref,
                        ctaLocation: AnalyticsCtaLocation.lockedPlan,
                        origin: PaywallOrigin.plan,
                      )
                    : startPlanMilestone(context, ref, milestone),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// « Compléter mon profil » — par quoi mesurer les domaines **jamais
  /// évalués**. Absent de la maquette, conservé : sans lui, un domaine non
  /// mesuré n'a aucune porte.
  Widget _assessmentSection(BuildContext context) {
    return SfSection(
      title: kPlanCompleteProfileTitle,
      flush: true,
      child: SfCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SfTiny(kPlanCompleteProfileText),
            const SizedBox(height: 10),
            for (final assessment in plan.domainesAEvaluer) ...[
              SfExamRow(
                icon: planDomainIcon(assessment.epreuve),
                title: planDomainLabel(assessment.epreuve),
                subtitle: planAssessmentMeta(assessment),
              ),
              const SizedBox(height: 8),
              SfButton(
                label: planAssessmentCta(assessment),
                variant: SfButtonVariant.line,
                onPressed: () => openPlanAssessment(context, assessment),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  /// Les accès secondaires du Plan. La maquette n'en montre aucun : ils restent
  /// parce que ce sont les **seules** portes vers le référentiel complet, la
  /// progression par domaine et le diagnostic.
  Widget _links(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, sfSectionGap, 16, 0),
      child: ListGroup(
        children: [
          ListRow(
            icon: LucideIcons.layoutGrid,
            iconBg: AppColors.surface2,
            iconColor: AppColors.muted,
            title: kPlanAllSkillsTitle,
            sub: kPlanAllSkillsSub,
            onTap: () => context.push(AppRoutes.planSkills),
          ),
          ListRow(
            icon: LucideIcons.trendingUp,
            iconBg: AppColors.surface2,
            iconColor: AppColors.muted,
            title: planProgressTitle(objective),
            sub: planProfileCoverage(plan.cycle, plan.domaines.length),
            onTap: () => context.push(AppRoutes.planProgress),
          ),
          ListRow(
            icon: LucideIcons.graduationCap,
            iconBg: AppColors.surface2,
            iconColor: AppColors.muted,
            title: kPlanExamsTitle,
            sub: kPlanExamsSub,
            onTap: () => context.go(AppRoutes.examens),
          ),
          ListRow(
            icon: LucideIcons.clipboardCheck,
            iconBg: AppColors.surface2,
            iconColor: AppColors.muted,
            title: kPlanDiagnosticTitle,
            sub: kPlanDiagnosticSub,
            onTap: () => context.push(AppRoutes.diagnostic),
          ),
        ],
      ),
    );
  }

  /* ------------------------------------------------------------ lecture --- */

  Set<String> _completedIds() =>
      plan.completedSteps.map((step) => step.skillId).toSet();

  SfStepState _rowState(PlanPriorityGroupRow row, Set<String> done) {
    if (row.skillId == plan.currentPriority?.skillId) return SfStepState.now;
    if (done.contains(row.skillId)) return SfStepState.done;
    return row.status == PlanRowStatus.solide
        ? SfStepState.done
        : SfStepState.todo;
  }

  PlanDomainTask? _taskDto(SkillTaskCode task) => planTaskDto(plan, task);

  /// Le parcours de la tâche en cours. 🛑 **La dérivation vit dans
  /// [planTaskPath]**, partagée avec le bloc « Votre Plan » de l'Accueil : deux
  /// copies auraient fini par cocher deux étapes différentes.
  PlanTaskPath? _taskSteps() => planTaskPath(plan);
}

/// Le geste de la barre basse : il nomme le palier visé quand il est connu,
/// jamais un palier deviné. Le libellé de base reste celui de
/// [kUnlockPlanCta] — l'app n'a qu'une formule pour cette action.
String _unlockCta(TargetLevel? objective) =>
    objective == null ? kUnlockPlanCta : '$kUnlockPlanCta ${objective.wire}';

