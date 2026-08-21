import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/skill_progress.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_tag.dart';
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
/// « Tout voir » déplie les **compétences observées** — les mêmes compétences,
/// avec le même signal de maîtrise que « Réviser → Compétences ».
class PlanPrioritiesSection extends ConsumerStatefulWidget {
  const PlanPrioritiesSection({super.key, required this.plan});

  final LearningPlan plan;

  @override
  ConsumerState<PlanPrioritiesSection> createState() =>
      _PlanPrioritiesSectionState();
}

class _PlanPrioritiesSectionState extends ConsumerState<PlanPrioritiesSection> {
  bool _showObserved = false;
  bool _showDone = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final priorities = <LearningPlanPriority>[
      if (plan.currentPriority != null) plan.currentPriority!,
      ...plan.nextPriorities,
    ];
    final observed = plan.observedSkills
        .where((skill) => skill.status != LearningPlanSkillStatus.notObserved)
        .toList(growable: false);
    final completed = plan.completedSteps;

    if (priorities.isEmpty && observed.isEmpty && completed.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: kPlanPrioritiesTitle,
          action: observed.isEmpty
              ? null
              : TextButton(
                  onPressed: () =>
                      setState(() => _showObserved = !_showObserved),
                  style: _linkStyle,
                  child: Text(
                    _showObserved ? kPlanPrioritiesLess : kPlanPrioritiesAll,
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
        if (_showObserved && observed.isNotEmpty) ...[
          const SizedBox(height: 14),
          SectionTitle(title: kPlanObservedTitle),
          const SizedBox(height: 10),
          for (final skill in observed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ObservedSkillCard(skill: skill),
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
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: () =>
            openPlanSkill(context, priority.skillId, priority.section),
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
              PlanRankBadge(
                rank: rank,
                tone: mastery?.color ?? priority.status.color,
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
                          child: Column(
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
                                planSkillMeta(
                                  priority.skillCode,
                                  priority.section,
                                ),
                                style: AppFonts.ui(
                                  size: 12.5,
                                  color: AppColors.inkFaint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (priority.locked) ...[
                          const PremiumLockTag(),
                          const SizedBox(width: 6),
                        ],
                        if (mastery != null)
                          SkillMasteryTag(state: mastery, compact: true)
                        else
                          AppTag(
                            label: priority.status.label,
                            tone: TagTone.neutral,
                            compact: true,
                          ),
                      ],
                    ),
                    if (priority.stepPromptCount > 0) ...[
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

/// Mêmes briques que « Réviser → Compétences » : anneau, titre, état en clair,
/// chevron. Les deux écrans parlent des mêmes compétences de la même façon.
class _ObservedSkillCard extends StatelessWidget {
  const _ObservedSkillCard({required this.skill});

  final LearningPlanSkill skill;

  @override
  Widget build(BuildContext context) {
    // L'état de maîtrise (tout l'historique) dès que le serveur en a un ;
    // sinon le verdict de la dernière production. **Jamais les deux**.
    final mastery = skill.masteryState;
    final tone = mastery == null ? skill.status.color : mastery.color;
    return PressableCard(
      onTap: () {
        // Verrouillée, la carte reste lisible et tappable : le tap ouvre
        // l'offre au lieu d'une liste de sujets qu'on ne pourrait pas produire.
        if (skill.locked) {
          unawaited(showTcfLockPaywall(context));
          return;
        }
        openPlanSkill(context, skill.skillId, skill.section);
      },
      radius: AppRadii.lg,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            PlanSkillRing(
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
