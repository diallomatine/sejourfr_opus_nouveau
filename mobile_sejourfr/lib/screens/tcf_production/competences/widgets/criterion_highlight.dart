import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../widgets/production_blocks.dart';

/// Encart du **critère unique** travaillé (`.objective-card` du prototype) :
/// dégradé très clair de l'accent, `radius 19`, label « ◎ » en tête.
///
/// Affiché *avant* la production (§13.1 de la spec) : c'est la seule chose que
/// le candidat doit réussir sur ce sujet, et le seul angle que l'IA évaluera.
class CriterionHighlight extends StatelessWidget {
  const CriterionHighlight({
    super.key,
    required this.criterion,
    required this.accent,
    this.label = 'Compétence évaluée',
    this.icon = LucideIcons.target,
  });

  final String criterion;
  final Color accent;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppGradients.hero(
          accent.withValues(alpha: 0.10),
          accent.withValues(alpha: 0.03),
        ),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 7),
              Text(
                label.toUpperCase(),
                style: AppFonts.label(size: 10, color: accent)
                    .copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            criterion,
            style: AppFonts.ui(size: 13, weight: FontWeight.w800, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// Encart « Pourquoi cet exercice ? » (`.why-box`) — une phrase qui explique ce
/// que le critère apporte au TCF. Source : `skill.description`.
/// Bordure **pointillée**, comme la maquette et le web.
class WhyThisExercise extends StatelessWidget {
  const WhyThisExercise({super.key, required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DashedBox(
      radius: 16,
      color: AppColors.line,
      background: AppColors.surface2,
      padding: const EdgeInsets.all(11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 27,
            height: 27,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(LucideIcons.lightbulb, size: 14, color: accent),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Pourquoi cet exercice ?\n',
                    style: AppFonts.ui(
                      size: 11,
                      height: 1.45,
                      weight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: text,
                    style: AppFonts.ui(
                      size: 11,
                      height: 1.45,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chips de contraintes (`.requirements`) au-dessus de la zone de production :
/// longueur ou durée conseillée, palier, rappel du critère unique.
/// **Indicatif, jamais bloquant** (règle 15 de la spec).
class ConstraintChips extends StatelessWidget {
  const ConstraintChips({super.key, required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final label in labels)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(color: AppColors.line),
            ),
            child: Text(
              label,
              style: AppFonts.ui(
                size: 10,
                weight: FontWeight.w800,
                color: AppColors.inkSoft,
              ),
            ),
          ),
      ],
    );
  }
}
