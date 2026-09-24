import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/skill_models.dart';

/// Les pictogrammes d'une épreuve TCF et d'un thème civique, **déclarés une
/// fois** : les cartes « Où vous en êtes » de l'Accueil et les cartes des
/// écrans de progression montrent le même repère (les émojis des maquettes
/// deviennent ces icônes).
///
/// Décoratifs : le nom de l'épreuve ou du thème est toujours écrit à côté.
/// Miroirs web : `SITUATION_EPREUVE_ICON` / `SITUATION_THEME_ICON`.
IconData situationEpreuveIcon(SkillSection? section) => switch (section) {
      SkillSection.co => LucideIcons.headphones,
      SkillSection.ce => LucideIcons.bookOpen,
      SkillSection.ee => LucideIcons.penLine,
      SkillSection.eo => LucideIcons.mic,
      null => LucideIcons.bookOpen,
    };

IconData situationThemeIcon(String? code) => switch (code) {
      'CIV_PRINCIPES' => LucideIcons.scale,
      'CIV_INSTITUTIONS' => LucideIcons.landmark,
      'CIV_DROITS_DEVOIRS' => LucideIcons.gavel,
      'CIV_HISTOIRE_GEO' => LucideIcons.globe,
      'CIV_SOCIETE' => LucideIcons.users,
      _ => LucideIcons.bookOpen,
    };
