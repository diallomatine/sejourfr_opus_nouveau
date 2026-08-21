import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/models/diagnostic_models.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/blurred_content.dart';
import '../../../core/widgets/list_group.dart';
import '../../../core/widgets/premium_lock.dart';
import '../../../core/widgets/pressable_card.dart';
import '../../../core/widgets/skill_mastery_tag.dart';
import '../plan_actions.dart';
import '../plan_labels.dart';
import '../plan_step_labels.dart';
import 'plan_tokens.dart';

/// **Mes priorités** : le parcours numéroté des compétences que le Plan tient
/// pour les plus rentables, dans l'ordre **servi**.
///
/// Les étapes **franchies** ne disparaissent pas — elles se replient sous la
/// liste. Elles s'accumulent (cinq servies) et, mises en tête, repoussaient la
/// priorité n°1 hors écran ; c'est le seul écart assumé avec « elles se lisent
/// avant ».
///
/// « Tout voir » ouvre la page **Toutes mes compétences** — l'index des six
/// tâches d'expression et des deux domaines de compréhension. Elle **déplia**
/// un temps les compétences observées ici même : un écran de plan n'est pas un
/// catalogue, et la liste dépliée poussait le reste du Plan hors de vue.
///
/// ⚠️ **C'est un verrou de NAVIGATION** pour un compte gratuit : le Plan reste
/// intégralement visible (aucune priorité, aucun compteur n'est masqué), mais
/// le catalogue complet est un accès, et les accès sont fermés.
class PlanPrioritiesSection extends ConsumerStatefulWidget {
  const PlanPrioritiesSection({super.key, required this.plan});

  final LearningPlan plan;

  @override
  ConsumerState<PlanPrioritiesSection> createState() =>
      _PlanPrioritiesSectionState();
}

class _PlanPrioritiesSectionState extends ConsumerState<PlanPrioritiesSection> {
  bool _showDone = false;

  /// « Tout voir ». Un compte sans accès TCF n'y entre pas : le catalogue
  /// complet est un accès, et le verrou s'oppose ici comme partout ailleurs.
  void _openAll() {
    final auth = ref.read(authControllerProvider);
    if (auth is! AuthAuthenticated || !auth.user.hasTcf) {
      unawaited(showTcfLockPaywall(context));
      return;
    }
    context.push(AppRoutes.planSkills);
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final priorities = <LearningPlanPriority>[
      if (plan.currentPriority != null) plan.currentPriority!,
      ...plan.nextPriorities,
    ];
    final completed = plan.completedSteps;

    if (priorities.isEmpty && completed.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: kPlanPrioritiesTitle,
          action: TextButton(
            onPressed: _openAll,
            style: _linkStyle,
            child: Text(
              kPlanPrioritiesAll,
              style: AppFonts.ui(
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.blue,
              ),
            ),
          ),
        ),
        if (priorities.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                for (var i = 0; i < priorities.length; i++)
                  _PriorityRow(
                    rank: i + 1,
                    priority: priorities[i],
                    first: i == 0,
                  ),
              ],
            ),
          ),
        ],
        if (completed.isNotEmpty) ...[
          const SizedBox(height: 12),
          AppButton(
            label: planDoneSectionCta(completed.length, _showDone),
            icon: LucideIcons.check,
            variant: AppButtonVariant.outline,
            height: 46,
            onPressed: () => setState(() => _showDone = !_showDone),
          ),
          if (_showDone)
            for (final step in completed)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _CompletedStepCard(step: step),
              ),
        ],
      ],
    );
  }
}

final ButtonStyle _linkStyle = TextButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 6),
  minimumSize: Size.zero,
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
);

/// Une priorité : son rang, sa compétence, son état de maîtrise et les points
/// de son **étape** (les 5 premiers sujets, jamais les 15 de la compétence).
///
/// 🛑 **Verrouillée**, la ligne garde son rang net et passe sa compétence
/// derrière un rideau de flou (`BlurredContent`) — c'est le **vrai** titre qui
/// est flouté, jamais un décor. Son état de maîtrise et ses points d'étape ne
/// s'affichent alors pas : situer une compétence dont on cache le nom ne dit
/// rien à personne. Le tap mène à l'offre, pas à des sujets qu'on ne pourrait
/// pas produire.
///
/// ⚠ Le verrou est **lu** sur le DTO. Jamais « à partir de la 2ᵉ ligne ».
class _PriorityRow extends StatelessWidget {
  const _PriorityRow({
    required this.rank,
    required this.priority,
    required this.first,
  });

  final int rank;
  final LearningPlanPriority priority;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final mastery = priority.masteryState;
    final locked = priority.locked;

    // Le **vrai** titre et la **vraie** compétence. Verrouillés, ils passent
    // derrière le rideau sans être remplacés par quoi que ce soit.
    final Widget identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          priority.title,
          style: AppFonts.ui(
            size: 14.5,
            weight: FontWeight.w600,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          planSkillMeta(priority.skillCode, priority.section),
          style: AppFonts.ui(size: 12.5, color: AppColors.inkFaint),
        ),
      ],
    );

    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: () => locked
            ? unawaited(showTcfLockPaywall(context))
            : openPlanSkill(context, priority.skillId, priority.section),
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
          decoration: BoxDecoration(
            border: first
                ? null
                : const Border(top: BorderSide(color: AppColors.lineSoft)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Le rang reste **net** — il dit la place dans le parcours, pas
              // ce qu'il y a à y faire. Verrouillé, il reprend la teinte
              // neutre : sa couleur porte l'état de maîtrise, qu'on ne montre
              // pas ici.
              PlanRankBadge(
                rank: rank,
                tone: locked
                    ? AppColors.inkFaint
                    : mastery?.color ?? priority.status.color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: locked
                              ? BlurredContent(child: identity)
                              : identity,
                        ),
                        const SizedBox(width: 8),
                        if (locked)
                          const PremiumLockPill()
                        else if (mastery != null)
                          SkillMasteryTag(state: mastery, compact: true)
                        else
                          AppTag(
                            label: priority.status.label,
                            tone: TagTone.neutral,
                            compact: true,
                          ),
                      ],
                    ),
                    if (!locked && priority.stepPromptCount > 0) ...[
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Expanded(
                            child: PlanStepDots(
                              done: priority.stepAttemptedCount,
                              total: priority.stepPromptCount,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Text(
                            '${priority.stepAttemptedCount.clamp(0, priority.stepPromptCount)} / '
                            '${priority.stepPromptCount} sujets',
                            style: AppFonts.ui(
                              size: 11.5,
                              weight: FontWeight.w700,
                              color: AppColors.inkFaint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Une étape **franchie** : cochée, sobre, **sans aucun bouton d'action** — il
/// n'y a plus rien à y faire, et ce n'est pas une porte commerciale (le DTO ne
/// porte ni exercice ni `locked`). Elle reste tappable, pour se relire.
///
/// ⚠️ La coche ne dépend **pas** de `masteryState` : l'appartenance à
/// `completedSteps` **est** la coche.
class _CompletedStepCard extends StatelessWidget {
  const _CompletedStepCard({required this.step});

  final LearningPlanCompletedStep step;

  @override
  Widget build(BuildContext context) => PressableCard(
        onTap: () => openPlanSkill(context, step.skillId, step.section),
        radius: AppRadii.lg,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              PlanRankBadge(
                rank: 0,
                tone: AppColors.green,
                icon: LucideIcons.check,
                semanticsLabel: kPlanStepDoneMarkLabel,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.ui(
                        size: 13.5,
                        weight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      planSkillMeta(step.skillCode, step.section),
                      style: AppFonts.ui(
                        size: 11,
                        weight: FontWeight.w600,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const AppTag(
                label: kPlanStepBadgeDone,
                tone: TagTone.success,
                compact: true,
              ),
            ],
          ),
        ),
      );
}
