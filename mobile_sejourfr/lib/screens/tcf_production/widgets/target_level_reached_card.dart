import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';
import '../production_result_labels.dart';
import 'results_section_head.dart';

/// **Objectif atteint** : ce qui prend la place de « la marche au-dessus »
/// quand le candidat tient deja le palier qu'il vise.
///
/// Avant, il n'y avait rien du tout a cet endroit — la section disparaissait en
/// silence. Depuis le retrait de `version_amelioree`, c'etait le seul texte
/// modele de l'ecran : le candidat qui **reussit** se retrouvait avec un
/// rapport plus vide que celui qui echoue, sans la moindre explication. Sa
/// reussite avait exactement la meme tete qu'une panne.
///
/// Le front ne **deduit** rien : il ne saurait pas distinguer « objectif
/// atteint » d'un second appel LLM en echec. C'est le serveur qui pose
/// `niveau_vise_atteint` (exclusif de [TargetLevelVersionCard]).
///
/// Teinte verte, pas bleue : le vert dit « palier tenu » dans toute l'app
/// (`CecrlColor`), et il n'y a ici aucune marche a monter. Miroir web :
/// `TargetLevelReachedCard.tsx`.
class TargetLevelReachedCard extends StatelessWidget {
  const TargetLevelReachedCard({super.key, required this.atteint});

  final NiveauViseAtteint? atteint;

  @override
  Widget build(BuildContext context) {
    final a = atteint;
    if (a == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResultsSectionHead(title: niveauViseAtteintTitle(a.niveauVise)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.green.withValues(alpha: 0.26)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.circleCheck,
                    size: 15,
                    color: AppColors.green,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      kNiveauViseAtteintEyebrow.toUpperCase(),
                      style: AppFonts.label(size: 10, color: AppColors.green),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                kNiveauViseAtteintIntro,
                style: AppFonts.ui(
                  size: 13,
                  color: AppColors.ink2,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
