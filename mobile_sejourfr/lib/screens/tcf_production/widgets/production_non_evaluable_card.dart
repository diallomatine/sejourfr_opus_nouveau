import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../production_result_labels.dart';

/// Ce que voit le candidat quand sa production a bien été rendue mais que
/// **rien n'a pu y être observé** (`ProductionEvaluabilite.nonEvaluable`) :
/// production vide ou quasi vide, langue non française, consigne recopiée.
///
/// Elle remplace le rapport **en entier** — pas de bandeau de niveau, pas de
/// pastille de palier, pas de barre des paliers, pas de profil par critère.
/// Le serveur ne rend plus rien de tout ça (`scores_criteres` est absent, note
/// et niveau sont `null`) : l'écran affichait un bloc « critères » vide et une
/// ligne « Niveau indisponible », sans jamais dire au candidat ce qui s'était
/// passé.
///
/// 🛑 **Ni reproche, ni verdict déguisé.** Une absence de preuve n'est pas la
/// preuve du niveau le plus faible — c'est exactement le défaut que le backend
/// vient de retirer de sa base. D'où l'ambre (attention) et non le rouge
/// (échec), et un texte qui décrit la **production**, jamais le candidat.
///
/// Les raisons viennent du serveur et sont déjà rédigées pour le candidat : on
/// les rend telles quelles, sans en réécrire une seule.
class ProductionNonEvaluableCard extends StatelessWidget {
  const ProductionNonEvaluableCard({
    super.key,
    this.eyebrow,
    this.raisons = const [],
  });

  /// Situe la tâche (« Expression écrite · Tâche 1 »), comme sur le hero d'un
  /// rapport normal. `null` depuis un contexte qui ne la connaît pas.
  final String? eyebrow;

  /// `feedback.confiance_raisons`, à défaut `feedback.avertissements`. Vide est
  /// un cas normal : la carte se suffit alors à elle-même.
  final List<String> raisons;

  @override
  Widget build(BuildContext context) {
    final situe = eyebrow;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (situe != null) ...[
            Text(
              situe.toUpperCase(),
              style: AppFonts.label(size: 11, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              const Icon(
                LucideIcons.circleAlert,
                size: 15,
                color: AppColors.amberDark,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  kProductionNonEvaluableEyebrow.toUpperCase(),
                  style: AppFonts.label(size: 10, color: AppColors.amberDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            kProductionNonEvaluableTitle,
            style: AppFonts.display(
              size: 20,
              weight: FontWeight.w700,
              color: AppColors.ink,
            ).copyWith(height: 1.2),
          ),
          const SizedBox(height: 9),
          Text(
            kProductionNonEvaluableIntro,
            style: AppFonts.ui(size: 13.5, color: AppColors.ink2, height: 1.55),
          ),
          if (raisons.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              kProductionNonEvaluableRaisonsTitle.toUpperCase(),
              style: AppFonts.label(size: 10, color: AppColors.muted),
            ),
            for (final raison in raisons) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5, right: 8),
                    child: _Puce(),
                  ),
                  Expanded(
                    child: Text(
                      raison,
                      style: AppFonts.ui(
                        size: 13,
                        color: AppColors.ink2,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 14),
          Text(
            kProductionNonEvaluableRassurance,
            style: AppFonts.ui(size: 12.5, color: AppColors.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// Puce neutre : une liste de constats, pas une liste de fautes — donc ni
/// croix, ni icône d'erreur.
class _Puce extends StatelessWidget {
  const _Puce();

  @override
  Widget build(BuildContext context) => Container(
        width: 5,
        height: 5,
        decoration: const BoxDecoration(
          color: AppColors.amberDark,
          shape: BoxShape.circle,
        ),
      );
}
