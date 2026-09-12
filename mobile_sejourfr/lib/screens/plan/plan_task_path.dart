import '../../core/models/diagnostic_models.dart';
import '../../core/models/skill_models.dart';
import '../../core/widgets/sejour/sejour_kit.dart';

/// **Le parcours de la tâche en cours** — les compétences de la tâche que la
/// priorité n°1 travaille, dans l'ordre du référentiel.
///
/// 🛑 **Rien n'est compté ici.** La tâche vient du code de la compétence
/// prioritaire, son compteur est **servi** (`domaines[].taches[]`), et ses
/// compétences sont celles que le serveur publie. Sans l'un des trois, il n'y a
/// **pas** de parcours — on n'en invente pas un.
///
/// ⚠️ Extrait de `PlanTcfView` à sa **deuxième** surface : l'Accueil montre le
/// même parcours dans son bloc « Votre Plan » (la maquette du propriétaire,
/// `~/Desktop/grok_ecran`). Deux dérivations auraient fini par cocher deux
/// étapes différentes pour le même candidat.
class PlanTaskPath {
  const PlanTaskPath({
    required this.task,
    required this.dto,
    required this.skills,
  });

  final SkillTaskCode task;
  final PlanDomainTask dto;
  final List<PlanDomainSkill> skills;
}

/// La tâche **servie** portant ce code, cherchée dans les domaines publiés.
PlanDomainTask? planTaskDto(LearningPlan plan, SkillTaskCode task) {
  for (final domain in plan.domaines) {
    for (final candidate in domain.taches) {
      if (candidate.taskCode == task.wire) return candidate;
    }
  }
  return null;
}

/// `null` dès qu'un des trois éléments manque — notamment en compréhension, où
/// aucune tâche n'est servie.
PlanTaskPath? planTaskPath(LearningPlan plan) {
  final current = plan.currentPriority;
  if (current == null) return null;
  final task = SkillTaskCode.fromSkillCode(current.skillCode);
  if (task == null) return null;
  final dto = planTaskDto(plan, task);
  if (dto == null) return null;
  final skills = <PlanDomainSkill>[
    for (final domain in plan.domaines)
      for (final skill in domain.skills)
        if (skill.taskCode == task.wire) skill,
  ];
  if (skills.isEmpty) return null;
  return PlanTaskPath(task: task, dto: dto, skills: skills);
}

/// L'état d'une compétence dans le parcours. Il se lit sur des **états
/// servis** — l'étape est franchie, ou la compétence est la priorité n°1 —
/// jamais sur un compteur classé ici.
SfStepState planSkillStepState(LearningPlan plan, PlanDomainSkill skill) {
  if (skill.skillId == plan.currentPriority?.skillId) return SfStepState.now;
  final done = plan.completedSteps.any((step) => step.skillId == skill.skillId);
  if (done) return SfStepState.done;
  return skill.masteryState == SkillMasteryState.solid
      ? SfStepState.done
      : SfStepState.todo;
}

/// Les étapes du parcours, prêtes pour le kit.
List<SfPathStep> planPathSteps(LearningPlan plan, PlanTaskPath path) =>
    <SfPathStep>[
      for (final skill in path.skills)
        SfPathStep(label: skill.title, state: planSkillStepState(plan, skill)),
    ];
