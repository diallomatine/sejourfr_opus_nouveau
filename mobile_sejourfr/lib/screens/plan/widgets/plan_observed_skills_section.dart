import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/models/diagnostic_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/skill_progress.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/list_group.dart';
import '../../../core/widgets/premium_lock.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/skill_mastery_tag.dart';
import '../plan_actions.dart';
import '../plan_labels.dart';

/// **Mes compétences observées** — ce que les productions du candidat ont
/// réellement montré, compétence par compétence.
///
/// 🛑 **Ce bloc n'existait que sur le web.** Le mobile décodait pourtant
/// `observedSkills` / `observedSkillCount` depuis toujours et ne les affichait
/// nulle part : le même compte lisait sur ordinateur un historique que son
/// téléphone lui cachait. C'est la seule surface du Plan qui dit *ce qui a été
/// constaté* plutôt que *ce qu'il reste à faire*.
///
/// 🛑 **Uniquement ce qui a été observé** : l'appelant écarte les
/// `NOT_OBSERVED` — une compétence que le correcteur n'a pas pu voir n'est pas
/// une compétence faible, et l'inscrire ici la ferait lire comme telle.
///
/// ⚠️ **L'état affiché est l'état AGRÉGÉ** (`SkillMasteryState`), pas la nature
/// d'une action : ici on décrit une compétence, pas ce qu'il y a à y faire.
/// C'est exactement l'inverse des cartes de « Mes priorités ». Trois grains,
/// trois endroits — ils ne se remplacent pas.
///
/// ⚠️ Verrouillée, la compétence garde son **résultat mesuré en clair** : on
/// floute l'action pas encore accessible, jamais le résultat. Seul le cadenas
/// s'ajoute, et le tap ouvre l'offre au lieu des sujets.
class PlanObservedSkillsSection extends StatefulWidget {
  const PlanObservedSkillsSection({
    super.key,
    required this.skills,
    required this.total,
  });

  /// Les compétences réellement observées, dans l'ordre **servi**.
  final List<LearningPlanSkill> skills;

  /// Le compte servi par le serveur (`observedSkillCount`), jamais recompté ici.
  final int total;

  @override
  State<PlanObservedSkillsSection> createState() =>
      _PlanObservedSkillsSectionState();
}

/// Combien de cartes avant le repli — miroir du web (`VISIBLE_SKILLS`) : le
/// brief interdit de dérouler les 48 d'un coup.
const int _visibleSkills = 6;

class _PlanObservedSkillsSectionState extends State<PlanObservedSkillsSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final skills = widget.skills;
    if (skills.isEmpty) return const SizedBox.shrink();

    final shown =
        _showAll ? skills : skills.take(_visibleSkills).toList(growable: false);
    final total = widget.total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: kPlanObservedTitle,
          action: Text(
            '$total observée${total > 1 ? 's' : ''}',
            style: AppFonts.ui(size: 12.5, color: AppColors.inkFaint),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            kPlanObservedText,
            style: AppFonts.ui(size: 12, height: 1.35, color: AppColors.inkSoft),
          ),
        ),
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
              for (var i = 0; i < shown.length; i++)
                _ObservedRow(skill: shown[i], first: i == 0),
            ],
          ),
        ),
        if (skills.length > _visibleSkills) ...[
          const SizedBox(height: 10),
          AppButton(
            label: _showAll ? kPlanObservedLess : kPlanObservedMore,
            icon: _showAll ? LucideIcons.chevronUp : LucideIcons.chevronDown,
            variant: AppButtonVariant.outline,
            height: 46,
            onPressed: () => setState(() => _showAll = !_showAll),
          ),
        ],
      ],
    );
  }
}

class _ObservedRow extends ConsumerWidget {
  const _ObservedRow({required this.skill, required this.first});

  final LearningPlanSkill skill;
  final bool first;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = skill.promptCount;
    final attempted = total == 0 ? 0 : skill.attemptedCount.clamp(0, total);
    final percent = total == 0 ? 0.0 : (attempted / total) * 100;
    final mastery = skill.masteryState;

    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: () => skill.locked
            ? unawaited(showTcfLockPaywall(
                context,
                ref: ref,
                ctaLocation: AnalyticsCtaLocation.lockedPlan,
              ))
            : openPlanSkill(context, skill.skillId, skill.section),
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
          decoration: BoxDecoration(
            border: first
                ? null
                : const Border(top: BorderSide(color: AppColors.lineSoft)),
          ),
          child: Row(
            children: [
              ProgressRing(
                value: percent,
                size: 42,
                stroke: 5,
                label: total == 0 ? '—' : '$attempted/$total',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.ui(
                        size: 14,
                        weight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${skill.section.label} · '
                      '${skillProgressLabel(
                        promptCount: skill.promptCount,
                        attemptedCount: skill.attemptedCount,
                        validatedCount: skill.validatedCount,
                      )}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.ui(size: 12, color: AppColors.inkFaint),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 🛑 Le **résultat mesuré** reste net même verrouillé : ce sont
              // ses propres productions. Seul le cadenas s'ajoute.
              if (skill.locked) ...[
                const PremiumLockPill(size: 22),
                const SizedBox(width: 6),
              ],
              if (mastery != null)
                SkillMasteryTag(state: mastery)
              else
                Text(
                  skill.status.label,
                  style: AppFonts.ui(size: 12, color: AppColors.inkFaint),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
