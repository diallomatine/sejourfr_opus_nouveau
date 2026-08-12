import 'package:flutter/material.dart';

import '../models/skill_models.dart';
import '../theme/app_theme.dart';
import 'app_tag.dart';

/// Teinte et pilule d'un état de maîtrise, **déclarées ici et nulle part
/// ailleurs**.
///
/// ⚠️ **Aucune teinte nouvelle** : on reprend exactement celles des statuts de
/// compétence (`LearningPlanSkillStatus.color`), pour qu'un même état ne change
/// pas de couleur d'un écran à l'autre. Miroir des tons de `SkillMasteryPill`
/// côté web.
extension SkillMasteryStateStyle on SkillMasteryState {
  TagTone get tone => switch (this) {
        SkillMasteryState.priority => TagTone.red,
        SkillMasteryState.toReinforce => TagTone.amber,
        SkillMasteryState.consolidating => TagTone.blue,
        SkillMasteryState.solid => TagTone.success,
      };

  /// Pour les écrans qui écrivent l'état en toutes lettres plutôt qu'en
  /// pilule (cartes « Mes compétences observées » du Plan).
  Color get color => switch (this) {
        SkillMasteryState.priority => AppColors.red,
        SkillMasteryState.toReinforce => AppColors.amberDark,
        SkillMasteryState.consolidating => AppColors.blue,
        SkillMasteryState.solid => AppColors.green,
      };
}

/// Où en est le candidat sur une compétence, tout son historique confondu —
/// **ce que la carte affiche à la place du compteur de sujets traités**.
///
/// Brique partagée par la liste des compétences (Réviser → Compétences) et par
/// le Plan : ce sont les mêmes compétences, elles doivent porter le même
/// signal. Miroir de `SkillMasteryPill` côté web.
class SkillMasteryTag extends StatelessWidget {
  const SkillMasteryTag({super.key, required this.state, this.compact = true});

  final SkillMasteryState state;
  final bool compact;

  @override
  Widget build(BuildContext context) =>
      AppTag(label: state.label, tone: state.tone, compact: compact);
}
