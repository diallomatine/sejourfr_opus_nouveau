import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Palette d'accent par numéro de tâche TCF Expression : utilisée par les
/// pastilles circulaires du hub (`_TaskRow`), de l'historique cartes
/// (`_RecentSingleRow`, `HistorySessionCard`) et partout où l'on identifie
/// visuellement T1/T2/T3.
///
/// Retourne `(background teinté, foreground texte)`.
(Color, Color) taskPalette(int tache) {
  switch (tache) {
    case 1:
      return (AppColors.green.withValues(alpha: 0.14), AppColors.green);
    case 2:
      return (AppColors.amber.withValues(alpha: 0.18), AppColors.amber);
    default:
      return (AppColors.red.withValues(alpha: 0.12), AppColors.red);
  }
}
