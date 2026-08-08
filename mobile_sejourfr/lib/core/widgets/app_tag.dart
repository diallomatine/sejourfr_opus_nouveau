import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../theme/app_theme.dart';

enum TagTone { blue, red, neutral, success, amber, ghost }

/// Badge pill de la refonte 2026 (cf. `Badge` maquette) : fond teinté doux,
/// Hanken 12 w600, icône optionnelle. Le libellé est rendu tel quel.
class AppTag extends StatelessWidget {
  const AppTag({
    super.key,
    required this.label,
    this.tone = TagTone.blue,
    this.icon,
    this.compact = false,
  });

  final String label;
  final TagTone tone;
  final IconData? icon;

  /// Pilule du prototype « Compétences » : plus petite (10 px) et beaucoup plus
  /// grasse (w900), padding 9/6 — c'est cette graisse qui fait l'identité des
  /// badges de la maquette. **Opt-in** : les appelants historiques gardent leur
  /// rendu au pixel près.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;

    switch (tone) {
      case TagTone.blue:
        bg = AppColors.blueLight;
        fg = AppColors.blueDark;
        break;
      case TagTone.red:
        bg = AppColors.redLight;
        fg = AppColors.red;
        break;
      case TagTone.success:
        bg = AppColors.greenLight;
        fg = AppColors.green;
        break;
      case TagTone.amber:
        bg = AppColors.amberLight;
        fg = AppColors.amberDark;
        break;
      case TagTone.neutral:
        bg = AppColors.surface3;
        fg = AppColors.inkSoft;
        break;
      case TagTone.ghost:
        bg = Colors.transparent;
        fg = AppColors.inkSoft;
        break;
    }

    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 9, vertical: 6)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: tone == TagTone.ghost
            ? Border.all(color: AppColors.line)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 11 : 13, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppFonts.ui(
              size: compact ? 10 : 12,
              weight: compact ? FontWeight.w900 : FontWeight.w600,
              color: fg,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ton de badge portant [accent] comme teinte pleine.
///
/// Pont entre les deux representations d'une meme couleur : une [Color] pour
/// les barres, icones et gros chiffres ; un [TagTone] pour les pills. Sans lui,
/// chaque regle « telle valeur vaut telle teinte » devrait etre ecrite deux
/// fois et tenue synchrone a la main.
TagTone tagToneForAccent(Color accent) {
  if (accent == AppColors.blue || accent == AppColors.blueDark) {
    return TagTone.blue;
  }
  if (accent == AppColors.red || accent == AppColors.redDark) {
    return TagTone.red;
  }
  if (accent == AppColors.green) return TagTone.success;
  if (accent == AppColors.amber) return TagTone.amber;
  return TagTone.neutral;
}

/// Ton d'un badge portant un niveau CECRL. **Derive de [CecrlColor]** : les
/// paliers ne sont declares qu'une fois, dans `core/theme/app_theme.dart` ; ici
/// on ne fait que traduire la teinte obtenue dans le vocabulaire des badges.
///
/// **Jamais de rouge pour un niveau** : une note de production se lit sur
/// l'echelle du TCF, pas comme une note scolaire. 12/20 vaut B2, le palier le
/// plus haut de l'examen ; le peindre en rouge dirait l'inverse de ce qu'il
/// vaut. La regle tient parce qu'aucun niveau n'est teinte `AppColors.red`.
extension CecrlTagTone on NiveauCecrl {
  TagTone get tagTone => tagToneForAccent(color);
}
