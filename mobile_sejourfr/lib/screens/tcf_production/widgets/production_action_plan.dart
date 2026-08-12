import 'package:flutter/material.dart';

import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';
import 'action_plan.dart';
import 'results_section_head.dart';

/// **Le plan d'action** du candidat vers le palier qu'il vise : les leviers, une
/// version plus aboutie (ou, a l'oral, deux ou trois passages redits) et la
/// tournure a retenir.
///
/// C'est exactement ce que rend deja le module Competences apres un
/// micro-exercice — memes blocs, memes libelles, memes widgets
/// ([ActionPlanLeviers], [ActionPlanExempleCard], [ActionPlanMemoCard]). Seuls
/// les intertitres sont rendus ici, avec le gabarit du rapport de correction.
///
/// ⚠️ **Ce bloc ne dit plus « au niveau B2, votre reponse pourrait ressembler a
/// ceci ».** Rien ne verifie qu'un texte atteint le palier dont on l'etiquette,
/// et un candidat qui a recopie un exemple annonce B2 l'a vu noter B1. On retire
/// l'affirmation inverifiable ; on garde l'**objectif** (« Pour viser B2 »), qui
/// lui est exact. Meme correctif que celui deja applique aux petits sujets.
///
/// **Trois formes, plus l'absence** (cf. [VersionCiblee]) :
/// - v2 ecrit : leviers + version plus aboutie surlignee + a retenir ;
/// - v2 oral : leviers + reformulations + a retenir. **Aucun texte modele
///   complet** : la production orale n'est jamais reecrite en entier ;
/// - v1 (une centaine d'evaluations en base) : le texte modele et les leviers
///   en texte libre, rendus comme avant — mais sans l'etiquette de palier ;
/// - absent (second appel en echec, eval anterieure, oral degrade) ⇒ **rien**.
///   Pas de squelette, pas de « non disponible », pas d'encart d'excuse.
///
/// Chaque section se masque **independamment** : un plan sans « a retenir »
/// reste un plan. Miroir web : `ProductionActionPlan.tsx`.
class ProductionActionPlan extends StatelessWidget {
  const ProductionActionPlan({super.key, required this.version});

  final VersionCiblee? version;

  @override
  Widget build(BuildContext context) {
    final v = version;
    if (v == null) return const SizedBox.shrink();

    final hasLeviers = v.leviers.isNotEmpty;
    final hasLegacyLeviers = !hasLeviers && v.ceQuiManque.isNotEmpty;
    final texte = v.texte;
    final hasLegacyTexte =
        v.exempleCible == null && v.reformulations.isEmpty && texte != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasLeviers || hasLegacyLeviers) ...[
          ResultsSectionHead(title: pourViserTitle(v.niveauVise)),
          const SizedBox(height: 8),
          if (hasLeviers)
            ActionPlanLeviers(leviers: v.leviers)
          else
            // Contrat v1 : des phrases libres, pas des couples action/exemple.
            // Ordre du backend PRESERVE (du plus rentable au moins rentable) ;
            // le numero le rend lisible sans le retrier.
            _LegacyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < v.ceQuiManque.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _LegacyLevier(rank: i + 1, texte: v.ceQuiManque[i]),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 14),
        ],
        if (v.exempleCible != null) ...[
          const ResultsSectionHead(title: kActionPlanExempleTitle),
          const SizedBox(height: 8),
          ActionPlanExempleCard(exemple: v.exempleCible!),
          const SizedBox(height: 14),
        ],
        if (v.reformulations.isNotEmpty) ...[
          const ResultsSectionHead(title: kActionPlanReformulationsTitle),
          const SizedBox(height: 8),
          ActionPlanReformulationsList(reformulations: v.reformulations),
          const SizedBox(height: 14),
        ],
        if (hasLegacyTexte) ...[
          const ResultsSectionHead(title: kActionPlanExempleTitle),
          const SizedBox(height: 8),
          _LegacyCard(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                texte,
                style: AppFonts.ui(
                  size: 13.5,
                  color: AppColors.ink,
                  height: 1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (v.aRetenir != null) ...[
          ActionPlanMemoCard(memo: v.aRetenir!),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

/// Le cadre bleu des evaluations du contrat v1, conserve tel quel : elles n'ont
/// ni segments a surligner ni couples action/exemple a mettre en ligne.
class _LegacyCard extends StatelessWidget {
  const _LegacyCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.22)),
      ),
      child: child,
    );
  }
}

class _LegacyLevier extends StatelessWidget {
  const _LegacyLevier({required this.rank, required this.texte});

  final int rank;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$rank',
            style: AppFonts.label(size: 10, color: AppColors.blue),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            texte,
            style: AppFonts.ui(size: 13, color: AppColors.ink2, height: 1.5),
          ),
        ),
      ],
    );
  }
}
