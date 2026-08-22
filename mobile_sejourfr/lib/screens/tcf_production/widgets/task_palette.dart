import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Palette d'accent par numéro de tâche TCF Expression : les cartes de tâche
/// et la carte de consigne du parcours, les pastilles de l'historique
/// (`HistorySessionCard`) et partout où l'on identifie visuellement T1/T2/T3.
///
/// C'est **la** table des trois teintes de tâche — la maquette en propose une
/// autre (bleu / violet / rouge), sans équivalent dans la palette produit : on
/// garde celle-ci plutôt que d'inventer un violet.
///
/// Retourne `(background teinté, foreground texte)`.
(Color, Color) taskPalette(int tache) {
  switch (tache) {
    case 1:
      return (AppColors.green.withValues(alpha: 0.14), AppColors.green);
    case 2:
      // `amber` est un ambre de **remplissage** : en lettres sur ce fond, il
      // n'est pas lisible. Toute mention ambre écrite passe par `amberDark`.
      return (AppColors.amber.withValues(alpha: 0.18), AppColors.amberDark);
    default:
      return (AppColors.red.withValues(alpha: 0.12), AppColors.red);
  }
}
