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
import '../../core/providers/target_level_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/router/route_observer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/screen_header.dart';
import '../tcf_production/competences/competences_nav.dart';
import '../tcf_production/tcf_production_module.dart';
import 'learning_plan_provider.dart';

/// Plan adaptatif calculé par le serveur à partir du diagnostic et des
/// activités productives récentes. L'écran ne recalcule ni priorité ni statut.
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
    unawaited(_track(AudienceEvent.planRecommendedExerciseStarted));
    final module = exercise.section == SkillSection.eo
        ? TcfProductionModule.eo
        : TcfProductionModule.ee;
    context.push(
      competencePromptPath(
        module,
        exercise.skillId,
        exercise.skillPromptId,
      ),
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
                    onOpenProgress: () => context.push(AppRoutes.progress),
                    onOpenRecommended: _openRecommended,
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

class _PlanContent extends StatelessWidget {
  const _PlanContent({
    required this.plan,
    required this.objective,
    required this.onOpenDiagnostic,
    required this.onOpenProgress,
    required this.onOpenRecommended,
  });

  final LearningPlan plan;
  final String? objective;
  final VoidCallback onOpenDiagnostic;
  final VoidCallback onOpenProgress;
  final ValueChanged<PlanRecommendedExercise> onOpenRecommended;

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
          onOpenProgress: onOpenProgress,
        ),
      LearningPlanState.diagnosticInProgress => _PlanEmptyState(
          title: 'Votre diagnostic est en cours',
          description:
              'Reprenez là où vous vous êtes arrêté. Vos réponses déjà envoyées sont conservées sur votre compte.',
          actionLabel: 'Reprendre le diagnostic',
          actionIcon: LucideIcons.play,
          onAction: onOpenDiagnostic,
          onOpenProgress: onOpenProgress,
        ),
      LearningPlanState.active => _ActivePlan(
          plan: plan,
          objective: objective,
          onOpenDiagnostic: onOpenDiagnostic,
          onOpenProgress: onOpenProgress,
          onOpenRecommended: onOpenRecommended,
        ),
    };
  }
}

class _ActivePlan extends StatelessWidget {
  const _ActivePlan({
    required this.plan,
    required this.objective,
    required this.onOpenDiagnostic,
    required this.onOpenProgress,
    required this.onOpenRecommended,
  });

  final LearningPlan plan;
  final String? objective;
  final VoidCallback onOpenDiagnostic;
  final VoidCallback onOpenProgress;
  final ValueChanged<PlanRecommendedExercise> onOpenRecommended;

  @override
  Widget build(BuildContext context) {
    final current = plan.currentPriority;
    final observed = plan.observedSkills
        .where((skill) => skill.status != LearningPlanSkillStatus.notObserved)
        .take(8)
        .toList(growable: false);
    final priorityCount = current == null ? 0 : 1 + plan.nextPriorities.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _PlanSummary(
          objective: objective,
          priorityCount: priorityCount,
          activitiesThisWeek: plan.activitiesThisWeek,
        ),
        const SizedBox(height: 20),
        Text('À travailler maintenant', style: AppFonts.display(size: 19)),
        const SizedBox(height: 10),
        if (current == null)
          AppCard(
            child: Text(
              'Votre prochaine priorité est en cours de préparation.',
              style: AppFonts.ui(size: 13.5, color: AppColors.inkSoft),
            ),
          )
        else
          _CurrentPriorityCard(
            priority: current,
            onOpenRecommended: onOpenRecommended,
            onOpenFallback: () => context.push(
              current.section == SkillSection.eo
                  ? AppRoutes.tcfEoEntry
                  : AppRoutes.tcfEeEntry,
            ),
          ),
        if (plan.nextPriorities.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text('Ensuite', style: AppFonts.display(size: 19)),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              children: [
                for (var index = 0;
                    index < plan.nextPriorities.take(3).length;
                    index++)
                  _PriorityLine(
                    priority: plan.nextPriorities[index],
                    index: index + 2,
                    divider: index != plan.nextPriorities.take(3).length - 1,
                  ),
              ],
            ),
          ),
        ],
        if (observed.isNotEmpty) ...[
          const SizedBox(height: 22),
          _ObservedSkillsCard(
            skills: observed,
            total: plan.observedSkillCount,
          ),
        ],
        const SizedBox(height: 20),
        AppCard(
          color: AppColors.blueSoft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                LucideIcons.refreshCw,
                size: 20,
                color: AppColors.blue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prochaine vérification',
                      style: AppFonts.ui(
                        size: 14,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
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
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppButton(
          label: 'Voir mon diagnostic',
          variant: AppButtonVariant.outline,
          icon: LucideIcons.clipboardCheck,
          onPressed: onOpenDiagnostic,
        ),
        const SizedBox(height: 8),
        AppButton(
          label: 'Voir ma progression',
          variant: AppButtonVariant.ghost,
          icon: LucideIcons.chartColumn,
          onPressed: onOpenProgress,
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

class _PlanSummary extends StatelessWidget {
  const _PlanSummary({
    required this.objective,
    required this.priorityCount,
    required this.activitiesThisWeek,
  });

  final String? objective;
  final int priorityCount;
  final int activitiesThisWeek;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.hero(AppColors.blueDark, AppColors.blue),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PLAN PERSONNALISÉ',
            style: AppFonts.label(
              color: AppColors.white.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            objective == null
                ? 'Votre cap de progression'
                : 'Objectif : $objective',
            style: AppFonts.display(size: 25, color: AppColors.white),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryPill(
                icon: LucideIcons.listChecks,
                label: '$priorityCount priorité${priorityCount > 1 ? 's' : ''}',
              ),
              _SummaryPill(
                icon: LucideIcons.calendarDays,
                label:
                    '$activitiesThisWeek activité${activitiesThisWeek > 1 ? 's' : ''} cette semaine',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppFonts.ui(
                size: 11.5,
                weight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      );
}

class _CurrentPriorityCard extends StatelessWidget {
  const _CurrentPriorityCard({
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
    return AppCard(
      border: Border.all(color: AppColors.blue.withValues(alpha: 0.18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppTag(
                label: 'PRIORITÉ 1',
                tone: TagTone.blue,
                icon: LucideIcons.zap,
              ),
              const Spacer(),
              AppTag(
                label: priority.section.wire,
                tone: TagTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(priority.title, style: AppFonts.display(size: 20)),
          if (priority.explanation != null) ...[
            const SizedBox(height: 7),
            Text(
              priority.explanation!,
              style: AppFonts.ui(
                size: 13.5,
                color: AppColors.inkSoft,
                height: 1.4,
              ),
            ),
          ],
          if (priority.evidence != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text(
                '« ${priority.evidence!} »',
                style: AppFonts.ui(
                  size: 12.5,
                  color: AppColors.inkSoft,
                  height: 1.35,
                ),
              ),
            ),
          ],
          if (exercise != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.dumbbell,
                    size: 21,
                    color: AppColors.blue,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.ui(
                            size: 13.5,
                            weight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${exercise.section.wire} · ${exercise.estimatedMinutes} min',
                          style: AppFonts.ui(
                            size: 11.5,
                            color: AppColors.inkFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              label: 'Commencer l’exercice recommandé ${exercise.title}',
              button: true,
              child: AppButton(
                label: 'Commencer',
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

class _PriorityLine extends StatelessWidget {
  const _PriorityLine({
    required this.priority,
    required this.index,
    required this.divider,
  });

  final LearningPlanPriority priority;
  final int index;
  final bool divider;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: divider
              ? const Border(bottom: BorderSide(color: AppColors.lineSoft))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.blueLight,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$index',
                style: AppFonts.ui(
                  size: 12.5,
                  weight: FontWeight.w800,
                  color: AppColors.blueDark,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                priority.title,
                style: AppFonts.ui(size: 13.5, weight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            AppTag(
              label: priority.section.wire,
              tone: TagTone.neutral,
              compact: true,
            ),
          ],
        ),
      );
}

class _ObservedSkillsCard extends StatefulWidget {
  const _ObservedSkillsCard({required this.skills, required this.total});

  final List<LearningPlanSkill> skills;
  final int total;

  @override
  State<_ObservedSkillsCard> createState() => _ObservedSkillsCardState();
}

class _ObservedSkillsCardState extends State<_ObservedSkillsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final visible = (_expanded ? widget.skills : widget.skills.take(6))
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Mes compétences observées',
                style: AppFonts.display(size: 19),
              ),
            ),
            Text(
              '${widget.total}',
              style: AppFonts.ui(
                size: 13,
                color: AppColors.inkFaint,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            children: [
              for (var index = 0; index < visible.length; index++)
                _ObservedSkillLine(
                  skill: visible[index],
                  divider: index != visible.length - 1,
                ),
            ],
          ),
        ),
        if (widget.skills.length > 6)
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

class _ObservedSkillLine extends StatelessWidget {
  const _ObservedSkillLine({required this.skill, required this.divider});

  final LearningPlanSkill skill;
  final bool divider;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          border: divider
              ? const Border(bottom: BorderSide(color: AppColors.lineSoft))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              _skillIcon(skill.status),
              size: 17,
              color: _skillColor(skill.status),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                skill.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.ui(size: 13, weight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            AppTag(
              label: skill.status.label,
              tone: _skillTone(skill.status),
              compact: true,
            ),
          ],
        ),
      );
}

class _PlanEmptyState extends StatelessWidget {
  const _PlanEmptyState({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    required this.onOpenProgress,
  });

  final String title;
  final String description;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;
  final VoidCallback onOpenProgress;

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
          const SizedBox(height: 14),
          AppButton(
            label: 'Voir ma progression',
            variant: AppButtonVariant.ghost,
            icon: LucideIcons.chartColumn,
            onPressed: onOpenProgress,
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

IconData _skillIcon(LearningPlanSkillStatus status) => switch (status) {
      LearningPlanSkillStatus.priority => LucideIcons.zap,
      LearningPlanSkillStatus.toReinforce => LucideIcons.trendingUp,
      LearningPlanSkillStatus.solid => LucideIcons.circleCheck,
      LearningPlanSkillStatus.notObserved => LucideIcons.circle,
    };

Color _skillColor(LearningPlanSkillStatus status) => switch (status) {
      LearningPlanSkillStatus.priority => AppColors.blue,
      LearningPlanSkillStatus.toReinforce => AppColors.amberDark,
      LearningPlanSkillStatus.solid => AppColors.green,
      LearningPlanSkillStatus.notObserved => AppColors.inkFaint,
    };

TagTone _skillTone(LearningPlanSkillStatus status) => switch (status) {
      LearningPlanSkillStatus.priority => TagTone.blue,
      LearningPlanSkillStatus.toReinforce => TagTone.amber,
      LearningPlanSkillStatus.solid => TagTone.success,
      LearningPlanSkillStatus.notObserved => TagTone.neutral,
    };

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
