import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/skill_models.dart';
import '../../../core/theme/app_theme.dart';
import '../expression_labels.dart';
import '../production_catalog.dart';
import '../tcf_production_module.dart';
import 'production_common.dart';

/// **La tête d'une tâche d'expression** : ce qu'on va faire, la contrainte, la
/// consigne. Miroir web : `app/_components/production/TaskChrome.tsx`.
///
/// ⚠️ **Fond clair depuis le 2026-09-20** (demande du propriétaire). L'encart
/// était un aplat bleu plein qui pesait plus lourd que la liste de sujets qu'il
/// introduisait ; le bleu ne sert plus que d'**accent** — la pastille du niveau
/// visé, le libellé de la consigne et la contrainte. Le rouge reste réservé aux
/// CTA critiques.
///
/// La hiérarchie suit ce que le candidat cherche : l'**intitulé** de la tâche
/// est le titre (son rang reste dit, en sur-titre, parce que consignes et
/// corrigés parlent de « tâche 2 »), puis la **contrainte** — le fait le plus
/// utile avant de produire — puis la consigne.
///
/// Le widget lit lui-même ses deux sources : sans ça, ses deux écrans
/// (sujets complets, compétences ouvertes depuis le Plan) auraient chacun
/// recopié la même résolution.
class TaskBanner extends ConsumerWidget {
  const TaskBanner({
    super.key,
    required this.module,
    required this.tache,
    required this.onBack,
  });

  final TcfProductionModule module;
  final int tache;
  final VoidCallback onBack;

  SkillSection get _section => module.isEo ? SkillSection.eo : SkillSection.ee;

  /// Contrainte réelle de la tâche (longueur à l'écrit, durée à l'oral), lue
  /// sur son premier sujet publié. `null` quand l'API ne la porte pas : on
  /// n'invente jamais une consigne de longueur — les bornes vivent dans
  /// `production_tasks.mots_min/mots_max` côté serveur.
  String? _constraint(ProductionCatalog? catalog) {
    final subjects = catalog?.tasksForTache(tache) ?? const [];
    if (subjects.isEmpty) return null;
    return productionTaskConstraint(subjects.first, isOral: module.isEo);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = productionTaskMeta(module, tache);
    // 🛑 Le palier de la TÂCHE, lu sur le miroir gelé de l'enum backend —
    // aucun appel de plus. Il portait le palier de la **démarche du candidat**,
    // ce qui n'a rien à faire sur une tâche. C'est notre palier PÉDAGOGIQUE :
    // le libellé dit « Niveau visé », jamais « Palier » ni « Objectif ».
    final level = SkillTaskCode.values
        .firstWhere((t) => t.section == _section && t.tacheNumero == tache)
        .targetLevel
        .wire;
    final constraint =
        _constraint(ref.watch(productionCatalogProvider(module.epreuve)).valueOrNull);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: AppColors.surface2,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onBack,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 34,
                    height: 34,
                    child: Icon(
                      LucideIcons.arrowLeft,
                      size: 19,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tâche $tache · ${module.title}'.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.eyebrow(color: AppColors.inkFaint),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      meta.title,
                      style: AppFonts.display(size: 21, height: 1.18),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Pastille « NIVEAU VISÉ B1 » : le mot « visé » est porté par le
              // libellé partagé, sans lui le palier se lirait comme une règle
              // officielle du TCF IRN.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  niveauViseBadge(level).toUpperCase(),
                  style: AppFonts.label(size: 10.5, color: AppColors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.blueLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONSIGNE',
                  style: AppFonts.label(size: 10.5, color: AppColors.blue),
                ),
                // La contrainte est la PREMIÈRE chose lue de la consigne :
                // c'est elle qui cadre la production. Servie par
                // `production_tasks`, jamais un nombre écrit ici.
                if (constraint != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    constraint,
                    style: AppFonts.display(size: 24, color: AppColors.blue),
                  ),
                ],
                const SizedBox(height: 7),
                Text(
                  meta.intro,
                  style: AppFonts.ui(size: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La **tête commune** des deux écrans d'une tâche (sujets complets, et la
/// liste des compétences ouverte depuis le Plan), rendue en tête de leur liste
/// pour qu'elle défile avec elle plutôt que de rester collée en haut.
///
/// Elle est rendue quel que soit l'état de la liste — sans elle, une erreur de
/// chargement enfermerait le candidat dans l'écran, sans retour visible.
List<Widget> taskBannerTop(
  BuildContext context, {
  required TcfProductionModule module,
  required int tache,
}) =>
    [
      TaskBanner(
        module: module,
        tache: tache,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      const SizedBox(height: 14),
    ];
