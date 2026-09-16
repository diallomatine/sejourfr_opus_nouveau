/// **Les phrases du parcours TCF.** Le serveur sert des faits — type, purpose,
/// section, taskCode, skillTitle, progress, locked — et c'est ici qu'ils
/// deviennent du français.
///
/// 🛑 **Miroir mot pour mot de `web_sejoufr/lib/journey.ts`.** Un libellé qui
/// bouge, ce sont deux fichiers dans la même passe.
///
/// 🛑 **Rien ne se déduit ici d'un compteur ni d'une position.** Chaque fonction
/// pose un libellé sur un **état servi** : `status`, `locked`, `progress.unit`.
/// Un front qui recalculerait l'un d'eux finirait par désigner une autre étape
/// que le serveur.
library;

import '../../core/models/enums.dart';
import '../../core/models/journey_models.dart';
import '../../core/models/skill_models.dart';
import '../../core/widgets/sejour/sejour_kit.dart';

/// Le titre de l'écran : « Votre parcours vers le B2 ».
String journeyTitle(TargetLevel? targetLevel) => targetLevel == null
    ? 'Votre parcours'
    : 'Votre parcours vers le ${targetLevel.wire}';

/// Ce que porte la première ligne d'une étape.
String journeyStepTitle(JourneyStep step) {
  switch (step.type) {
    case JourneyStepType.diagnostic:
      return 'Diagnostic rapide';
    case JourneyStepType.sectionExam:
      return _epreuveLabel(step.examType);
    case JourneyStepType.trainSkill:
      return step.skillTitle ?? step.skillCode ?? 'Compétence';
  }
}

/// La seconde ligne. 🛑 **Elle dit ce que l'étape est**, jamais ce qu'il faut en
/// penser : « Expression écrite · Tâche 1 », « Vérifier mes progrès ».
String? journeyStepSubtitle(JourneyStep step) {
  switch (step.type) {
    case JourneyStepType.diagnostic:
      return 'Identifier vos premières priorités';
    case JourneyStepType.sectionExam:
      return step.purpose == JourneyStepPurpose.reassess
          ? 'Vérifier mes progrès'
          : 'Évaluer mon niveau';
    case JourneyStepType.trainSkill:
      final parts = <String>[
        if (step.section != null) _sectionLabel(step.section!),
        // 🛑 `taskCode` nul = compétence de COMPRÉHENSION : CO/CE n'ont ni tâche
        // ni petit sujet. On ne lui invente pas un « Tâche 1 » qui n'existe pas.
        if (step.taskCode != null) _tacheLabel(step.taskCode!),
      ];
      return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// La pastille de fin de ligne. **Servie au kit**, qui ne compose aucune phrase.
String? journeyBadge(JourneyStep step) {
  if (step.status == JourneyStepStatus.current) return 'Maintenant';
  if (step.status == JourneyStepStatus.skipped) return 'Déjà travaillée';
  if (step.status == JourneyStepStatus.upcoming &&
      step.type == JourneyStepType.sectionExam) {
    return 'Examen';
  }
  return null;
}

/// L'état de rendu, tel que le kit l'attend.
SfJourneyState journeyKitState(JourneyStep step) {
  switch (step.status) {
    case JourneyStepStatus.current:
      return SfJourneyState.current;
    case JourneyStepStatus.completed:
      return SfJourneyState.done;
    case JourneyStepStatus.skipped:
      return SfJourneyState.skipped;
    case JourneyStepStatus.upcoming:
    case JourneyStepStatus.obsolete:
      return SfJourneyState.upcoming;
  }
}

/// Un examen porte un double cercle : c'est un checkpoint, pas une tâche de plus.
SfJourneyKind journeyKind(JourneyStep step) =>
    step.type == JourneyStepType.sectionExam
        ? SfJourneyKind.exam
        : SfJourneyKind.step;

/// L'avancement, dans **l'unité servie**.
///
/// 🛑 L'unité ne se déduit **jamais** de la nullité de `taskCode` : ce serait
/// recopier une règle du référentiel dans les deux fronts.
String? journeyProgressLabel(JourneyProgress? progress) {
  if (progress == null || progress.quota <= 0) return null;
  if (progress.unit == JourneyProgressUnit.series) {
    final s = progress.done > 1 ? 's' : '';
    return '${progress.done} série$s sur ${progress.quota}';
  }
  return '${progress.done} / ${progress.quota} petits sujets';
}

/// Ce que la carte « À faire maintenant » met sous son titre.
String? journeyNowMeta(JourneyStep step) {
  switch (step.type) {
    case JourneyStepType.trainSkill:
      return journeyProgressLabel(step.progress);
    case JourneyStepType.sectionExam:
      return step.purpose == JourneyStepPurpose.reassess
          ? 'Cette épreuve mesure ce que vous venez de travailler.'
          : 'Cette épreuve complète votre niveau et identifie vos prochaines priorités.';
    case JourneyStepType.diagnostic:
      return 'Quelques minutes pour identifier vos premières priorités.';
  }
}

/// Le bouton de la carte « À faire maintenant ».
String journeyNowCta(JourneyStep step, bool locked) {
  if (locked) return 'Débloquer cette étape';
  switch (step.type) {
    case JourneyStepType.diagnostic:
      return 'Commencer';
    case JourneyStepType.sectionExam:
      return "Passer l'épreuve";
    case JourneyStepType.trainSkill:
      return 'Continuer';
  }
}

/// Ce que l'écran dit quand il n'y a plus rien à faire (§8).
///
/// 🛑 **Une suggestion n'est pas une étape** : elle n'a pas de position, elle ne
/// se clôt pas, et le candidat peut l'ignorer sans rien laisser « en attente ».
const String kJourneyUpToDateTitle = 'Votre parcours est à jour';
const String kJourneyUpToDateText =
    "Rien de nouveau à travailler pour l'instant : vos prochaines priorités "
    'viendront de votre prochaine évaluation.';
const String kJourneySuggestionMockExam =
    'Vos 4 épreuves sont mesurées. Un examen blanc complet confirmera votre '
    'niveau global.';

/// Aucune démarche déclarée (arbitrage D-3). 🛑 Ce n'est pas un parcours vide :
/// c'est l'absence de parcours.
const String kJourneyNeedsObjectiveTitle = 'Choisir mon objectif';
const String kJourneyNeedsObjectiveText =
    'Votre parcours dépend de la démarche que vous visez.';
const String kJourneyNeedsObjectiveCta = 'Choisir ma démarche';

/// Rien n'est exécutable : la carte montre la première étape, verrouillée.
const String kJourneyLockedCaption =
    "Cette étape fait partie de l'abonnement Intégral. Votre parcours, lui, "
    'reste entier.';

/// Le repli de « Voir les étapes suivantes ».
String? journeyMoreLabel(int hidden) {
  if (hidden <= 0) return null;
  final s = hidden > 1 ? 's' : '';
  return 'Voir les $hidden étape$s suivante$s';
}

/// L'étape que la carte « À faire maintenant » doit montrer (R16, D-1).
JourneyStep? journeyNowStep(Journey journey) {
  if (journey.current != null) return journey.current;
  // 🛑 `LOCKED` : la carte montre la PREMIÈRE étape ouverte, verrouillée, avec
  // son paywall. La masquer priverait le candidat de l'information la plus
  // utile qu'il possède.
  if (journey.state == JourneyState.locked) {
    for (final step in journey.steps) {
      if (step.status == JourneyStepStatus.upcoming) return step;
    }
  }
  return null;
}

String _epreuveLabel(EpreuveType? epreuve) =>
    epreuve == null ? 'Épreuve' : epreuve.displayLabel;

String _sectionLabel(SkillSection section) {
  switch (section) {
    case SkillSection.ee:
      return 'Expression écrite';
    case SkillSection.eo:
      return 'Expression orale';
    case SkillSection.co:
      return 'Compréhension orale';
    case SkillSection.ce:
      return 'Compréhension écrite';
  }
}

String _tacheLabel(SkillTaskCode taskCode) =>
    'Tâche ${taskCode.wire.substring(taskCode.wire.length - 1)}';
