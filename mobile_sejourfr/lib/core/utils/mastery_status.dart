import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Palier de progression basé sur la MAÎTRISE = bonnes réponses / total de
/// questions du module (ou sous-module). C'est la formule de progression
/// unique de l'app : « combien de questions du programme je sais réussir »,
/// pas « combien j'en ai vues » (couverture) ni « mon taux sur ce que j'ai
/// tenté » (précision).
///
/// Source unique de vérité des badges + couleurs de barre de l'écran
/// Progression, des hubs TCF/Civique, du home et du détail sous-module.
/// [hasAnswered] distingue « jamais commencé » d'un vrai 0 % (tout faux).
class MasteryStatus {
  const MasteryStatus({required this.label, required this.color});

  final String label;
  final Color color;

  /// Fond léger pour un chip/pastille adossé à [color].
  Color get softBg => color.withValues(alpha: 0.12);

  static MasteryStatus of({
    required bool hasAnswered,
    required double mastery,
  }) {
    if (!hasAnswered) {
      return const MasteryStatus(label: 'À démarrer', color: AppColors.muted);
    }
    if (mastery < 0.40) {
      return const MasteryStatus(label: 'À retravailler', color: AppColors.red);
    }
    if (mastery < 0.65) {
      return const MasteryStatus(label: 'En progrès', color: AppColors.amber);
    }
    if (mastery < 0.85) {
      return const MasteryStatus(label: 'Bon niveau', color: AppColors.blue);
    }
    return const MasteryStatus(label: 'Maîtrisé', color: AppColors.green);
  }
}
