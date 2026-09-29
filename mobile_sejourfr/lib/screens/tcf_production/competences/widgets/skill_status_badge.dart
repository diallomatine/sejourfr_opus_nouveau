import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/skill_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_tag.dart';

/// Teinte d'un statut de petit sujet. **Seul endroit** qui en décide : le
/// badge, le liseré vertical de la carte et la pastille de numéro en dérivent
/// tous, sinon les trois divergent au premier ajout de statut.
///
/// `TREATED` (« Fait ») est bleu et non vert : une production sans analyse IA
/// n'a pas de verdict de critère — la peindre en « validé » serait faux.
Color skillStatusColor(SkillPromptStatus status) => switch (status) {
      SkillPromptStatus.validated => AppColors.green,
      SkillPromptStatus.toReinforce => AppColors.amber,
      SkillPromptStatus.treated => AppColors.blue,
      SkillPromptStatus.todo => AppColors.muted2,
    };

IconData skillStatusIcon(SkillPromptStatus status) => switch (status) {
      SkillPromptStatus.validated => LucideIcons.circleCheck,
      SkillPromptStatus.toReinforce => LucideIcons.refreshCw,
      SkillPromptStatus.treated => LucideIcons.check,
      SkillPromptStatus.todo => LucideIcons.circleDashed,
    };

/// Teinte d'un verdict IA sur le critère unique.
///
/// `PARTIEL` prend **`amberDark`** et non `amber` : cette couleur habille aussi
/// le libellé du verdict, et `amber` est un ambre de *remplissage*, illisible
/// en lettres (le CLAUDE.md du module l'interdit en texte). Le web utilise
/// `--color-amber-dark` au même endroit.
Color skillCriterionColor(SkillCriterionStatus status) => switch (status) {
      SkillCriterionStatus.validated => AppColors.green,
      SkillCriterionStatus.partial => AppColors.amberDark,
      SkillCriterionStatus.notValidated => AppColors.red,
    };

IconData skillCriterionIcon(SkillCriterionStatus status) => switch (status) {
      SkillCriterionStatus.validated => LucideIcons.circleCheck,
      SkillCriterionStatus.partial => LucideIcons.circleDot,
      SkillCriterionStatus.notValidated => LucideIcons.circleAlert,
    };

/// Ton de pastille d'un statut de critère. `partial` prend `TagTone.amber`
/// (fg `amberDark`) pour rester la même teinte que [skillCriterionColor] —
/// `tagToneForAccent` ne reconnaît que `AppColors.amber`, pas `amberDark`.
TagTone skillCriterionTagTone(SkillCriterionStatus status) => switch (status) {
      SkillCriterionStatus.validated => TagTone.success,
      SkillCriterionStatus.partial => TagTone.amber,
      SkillCriterionStatus.notValidated => TagTone.red,
    };

/// Pastille compacte du verdict IA sur le critère unique du sujet, destinée à
/// la rangée du haut de [SkillLevelCard] — à ne pas confondre avec
/// [SkillStatusBadge], qui porte le statut du **sujet** (`SkillPromptStatus`).
class SkillCriterionBadge extends StatelessWidget {
  const SkillCriterionBadge({super.key, required this.status});

  final SkillCriterionStatus status;

  @override
  Widget build(BuildContext context) => AppTag(
        label: status.label,
        tone: skillCriterionTagTone(status),
        icon: skillCriterionIcon(status),
        compact: true,
      );
}

/// Badge pill du statut d'un petit sujet (« À faire » / « Fait » / « Validé »
/// / « À renforcer »), libellés du contrat.
class SkillStatusBadge extends StatelessWidget {
  const SkillStatusBadge({super.key, required this.status});

  final SkillPromptStatus status;

  @override
  Widget build(BuildContext context) {
    final tone = status == SkillPromptStatus.todo
        ? TagTone.neutral
        : tagToneForAccent(skillStatusColor(status));
    return AppTag(
      label: status.label,
      tone: tone,
      icon: skillStatusIcon(status),
      compact: true,
    );
  }
}
