import 'package:flutter/material.dart';

import '../../../../core/models/diagnostic_models.dart';
import '../../../../core/models/skill_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format_date.dart';
import '../../../../core/widgets/app_tag.dart';
import '../../widgets/production_blocks.dart';

/// La frise d'une compétence : ce qui a été constaté, quand, et dans quoi —
/// **du plus ancien au plus récent**, le sens dans lequel un parcours se lit.
/// L'ordre vient du serveur, il n'est pas retrié ici.
///
/// Ce que cette frise apprend au candidat, aucun pourcentage ne le dirait :
/// « Diagnostic : prioritaire → Entraînement ciblé : à renforcer → Production
/// complète : solide ». L'état agrégé qu'elle produit, lui, est la pilule de
/// maîtrise portée par la carte de la compétence.
///
/// **Trajectoire vide ⇒ aucune section** (`SizedBox.shrink`), pas d'encart
/// d'excuse : une compétence jamais observée n'a rien à raconter.
///
/// `confidence` n'est **jamais** affichée : c'est la certitude du correcteur,
/// pas une information sur le niveau du candidat.
///
/// Miroir de `SkillTrajectory` côté web.
class SkillTrajectorySection extends StatelessWidget {
  const SkillTrajectorySection({super.key, required this.points});

  final List<SkillObservationPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProductionSectionHead(
          title: 'Ton parcours sur cette compétence',
          description: 'Ce que tes productions ont montré, dans l\'ordre.',
        ),
        const SizedBox(height: 11),
        for (var i = 0; i < points.length; i++)
          _TrajectoryRow(point: points[i], last: i == points.length - 1),
      ],
    );
  }
}

class _TrajectoryRow extends StatelessWidget {
  const _TrajectoryRow({required this.point, required this.last});

  final SkillObservationPoint point;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final explanation = point.explanation?.trim();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pastille + filet : c'est le filet qui fait lire une progression
          // plutôt qu'une pile de lignes. Il s'arrête au dernier repère.
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: point.status.color,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(width: 2, color: AppColors.line),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 7,
                    runSpacing: 5,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        point.source.label,
                        style: AppFonts.ui(size: 13, weight: FontWeight.w800),
                      ),
                      AppTag(
                        label: point.status.label,
                        tone: _tone(point.status),
                        compact: true,
                      ),
                      Text(
                        formatLongDate(point.observedAt),
                        style: AppFonts.mono(
                          size: 10,
                          weight: FontWeight.w700,
                          color: AppColors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                  // Le constat du correcteur, en second plan : la ligne se lit
                  // d'abord par sa source et son verdict.
                  if (explanation != null && explanation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      explanation,
                      style: AppFonts.ui(
                        size: 12.5,
                        height: 1.4,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Même échelle que la pilule de maîtrise : un verdict ne change pas de couleur
/// d'un écran à l'autre.
TagTone _tone(LearningPlanSkillStatus status) => switch (status) {
      LearningPlanSkillStatus.priority => TagTone.red,
      LearningPlanSkillStatus.toReinforce => TagTone.amber,
      LearningPlanSkillStatus.solid => TagTone.success,
      LearningPlanSkillStatus.notObserved => TagTone.neutral,
    };
