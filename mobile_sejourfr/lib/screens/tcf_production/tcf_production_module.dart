import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/enums.dart';
import '../../core/theme/app_theme.dart';

/// Module TCF productif (Expression écrite ou orale). Porte les libellés et
/// l'icône partagés par les écrans du parcours (Compétences, Sujets, Examens)
/// et le briefing d'examen complet.
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
    icon: LucideIcons.penLine,
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
    icon: LucideIcons.mic,
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

  /// Accent du module : **EO rouge, EE bleu** (sémantique de la refonte 2026).
  /// Déclaré ici et nulle part ailleurs — les écrans du module Compétences
  /// recopiaient tous le même ternaire.
  Color get accent => isEo ? AppColors.red : AppColors.blue;

  /// Ton foncé du même accent, pour les dégradés de hero.
  Color get accentDark => isEo ? AppColors.redDark : AppColors.blueDark;
}
