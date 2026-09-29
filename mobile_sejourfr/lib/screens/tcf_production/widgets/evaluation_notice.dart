import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';

/// « À savoir sur cette évaluation » — la note de transparence du rapport,
/// posée **juste sous le bandeau de résultat**.
///
/// ⚠️ Ce texte n'est PAS produit par le correcteur : c'est le **serveur** qui
/// l'écrit. Il porte la limite assumée de l'évaluation orale et le signalement
/// des purges automatiques. C'est pour ca qu'il a survecu au retrait de
/// « Voir l'analyse complète » (contrat v15/v9, qui supprime `exemples_corriges`
/// et `suggestions`) : lui ne depend d'aucun champ du LLM.
///
/// **Une note, pas une carte** : pas de bordure, pas de section titree, pas
/// d'accordeon — elle se lit au passage et ne dispute pas la premiere lecture
/// au verdict. Liste vide ⇒ [SizedBox.shrink] : rien a dire, rien a afficher.
class EvaluationNotice extends StatelessWidget {
  const EvaluationNotice({super.key, required this.avertissements});

  final List<String> avertissements;

  @override
  Widget build(BuildContext context) {
    if (avertissements.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1, right: 9),
            child: Icon(LucideIcons.info, size: 15, color: AppColors.amberDark),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'À savoir sur cette évaluation',
                  style: AppFonts.ui(
                    size: 12,
                    weight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                for (final (index, message) in avertissements.indexed)
                  Padding(
                    padding: EdgeInsets.only(top: index == 0 ? 4 : 5),
                    child: Text(
                      message,
                      style: AppFonts.ui(
                        size: 12.5,
                        color: AppColors.muted,
                        height: 1.45,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
