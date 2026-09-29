import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/epreuve_duration.dart';

/// Module TCF productif (Expression écrite ou orale). Porte les libellés et
/// l'icône partagés par les écrans du parcours (Compétences, Sujets, Examens)
/// et le briefing d'examen complet.
///
/// **Les deux épreuves sont BLEUES** (décision client 2026-08-09). Le rouge ne
/// distingue plus l'oral de l'écrit : il reste réservé aux CTA critiques et aux
/// signaux d'urgence (`docs/identite-visuelle.md`). Ce qui distingue les deux
/// épreuves, c'est donc :
///
/// 1. le **titre** (« Expression écrite » / « Expression orale ») et le
///    sous-titre d'épreuve, portés par l'en-tête du parcours ;
/// 2. le **pictogramme** ([icon] : stylo vs micro), rendu sur la carte
///    « Prochain entraînement », le bouton d'action d'un sujet et les liens
///    d'appoint ;
/// 3. le **verbe** ([actionVerb] : « Rédiger » / « Enregistrer ») et la durée
///    d'épreuve.
///
/// Ne pas réintroduire d'accent rouge sur l'oral : deux épreuves du même module
/// qui se peignent différemment se lisent comme deux produits.
enum TcfProductionModule {
  ee(
    routeKey: 'ee',
    epreuve: EpreuveType.tcfEe,
    eyebrow: 'Production écrite',
    title: 'Expression écrite',
    headline: 'Correction IA détaillée',
    description:
        'Rédige tes réponses puis reçois un niveau CECRL, des corrections et des conseils personnalisés.',
    icon: LucideIcons.penLine,
    historyTabLabel: 'Corrections',
    actionVerb: 'Rédiger',
  ),
  eo(
    routeKey: 'eo',
    epreuve: EpreuveType.tcfEo,
    eyebrow: 'Production orale',
    title: 'Expression orale',
    headline: 'Parle comme au vrai examen',
    description: 'Enregistre tes réponses et reçois une analyse IA avec transcription et niveau CECRL.',
    icon: LucideIcons.mic,
    historyTabLabel: 'Analyses',
    actionVerb: 'Enregistrer',
  );

  const TcfProductionModule({
    required this.routeKey,
    required this.epreuve,
    required this.eyebrow,
    required this.title,
    required this.headline,
    required this.description,
    required this.icon,
    required this.historyTabLabel,
    required this.actionVerb,
  });

  final String routeKey;
  final EpreuveType epreuve;
  final String eyebrow;
  final String title;
  final String headline;
  final String description;

  /// Pictogramme de l'épreuve — **le repère visuel** qui remplace l'ancien
  /// code couleur rouge/bleu.
  final IconData icon;

  final String historyTabLabel;

  /// Durée de l'épreuve en examen blanc, lue dans [kEpreuveDurationSeconds]
  /// (miroir de `DureeEpreuve` côté backend) — **jamais écrite ici**.
  ///
  /// ⚠️ L'expression orale **n'a pas de durée d'épreuve** : elle rend
  /// « Chrono par tâche ». Elle a longtemps annoncé « 15 min », un chrono global
  /// qui n'existe plus — au TCF le temps se compte par tâche et ne part qu'au
  /// lancement de la tâche.
  String get durationLabel => epreuveDurationLabelFor(epreuve);

  /// Verbe de production, l'autre repère écrit/oral (« Rédiger » /
  /// « Enregistrer »).
  final String actionVerb;

  bool get isEo => epreuve == EpreuveType.tcfEo;

  /// Sous-titre d'épreuve de l'en-tête du parcours : « TCF IRN · 3 tâches ·
  /// 30 min » à l'écrit, « TCF IRN · 3 tâches · Chrono par tâche » à l'oral.
  /// Écrit ici et nulle part ailleurs — trois écrans le composaient.
  String get epreuveMeta => 'TCF IRN · 3 tâches · $durationLabel';

  /// Accent du module : **bleu pour les deux épreuves**. Conservé comme
  /// propriété (et non inliné) parce que toutes les briques du parcours le
  /// reçoivent en paramètre.
  Color get accent => AppColors.blue;

  /// Ton foncé du même accent, pour les dégradés de hero.
  Color get accentDark => AppColors.blueDark;
}
