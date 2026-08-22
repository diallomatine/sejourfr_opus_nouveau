import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/diagnostic_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/list_group.dart';
import '../plan_actions.dart';
import '../plan_labels.dart';
import 'plan_tokens.dart';

/// **Mon profil TCF** : les quatre domaines, dans l'ordre **servi**.
///
/// 🛑 Le serveur les trie déjà par urgence. **Aucun front ne retrie.**
///
/// Un domaine jamais mesuré n'est pas un domaine faible : il est **inconnu**.
/// Il garde sa ligne, sa pastille « À évaluer », et aucun niveau ne lui est
/// prêté.
class PlanProfileSection extends StatelessWidget {
  const PlanProfileSection({super.key, required this.plan});

  final LearningPlan plan;

  @override
  Widget build(BuildContext context) {
    final domains = plan.domaines;
    if (domains.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(title: kPlanProfileTitle),
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
              Container(
                padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.lineSoft),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        planProfileCoverage(plan.cycle, domains.length),
                        style: AppFonts.ui(
                          size: 13,
                          weight: FontWeight.w700,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                    for (final domain in domains) ...[
                      const SizedBox(width: 5),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: domain.evaluated
                              ? AppColors.blue
                              : AppColors.surface3,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.line),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              for (var i = 0; i < domains.length; i++)
                _DomainRow(domain: domains[i], first: i == 0),
            ],
          ),
        ),
      ],
    );
  }
}

class _DomainRow extends StatelessWidget {
  const _DomainRow({required this.domain, required this.first});

  final PlanDomain domain;
  final bool first;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.white,
        child: InkWell(
          onTap: () => openPlanDomain(context, domain.epreuve),
          child: Container(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
            decoration: BoxDecoration(
              border: first
                  ? null
                  : const Border(top: BorderSide(color: AppColors.lineSoft)),
            ),
            child: Row(
              children: [
                PlanDomainTile(
                  epreuve: domain.epreuve,
                  filled: domain.priority == PlanDomainPriority.forte,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planDomainLabel(domain.epreuve),
                        style: AppFonts.ui(
                          size: 14.5,
                          weight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        planDomainSubtitle(domain),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.ui(
                          size: 12.5,
                          height: 1.35,
                          color: AppColors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PlanDomainPriorityTag(priority: domain.priority),
              ],
            ),
          ),
        ),
      );
}

/// **Compléter mon profil** : par quoi mesurer les domaines jamais évalués.
///
/// 🛑 C'est **la seule** réponse à « comment compléter mon profil ». Une série
/// ciblée est un entraînement : elle ne rend jamais un domaine « évalué ». La
/// liste est **vide quand le profil est complet** — état visé, pas anomalie :
/// l'appelant ne construit alors pas la section.
class PlanCompleteProfileSection extends ConsumerWidget {
  const PlanCompleteProfileSection({
    super.key,
    required this.assessments,
  });

  final List<PlanDomainAssessment> assessments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(title: kPlanCompleteProfileTitle),
        const SizedBox(height: 10),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 14, 15, 12),
                child: Text(
                  kPlanCompleteProfileText,
                  style: AppFonts.ui(
                    size: 13.5,
                    height: 1.55,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              for (final assessment in assessments)
                _AssessmentRow(assessment: assessment),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const PlanNote(kPlanNotEvaluatedNote),
      ],
    );
  }
}

class _AssessmentRow extends ConsumerWidget {
  const _AssessmentRow({required this.assessment});

  final PlanDomainAssessment assessment;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => openPlanAssessment(context, assessment),
          child: Container(
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.lineSoft)),
            ),
            child: Row(
              children: [
                PlanDomainTile(epreuve: assessment.epreuve, size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planDomainLabel(assessment.epreuve),
                        style: AppFonts.ui(
                          size: 14,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        // « Pas encore mesuré · Examen blanc n°1 · ≈ 20 min » —
                        // l'état d'abord, le parcours ensuite, comme sur le web.
                        '$kPlanDomainNotEvaluatedShort · '
                        '${planAssessmentMeta(assessment)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.ui(
                          size: 12.5,
                          height: 1.35,
                          color: AppColors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Le geste, nommé — comme sur le web (`planAssessmentCta`).
                // Un chevron seul ne disait pas ce que la ligne allait ouvrir :
                // un diagnostic, une production et un examen blanc ne coûtent
                // pas le même quart d'heure.
                Flexible(
                  child: Text(
                    planAssessmentCta(assessment),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AppFonts.ui(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: AppColors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 15,
                  color: AppColors.blue,
                ),
              ],
            ),
          ),
        ),
      );
}
