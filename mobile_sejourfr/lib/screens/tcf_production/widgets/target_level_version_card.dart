import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';
import '../production_result_labels.dart';
import 'results_section_head.dart';

/// **La marche au-dessus** : la reponse du candidat reecrite au palier qu'il
/// VISE, plus les deux ou trois leviers qui l'en separent.
///
/// **C'est le SEUL texte modele de l'ecran** depuis le 2026-08-08 :
/// `version_amelioree` (qui reecrivait la production au niveau **deja
/// constate**, en bascule sous la redaction) n'est plus affichee nulle part.
/// Elle etait le texte le plus visible et le plus copiable de l'ecran, et
/// recopier un modele ecrit a son propre niveau ne fait pas monter d'un palier
/// — mesure : meme note, meme niveau au dixieme pres.
///
/// D'ou la forme : **section titree a part**, teinte bleue, titre qui nomme le
/// niveau vise, et sous-titre qui dit explicitement que ce texte n'est pas
/// celui du candidat.
///
/// Rien n'est rendu quand le bloc est absent : EO, evaluation anterieure,
/// second appel LLM en echec, ou niveau vise deja atteint. Pas de squelette,
/// pas de « non disponible ». Miroir web : `TargetLevelVersionCard.tsx`.
class TargetLevelVersionCard extends StatelessWidget {
  const TargetLevelVersionCard({super.key, required this.version});

  final VersionCiblee? version;

  @override
  Widget build(BuildContext context) {
    final v = version;
    if (v == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResultsSectionHead(title: versionCibleeTitle(v.niveauVise)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.blue.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.arrowUpRight,
                    size: 15,
                    color: AppColors.blue,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      kVersionCibleeEyebrow.toUpperCase(),
                      style: AppFonts.label(size: 10, color: AppColors.blue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                versionCibleeIntro(v.niveauVise),
                style: AppFonts.ui(
                  size: 12.5,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 11),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Text(
                  v.texte,
                  style: AppFonts.ui(
                    size: 13.5,
                    color: AppColors.ink,
                    height: 1.6,
                  ),
                ),
              ),
              if (v.ceQuiManque.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  kVersionCibleeLeviersTitle,
                  style: AppFonts.ui(
                    size: 13,
                    weight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                // Ordre du backend PRESERVE : il est trie du plus rentable au
                // moins rentable, le numero le rend lisible sans le retrier.
                for (var i = 0; i < v.ceQuiManque.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _Levier(rank: i + 1, texte: v.ceQuiManque[i]),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Levier extends StatelessWidget {
  const _Levier({required this.rank, required this.texte});

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
