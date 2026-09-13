import '../../core/models/diagnostic_models.dart';
import '../../core/models/skill_models.dart';

/// **Les phrases des trois écrans d'expression** — détail de l'épreuve, détail
/// d'une tâche, fiche d'une compétence.
///
/// 🛑 **Miroir mot pour mot de `web_sejoufr/lib/expression.ts`.** Un libellé qui
/// bouge, ce sont deux fichiers dans la même passe.
///
/// 🛑 **Rien n'est classé ici.** Chaque fonction pose une phrase sur des **faits
/// servis** : [SkillDto.masteryState] (dérivé par `SkillMasteryEngine`),
/// [SkillDto.targetLevel] (le référentiel), les compteurs de sujets, et
/// [SkillPromptSummary.estimatedMinutes] (dérivé par `ExerciseDuration`). Aucune
/// ne décide d'un état pédagogique ni d'un palier.
///
/// ## Les deux décisions que ce fichier applique (arbitrage du 2026-09-12)
///
/// 🛑 **« Acquise » ≠ « Série terminée », et on dit les deux.**
/// - **Acquise** ⇔ `masteryState == SOLID`, c'est-à-dire transfert **prouvé sur
///   une production complète** : le moteur exige au moins une observation
///   contextualisée, jamais des micro-exercices seuls.
/// - **Série terminée** ⇔ tous les sujets du périmètre sont travaillés. C'est ce
///   que le candidat a **fait**, pas ce qui est **prouvé**.
/// Les confondre reproduirait le défaut que le dépôt nomme « NON FRAGILE ≠ PLUS
/// RIEN À APPRENDRE ».
///
/// 🛑 **Aucun palier CECRL ne s'affiche à côté d'« Acquis »** (arbitrage du
/// 2026-09-13). `skills.target_level` est notre palier **pédagogique interne** —
/// France Éducation international n'en rattache aucun à une tâche. « Acquis · A2 »
/// se lirait « tu as cette compétence au niveau A2 », ce que le serveur ne peut
/// pas dire : `learning_plan_observations` ne porte **aucun niveau**, et
/// `ProgressionStateKey` interdit un `level` sur un `PRODUCTIVE_SKILL`. Le palier
/// ne s'affiche plus que comme **« Niveau visé »**, une fois, en tête de tâche.

/* ------------------------------------------------- Acquis ⇄ série terminée */

const String kExpressionAcquis = 'Acquis';
const String kExpressionEnCours = 'En cours';
const String kExpressionAFaire = 'À faire';
const String kExpressionADecouvrir = 'À découvrir';
const String kExpressionSerieTerminee = 'Série terminée';

/// Une compétence est acquise **quand le moteur l'a prouvée**, et pas avant.
bool estAcquise(SkillDto skill) =>
    skill.masteryState == SkillMasteryState.solid;

/// Le ton d'une pastille de compétence. Trois valeurs, pas quatre : ce n'est pas
/// une échelle de gravité, c'est un état d'avancement.
enum ExpressionBadgeTone { acquis, enCours, aFaire }

typedef ExpressionBadge = ({String label, ExpressionBadgeTone tone});

/// La pastille d'une ligne de compétence : « Acquis », « En cours », « À faire ».
///
/// 🛑 **Sans palier** — cf. l'en-tête de ce fichier. Le serveur sait dire « cette
/// compétence est solide », jamais « tu l'as au A2 mais pas au B2 ».
ExpressionBadge competenceBadge(SkillDto skill) {
  if (estAcquise(skill)) {
    return (label: kExpressionAcquis, tone: ExpressionBadgeTone.acquis);
  }
  return skill.attemptedCount > 0
      ? (label: kExpressionEnCours, tone: ExpressionBadgeTone.enCours)
      : (label: kExpressionAFaire, tone: ExpressionBadgeTone.aFaire);
}

/// La ligne d'état sous le titre d'une compétence.
///
/// L'ordre des cas **est** la règle : ce qui est **prouvé** passe devant ce qui
/// est **fait**, et « à découvrir » n'est dit qu'en dernier — jamais comme un
/// reproche.
String competenceStatus(SkillDto skill) {
  if (estAcquise(skill)) return kExpressionAcquis;
  if (skill.promptCount > 0 && skill.attemptedCount >= skill.promptCount) {
    return '$kExpressionSerieTerminee · '
        '${skill.validatedCount}/${skill.promptCount}';
  }
  if (skill.attemptedCount > 0) {
    return '$kExpressionEnCours · '
        '${skill.validatedCount}/${skill.promptCount} réussis';
  }
  return kExpressionADecouvrir;
}

/* ----------------------------------------------------------- Une tâche --- */

/// « 3/8 compétences acquises » — **et `SOLID` seulement**.
///
/// 🛑 Ni une compétence simplement observée, ni une série 5/5 ne comptent : le
/// compteur dit ce qui est **prouvé**. C'est de l'arithmétique sur un
/// `masteryState` **servi**, jamais une règle de classement rejouée ici.
String acquisesLabel(List<SkillDto> skills) {
  final acquises = skills.where(estAcquise).length;
  // 🛑 Le pluriel suit le TOTAL, jamais le compteur : « 0/8 compétence
  // acquise » se lit comme une faute, et c'est bien « sur huit compétences »
  // que porte le nom. Même règle pour « 0/5 exercices réussis ».
  final s = skills.length > 1 ? 's' : '';
  return '$acquises/${skills.length} compétence$s acquise$s';
}

/// Le badge d'une tâche. `null` tant que rien n'y a été travaillé.
String? tacheBadge(List<SkillDto> skills) {
  if (skills.isEmpty) return null;
  // 🛑 « Acquis » sur une tâche n'a de sens que si les 8 le sont : à 3/8 le
  // badge contredirait le compteur affiché juste à côté.
  if (skills.every(estAcquise)) return kExpressionAcquis;
  return skills.any((s) => s.attemptedCount > 0) ? kExpressionEnCours : null;
}

/// « NIVEAU VISÉ B1 » — le palier **pédagogique** de la tâche, dit comme tel.
///
/// 🛑 **Deux formulations écartées, et pour deux raisons différentes.**
/// - La maquette porte « OBJECTIF B2 » sur la Tâche 1, qui est une tâche A2 :
///   posé là, il laisse croire que la réussir vaut B2. L'objectif personnel vit
///   sur l'écran **global** de l'épreuve, pas sur une tâche.
/// - « PALIER A2 » a été écarté à son tour (2026-09-13) : il se lit comme un
///   palier **officiel** du TCF IRN, or France Éducation international ne
///   rattache aucun niveau CECRL à une tâche.
///
/// « Niveau visé » est la formule que `docs/notation-ia-eo-ee.md` impose déjà aux
/// écrans de production, et elle dit exactement ce que c'est.
String niveauViseBadge(String targetLevel) => 'Niveau visé $targetLevel';

/* ------------------------------------------------- Une fiche de compétence */

const String kExpressionLearningPointsTitle = 'Vous allez apprendre à :';
const String kExpressionCompetenceAcquise = 'Compétence acquise';
const String kExpressionCompetenceEnCours = 'Compétence en cours';
const String kExpressionCompetenceADecouvrir = 'Compétence à découvrir';

/// L'eyebrow de la carte de tête d'une compétence.
///
/// 🛑 **Trois états, et le troisième n'est pas un détail.** « Compétence en
/// cours » posé sur une compétence où rien n'a jamais été fait annonçait un
/// travail entamé qui n'existait pas — le cas est devenu la norme après la
/// bascule V3, qui a renouvelé les sujets de dix-neuf compétences.
/// `masteryState` et `attemptedCount` sont tous deux **servis** : on ne classe
/// rien ici.
String competenceEyebrow(SkillDto skill) {
  if (estAcquise(skill)) return kExpressionCompetenceAcquise;
  if (skill.masteryState == null && skill.attemptedCount == 0) {
    return kExpressionCompetenceADecouvrir;
  }
  return kExpressionCompetenceEnCours;
}

/// « 5 petits sujets · ≈ 4 min chacun ».
///
/// 🛑 **« chacun », et c'est tout l'enjeu** : les 5 sujets d'une étape font une
/// quinzaine de minutes, pas cinq. Annoncer « ≈ 5 min » comme durée de séance
/// serait faux (arbitrage du 2026-09-12).
///
/// La minute vient de `estimatedMinutes`, **servi** par `ExerciseDuration`. On
/// retient la **médiane** des sujets du périmètre : une moyenne serait tirée par
/// le sujet le plus long, et la valeur doit décrire le cas courant.
String? sujetsMeta(List<SkillPromptSummary> prompts) {
  if (prompts.isEmpty) return null;
  final s = prompts.length > 1 ? 's' : '';
  final compte = '${prompts.length} petit$s sujet$s';
  final minutes = prompts
      .map((p) => p.estimatedMinutes)
      .where((m) => m > 0)
      .toList()
    ..sort();
  if (minutes.isEmpty) return compte;
  return '$compte · ≈ ${minutes[minutes.length ~/ 2]} min chacun';
}

const String kExpressionCtaStart = 'Commencer la séance';
const String kExpressionCtaContinue = 'Continuer la séance';
const String kExpressionCtaRedo = 'Retravailler cette compétence';
const String kExpressionCtaLocked = 'Voir l\'abonnement Intégral';

/// Le CTA de la fiche d'une compétence — **il dit ce qui va réellement se
/// passer**.
///
/// 🛑 Le périmètre terminé, « Continuer la séance » serait incohérent : il n'y a
/// plus rien à continuer. On propose alors de **retravailler**, ce qui est le
/// seul geste que les écrans existants savent faire — aucune logique métier
/// nouvelle n'est inventée ici.
String competenceCta(List<SkillPromptSummary> prompts, {required bool locked}) {
  if (locked) return kExpressionCtaLocked;
  final reste =
      prompts.where((p) => p.status == SkillPromptStatus.todo).length;
  if (reste == 0) {
    return prompts.isEmpty ? kExpressionCtaStart : kExpressionCtaRedo;
  }
  return reste == prompts.length ? kExpressionCtaStart : kExpressionCtaContinue;
}

/// « 0 restants » / « 3 restants » — ce qu'il reste à faire dans le périmètre.
String restantsLabel(List<SkillPromptSummary> prompts) {
  final reste =
      prompts.where((p) => p.status == SkillPromptStatus.todo).length;
  return '$reste restant${reste > 1 ? 's' : ''}';
}

/* ------------------------------------------------------------- Onglets --- */

/// 🛑 **« Sujets complets », et plus « Sujets d'examen »** (maquette du
/// propriétaire, 2026-09-12). Libellés gelés, miroirs du web.
const String kExpressionTabCompetences = 'Compétences';
const String kExpressionTabSujets = 'Sujets complets';

/* ----------------------------------------------- « Recommandé pour vous » */

const String kExpressionRecommendedLabel = 'Recommandé pour vous';
const String kExpressionRecommendedCta = 'Continuer';

/// `"EE3"` → « Tâche 3 ». Miroir de `tacheLabel` (`production/parcours.ts`).
/// Un code inattendu se rend tel quel plutôt qu'en « Tâche NaN ».
String tacheLabel(String taskCode) {
  final n = int.tryParse(taskCode.substring(taskCode.length - 1));
  return n == null ? taskCode : 'Tâche $n';
}

/// « 2/5 exercices réussis » — les compteurs **servis** par le Plan.
String? exercicesReussisLabel(int validated, int total) {
  if (total <= 0) return null;
  final s = total > 1 ? 's' : '';
  return '$validated/$total exercice$s réussi$s';
}

/// « Votre progression vers l'objectif B2 ». `null` sans objectif déclaré.
String? progressionVersObjectif(String? objectif) => objectif == null
    ? null
    : 'Votre progression vers l\'objectif $objectif';

/* ------------------------------------- La recommandation VIENT DU PLAN --- */

/// **La compétence que le Plan recommande sur CETTE épreuve.**
///
/// 🛑 **Jamais l'ordre du catalogue** (arbitrage du propriétaire, 2026-09-12).
/// L'écran web cherchait la première compétence non terminée du référentiel : un
/// choix de catalogue, pas un choix pédagogique. On lit désormais le Plan, dans
/// l'ordre où lui-même range ses décisions :
///
///   1. `seance.items` — la séance du jour, déjà ordonnée par le serveur ;
///   2. `currentPriority` — la priorité n°1 ;
///   3. `nextPriorities` — les suivantes, dans l'ordre servi.
///
/// 🛑 **Aucun repli artificiel.** Le Plan classe les **quatre** domaines par
/// urgence : un candidat dont la priorité n°1 est en compréhension n'a rien à
/// recommander ici. On rend alors `null` et **la carte disparaît** — retomber
/// sur « la première case libre » recommanderait autre chose que le Plan.
///
/// 🛑 **Rien n'est compté ici** : les compteurs d'étape (« 2/5 exercices
/// réussis ») arrivent servis.
class ExpressionRecommendation {
  const ExpressionRecommendation({
    required this.skillId,
    required this.skillCode,
    required this.section,
    required this.title,
    required this.taskCode,
    required this.validated,
    required this.total,
    required this.locked,
  });

  final String skillId;

  /// `EE2-C3` — sert à ouvrir la fiche de la compétence.
  final String skillCode;
  final SkillSection section;
  final String title;
  final String? taskCode;

  /// Compteurs de l'**étape**, servis par le Plan.
  final int validated;
  final int total;
  final bool locked;
}

ExpressionRecommendation? recommandationDuPlan(
  LearningPlan? plan,
  SkillSection section,
) {
  if (plan == null) return null;

  for (final item in plan.seance.items) {
    final skillId = item.skillId;
    final title = item.title;
    final skillCode = item.skillCode;
    if (item.section != section ||
        skillId == null ||
        title == null ||
        skillCode == null) {
      continue;
    }
    return ExpressionRecommendation(
      skillId: skillId,
      skillCode: skillCode,
      section: section,
      title: title,
      taskCode: _taskCodeOf(skillCode),
      validated: item.stepValidatedCount,
      total: item.stepPromptCount,
      locked: item.locked,
    );
  }

  final priorites = <LearningPlanPriority>[
    if (plan.currentPriority != null) plan.currentPriority!,
    ...plan.nextPriorities,
  ];
  for (final priority in priorites) {
    if (priority.section != section) continue;
    return ExpressionRecommendation(
      skillId: priority.skillId,
      skillCode: priority.skillCode,
      section: section,
      title: priority.title,
      taskCode: _taskCodeOf(priority.skillCode),
      validated: priority.stepValidatedCount,
      total: priority.stepPromptCount,
      locked: priority.locked,
    );
  }
  return null;
}

/// `"EE2-C3"` → `"EE2"`. Un code inattendu rend `null` plutôt qu'une tâche
/// inventée.
String? _taskCodeOf(String? skillCode) {
  final match = RegExp(r'^(EE|EO)[1-3]').firstMatch(skillCode ?? '');
  return match?.group(0);
}
