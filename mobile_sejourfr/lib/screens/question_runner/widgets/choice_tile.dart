import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/question_models.dart';
import '../../../core/theme/app_theme.dart';

/// Une réponse possible affichée dans le runner (cf. `MQuestion` maquette).
/// 4 états visuels :
///   - idle (non sélectionnée, pas de correction)
///   - selected (cochée, en cours de saisie — bleu)
///   - correct (révélée correcte — vert, check dans la pastille)
///   - incorrect (révélée fausse — rouge, croix dans la pastille)
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.choice,
    required this.index,
    required this.selected,
    required this.showCorrection,
    required this.onTap,
    this.isCorrect,
    this.letterKeyMode = false,
  });

  final ChoiceDto choice;
  final int index;
  final bool selected;
  final bool showCorrection;
  final VoidCallback? onTap;

  /// Mode TCF CO FULL_AUDIO : le label du choix est une lettre-clé (A/B/C/D)
  /// citée par l'audio. On affiche cette lettre dans la pastille et on masque
  /// le texte. Décidé au niveau de la question ([QuestionDto.usesLetterKeyChoices])
  /// pour ne PAS s'appliquer à un choix isolé d'une autre épreuve (ex. « y »).
  final bool letterKeyMode;

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
    Color letterBg = AppColors.surface3;
    Color letterColor = AppColors.inkSoft;
    IconData? mark;

    final correct = isCorrect ?? choice.correct;

    if (showCorrection) {
      if (correct) {
        background = AppColors.greenLight;
        border = AppColors.green;
        letterBg = AppColors.green;
        letterColor = AppColors.white;
        mark = LucideIcons.check;
      } else if (selected) {
        background = AppColors.redLight;
        border = AppColors.red;
        letterBg = AppColors.red;
        letterColor = AppColors.white;
        mark = LucideIcons.x;
      } else {
        textColor = AppColors.muted;
      }
    } else if (selected) {
      background = AppColors.blueLight;
      border = AppColors.blue;
      letterBg = AppColors.blue;
      letterColor = AppColors.white;
    }

    // Mode TCF CO FULL_AUDIO : la pastille affiche la lettre-clé du label
    // (A/B/C/D citée par l'audio) et le texte redondant est masqué. Sinon la
    // pastille suit l'index d'affichage. Le mode est décidé par la question,
    // pas par la forme d'un choix isolé.
    final letter = letterKeyMode
        ? choice.label.trim().toUpperCase()
        : String.fromCharCode('A'.codeUnitAt(0) + index);

    final emphasized =
        selected || (showCorrection && (isCorrect ?? choice.correct));

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: showCorrection ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            border: Border.all(
              color: border,
              width: emphasized ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: letterBg,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: mark != null
                    ? Icon(mark, size: 16, color: letterColor)
                    : Text(
                        letter,
                        style: AppFonts.ui(
                          size: 13,
                          weight: FontWeight.w700,
                          color: letterColor,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: letterKeyMode
                    ? const SizedBox.shrink()
                    : Text(
                        choice.label,
                        style: AppFonts.ui(
                          size: 15,
                          weight: FontWeight.w500,
                          color: textColor,
                          height: 1.35,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
