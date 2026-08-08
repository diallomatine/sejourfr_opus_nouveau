import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/production_models.dart';
import '../../../core/theme/app_theme.dart';
import '../tcf_production_module.dart';

/// Petites briques partagées par le hub d'épreuve et l'écran d'une tâche,
/// extraites quand les deux écrans ont été séparés en fichiers dédiés.

/// Libellé d'une tâche : titre court, sous-titre de contrainte et phrase de
/// présentation. Source unique — le hub, l'en-tête de l'écran de tâche et son
/// hero le lisaient chacun de leur côté.
///
/// **Écrit et oral disent la même chose** : mêmes tâches, mêmes intentions,
/// seule la façon de produire change (rédiger ou parler).
({String title, String subtitle, String intro}) productionTaskMeta(
  TcfProductionModule module,
  int tache,
) {
  if (module.isEo) {
    return switch (tache) {
      1 => (
          title: 'Entretien dirigé',
          subtitle: 'Se présenter · 3 min',
          intro:
              "Tu te présentes et tu réponds aux questions de l'examinateur : ton parcours, tes goûts, tes projets.",
        ),
      2 => (
          title: 'Jeu de rôle',
          subtitle: 'Poser des questions · 3 min 30',
          intro:
              'Tu joues une situation de la vie courante et tu poses les questions qu\'il faut pour obtenir ce que tu veux.',
        ),
      _ => (
          title: 'Donner son opinion',
          subtitle: 'Point de vue · 3 min 30',
          intro:
              'Tu donnes ton point de vue sur un sujet et tu le défends avec des arguments et des exemples.',
        ),
    };
  }
  return switch (tache) {
    1 => (
        title: 'Message',
        subtitle: 'Répondre à un message · 30-60 mots',
        intro:
            'Tu réponds à un message court — invitation, demande, annonce — en traitant chaque point demandé.',
      ),
    2 => (
        title: 'Récit',
        subtitle: 'Raconter une expérience · 40-90 mots',
        intro:
            'Tu racontes une expérience personnelle au passé, dans l\'ordre, avec ce que tu en as retenu.',
      ),
    _ => (
        title: 'Opinion',
        subtitle: 'Avis argumenté · 40-90 mots',
        intro:
            'Tu donnes ton avis sur une question et tu l\'argumentes, en tenant compte de l\'avis opposé.',
      ),
  };
}

/// Intitulé **court** d'une tâche — celui du sélecteur de tâche du parcours,
/// où trois cartes se partagent la largeur d'un téléphone.
///
/// ⚠️ **Libellés gelés**, miroir mot pour mot du web
/// (`productionTaskShortTitle`, `lib/types.ts`). Les deux fronts en tiennent
/// chacun une copie écrite à la main : un libellé qui bouge, ce sont deux
/// fichiers à changer dans la même passe, et deux tests.
String productionTaskShortTitle(TcfProductionModule module, int tache) {
  if (module.isEo) {
    return switch (tache) {
      1 => 'Entretien dirigé',
      2 => 'Jeu de rôle',
      3 => 'Opinion',
      _ => 'Tâche $tache',
    };
  }
  return switch (tache) {
    1 => 'Message',
    2 => 'Récit',
    3 => 'Opinion',
    _ => 'Tâche $tache',
  };
}

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
