import 'package:flutter/material.dart';

import '../../../../core/models/skill_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../../widgets/production_blocks.dart';

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
            const ProductionChevron(),
          ],
        ),
      ),
    );
  }
}

/// État d'une compétence en une phrase, depuis les **compteurs servis par
/// `GET /api/skills`** — aucun agrégat inventé.
///
/// ⚠️ **Libellé gelé**, miroir mot pour mot du web
/// (`competenceProgressLabel`, `lib/skill-progress.ts`). Les deux fronts en
/// tiennent chacun une copie écrite à la main : un libellé qui bouge, ce sont
/// deux fichiers à changer dans la même passe, et deux tests.
String competenceProgressLabel(SkillDto skill) {
  final total = skill.promptCount;
  if (total == 0) return 'Bientôt disponible';

  final attempted = skill.attemptedCount.clamp(0, total);
  if (attempted == 0) return '$total à découvrir';

  final validated = skill.validatedCount.clamp(0, attempted);
  final head = validated > 0
      ? '$validated réussi${validated > 1 ? 's' : ''}'
      : '$attempted commencé${attempted > 1 ? 's' : ''}';

  final remaining = total - attempted;
  if (remaining == 0) return head;
  return '$head · $remaining restant${remaining > 1 ? 's' : ''}';
}
