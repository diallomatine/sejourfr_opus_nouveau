import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/api/audience_repository.dart';
import '../../core/api/repositories.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/skill_models.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/target_level_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/router/route_observer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/skill_progress.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/gradient_hero.dart';
import '../../core/widgets/premium_lock.dart';
import '../../core/widgets/pressable_card.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/skill_mastery_tag.dart';
import '../../core/widgets/screen_header.dart';
import '../tcf_production/competences/competences_nav.dart';
import '../tcf_production/recommended_exercise_launcher.dart';
import '../tcf_production/tcf_production_module.dart';
import 'learning_plan_provider.dart';
import 'plan_milestone_card.dart';
import 'plan_milestone_labels.dart';

/// Plan adaptatif calculé par le serveur à partir du diagnostic et des
/// activités productives récentes. L'écran ne recalcule ni priorité ni statut.
///
/// Colonne vertébrale : **le chemin en étapes numérotées** (« Votre
/// parcours »). Une priorité n'est pas une carte de plus dans une pile, c'est
/// une étape qui vient après la précédente et avant la réévaluation.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> with RouteAware {
  PageRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_track(AudienceEvent.planOpened));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _route) {
      if (_route != null) appRouteObserver.unsubscribe(this);
      _route = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    // Une production terminée au-dessus de cette page peut avoir changé le
    // plan. Le retour est le moment fiable pour récupérer le calcul final.
    ref.invalidate(learningPlanProvider);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _track(AudienceEvent event) async {
    try {
      await ref
          .read(audienceRepositoryProvider)
          .track(path: '/plan', event: event);
    } catch (_) {
      // Une statistique agrégée ne doit jamais bloquer le plan.
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(learningPlanProvider);
    await ref.read(learningPlanProvider.future);
  }

  void _openRecommended(PlanRecommendedExercise exercise) {
    // Un exercice verrouillé n'est jamais « démarré » (l'événement d'audience
    // mentirait) : c'est le lanceur partagé qui tranche, ici comme sur le
    // résultat du diagnostic, et qui sait où mènent ses deux natures
    // (micro-sujet ou vérification en situation).
    if (!exercise.locked) {
      unawaited(_track(AudienceEvent.planRecommendedExerciseStarted));
    }
    unawaited(openRecommendedExercise(context, ref, exercise));
  }

  /// Ouverte **depuis le Plan**, une compétence encore prioritaire s'affiche à
  /// l'échelle de son **étape** (les 5 sujets, « 2/5 »), pas de la compétence
  /// entière (« 1/15 »). Sortie des priorités — ce que fait le serveur dès
  /// qu'une vérification en situation a réussi —, l'écran retombe
  /// **silencieusement** sur la fiche complète.
  void _openSkill(String skillId, SkillSection section) {
    context.push(
      competenceDetailPath(_moduleOf(section), skillId, planStep: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(learningPlanProvider);
    final objective = ref.watch(userTargetLevelProvider)?.wire;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenHeader(
              title: 'Mon plan',
              sub: 'Vos priorités, mises à jour au fil de vos entraînements',
              large: true,
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.blue,
                onRefresh: _refresh,
                child: plan.when(
                  loading: () => const _LoadingPlan(),
                  error: (error, _) => _PlanError(
                    message: ApiClient.toApiException(error).message,
                    onRetry: () => ref.invalidate(learningPlanProvider),
                  ),
                  data: (value) => _PlanContent(
                    plan: value,
                    objective: objective,
                    onOpenDiagnostic: () => context.push(AppRoutes.diagnostic),
                    onOpenRecommended: _openRecommended,
                    onOpenSkill: _openSkill,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TcfProductionModule _moduleOf(SkillSection section) =>
    section == SkillSection.eo
        ? TcfProductionModule.eo
        : TcfProductionModule.ee;

typedef SkillOpener = void Function(String skillId, SkillSection section);

class _PlanContent extends StatelessWidget {
  const _PlanContent({
    required this.plan,
    required this.objective,
    required this.onOpenDiagnostic,
    required this.onOpenRecommended,
    required this.onOpenSkill,
  });

  final LearningPlan plan;
  final String? objective;
  final VoidCallback onOpenDiagnostic;
  final ValueChanged<PlanRecommendedExercise> onOpenRecommended;
  final SkillOpener onOpenSkill;

  @override
  Widget build(BuildContext context) {
    return switch (plan.state) {
      LearningPlanState.needsDiagnostic => _PlanEmptyState(
          title: 'Construisons votre plan personnalisé',
          description:
              'Faites 1 exercice écrit et 1 oral pour identifier vos premières priorités.',
          actionLabel: 'Faire mon diagnostic',
          actionIcon: LucideIcons.sparkles,
          onAction: onOpenDiagnostic,
        ),
      LearningPlanState.diagnosticInProgress => _PlanEmptyState(
          title: 'Votre diagnostic est en cours',
          description:
              'Reprenez là où vous vous êtes arrêté. Vos réponses déjà envoyées sont conservées sur votre compte.',
          actionLabel: 'Reprendre le diagnostic',
          actionIcon: LucideIcons.play,
          onAction: onOpenDiagnostic,
        ),
      LearningPlanState.active => _ActivePlan(
          plan: plan,
          objective: objective,
          onOpenDiagnostic: onOpenDiagnostic,
          onOpenRecommended: onOpenRecommended,
          onOpenSkill: onOpenSkill,
        ),
    };
  }
}

class _ActivePlan extends StatelessWidget {
  const _ActivePlan({
    required this.plan,
    required this.objective,
    required this.onOpenDiagnostic,
    required this.onOpenRecommended,
    required this.onOpenSkill,
  });

  final LearningPlan plan;
  final String? objective;
  final VoidCallback onOpenDiagnostic;
  final ValueChanged<PlanRecommendedExercise> onOpenRecommended;
  final SkillOpener onOpenSkill;

  @override
  Widget build(BuildContext context) {
    final current = plan.currentPriority;
    final next = plan.nextPriorities.take(2).toList(growable: false);
    final observed = plan.observedSkills
        .where((skill) => skill.status != LearningPlanSkillStatus.notObserved)
        .take(8)
        .toList(growable: false);
    final priorityCount = current == null ? 0 : 1 + plan.nextPriorities.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _PlanHero(
          objective: objective,
          priorityCount: priorityCount,
          activitiesThisWeek: plan.activitiesThisWeek,
          observedSkillCount: plan.observedSkillCount,
        ),
        const SizedBox(height: 22),
        const _PlanSectionHead(
          title: 'À faire maintenant',
          description: 'Une seule chose à la fois, celle qui rapporte le plus.',
        ),
        const SizedBox(height: 10),
        if (current == null)
          AppCard(
            child: Text(
              'Votre prochaine priorité est en cours de préparation.',
              style: AppFonts.ui(size: 13.5, color: AppColors.inkSoft),
            ),
          )
        else
          _NowCard(
            priority: current,
            onOpenRecommended: onOpenRecommended,
            onOpenFallback: () => context.push(
              current.section == SkillSection.eo
                  ? AppRoutes.tcfEoEntry
                  : AppRoutes.tcfEeEntry,
            ),
          ),
        const SizedBox(height: 24),
        const _PlanSectionHead(
          title: 'Votre parcours',
          description: 'Vos étapes dans l’ordre, jusqu’à la réévaluation.',
        ),
        const SizedBox(height: 12),
        _PlanPath(
          current: current,
          next: next,
          onOpenRecommended: onOpenRecommended,
        ),
        // Le jalon vit SOUS les priorités, jamais à leur place : c'est un cran
        // au-dessus des étapes, pas un remplaçant. `milestone == null` est le
        // cas NORMAL (rien à mesurer, ou examen blanc tout juste passé) — rien
        // ne s'affiche, ni indicateur, ni message.
        if (plan.milestone != null) ...[
          const SizedBox(height: 24),
          const _PlanSectionHead(
            title: kPlanMilestoneSectionTitle,
            description: kPlanMilestoneSectionText,
          ),
          const SizedBox(height: 12),
          PlanMilestoneCard(milestone: plan.milestone!),
        ],
        if (observed.isNotEmpty) ...[
          const SizedBox(height: 24),
          _ObservedSkillsSection(
            skills: observed,
            total: plan.observedSkillCount,
            onOpenSkill: onOpenSkill,
          ),
        ],
        const SizedBox(height: 22),
        AppButton(
          label: 'Voir mon diagnostic',
          variant: AppButtonVariant.ghost,
          icon: LucideIcons.clipboardCheck,
          onPressed: onOpenDiagnostic,
        ),
        if (plan.diagnosticCompletedAt != null) ...[
          const SizedBox(height: 6),
          Text(
            'Diagnostic réalisé le ${_shortDate(plan.diagnosticCompletedAt!)}',
            textAlign: TextAlign.center,
            style: AppFonts.ui(size: 11.5, color: AppColors.inkFaint),
          ),
        ],
      ],
    );
  }
}

/// Héros du Plan : le cap du candidat (« B1 → B2 ») et trois compteurs
/// **réels**. Aucun pourcentage de progression vers un palier — le brief
/// l'interdit, et le serveur n'en publie aucun.
class _PlanHero extends ConsumerWidget {
  const _PlanHero({
    required this.objective,
    required this.priorityCount,
    required this.activitiesThisWeek,
    required this.observedSkillCount,
  });

  final String? objective;
  final int priorityCount;
  final int activitiesThisWeek;
  final int observedSkillCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Le niveau TCF estimé n'a **qu'une seule surface autorisée** :
    // `DashboardSummaryResponse.estimatedTcfLevel`. On le lit, on ne le
    // recalcule pas, et son absence dégrade l'affichage sans le casser.
    final estimated =
        ref.watch(dashboardProvider).valueOrNull?.estimatedTcfLevel;

    return GradientHero(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PLAN PERSONNALISÉ',
            style: AppFonts.label(
              color: AppColors.white.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: 9),
          if (objective == null)
            Text(
              'Votre cap de progression',
              style: AppFonts.display(size: 25, color: AppColors.white),
            )
          else if (estimated == null)
            Text(
              'Objectif : $objective',
              style: AppFonts.display(size: 25, color: AppColors.white),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  estimated.shortName,
                  style: AppFonts.display(size: 30, color: AppColors.white),
                ),
                const SizedBox(width: 10),
                Icon(
                  LucideIcons.arrowRight,
                  size: 20,
                  color: AppColors.white.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 10),
                Text(
                  objective!,
                  style: AppFonts.display(size: 30, color: AppColors.white),
                ),
              ],
            ),
          const SizedBox(height: 7),
          Text(
            estimated == null
                ? 'Vos priorités sont ordonnées par ce qui vous fera progresser le plus vite.'
                : 'Niveau estimé aujourd’hui, puis les priorités qui réduisent l’écart.',
            style: AppFonts.ui(
              size: 12.5,
              height: 1.4,
              color: AppColors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 16),
          // Trois compteurs **réels**, en colonnes plutôt qu'en pastilles : à
          // 360 px une pastille « 5 compétences observées » déborde, et un
          // chiffre isolé se lit mieux qu'une phrase.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroStat(
                value: priorityCount,
                label: 'priorité${priorityCount > 1 ? 's' : ''}',
              ),
              const _HeroStatDivider(),
              _HeroStat(
                value: activitiesThisWeek,
                label: 'cette semaine',
              ),
              const _HeroStatDivider(),
              _HeroStat(
                value: observedSkillCount,
                label:
                    'compétence${observedSkillCount > 1 ? 's' : ''} observée${observedSkillCount > 1 ? 's' : ''}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: AppFonts.display(size: 22, color: AppColors.white),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppFonts.ui(
                size: 11,
                height: 1.25,
                weight: FontWeight.w600,
                color: AppColors.white.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
      );
}

class _HeroStatDivider extends StatelessWidget {
  const _HeroStatDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: AppColors.white.withValues(alpha: 0.16),
      );
}

class _PlanSectionHead extends StatelessWidget {
  const _PlanSectionHead({required this.title, this.description});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppFonts.display(size: 19)),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                style: AppFonts.ui(
                  size: 12,
                  height: 1.35,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ],
        ),
      );
}

/// Carte d'action : ce que le candidat ouvre maintenant, avec sa durée.
class _NowCard extends StatelessWidget {
  const _NowCard({
    required this.priority,
    required this.onOpenRecommended,
    required this.onOpenFallback,
  });

  final LearningPlanPriority priority;
  final ValueChanged<PlanRecommendedExercise> onOpenRecommended;
  final VoidCallback onOpenFallback;

  @override
  Widget build(BuildContext context) {
    final exercise = priority.recommendedExercise;
    final locked = _isLocked(priority, exercise);
    // Assez travaillée en ciblé, pas encore prouvée en situation : la même
    // carte, au même endroit, cesse de proposer un micro-sujet et propose une
    // vérification sur une vraie tâche TCF. Jamais une seconde carte à côté.
    final check = exercise?.kind == PlanExerciseKind.reassessment;
    return AppCard(
      border: Border.all(color: AppColors.blue.withValues(alpha: 0.22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppTag(
                label: 'PRIORITÉ 1',
                tone: TagTone.blue,
                icon: LucideIcons.zap,
                compact: true,
              ),
              const Spacer(),
              if (locked) ...[
                const PremiumLockTag(),
                const SizedBox(width: 6),
              ],
              AppTag(
                label: priority.section.wire,
                tone: TagTone.neutral,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(priority.title, style: AppFonts.display(size: 20)),
          if (exercise != null) ...[
            const SizedBox(height: 15),
            _ExerciseRow(exercise: exercise),
            const SizedBox(height: 13),
            if (locked) ...[
              AppButton(
                label: 'Débloquer cet exercice',
                icon: LucideIcons.lock,
                variant: AppButtonVariant.soft,
                onPressed: () => unawaited(showTcfLockPaywall(context)),
              ),
              const SizedBox(height: 9),
              Text(
                'Cet exercice fait partie de l’abonnement Intégral. Votre plan, '
                'lui, reste entier.',
                style: AppFonts.ui(
                  size: 11.5,
                  height: 1.4,
                  color: AppColors.inkFaint,
                ),
              ),
            ] else
              Semantics(
                label: check
                    ? 'Vérifier ma progression sur ${exercise.title}'
                    : 'Commencer l’exercice recommandé ${exercise.title}',
                button: true,
                child: AppButton(
                  label: check ? 'Vérifier ma progression' : 'Commencer',
                  iconRight: LucideIcons.arrowRight,
                  onPressed: () => onOpenRecommended(exercise),
                ),
              ),
          ] else ...[
            const SizedBox(height: 16),
            AppButton(
              label: 'Ouvrir l’épreuve',
              iconRight: LucideIcons.arrowRight,
              onPressed: onOpenFallback,
            ),
          ],
        ],
      ),
    );
  }
}

/// L'exercice recommandé, annoncé **à l'identique qu'il soit verrouillé ou
/// non** (miroir du web) : le candidat doit savoir ce que son plan lui
/// recommande. Le verrou se dit dans l'en-tête et dans le bouton, pas en
/// effaçant l'information.
class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise});

  final PlanRecommendedExercise exercise;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.blueLight,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: const Icon(
                LucideIcons.dumbbell,
                size: 18,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.ui(size: 13.5, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${exercise.section.wire} · ${exercise.estimatedMinutes} min',
                    style: AppFonts.ui(
                      size: 11.5,
                      weight: FontWeight.w600,
                      color: AppColors.inkFaint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Le chemin : des étapes **numérotées, verticales et reliées**. C'est ce qui
/// distingue un plan d'une pile de cartes — on voit où on en est, ce qui suit,
/// et que ça se termine par une réévaluation.
class _PlanPath extends StatelessWidget {
  const _PlanPath({
    required this.current,
    required this.next,
    required this.onOpenRecommended,
  });

  final LearningPlanPriority? current;
  final List<LearningPlanPriority> next;
  final ValueChanged<PlanRecommendedExercise> onOpenRecommended;

  @override
  Widget build(BuildContext context) {
    final steps = <Widget>[];
    var number = 1;

    if (current != null) {
      steps.add(
        _PathStep(
          number: number++,
          tone: AppColors.blue,
          child: _CurrentStepCard(
            priority: current!,
            onOpenRecommended: onOpenRecommended,
          ),
        ),
      );
    }
    for (final priority in next) {
      steps.add(
        _PathStep(
          number: number++,
          tone: AppColors.inkFaint,
          child: _NextStepCard(priority: priority),
        ),
      );
    }
    steps.add(
      _PathStep(
        number: number,
        tone: AppColors.green,
        icon: LucideIcons.refreshCw,
        isLast: true,
        child: const _ReassessmentStepCard(),
      ),
    );

    return Column(children: steps);
  }
}

class _PathStep extends StatelessWidget {
  const _PathStep({
    required this.number,
    required this.tone,
    required this.child,
    this.icon,
    this.isLast = false,
  });

  final int number;
  final Color tone;
  final Widget child;
  final IconData? icon;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: tone.withValues(alpha: 0.35)),
                  ),
                  child: icon != null
                      ? Icon(icon, size: 16, color: tone)
                      : Text(
                          '$number',
                          style: AppFonts.display(size: 14, color: tone),
                        ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColors.line),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Étape en cours : anneau alimenté par les **compteurs réels** de la
/// compétence (sujets traités / sujets publiés), jamais par un pourcentage
/// d'avancement inventé.
class _CurrentStepCard extends StatelessWidget {
  const _CurrentStepCard({
    required this.priority,
    required this.onOpenRecommended,
  });

  final LearningPlanPriority priority;
  final ValueChanged<PlanRecommendedExercise> onOpenRecommended;

  @override
  Widget build(BuildContext context) {
    final exercise = priority.recommendedExercise;
    final locked = _isLocked(priority, exercise);
    // Une étape, ce sont les 5 premiers sujets de la compétence — jamais ses 15.
    // L'état « terminée » est **servi**, jamais déduit d'une comparaison locale.
    final done = priority.stepCompleted;
    // L'étape change de NATURE quand le serveur juge la compétence assez
    // travaillée en ciblé sans preuve de transfert : même carte, même place,
    // mais on ne propose plus un micro-sujet — on va vérifier en situation.
    // La teinte est celle de la réévaluation qui clôt déjà le parcours : le
    // même mot ne doit pas porter deux couleurs sur le même écran.
    final check = exercise?.kind == PlanExerciseKind.reassessment;
    return AppCard(
      border: Border.all(color: AppColors.blue.withValues(alpha: 0.22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppTag(
                label: check
                    ? 'VÉRIFICATION'
                    : done
                        ? 'TERMINÉE'
                        : 'EN COURS',
                tone: check || done ? TagTone.success : TagTone.blue,
                compact: true,
              ),
              if (locked) ...[
                const SizedBox(width: 6),
                const PremiumLockTag(),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SkillRing(
                promptCount: priority.stepPromptCount,
                attemptedCount: priority.stepAttemptedCount,
                color: AppColors.blue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      priority.title,
                      style: AppFonts.display(size: 17, height: 1.2),
                    ),
                    if (done) ...[
                      const SizedBox(height: 5),
                      _StepDoneLines(priority: priority),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _skillMeta(priority.skillCode, priority.section),
                      style: AppFonts.ui(
                        size: 11.5,
                        weight: FontWeight.w600,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Pas de citation de la production ici : le Plan répond à « que
          // travailler maintenant ? ». Relire ce qu'on a rendu a déjà son
          // endroit — le sujet lui-même, atteint par l'exercice ci-dessous.
          if (exercise != null) ...[
            const SizedBox(height: 12),
            _ExerciseRow(exercise: exercise),
            const SizedBox(height: 11),
            if (locked)
              AppButton(
                label: 'Débloquer cette étape',
                icon: LucideIcons.lock,
                variant: AppButtonVariant.soft,
                height: 46,
                onPressed: () => unawaited(showTcfLockPaywall(context)),
              )
            else
              AppButton(
                label:
                    check ? 'Vérifier ma progression' : 'Continuer cette étape',
                variant: AppButtonVariant.soft,
                iconRight: LucideIcons.arrowRight,
                height: 46,
                onPressed: () => onOpenRecommended(exercise),
              ),
          ],
        ],
      ),
    );
  }
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard({required this.priority});

  final LearningPlanPriority priority;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _SkillRing(
              promptCount: priority.stepPromptCount,
              attemptedCount: priority.stepAttemptedCount,
              color: AppColors.inkFaint,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    priority.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.ui(
                      size: 13.5,
                      weight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  if (priority.stepCompleted) ...[
                    const SizedBox(height: 4),
                    _StepDoneLines(priority: priority),
                  ],
                  const SizedBox(height: 3),
                  // Le cadenas s'ajoute à « À VENIR », il ne le remplace pas :
                  // l'étape est bien à venir, et elle demande en plus un
                  // abonnement. Tout le reste de l'étape reste lisible.
                  Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (priority.locked) const PremiumLockTag(),
                      Text(
                        _skillMeta(priority.skillCode, priority.section),
                        style: AppFonts.ui(
                          size: 11,
                          weight: FontWeight.w600,
                          color: AppColors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const AppTag(
              label: 'À VENIR',
              tone: TagTone.neutral,
              compact: true,
            ),
          ],
        ),
      );
}

/// Ce qu'on dit d'une étape **terminée**, à un seul endroit (parité mot pour mot
/// avec `LearningPlanView` côté web).
///
/// Une étape terminée **reste affichée** — les priorités ne changent qu'à
/// l'arrivée d'une nouvelle observation, donc à la prochaine production. Sans la
/// première ligne, un candidat qui a fini son étape et la voit toujours là croit
/// à un bug. La seconde ne s'affiche que lorsqu'elle apprend quelque chose :
/// terminer n'est pas tout réussir.
class _StepDoneLines extends StatelessWidget {
  const _StepDoneLines({required this.priority});

  final LearningPlanPriority priority;

  @override
  Widget build(BuildContext context) {
    final partiallyValidated =
        priority.stepValidatedCount < priority.stepPromptCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Réévaluée à ta prochaine production.',
          style: AppFonts.ui(
            size: 12,
            weight: FontWeight.w600,
            height: 1.35,
            color: AppColors.green,
          ),
        ),
        if (partiallyValidated) ...[
          const SizedBox(height: 3),
          Text(
            '${priority.stepValidatedCount} validés sur '
            '${priority.stepPromptCount}',
            style: AppFonts.ui(
              size: 11,
              weight: FontWeight.w700,
              height: 1.35,
              color: AppColors.inkFaint,
            ),
          ),
        ],
      ],
    );
  }
}

class _ReassessmentStepCard extends StatelessWidget {
  const _ReassessmentStepCard();

  @override
  Widget build(BuildContext context) => AppCard(
        color: AppColors.greenLight,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Réévaluation',
              style: AppFonts.ui(size: 14, weight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Après quelques entraînements, une nouvelle production permettra de vérifier si cette faiblesse est réellement corrigée.',
              style: AppFonts.ui(
                size: 12.5,
                color: AppColors.inkSoft,
                height: 1.35,
              ),
            ),
          ],
        ),
      );
}

class _SkillRing extends StatelessWidget {
  const _SkillRing({
    required this.promptCount,
    required this.attemptedCount,
    required this.color,
    this.size = 46,
  });

  final int promptCount;
  final int attemptedCount;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final attempted = attemptedCount.clamp(0, promptCount);
    return ProgressRing(
      value: skillProgressValue(
            promptCount: promptCount,
            attemptedCount: attemptedCount,
          ) *
          100,
      size: size,
      stroke: 5,
      color: color,
      label: promptCount == 0 ? '—' : '$attempted',
      sub: promptCount == 0 ? null : '/$promptCount',
      textColor: color,
      subColor: AppColors.inkFaint,
    );
  }
}

/// Mêmes briques que « Réviser → Compétences » (`CompetenceCard`) : anneau,
/// titre, état en clair, chevron. Le propriétaire veut que les deux écrans
/// parlent des mêmes compétences de la même façon.
class _ObservedSkillsSection extends StatefulWidget {
  const _ObservedSkillsSection({
    required this.skills,
    required this.total,
    required this.onOpenSkill,
  });

  final List<LearningPlanSkill> skills;
  final int total;
  final SkillOpener onOpenSkill;

  @override
  State<_ObservedSkillsSection> createState() => _ObservedSkillsSectionState();
}

class _ObservedSkillsSectionState extends State<_ObservedSkillsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final visible = (_expanded ? widget.skills : widget.skills.take(4))
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: _PlanSectionHead(
                title: 'Mes compétences observées',
                description: 'Ouvrez-en une pour vous entraîner dessus.',
              ),
            ),
            Text(
              '${widget.total}',
              style: AppFonts.display(size: 17, color: AppColors.inkFaint),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final skill in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ObservedSkillCard(
              skill: skill,
              // Verrouillée, la carte reste lisible et tappable : le tap ouvre
              // l'offre au lieu d'une liste de sujets qu'on ne pourrait pas
              // produire.
              onTap: () {
                if (skill.locked) {
                  unawaited(showTcfLockPaywall(context));
                  return;
                }
                widget.onOpenSkill(skill.skillId, skill.section);
              },
            ),
          ),
        if (widget.skills.length > 4)
          TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            iconAlignment: IconAlignment.end,
            icon: Icon(
              _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
              size: 16,
              color: AppColors.blue,
            ),
            label: Text(
              _expanded
                  ? 'Réduire la liste'
                  : 'Voir toutes mes compétences observées',
              style: AppFonts.ui(
                size: 12.5,
                weight: FontWeight.w700,
                color: AppColors.blue,
              ),
            ),
          ),
      ],
    );
  }
}

class _ObservedSkillCard extends StatelessWidget {
  const _ObservedSkillCard({required this.skill, required this.onTap});

  final LearningPlanSkill skill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // L'état de maîtrise (tout l'historique) dès que le serveur en a un ;
    // sinon le verdict de la dernière production. **Jamais les deux** :
    // « Priorité » et « Prioritaire » côte à côte se liraient comme deux
    // informations, alors que c'est la même.
    final mastery = skill.masteryState;
    final tone = mastery == null ? skill.status.color : mastery.color;
    return PressableCard(
      onTap: onTap,
      radius: AppRadii.lg,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _SkillRing(
              promptCount: skill.promptCount,
              attemptedCount: skill.attemptedCount,
              color: tone,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          skill.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.ui(
                            size: 14.5,
                            weight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                      if (skill.locked) ...[
                        const SizedBox(width: 8),
                        const PremiumLockTag(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: mastery?.label ?? skill.status.label,
                          style: AppFonts.ui(
                            size: 11.5,
                            weight: FontWeight.w800,
                            color: tone,
                          ),
                        ),
                        TextSpan(
                          text: ' · ${skillProgressLabel(
                            promptCount: skill.promptCount,
                            attemptedCount: skill.attemptedCount,
                            validatedCount: skill.validatedCount,
                          )}',
                          style: AppFonts.ui(
                            size: 11.5,
                            weight: FontWeight.w600,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const CardChevron(),
          ],
        ),
      ),
    );
  }
}

class _PlanEmptyState extends StatelessWidget {
  const _PlanEmptyState({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  final String title;
  final String description;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
        children: [
          AppCard(
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    color: AppColors.blueLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.map,
                    size: 29,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(height: 17),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppFonts.display(size: 21),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: AppFonts.ui(
                    size: 13.5,
                    color: AppColors.inkSoft,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: actionLabel,
                  icon: actionIcon,
                  onPressed: onAction,
                ),
              ],
            ),
          ),
        ],
      );
}

class _LoadingPlan extends StatelessWidget {
  const _LoadingPlan();

  @override
  Widget build(BuildContext context) => ListView(
        children: const [
          Padding(
            padding: EdgeInsets.only(top: 120),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.blue),
            ),
          ),
        ],
      );
}

class _PlanError extends StatelessWidget {
  const _PlanError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              children: [
                const Icon(
                  LucideIcons.cloudOff,
                  size: 28,
                  color: AppColors.inkFaint,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppFonts.ui(size: 13.5, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 14),
                AppButton(
                  label: 'Réessayer',
                  variant: AppButtonVariant.soft,
                  height: 44,
                  fullWidth: false,
                  onPressed: onRetry,
                ),
              ],
            ),
          ),
        ],
      );
}

/// Une étape est fermée si le serveur a verrouillé **la priorité** ou
/// **l'exercice** qu'elle recommande — deux booléens distincts, aucun des deux
/// n'est déduit de l'autre côté app.
bool _isLocked(
  LearningPlanPriority priority,
  PlanRecommendedExercise? exercise,
) =>
    priority.locked || (exercise?.locked ?? false);

String _skillMeta(String skillCode, SkillSection section) {
  final label = section.productionLabel;
  return skillCode.isEmpty ? label : '$skillCode · $label';
}

String _shortDate(DateTime date) {
  final local = date.toLocal();
  const months = <String>[
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}
