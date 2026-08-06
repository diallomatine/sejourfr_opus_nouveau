import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
        subtitle: 'Raconter une expérience · 60-90 mots',
        intro:
            'Tu racontes une expérience personnelle au passé, dans l\'ordre, avec ce que tu en as retenu.',
      ),
    _ => (
        title: 'Opinion',
        subtitle: 'Avis argumenté · 60-90 mots',
        intro:
            'Tu donnes ton avis sur une question et tu l\'argumentes, en tenant compte de l\'avis opposé.',
      ),
  };
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
