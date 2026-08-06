import 'package:flutter/material.dart';

import '../../../../core/models/skill_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/progress_track.dart';
import '../../widgets/production_blocks.dart';

/// Carte d'une compétence (`.skill-card` du prototype) : grille
/// `48px 1fr auto`, `gap 12`, `padding 15`, `radius 23`, ombre douce.
///
/// La progression se lit en **sujets traités** (et non validés — §12 de la
/// spec) : c'est ce que dit la barre et ce que dit le compteur.
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
    final done = skill.attemptedCount;
    final total = skill.promptCount;
    final complete = skill.isComplete;

    return PressableCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ProductionIndexChip(
              order: skill.displayOrder,
              done: complete,
              foreground: complete ? AppColors.green : accent,
              background: complete
                  ? AppColors.greenLight
                  : accent.withValues(alpha: 0.10),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skill.title,
                    style: AppFonts.ui(
                      size: 15,
                      weight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(
                        child: ProgressTrack(
                          value: skill.progress * 100,
                          color: complete ? AppColors.green : accent,
                          height: 5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _countLabel(done, total),
                        style: AppFonts.ui(
                          size: 11,
                          weight: FontWeight.w800,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const ProductionChevron(),
          ],
        ),
      ),
    );
  }

  String _countLabel(int done, int total) {
    final base = '$done/$total traités';
    return skill.validatedCount > 0 ? '$base · ${skill.validatedCount} ✓' : base;
  }
}
