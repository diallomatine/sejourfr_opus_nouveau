import 'package:flutter/material.dart';

import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';

/// Pastille de niveau colorée par le helper canonique. C1/C2 restent lisibles
/// uniquement pour les anciennes évaluations ; le profil actif s'arrête à B2.
/// [CecrlColor] du thème (ambre A1/A2, bleu B1, vert B2+) — mêmes couleurs
/// que le hub TCF et le bilan d'examen. Distincte du `AppTag` existant
/// (CSP/CR/NAT) qui sert pour les parcours.
class LevelPill extends StatelessWidget {
  const LevelPill({super.key, required this.level, this.small = false});

  final NiveauCecrl level;
  final bool small;

  Color get _textColor => level.color;

  Color get _bgColor => level.color.withValues(alpha: 0.12);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        // Forme COURTE dans une pastille : `A1_NON_ATTEINT` s'y rend « <A1 »,
        // jamais « A1 non atteint », qui déborde et annonce un palier que le
        // candidat n'a justement pas atteint (règle unique, `NiveauCecrl`).
        level.shortName,
        style: AppFonts.ui(
          size: small ? 11 : 12,
          weight: FontWeight.w700,
          color: _textColor,
        ),
      ),
    );
  }
}
