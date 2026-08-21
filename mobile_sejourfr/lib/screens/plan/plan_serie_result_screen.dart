import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/api_client.dart';
import '../../core/api/repositories.dart';
import '../../core/models/attempt_models.dart';
import '../../core/models/diagnostic_models.dart';
import '../../core/models/skill_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_tag.dart';
import '../../core/widgets/list_group.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/skill_mastery_tag.dart';
import 'learning_plan_provider.dart';
import 'plan_labels.dart';
import 'plan_series_launcher.dart';

final _attemptProvider =
    FutureProvider.autoDispose.family<Attempt, String>((ref, attemptId) {
  return ref.watch(attemptsRepositoryProvider).getById(attemptId);
});

/// **Le bilan d'une série ciblée de compréhension.**
///
/// Poussé par le runner quand la route porte `from=planSerie` — exactement le
/// montage des lots TCF. Il répond à une seule question : *cette série a-t-elle
/// changé quelque chose à ma maîtrise ?*
///
/// 🛑 **Rien n'est recalculé.** L'« après » est l'état de maîtrise que le
/// serveur sert au prochain chargement du Plan ; l'« avant » est celui que le
/// Plan affichait au lancement, repassé dans la route. Quand l'un des deux
/// manque, on ne comble pas : les observations s'écrivent après la correction,
/// best-effort, donc un « pas encore » est un **état normal**.
///
/// 🛑 **Une série ciblée ne rend jamais un domaine « évalué »** : c'est un
/// entraînement. La note de bas d'écran le dit, pour qu'aucun candidat ne croie
/// avoir mesuré son niveau.
class PlanSerieResultScreen extends ConsumerStatefulWidget {
  const PlanSerieResultScreen({
    super.key,
    required this.attemptId,
    this.skillId,
    this.masteryBefore,
  });

  final String attemptId;
  final String? skillId;
  final SkillMasteryState? masteryBefore;

  @override
  ConsumerState<PlanSerieResultScreen> createState() =>
      _PlanSerieResultScreenState();
}

class _PlanSerieResultScreenState
    extends ConsumerState<PlanSerieResultScreen> {
  @override
  void initState() {
    super.initState();
    // La série vient d'alimenter la compétence : on relit le Plan pour que
    // l'« après » soit celui du serveur, jamais un état déduit du score.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(learningPlanProvider);
    });
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.plan);
  }

  @override
  Widget build(BuildContext context) {
    final attemptAsync = ref.watch(_attemptProvider(widget.attemptId));
    final plan = ref.watch(learningPlanProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(title: kPlanSerieDoneTitle, onBack: _leave),
            Expanded(
              child: attemptAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.blue),
                ),
                error: (error, _) => ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    AppCard(
                      child: Text(
                        ApiClient.toApiException(error).message,
                        textAlign: TextAlign.center,
                        style: AppFonts.ui(
                          size: 13.5,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppButton(label: kPlanSerieBack, onPressed: _leave),
                  ],
                ),
                data: (attempt) => _Body(
                  attempt: attempt,
                  plan: plan,
                  skillId: widget.skillId,
                  masteryBefore: widget.masteryBefore,
                  onLeave: _leave,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.attempt,
    required this.plan,
    required this.skillId,
    required this.masteryBefore,
    required this.onLeave,
  });

  final Attempt attempt;
  final LearningPlan? plan;
  final String? skillId;
  final SkillMasteryState? masteryBefore;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = attempt.totalQuestions;
    final score = attempt.score ?? 0;
    final level = _levelOf(plan, skillId);
    final after = level?.masteryState;
    final next = _nextLevel(plan, skillId);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$score',
                      style: AppFonts.display(size: 46, height: 1),
                    ),
                    TextSpan(
                      text: ' / $total',
                      style: AppFonts.display(
                        size: 26,
                        height: 1,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'bonnes réponses',
                style: AppFonts.ui(
                  size: 13,
                  weight: FontWeight.w600,
                  color: AppColors.inkFaint,
                ),
              ),
              if (level != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.only(top: 14),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.lineSoft),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _skillTitle(plan, skillId) ??
                            'Palier ${level.niveau.wire}',
                        style: AppFonts.ui(
                          size: 14.5,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 9),
                      AppTag(
                        label: level.niveau.wire,
                        tone: TagTone.neutral,
                        compact: true,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionTitle(title: kPlanSerieImpact),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (after == null)
                Text(
                  kPlanSeriePending,
                  style: AppFonts.ui(
                    size: 13.5,
                    height: 1.5,
                    color: AppColors.inkSoft,
                  ),
                )
              else ...[
                Row(
                  children: [
                    if (masteryBefore != null) ...[
                      SkillMasteryTag(state: masteryBefore!, compact: true),
                      const SizedBox(width: 10),
                      const Icon(
                        LucideIcons.arrowRight,
                        size: 16,
                        color: AppColors.inkFaint,
                      ),
                      const SizedBox(width: 10),
                    ],
                    SkillMasteryTag(state: after, compact: true),
                    const Spacer(),
                    if (masteryBefore == after)
                      Text(
                        kPlanSerieConfirmed,
                        style: AppFonts.ui(
                          size: 12,
                          weight: FontWeight.w700,
                          color: AppColors.inkFaint,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.lineSoft),
                    ),
                  ),
                  child: Text(
                    kPlanSerieNote,
                    style: AppFonts.ui(
                      size: 13.5,
                      height: 1.5,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (next != null) ...[
          const SizedBox(height: 20),
          SectionTitle(title: kPlanSerieNext),
          const SizedBox(height: 10),
          AppCard(
            onTap: () => unawaited(
              startTargetedSeries(
                context,
                ref,
                skillId: next.skillId,
                masteryBefore: next.masteryState,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    next.niveau.wire,
                    style: AppFonts.display(size: 17),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kPlanSeriesCta,
                        style: AppFonts.ui(
                          size: 14.5,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        planLevelSubtitle(next),
                        style: AppFonts.ui(
                          size: 12.5,
                          color: AppColors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (next.masteryState != null)
                  SkillMasteryTag(state: next.masteryState!, compact: true),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        AppButton(
          label: kPlanSerieBack,
          iconRight: LucideIcons.arrowRight,
          onPressed: onLeave,
        ),
        if (skillId != null) ...[
          const SizedBox(height: 9),
          AppButton(
            label: kPlanSerieAgain,
            variant: AppButtonVariant.outline,
            icon: LucideIcons.refreshCw,
            onPressed: () => unawaited(
              startTargetedSeries(
                context,
                ref,
                skillId: skillId!,
                masteryBefore: after,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Le palier travaillé, retrouvé dans le Plan **déjà chargé**. `null` tant que
/// le Plan n'est pas revenu, ou si la compétence n'est plus dans les domaines
/// servis — cas normal, l'écran affiche alors le score seul.
PlanDomainLevel? _levelOf(LearningPlan? plan, String? skillId) {
  if (plan == null || skillId == null) return null;
  for (final domain in plan.domaines) {
    for (final level in domain.paliers) {
      if (level.skillId == skillId) return level;
    }
  }
  return null;
}

/// Le palier **qui bloque** le domaine de la compétence travaillée, quand ce
/// n'est pas celui qu'on vient de faire. C'est le seul « ensuite » que le
/// serveur désigne : on ne choisit pas à sa place.
PlanDomainLevel? _nextLevel(LearningPlan? plan, String? skillId) {
  if (plan == null || skillId == null) return null;
  for (final domain in plan.domaines) {
    if (!domain.paliers.any((level) => level.skillId == skillId)) continue;
    for (final level in domain.paliers) {
      if (level.blocking && level.skillId != skillId) return level;
    }
  }
  return null;
}

/// Le titre de la compétence travaillée, s'il apparaît quelque part dans le
/// Plan (séance, priorités, compétences observées). Le palier, lui, ne porte
/// que son code — on n'invente pas de libellé.
String? _skillTitle(LearningPlan? plan, String? skillId) {
  if (plan == null || skillId == null) return null;
  for (final item in plan.seance.items) {
    if (item.skillId == skillId && item.title != null) return item.title;
  }
  for (final skill in plan.observedSkills) {
    if (skill.skillId == skillId) return skill.title;
  }
  final current = plan.currentPriority;
  if (current != null && current.skillId == skillId) return current.title;
  for (final priority in plan.nextPriorities) {
    if (priority.skillId == skillId) return priority.title;
  }
  return null;
}
