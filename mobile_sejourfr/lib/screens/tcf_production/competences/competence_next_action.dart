import '../../../core/models/skill_models.dart';

/// Le bloc 6 du rapport court : **la prochaine action** (`10_` §8.2).
///
/// > « [6. Prochaine action] **JAMAIS un simple « Retour »** »
///
/// 🛑 **Rien n'est dérivé ici.** Le verdict (`SkillCriterionStatus`) arrive
/// **servi** par le serveur, qui l'a lui-même reçu du correcteur sous contrat.
/// Ce fichier ne fait que le mettre en mots et désigner l'action
/// correspondante. Aucun front ne classe un résultat en état pédagogique.
///
/// 🛑 **Aucun niveau CECRL n'apparaît** dans ces phrases : `10_` §8.2
/// l'interdit explicitement sur un exercice de deux phrases.
///
/// Miroir mot pour mot de `web_sejoufr/lib/competence-next-action.ts`.

/// Ce que la carte de fin propose.
enum CompetenceNextKind { reessayer, sujetSuivant, plan }

class CompetenceNextAction {
  const CompetenceNextAction({
    required this.title,
    required this.hint,
    required this.cta,
    required this.kind,
  });

  /// Le titre : il dit où en est le candidat, pas ce qu'il a raté.
  final String title;

  /// Une phrase, jamais deux : c'est une porte de sortie, pas un cours.
  final String hint;

  /// Le libellé du bouton principal. Jamais « Retour ».
  final String cta;

  final CompetenceNextKind kind;
}

/// [hasNextPrompt] : reste-t-il un sujet sur cette compétence ?
///
/// 🛑 Sans sujet suivant, on n'en propose pas : un bouton qui ne mène nulle
/// part est pire qu'un bouton absent.
CompetenceNextAction competenceNextAction(
  SkillCriterionStatus status,
  bool hasNextPrompt,
) {
  switch (status) {
    case SkillCriterionStatus.notValidated:
      // Le critère n'est pas atteint : on rejoue LE MÊME point. Enchaîner un
      // sujet de plus sur une compétence non acquise empile des échecs.
      return const CompetenceNextAction(
        title: 'Essayez encore une fois',
        hint: 'Reprenez ce point précis : c\'est en le rejouant qu\'il s\'installe.',
        cta: 'S\'entraîner sur ce point',
        kind: CompetenceNextKind.reessayer,
      );
    case SkillCriterionStatus.partial:
      return hasNextPrompt
          ? const CompetenceNextAction(
              title: '🎉 Cette compétence progresse',
              hint: 'Un sujet de plus sur la même compétence, et elle sera acquise.',
              cta: 'Passer au sujet suivant',
              kind: CompetenceNextKind.sujetSuivant,
            )
          : const CompetenceNextAction(
              title: '🎉 Cette compétence progresse',
              hint: 'Vous avez traité tous les sujets de cette compétence.',
              cta: 'Continuer mon plan',
              kind: CompetenceNextKind.plan,
            );
    case SkillCriterionStatus.validated:
      return const CompetenceNextAction(
        title: '✅ Compétence maîtrisée',
        hint: 'Votre plan vous emmène maintenant sur la priorité suivante.',
        cta: 'Continuer mon plan',
        kind: CompetenceNextKind.plan,
      );
  }
}
