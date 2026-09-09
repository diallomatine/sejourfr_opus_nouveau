import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';
import '../tcf_production_module.dart';

/// Petites briques partagées par le hub d'épreuve et l'écran d'une tâche,
/// extraites quand les deux écrans ont été séparés en fichiers dédiés.

/// Libellé éditorial d'une tâche : son intitulé et la phrase qui dit ce qu'on
/// y fait. Source unique — la carte de tâche, la carte de consigne et l'écran
/// des exemples corrigés la lisaient chacun de leur côté.
///
/// 🛑 **L'intitulé n'est PAS écrit ici** : il vient de [productionTaskTitle]
/// (`core/models/production_models.dart`), seule autorité du front et miroir
/// du web. Une copie locale avait divergé — « Message » ici, « Message simple »
/// dans le briefing d'examen et sur le web, pour la même tâche.
///
/// **Écrit et oral disent la même chose** : mêmes tâches, mêmes intentions,
/// seule la façon de produire change (rédiger ou parler).
///
/// ⚠️ Aucune **borne** ici (longueur de copie, durée de parole) : elles vivent
/// dans `production_tasks.mots_min/mots_max` / `duree_max_sec` et se lisent par
/// [productionTaskConstraint]. Un sous-titre « 30-60 mots » écrit en dur a
/// vécu ici sans lecteur — c'est exactement ce que le dépôt interdit de
/// recopier.
({String title, String intro}) productionTaskMeta(
  TcfProductionModule module,
  int tache,
) {
  final intro = module.isEo
      ? switch (tache) {
          1 =>
            "Tu te présentes et tu réponds aux questions de l'examinateur : ton parcours, tes goûts, tes projets.",
          2 =>
            'Tu joues une situation de la vie courante et tu poses les questions qu\'il faut pour obtenir ce que tu veux.',
          _ =>
            'Tu donnes ton point de vue sur un sujet et tu le défends avec des arguments et des exemples.',
        }
      : switch (tache) {
          1 =>
            'Tu réponds à un message court — invitation, demande, annonce — en traitant chaque point demandé.',
          2 =>
            'Tu racontes une expérience personnelle au passé, dans l\'ordre, avec ce que tu en as retenu.',
          _ =>
            'Tu donnes ton avis sur une question et tu l\'argumentes, en tenant compte de l\'avis opposé.',
        };
  return (title: productionTaskTitle(module.epreuve, tache), intro: intro);
}

/// Intitulé d'une tâche **précédé de son rang** — « Tâche 1 : Message simple ».
///
/// Le rang est un repère du candidat : les consignes, les corrigés et l'examen
/// lui-même parlent de « tâche 1 », « tâche 2 », « tâche 3 ». La pastille
/// numérotée de la carte ne suffit pas à le dire à voix haute.
///
/// ⚠️ **Miroir mot pour mot du web** (`productionTaskLabeledTitle`,
/// `lib/types.ts`) : la forme du préfixe se change des deux côtés dans la même
/// passe.
String productionTaskLabeledTitle(TcfProductionModule module, int tache) =>
    'Tâche $tache : ${productionTaskMeta(module, tache).title}';

/// Titre affiché en tête d'une **carte de sujet**.
///
/// Le backend sert un intitulé éditorial (`production_tasks.titre`, V028) —
/// « Message à un ami », « Invitation à un pique-nique » — parce que toutes
/// les consignes d'une même tâche commencent pareil : sans lui, vingt sujets
/// se ressemblent dans la liste.
///
/// **Le titre peut manquer** (contenu antérieur à V028, sujet créé en console
/// sans titre) : on retombe alors sur « Sujet N », jamais sur un titre vide ni
/// sur un texte de remplacement. Un titre blanc est traité comme absent.
///
/// ⚠️ **Libellé gelé**, miroir mot pour mot du web (`productionSubjectTitle`,
/// `lib/types.ts`). Les deux fronts en tiennent chacun une copie écrite à la
/// main : un libellé qui bouge, ce sont deux fichiers à changer dans la même
/// passe, et deux tests.
String productionSubjectTitle(String? titre, int ordre) {
  final propre = titre?.trim();
  return (propre == null || propre.isEmpty) ? 'Sujet $ordre' : propre;
}

/// Contrainte **réelle** d'un sujet, telle que servie par l'API : la longueur
/// à l'écrit (`30-60 mots`), la durée à l'oral (`3 min`).
///
/// `null` quand le champ est absent — **on n'invente jamais une borne** : les
/// bornes EE vivent dans `production_tasks.mots_min/mots_max` côté serveur et
/// une valeur écrite en dur ici contredirait la consigne donnée au correcteur
/// (cf. `CLAUDE.md` racine, « Bornes EE strictes TCF IRN »).
///
/// Source unique : la carte de sujet, le sélecteur de tâche et le héros la
/// composaient chacun de leur côté.
String? productionTaskConstraint(
  ProductionTaskDto task, {
  required bool isOral,
}) {
  if (isOral) {
    final max = task.dureeMaxSec;
    if (max == null) return null;
    final minutes = max ~/ 60;
    final seconds = max % 60;
    if (minutes == 0) return '$max s';
    return seconds == 0 ? '$minutes min' : '$minutes min $seconds';
  }
  final min = task.motsMin;
  final max = task.motsMax;
  if (min == null || max == null) return null;
  return '$min-$max mots';
}

/// Poignée de bottom sheet.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Center(
        child: Container(
          width: 38,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.line,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// Voile d'attente pendant le démarrage d'une session.
class BusyOverlay extends StatelessWidget {
  const BusyOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.scrim,
      child: Center(child: CircularProgressIndicator(color: AppColors.white)),
    );
  }
}

/// Phrase d'état discrète dans une liste (aucun passage, filtre vide…).
class MutedHint extends StatelessWidget {
  const MutedHint({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        text,
        style: AppFonts.ui(size: 12.5, color: AppColors.muted, height: 1.4),
      ),
    );
  }
}

/// Lien « Voir les N autres » en pied de liste.
class ShowMoreButton extends StatelessWidget {
  const ShowMoreButton({
    super.key,
    required this.label,
    required this.onTap,
    this.accent = AppColors.blue,
  });

  final String label;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Text(
          label,
          style: AppFonts.ui(size: 13, weight: FontWeight.w700, color: accent),
        ),
        label: Icon(LucideIcons.chevronDown, size: 18, color: accent),
      ),
    );
  }
}
