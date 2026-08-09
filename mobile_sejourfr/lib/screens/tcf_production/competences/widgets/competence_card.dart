import 'package:flutter/material.dart';

import '../../../../core/models/skill_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/skill_progress.dart';
import '../../../../core/widgets/pressable_card.dart';
import '../../../../core/widgets/progress_ring.dart';

/// Ligne d'une compétence, structure de la maquette client : **anneau de
/// progression** (« 2/5 »), titre, état en clair, chevron.
///
/// L'anneau a remplacé la pastille de numéro + barre fine : le rang d'une
/// compétence dans sa tâche n'apprend rien au candidat, alors que « où j'en
/// suis sur cette compétence » est exactement ce qu'il vient chercher.
///
/// La progression se lit en **sujets traités** (et non validés — §12 de la
/// spec) : c'est ce que dit l'anneau. Les sujets réussis, eux, sont nommés
/// dans le libellé.
class CompetenceCard extends StatelessWidget {
  const CompetenceCard({
    super.key,
    required this.skill,
    required this.accent,
    required this.onTap,
  });

  final SkillDto skill;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final complete = skill.isComplete;
    final tone = complete ? AppColors.green : accent;

    return PressableCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ProgressRing(
              value: skill.progress * 100,
              size: 46,
              stroke: 5,
              color: tone,
              label: '${skill.attemptedCount}',
              sub: '/${skill.promptCount}',
              textColor: tone,
              subColor: AppColors.inkFaint,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.title,
                    style: AppFonts.ui(
                      size: 14.5,
                      weight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    competenceProgressLabel(skill),
                    style: AppFonts.ui(
                      size: 11.5,
                      weight: FontWeight.w600,
                      color: AppColors.inkSoft,
                    ),
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

/// État d'une compétence en une phrase, depuis les **compteurs servis par
/// `GET /api/skills`** — aucun agrégat inventé.
///
/// La règle vit dans `core/utils/skill_progress.dart` depuis que le Plan la
/// lit aussi, sur les compteurs de `GET /api/me/plan` : ici on ne fait que
/// l'appliquer à un [SkillDto].
String competenceProgressLabel(SkillDto skill) => skillProgressLabel(
      promptCount: skill.promptCount,
      attemptedCount: skill.attemptedCount,
      validatedCount: skill.validatedCount,
    );
