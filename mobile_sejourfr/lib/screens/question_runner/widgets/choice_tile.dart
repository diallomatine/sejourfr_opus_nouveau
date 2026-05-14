import 'package:flutter/material.dart';

import '../../../core/models/question_models.dart';
import '../../../core/theme/app_theme.dart';

/// Une réponse possible affichée dans le runner.
/// 4 états visuels :
///   - idle (non sélectionnée, pas de correction)
///   - selected (cochée, en cours de saisie)
///   - correct (révélée correcte)
///   - incorrect (révélée fausse)
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.choice,
    required this.index,
    required this.selected,
    required this.showCorrection,
    required this.onTap,
    this.isCorrect,
  });

  final ChoiceDto choice;
  final int index;
  final bool selected;
  final bool showCorrection;
  final VoidCallback? onTap;

  /// Vraie source de vérité quand le backend ne renvoie pas `correct` sur la
  /// question elle-même (cas standard pendant un attempt) : fournie par le
  /// parent à partir de `AnswerResult.correctChoiceIds`. Si non fournie, on
  /// retombe sur `choice.correct`.
  final bool? isCorrect;

  @override
  Widget build(BuildContext context) {
    Color background = AppColors.white;
    Color border = AppColors.line;
    Color textColor = AppColors.ink;
    Color letterBg = AppColors.line2;
    Color letterColor = AppColors.muted;
    Widget? trailing;

    final correct = isCorrect ?? choice.correct;

    if (showCorrection) {
      if (correct) {
        background = AppColors.green.withValues(alpha: 0.07);
        border = AppColors.green;
        letterBg = AppColors.green;
        letterColor = AppColors.white;
        trailing = const Icon(Icons.check_circle, color: AppColors.green);
      } else if (selected) {
        background = AppColors.redLight;
        border = AppColors.red;
        letterBg = AppColors.red;
        letterColor = AppColors.white;
        trailing = const Icon(Icons.cancel, color: AppColors.red);
      } else {
        textColor = AppColors.muted;
      }
    } else if (selected) {
      background = AppColors.blueSoft;
      border = AppColors.blue;
      letterBg = AppColors.blue;
      letterColor = AppColors.white;
    }

    final letter = String.fromCharCode('A'.codeUnitAt(0) + index);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: showCorrection ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: border,
              width: (selected || (showCorrection && (isCorrect ?? choice.correct))) ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: letterBg,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  letter,
                  style: AppFonts.jakarta(
                    size: 13,
                    weight: FontWeight.w800,
                    color: letterColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  choice.label,
                  style: AppFonts.jakarta(
                    size: 14,
                    weight: FontWeight.w500,
                    color: textColor,
                    height: 1.35,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
