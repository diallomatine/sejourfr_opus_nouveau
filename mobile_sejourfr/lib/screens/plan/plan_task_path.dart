import '../../core/models/diagnostic_models.dart';
import '../../core/models/skill_models.dart';
import '../../core/widgets/sejour/sejour_kit.dart';


/// La tâche **servie** portant ce code, cherchée dans les domaines publiés.
PlanDomainTask? planTaskDto(LearningPlan plan, SkillTaskCode task) {
  for (final domain in plan.domaines) {
    for (final candidate in domain.taches) {
      if (candidate.taskCode == task.wire) return candidate;
    }
  }
  return null;
}

/// L'**apparence** d'un état d'étape dans le kit. Elle ne décide rien : l'état
/// arrive **servi** (`PlanDomainSkill.stepState`), cette table dit seulement
/// quelle forme lui donner.
///
/// 🛑 [PlanSkillStepState.serieTerminee] n'est **pas** `done` : la coche verte
/// dit « acquis », et une série finie sans preuve en situation ne l'est pas.
/// [PlanSkillStepState.aVerifier] a sa forme propre — c'est le seul état qui
/// appelle une action d'une autre nature.
///
/// ⚠️ Miroir de `planStepKitState` (`web_sejoufr/lib/plan-domain.ts`).
SfStepState planStepKitState(PlanSkillStepState state) => switch (state) {
      PlanSkillStepState.acquis => SfStepState.done,
      PlanSkillStepState.aVerifier => SfStepState.verify,
      PlanSkillStepState.serieTerminee => SfStepState.doing,
      PlanSkillStepState.maintenant => SfStepState.now,
      PlanSkillStepState.enCours => SfStepState.doing,
      PlanSkillStepState.aVenir => SfStepState.todo,
    };

/// Le libellé d'un état d'étape, **avec sa progression réelle** quand elle
/// éclaire quelque chose : « Série terminée · 5/5 », « En cours · 2/5 ».
///
/// 🛑 Le libellé vient de l'enum **servi** ; seuls les **nombres** s'y ajoutent,
/// et ce sont ceux que le serveur a comptés. Aucun état n'est déduit ici.
///
/// 🛑 Aucun palier CECRL ne s'y accroche : « Acquis · B1 » n'existe pas. Le
/// palier d'une compétence est notre palier **pédagogique interne** et s'affiche
/// à part, « Niveau visé B1 ».
///
/// ⚠️ Miroir de `planStepStateLabel` (web).
String planStepStateLabel(PlanDomainSkill skill) {
  final label = skill.stepState.label;
  if (skill.stepPromptCount == 0) return label;
  final compteur = '${skill.stepAttemptedCount}/${skill.stepPromptCount}';
  return switch (skill.stepState) {
    PlanSkillStepState.serieTerminee ||
    PlanSkillStepState.enCours =>
      '$label · $compteur',
    _ => label,
  };
}

/// L'état d'une compétence dans le parcours — **servi**, jamais dérivé ici.
///
/// ⚠️ Il l'était : cette fonction cochait sur `completedSteps` **ou**
/// `masteryState == solid` pendant que le web cochait sur le seul `SOLID`. Deux
/// règles, deux parcours différents pour le même candidat.
SfStepState planSkillStepState(PlanDomainSkill skill) =>
    planStepKitState(skill.stepState);

/// Les étapes du parcours, prêtes pour le kit. La pastille porte l'état servi ;
/// « À venir » n'en a pas — une ligne que rien n'a encore touchée n'a rien à
