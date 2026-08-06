import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/skill_models.dart';
import '../../../../core/theme/app_theme.dart';

/// Auto-évaluation facultative, avant validation. Les libellés sont ceux du
/// contrat, mot pour mot.
///
/// Elle n'influence **jamais** le verdict de l'IA : c'est un miroir pour le
/// candidat, pas une note. Un second tap sur le choix actif le désélectionne —
/// « facultative » veut dire qu'on peut revenir en arrière.
class SelfEvaluationPicker extends StatelessWidget {
  const SelfEvaluationPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.accent = AppColors.blue,
  });

  final SkillSelfEvaluation? value;
  final ValueChanged<SkillSelfEvaluation?> onChanged;
  final bool enabled;

  /// Accent du module (rouge en EO). Bleu par défaut.
  final Color accent;

  @override
  Widget build(BuildContext context) {
    // `.self-eval` du prototype : un encadré gris qui porte son titre, sa
    // phrase d'explication, puis les trois choix.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Avant de comparer',
            style: AppFonts.ui(size: 12.5, weight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Penses-tu avoir respecté le critère annoncé ? Cette '
            "auto-évaluation n'influence pas la correction.",
            style: AppFonts.ui(
              size: 10.5,
              height: 1.4,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 10),
          for (final option in SkillSelfEvaluation.values) ...[
            _Option(
              option: option,
              selected: value == option,
              enabled: enabled,
              accent: accent,
              onTap: () => onChanged(value == option ? null : option),
            ),
            if (option != SkillSelfEvaluation.values.last)
              const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.accent,
    required this.onTap,
  });

  final SkillSelfEvaluation option;
  final bool selected;
  final bool enabled;
  final Color accent;
  final VoidCallback onTap;

  IconData get _icon => switch (option) {
        SkillSelfEvaluation.reussi => LucideIcons.smile,
        SkillSelfEvaluation.incertain => LucideIcons.meh,
        SkillSelfEvaluation.difficile => LucideIcons.frown,
      };

  @override
  Widget build(BuildContext context) {
    final fg = selected ? accent : AppColors.inkFaint;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: selected ? accent.withValues(alpha: 0.09) : AppColors.white,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected
                    ? accent.withValues(alpha: 0.45)
                    : AppColors.line,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Icon(_icon, size: 17, color: fg),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    option.label,
                    style: AppFonts.ui(
                      size: 12.5,
                      weight: FontWeight.w900,
                      color: selected ? accent : AppColors.inkSoft,
                    ),
                  ),
                ),
                if (selected)
                  Icon(LucideIcons.circleCheck, size: 16, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
