import 'package:flutter/material.dart';

import '../../core/models/enums.dart';

/// Module TCF productif (Expression écrite ou orale). Porte les libellés et
/// l'icône partagés par l'écran d'entraînement consolidé
/// (`TcfExpressionScreen`) et le briefing d'examen complet.
///
/// Palette stricte bleu / blanc / rouge SejourFR. EE et EO se distinguent par
/// leur icône et le libellé du 3ᵉ onglet (Corrections vs Analyses).
enum TcfProductionModule {
  ee(
    routeKey: 'ee',
    epreuve: EpreuveType.tcfEe,
    eyebrow: 'Production écrite',
    title: 'Expression écrite',
    headline: 'Correction IA détaillée',
    description:
        'Rédige tes réponses puis reçois un niveau CECRL, des corrections et des conseils personnalisés.',
    icon: Icons.edit_note_rounded,
    durationLabel: '30',
    historyTabLabel: 'Corrections',
  ),
  eo(
    routeKey: 'eo',
    epreuve: EpreuveType.tcfEo,
    eyebrow: 'Production orale',
    title: 'Expression orale',
    headline: 'Parle comme au vrai examen',
    description: 'Enregistre tes réponses et reçois une analyse IA avec transcription et niveau CECRL.',
    icon: Icons.mic_rounded,
    durationLabel: '10',
    historyTabLabel: 'Analyses',
  );

  const TcfProductionModule({
    required this.routeKey,
    required this.epreuve,
    required this.eyebrow,
    required this.title,
    required this.headline,
    required this.description,
    required this.icon,
    required this.durationLabel,
    required this.historyTabLabel,
  });

  final String routeKey;
  final EpreuveType epreuve;
  final String eyebrow;
  final String title;
  final String headline;
  final String description;
  final IconData icon;
  final String durationLabel;
  final String historyTabLabel;

  bool get isEo => epreuve == EpreuveType.tcfEo;
}
