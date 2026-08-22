import 'action_plan.dart';
import 'enums.dart';
import 'production_models.dart';
import 'skill_models.dart';

enum DiagnosticJourneyStatus {
  notStarted('NOT_STARTED'),
  inProgress('IN_PROGRESS'),
  analyzing('ANALYZING'),
  completed('COMPLETED'),
  failed('FAILED');

  const DiagnosticJourneyStatus(this.wire);

  final String wire;

  static DiagnosticJourneyStatus fromWire(String value) =>
      DiagnosticJourneyStatus.values.firstWhere(
        (status) => status.wire == value,
        orElse: () => DiagnosticJourneyStatus.notStarted,
      );

  bool get isFinal =>
      this == DiagnosticJourneyStatus.completed ||
      this == DiagnosticJourneyStatus.failed;
}

enum DiagnosticStep {
  presentation('PRESENTATION'),
  written('WRITTEN'),
  oral('ORAL'),
  analysis('ANALYSIS'),
  result('RESULT');

  const DiagnosticStep(this.wire);

  final String wire;

  static DiagnosticStep fromWire(String value) =>
      DiagnosticStep.values.firstWhere(
        (step) => step.wire == value,
        orElse: () => DiagnosticStep.presentation,
      );
}

enum LearningPlanState {
  needsDiagnostic('NEEDS_DIAGNOSTIC'),
  diagnosticInProgress('DIAGNOSTIC_IN_PROGRESS'),
  active('ACTIVE');

  const LearningPlanState(this.wire);

  final String wire;

  static LearningPlanState fromWire(String value) =>
      LearningPlanState.values.firstWhere(
        (state) => state.wire == value,
        orElse: () => LearningPlanState.needsDiagnostic,
      );
}

/// Statut d'une compétence dans le Plan, **dérivé serveur**.
///
/// ⚠️ **Libellés gelés, miroir mot pour mot du web**
/// (`LEARNING_PLAN_SKILL_STATUS_LABEL`, `web_sejoufr/lib/diagnostic.ts`). Les
/// deux fronts en tiennent chacun une copie écrite à la main : un libellé qui
/// bouge, ce sont deux fichiers à changer dans la même passe, et deux tests
/// (`test/diagnostic_models_test.dart` côté mobile). Le mobile disait
/// « À évaluer / Priorité », le web « Non observée / Prioritaire » — c'est le
/// web qui fait référence.
enum LearningPlanSkillStatus {
  notObserved('NOT_OBSERVED', 'Non observée'),
  priority('PRIORITY', 'Prioritaire'),
  toReinforce('TO_REINFORCE', 'À renforcer'),
  solid('SOLID', 'Solide');

  const LearningPlanSkillStatus(this.wire, this.label);

  final String wire;
  final String label;

  static LearningPlanSkillStatus fromWire(String value) =>
      LearningPlanSkillStatus.values.firstWhere(
        (status) => status.wire == value,
        orElse: () => LearningPlanSkillStatus.notObserved,
      );

  /// `null` quand rien n'est servi : une compétence **à acquérir** n'a aucun
  /// verdict, et lui prêter `NOT_OBSERVED` reviendrait à inventer une
  /// observation qui n'a jamais eu lieu.
  static LearningPlanSkillStatus? fromWireNullable(String? value) {
    if (value == null) return null;
    for (final status in LearningPlanSkillStatus.values) {
      if (status.wire == value) return status;
    }
    return null;
  }
}

/// D'où vient une observation du Plan.
///
/// ⚠️ **Libellés gelés**, miroir mot pour mot de `LEARNING_PLAN_SOURCE_LABEL`
/// (`web_sejoufr/lib/diagnostic.ts`). Écrit et oral partagent volontairement le
/// même mot : sur la frise d'une compétence, la section est déjà celle de la
/// compétence.
///
/// [tcfCo] / [tcfCe] sont **servis depuis le 2026-08-21** : une session QCM de
/// compréhension alimente le Plan, son résultat étant ventilé par niveau de
/// question. Ce sont des observations **contextualisées** — un QCM de CO ou de
/// CE *est* le format réel de l'épreuve, il n'existe pas de version « guidée » à
/// laquelle l'opposer.
enum LearningPlanSourceType {
  diagnosticEe('DIAGNOSTIC_EE', 'Diagnostic'),
  diagnosticEo('DIAGNOSTIC_EO', 'Diagnostic'),
  productionEe('PRODUCTION_EE', 'Production complète'),
  productionEo('PRODUCTION_EO', 'Production complète'),
  mockExamEe('MOCK_EXAM_EE', 'Examen blanc'),
  mockExamEo('MOCK_EXAM_EO', 'Examen blanc'),
  skillTraining('SKILL_TRAINING', 'Entraînement ciblé'),
  tcfCo('TCF_CO', 'Compréhension'),
  tcfCe('TCF_CE', 'Compréhension');

  const LearningPlanSourceType(this.wire, this.label);

  final String wire;
  final String label;

  static LearningPlanSourceType fromWire(String? value) =>
      LearningPlanSourceType.values.firstWhere(
        (source) => source.wire == value,
        orElse: () => LearningPlanSourceType.productionEe,
      );
}

/// Nature de l'action proposée par le Plan — **même carte, même emplacement,
/// action différente**. Les quatre ne mènent pas au même écran : on lit `kind`,
/// on ne le devine jamais d'un `null`.
///
/// Une échelle à trois barreaux, du plus assisté au moins assisté :
/// [microTraining] → [reassessment] (ce qui fait passer une compétence à
/// « solide »), puis [epreuveMockExam] (une épreuve entière en conditions
/// d'examen), puis [fullTcfMockExam] (les deux tenues ensemble).
///
/// ⚠️ Les **deux derniers rangs sont des jalons** : ils ne pointent aucun
/// contenu nouveau, ils désignent une session d'examen blanc **déjà existante**
/// par son épreuve et son slot de grille — et ils ne voyagent jamais sur un
/// [PlanRecommendedExercise], qui reste réservé aux étapes. Un jalon est un
/// [PlanMilestone].
enum PlanExerciseKind {
  /// Un petit sujet du module Compétences (`skillPromptId`).
  microTraining('MICRO_TRAINING'),

  /// Une vraie tâche TCF à produire (`productionTaskId`), pour vérifier que le
  /// moyen travaillé en ciblé se retrouve **en situation**.
  reassessment('REASSESSMENT'),

  /// Une **série ciblée de QCM** de compréhension : `skillId` seul (aucun sujet,
  /// aucune tâche) + `questionCount`. Se démarre par
  /// `POST /api/attempts { type: TRAINING, module: TCF, skillId }` — épreuve,
  /// palier et taille sont **dérivés serveur**.
  ///
  /// 🛑 **Une série ciblée ne rend JAMAIS un domaine « évalué »** : c'est un
  /// `TRAINING`, et seul un **examen blanc de module** mesure un domaine. Ce
  /// qu'il faut lancer pour mesurer un domaine manquant est dit par
  /// [LearningPlan.domainesAEvaluer], jamais par un exercice de séance.
  targetedQcmSeries('TARGETED_QCM_SERIES'),

  /// Jalon : un examen blanc d'**épreuve** — 3 tâches d'expression écrite ou
  /// orale d'affilée (`epreuve` + `slotNumber`).
  epreuveMockExam('EPREUVE_MOCK_EXAM'),

  /// Jalon final : l'examen blanc **TCF complet**, les 4 épreuves enchaînées.
  fullTcfMockExam('FULL_TCF_MOCK_EXAM');

  const PlanExerciseKind(this.wire);

  final String wire;

  /// Valeur inconnue ⇒ micro-exercice : c'est le comportement historique, et le
  /// seul qui ne puisse pas envoyer le candidat sur un écran inexistant.
  static PlanExerciseKind fromWire(String? value) =>
      PlanExerciseKind.values.firstWhere(
        (kind) => kind.wire == value,
        orElse: () => PlanExerciseKind.microTraining,
      );

  bool get isMilestone =>
      this == PlanExerciseKind.epreuveMockExam ||
      this == PlanExerciseKind.fullTcfMockExam;
}

/// **Ce que le Plan demande de faire** sur une entrée — la pastille d'une carte
/// « Aujourd'hui » et d'une carte « Mes priorités ». Miroir de
/// `PlanActionNature`.
///
/// Le Plan n'est pas seulement un moteur de **remédiation** : c'est un moteur
/// de **progression vers le niveau visé**. Il savait réparer ce qui était
/// fragile ; il ne savait pas **enseigner** ce qui n'avait jamais été
/// travaillé. [aAcquerir] est exactement cette troisième catégorie :
/// *non observé ≠ faible*, et *non fragile ≠ plus rien à apprendre*.
///
/// 🛑 **[aAcquerir] ne se dit JAMAIS « à renforcer ».** Renforcer suppose un
/// constat négatif ; sur une compétence jamais travaillée il n'y en a aucun.
/// Les deux natures ont leur propre constante, leur propre libellé, leur propre
/// teinte et leur propre icône : aucun chemin de code ne peut faire lire l'une
/// comme l'autre.
///
/// **Trois vocabulaires, trois grains — ils ne se remplacent pas.**
/// [LearningPlanSkillStatus] est le verdict d'**une production** (persisté,
/// sans surface) ; `SkillMasteryState` est l'état **agrégé** d'une compétence,
/// affiché sur **sa fiche** ; celui-ci est l'**action à faire maintenant**,
/// affichée sur **la carte du Plan**. [aRenforcer] et
/// `SkillMasteryState.toReinforce` portent volontairement le même libellé —
/// quand les deux s'appliquent ils disent la même chose, ils ne s'affichent
/// simplement pas au même endroit. Ce n'est pas une collision à corriger.
///
/// **L'ordre de déclaration EST l'ordre de choix** d'une séance : mesurer ce
/// qui manque, réparer ce qui est fragile, vérifier ce qui est prêt, apprendre
/// ce qui vient. Ne pas le réordonner.
///
/// Libellés **gelés côté serveur** (`PlanActionNature.getLabel()`, figés par
/// `SkillLabelsTest`), recopiés mot pour mot — jamais une chaîne écrite dans un
/// widget.
enum PlanActionNature {
  /// Une mesure manque, et elle est **indispensable** : le candidat a produit
  /// sur ce domaine et le correcteur n'a rien pu y observer. L'action n'est
  /// alors **pas un exercice** mais une [PlanDomainAssessment] — c'est la
  /// seule nature qui porte `assessment` au lieu de `exercise`.
  aEvaluer('A_EVALUER', 'À évaluer'),

  /// Une fragilité **réellement observée** : c'est ce qui bloque maintenant.
  aRenforcer('A_RENFORCER', 'À renforcer'),

  /// L'étape est terminée et le moteur juge la compétence prête : le Plan
  /// demande une **vérification en situation** plutôt qu'un micro-sujet de
  /// plus.
  aVerifier('A_VERIFIER', 'À vérifier'),

  /// **Une compétence du palier en construction, jamais travaillée.** Aucun
  /// constat négatif ne la désigne : elle est là parce qu'elle appartient au
  /// palier que le cycle construit et que le candidat ne l'a pas encore
  /// abordée. Rien n'est observé dessus — `status`, `explanation`, `evidence`,
  /// `confidence`, `observedAt` et `masteryState` valent `null`, et c'est le
  /// fait même : *null = inconnu, jamais mauvais*.
  aAcquerir('A_ACQUERIR', 'À acquérir');

  const PlanActionNature(this.wire, this.label);

  final String wire;
  final String label;

  static PlanActionNature? fromWireNullable(String? value) {
    if (value == null) return null;
    for (final nature in PlanActionNature.values) {
      if (nature.wire == value) return nature;
    }
    return null;
  }

  /// Valeur absente ou inconnue ⇒ [aRenforcer] : c'est le **comportement
  /// historique**, avant que cette nature existe toute priorité était une
  /// fragilité observée. Une acquisition, elle, est toujours nommée par le
  /// serveur — elle ne peut donc pas tomber dans ce repli.
  static PlanActionNature fromWire(String? value) =>
      fromWireNullable(value) ?? PlanActionNature.aRenforcer;

  /// L'action est une **mesure de domaine**, pas un entraînement.
  bool get isAssessment => this == PlanActionNature.aEvaluer;
}

enum ObservationConfidence {
  low('LOW'),
  medium('MEDIUM'),
  high('HIGH');

  const ObservationConfidence(this.wire);

  final String wire;

  static ObservationConfidence fromWire(String value) =>
      ObservationConfidence.values.firstWhere(
        (confidence) => confidence.wire == value,
        orElse: () => ObservationConfidence.low,
      );

  /// `null` quand rien n'est servi — une compétence jamais observée n'a pas de
  /// « confiance basse », elle n'a **pas de confiance du tout**.
  static ObservationConfidence? fromWireNullable(String? value) {
    if (value == null) return null;
    for (final confidence in ObservationConfidence.values) {
      if (confidence.wire == value) return confidence;
    }
    return null;
  }
}

enum DiagnosticTaskCompletion {
  completed('COMPLETED', 'Consigne accomplie'),
  partial('PARTIAL', 'Consigne partiellement accomplie'),
  notCompleted('NOT_COMPLETED', 'Consigne non accomplie');

  const DiagnosticTaskCompletion(this.wire, this.label);

  final String wire;

  /// Libellé candidat des cartes « Vos productions ». Miroir mot pour mot de
  /// `DIAGNOSTIC_TASK_COMPLETION_LABEL` (`web_sejoufr/lib/diagnostic.ts`),
  /// gelé des deux côtés par test.
  final String label;

  static DiagnosticTaskCompletion fromWire(String value) =>
      DiagnosticTaskCompletion.values.firstWhere(
        (completion) => completion.wire == value,
        orElse: () => DiagnosticTaskCompletion.notCompleted,
      );

  /// Le serveur ne rend **aucun verdict** sur une production non évaluable
  /// (cf. [ProductionEvaluabilite]) : `null` veut dire « rien à observer », pas
  /// « consigne non accomplie ». Ne jamais replier sur une valeur par défaut —
  /// le repli de [fromWire] est un garde-fou de valeur inconnue, pas d'absence.
  static DiagnosticTaskCompletion? fromWireNullable(String? value) =>
      value == null ? null : fromWire(value);
}

enum DiagnosticCommunicationStatus {
  effective('EFFECTIVE', 'Message clair'),
  partial('PARTIAL', 'Message compris avec effort'),
  ineffective('INEFFECTIVE', 'Message difficile à suivre');

  const DiagnosticCommunicationStatus(this.wire, this.label);

  final String wire;

  /// Libellé candidat, même usage que [DiagnosticTaskCompletion.label] :
  /// miroir de `DIAGNOSTIC_COMMUNICATION_LABEL` côté web.
  final String label;

  static DiagnosticCommunicationStatus fromWire(String value) =>
      DiagnosticCommunicationStatus.values.firstWhere(
        (status) => status.wire == value,
        orElse: () => DiagnosticCommunicationStatus.ineffective,
      );

  /// `null` = production non évaluable, donc **rien à observer** — surtout pas
  /// « message difficile à suivre ». Même règle que
  /// [DiagnosticTaskCompletion.fromWireNullable].
  static DiagnosticCommunicationStatus? fromWireNullable(String? value) =>
      value == null ? null : fromWire(value);
}

/// Ce qu'un exercice de diagnostic montre au candidat, quelle que soit sa
/// provenance. Deux sources le produisent :
///  - [DiagnosticExercise], servi par la session d'un compte, qui porte en plus
///    l'attempt et l'éventuelle soumission ;
///  - [PublicDiagnosticExercise], servi par le catalogue public à un visiteur
///    sans compte — il n'a ni `attemptId` ni `submissionId`, qui n'existent
///    qu'une fois la session créée, donc qu'après l'inscription.
///
/// Les écrans de production (consigne, écrit, oral) sont typés sur cette vue :
/// ils rendent le même exercice dans les deux régimes.
abstract class DiagnosticExerciseView {
  const DiagnosticExerciseView({
    required this.productionTaskId,
    required this.epreuve,
    required this.title,
    required this.instruction,
    required this.helperText,
    this.wordsMin,
    this.wordsMax,
    this.durationMinSeconds,
    this.durationMaxSeconds,
    this.instructionAudioUrl,
  });

  final String productionTaskId;
  final EpreuveType epreuve;
  final String title;
  final String instruction;
  final String helperText;
  final int? wordsMin;
  final int? wordsMax;
  final int? durationMinSeconds;
  final int? durationMaxSeconds;
  final String? instructionAudioUrl;
}

class DiagnosticExercise extends DiagnosticExerciseView {
  const DiagnosticExercise({
    required super.productionTaskId,
    required this.attemptId,
    required super.epreuve,
    required super.title,
    required super.instruction,
    required super.helperText,
    super.wordsMin,
    super.wordsMax,
    super.durationMinSeconds,
    super.durationMaxSeconds,
    super.instructionAudioUrl,
    this.submissionId,
    this.submissionStatus,
  });

  final String attemptId;
  final String? submissionId;
  final SubmissionStatut? submissionStatus;

  factory DiagnosticExercise.fromJson(Map<String, dynamic> json) =>
      DiagnosticExercise(
        productionTaskId: json['productionTaskId'] as String,
        attemptId: json['attemptId'] as String,
        epreuve: EpreuveType.fromWire(json['epreuve'] as String),
        title: json['title'] as String? ?? '',
        instruction: json['instruction'] as String? ?? '',
        helperText: json['helperText'] as String? ?? '',
        wordsMin: (json['wordsMin'] as num?)?.toInt(),
        wordsMax: (json['wordsMax'] as num?)?.toInt(),
        durationMinSeconds: (json['durationMinSeconds'] as num?)?.toInt(),
        durationMaxSeconds: (json['durationMaxSeconds'] as num?)?.toInt(),
        instructionAudioUrl: _trimmedOrNull(json['instructionAudioUrl']),
        submissionId: json['submissionId'] as String?,
        submissionStatus: json['submissionStatus'] == null
            ? null
            : SubmissionStatut.fromWire(json['submissionStatus'] as String),
      );
}

/// Exercice servi par `GET /api/public/diagnostics/current` — **sans jeton**.
class PublicDiagnosticExercise extends DiagnosticExerciseView {
  const PublicDiagnosticExercise({
    required super.productionTaskId,
    required super.epreuve,
    required super.title,
    required super.instruction,
    required super.helperText,
    super.wordsMin,
    super.wordsMax,
    super.durationMinSeconds,
    super.durationMaxSeconds,
    super.instructionAudioUrl,
  });

  factory PublicDiagnosticExercise.fromJson(Map<String, dynamic> json) =>
      PublicDiagnosticExercise(
        productionTaskId: json['productionTaskId'] as String,
        epreuve: EpreuveType.fromWire(json['epreuve'] as String),
        title: json['title'] as String? ?? '',
        instruction: json['instruction'] as String? ?? '',
        helperText: json['helperText'] as String? ?? '',
        wordsMin: (json['wordsMin'] as num?)?.toInt(),
        wordsMax: (json['wordsMax'] as num?)?.toInt(),
        durationMinSeconds: (json['durationMinSeconds'] as num?)?.toInt(),
        durationMaxSeconds: (json['durationMaxSeconds'] as num?)?.toInt(),
        instructionAudioUrl: _trimmedOrNull(json['instructionAudioUrl']),
      );
}

/// Les deux sujets du diagnostic tels qu'un visiteur les reçoit avant tout
/// compte. Il n'y a **ni session, ni attempt, ni soumission** ici : rien n'est
/// créé côté serveur tant que le visiteur ne s'est pas inscrit.
class PublicDiagnostic {
  const PublicDiagnostic({
    required this.diagnosticCode,
    required this.diagnosticVersion,
    required this.written,
    required this.oral,
  });

  final String diagnosticCode;
  final int diagnosticVersion;
  final PublicDiagnosticExercise written;
  final PublicDiagnosticExercise oral;

  factory PublicDiagnostic.fromJson(Map<String, dynamic> json) =>
      PublicDiagnostic(
        diagnosticCode: json['diagnosticCode'] as String? ?? '',
        diagnosticVersion: (json['diagnosticVersion'] as num? ?? 0).toInt(),
        written: PublicDiagnosticExercise.fromJson(
          json['written'] as Map<String, dynamic>,
        ),
        oral: PublicDiagnosticExercise.fromJson(
          json['oral'] as Map<String, dynamic>,
        ),
      );
}

class DiagnosticSkillObservation {
  const DiagnosticSkillObservation({
    required this.skillId,
    required this.skillCode,
    required this.skillTitle,
    required this.section,
    required this.observed,
    required this.status,
    required this.confidence,
    required this.priority,
    this.evidence,
    this.explanation,
  });

  final String skillId;
  final String skillCode;
  final String skillTitle;
  final SkillSection section;
  final bool observed;
  final LearningPlanSkillStatus status;
  final String? evidence;
  final String? explanation;
  final ObservationConfidence confidence;
  final bool priority;

  factory DiagnosticSkillObservation.fromJson(Map<String, dynamic> json) =>
      DiagnosticSkillObservation(
        skillId: json['skillId'] as String,
        skillCode: json['skillCode'] as String? ?? '',
        skillTitle: json['skillTitle'] as String? ?? '',
        section: SkillSection.fromWire(json['section'] as String),
        observed: json['observed'] as bool? ?? false,
        status: LearningPlanSkillStatus.fromWire(
          json['status'] as String? ?? 'NOT_OBSERVED',
        ),
        evidence: _trimmedOrNull(json['evidence']),
        explanation: _trimmedOrNull(json['explanation']),
        confidence: ObservationConfidence.fromWire(
          json['confidence'] as String? ?? 'LOW',
        ),
        priority: json['priority'] as bool? ?? false,
      );
}

/// Le résultat d'UNE des deux productions du diagnostic.
///
/// ⚠️ **Trois états, pas deux.** Le bloc entier `null` (côté
/// [DiagnosticResult.written] / [DiagnosticResult.oral]) signifie « pas encore
/// rendue ». Un bloc présent avec [ProductionEvaluabilite.nonEvaluable]
/// signifie « rendue, mais il n'y avait **rien à observer** » : les trois
/// verdicts valent alors `null`, [skills] ne porte que des observations non
/// observées, et [strengths] / [weaknesses] sont vides.
///
/// 🛑 **Les trois verdicts sont nullables, et on n'en fabrique aucun.** Ils
/// étaient déclarés non-null et parsés en `as String` : le serveur les a rendus
/// nullables (production inexploitable — vide, langue étrangère, consigne
/// recopiée), et la désérialisation du résultat de diagnostic **levait**, donc
/// l'écran ne se construisait jamais. *null = inconnu, jamais mauvais* : replier
/// sur `NOT_COMPLETED` / `INEFFECTIVE` aurait remplacé un plantage par un
/// reproche.
class DiagnosticProductionResult {
  const DiagnosticProductionResult({
    required this.strengths,
    required this.weaknesses,
    required this.skills,
    this.evaluabilite = ProductionEvaluabilite.evaluable,
    this.levelEstimate,
    this.taskCompletion,
    this.communicationStatus,
    this.summary,
  });

  /// **Jamais null** — [ProductionEvaluabilite.evaluable] sur toutes les
  /// analyses antérieures au champ. Le **même** enum que celui de
  /// [EvaluationResult.evaluabilite] : un seul fait, une seule définition.
  final ProductionEvaluabilite evaluabilite;

  /// `null` sur une production non évaluable : aucun niveau n'a été observé.
  final NiveauCecrl? levelEstimate;

  /// `null` sur une production non évaluable.
  final DiagnosticTaskCompletion? taskCompletion;

  /// `null` sur une production non évaluable.
  final DiagnosticCommunicationStatus? communicationStatus;
  final String? summary;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<DiagnosticSkillObservation> skills;

  /// La production a été rendue, mais **rien n'a pu y être observé**. Un écran
  /// n'affiche alors ni niveau, ni verdict de consigne, ni statut de
  /// communication — et le dit **sans reproche**.
  bool get estNonEvaluable =>
      evaluabilite == ProductionEvaluabilite.nonEvaluable;

  factory DiagnosticProductionResult.fromJson(Map<String, dynamic> json) =>
      DiagnosticProductionResult(
        evaluabilite:
            ProductionEvaluabilite.fromWire(json['evaluabilite'] as String?),
        levelEstimate:
            NiveauCecrl.fromWireNullable(json['levelEstimate'] as String?),
        taskCompletion: DiagnosticTaskCompletion.fromWireNullable(
          json['taskCompletion'] as String?,
        ),
        communicationStatus: DiagnosticCommunicationStatus.fromWireNullable(
          json['communicationStatus'] as String?,
        ),
        summary: _trimmedOrNull(json['summary']),
        strengths: _stringList(json['strengths']),
        weaknesses: _stringList(json['weaknesses']),
        skills: _objectList(json['skills'])
            .map(DiagnosticSkillObservation.fromJson)
            .toList(growable: false),
      );
}

/// L'exercice d'une **étape** du Plan.
///
/// **Deux natures, un seul champ** ([kind]) : un micro-exercice du module
/// Compétences, ou une **vérification en situation** sur une vraie tâche TCF.
/// D'où deux identifiants mutuellement exclusifs — [skillPromptId] pour
/// [PlanExerciseKind.microTraining], [productionTaskId] + [tacheNumero] pour
/// [PlanExerciseKind.reassessment].
///
/// ⚠️ **Un jalon n'est jamais un [PlanRecommendedExercise]** : il n'a ni titre,
/// ni compétence, ni section, et le serveur ne le sert que sur
/// `LearningPlanDto.milestone`. C'est [PlanMilestone], une classe à part, pour
/// qu'aucun écran ne puisse lire ici un titre qui n'existerait pas.
class PlanRecommendedExercise {
  const PlanRecommendedExercise({
    required this.kind,
    required this.skillId,
    required this.skillCode,
    required this.title,
    required this.section,
    required this.estimatedMinutes,
    this.skillPromptId,
    this.productionTaskId,
    this.tacheNumero,
    this.questionCount,
    this.locked = false,
  });

  final PlanExerciseKind kind;

  /// Micro-exercice uniquement ; `null` sur une vérification.
  final String? skillPromptId;

  /// Vérification uniquement ; `null` sur un micro-exercice.
  final String? productionTaskId;

  /// Numéro de tâche (1, 2 ou 3) du sujet de production — vérification
  /// uniquement. Avec [section], c'est ce qui permet d'ouvrir le bon écran.
  final int? tacheNumero;
  final String skillId;
  final String skillCode;
  final String title;
  final SkillSection section;
  final int estimatedMinutes;

  /// Nombre de questions de la série — **série ciblée uniquement**
  /// ([PlanExerciseKind.targetedQcmSeries]), `null` partout ailleurs. On
  /// l'affiche tel quel : la taille est décidée serveur, jamais choisie ici.
  final int? questionCount;

  /// Verrou freemium **calculé par le serveur** : ce candidat ne peut pas
  /// produire sur ce micro-exercice. Le Plan reste affiché en entier — seul le
  /// bouton devient une invitation à s'abonner. Aucune règle n'est recalculée
  /// ici (cf. `SkillDto.locked`).
  final bool locked;

  factory PlanRecommendedExercise.fromJson(Map<String, dynamic> json) =>
      PlanRecommendedExercise(
        kind: PlanExerciseKind.fromWire(json['kind'] as String?),
        skillPromptId: json['skillPromptId'] as String?,
        productionTaskId: json['productionTaskId'] as String?,
        tacheNumero: (json['tacheNumero'] as num?)?.toInt(),
        skillId: json['skillId'] as String,
        skillCode: json['skillCode'] as String? ?? '',
        title: json['title'] as String? ?? '',
        section: SkillSection.fromWire(json['section'] as String),
        estimatedMinutes: (json['estimatedMinutes'] as num? ?? 0).toInt(),
        questionCount: (json['questionCount'] as num?)?.toInt(),
        locked: json['locked'] as bool? ?? false,
      );
}

/// Le **jalon** du Plan : un examen blanc que le serveur juge mérité, un cran
/// au-dessus des étapes.
///
/// Il ne désigne **aucun contenu nouveau** — juste une session d'examen blanc
/// déjà existante, par son [epreuve] et son [slotNumber]. D'où l'absence
/// assumée de titre, de compétence et de section : le serveur expose des faits,
/// la phrase appartient aux fronts (`plan_milestone_labels.dart`), exactement
/// comme pour `PlanChange`.
///
/// Deux natures : un examen blanc d'épreuve ([PlanExerciseKind.epreuveMockExam],
/// `TCF_EE` ou `TCF_EO`) ou l'examen blanc TCF complet
/// ([PlanExerciseKind.fullTcfMockExam], `TCF_COMPLET`).
class PlanMilestone {
  const PlanMilestone({
    required this.kind,
    required this.epreuve,
    required this.slotNumber,
    required this.estimatedMinutes,
    this.locked = false,
  });

  final PlanExerciseKind kind;

  /// `TCF_EE` / `TCF_EO` / `TCF_COMPLET` — c'est **ce champ** qui dit vers quel
  /// examen envoyer, jamais une section de compétence.
  final EpreuveType epreuve;

  /// Slot de la grille d'examens blancs à démarrer. Le serveur désigne le
  /// premier slot non joué : on le repasse tel quel, on ne le choisit pas.
  final int slotNumber;

  final int estimatedMinutes;

  /// Verrou freemium **calculé par le serveur**. Le jalon reste **désigné et
  /// affiché en entier** : seul le bouton devient une invitation à s'abonner.
  final bool locked;

  bool get isFullExam => kind == PlanExerciseKind.fullTcfMockExam;

  static PlanMilestone? fromJsonOrNull(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final kind = PlanExerciseKind.fromWire(value['kind'] as String?);
    // Un rang non-jalon ici n'existe pas côté serveur ; s'il arrivait, mieux
    // vaut ne rien afficher que d'ouvrir un examen qu'on aurait deviné.
    if (!kind.isMilestone) return null;
    final epreuve = value['epreuve'] as String?;
    if (epreuve == null) return null;
    return PlanMilestone(
      kind: kind,
      epreuve: EpreuveType.fromWire(epreuve),
      slotNumber: (value['slotNumber'] as num? ?? 1).toInt(),
      estimatedMinutes: (value['estimatedMinutes'] as num? ?? 0).toInt(),
      locked: value['locked'] as bool? ?? false,
    );
  }
}

/// L'**avant/après** du diagnostic : la phrase que le candidat a réellement
/// écrite, sa réécriture au niveau visé, et les endroits où se joue la
/// différence.
///
/// **Production ÉCRITE seulement** — une production orale n'est jamais
/// réécrite (ce que lit le correcteur est une transcription automatique). Le
/// bloc vient d'un **second appel LLM best-effort** : `null` est un cas
/// **NORMAL**, jamais une erreur ni une attente à annoncer.
///
/// Les clés intérieures sont celles de `version_ciblee` / `exempleCible` du
/// module Compétences, donc [ActionPlanSegment] et le surlignage de
/// `screens/tcf_production/widgets/action_plan.dart` s'appliquent tels quels —
/// on ne réécrit pas une seconde mécanique de mise en évidence.
class DiagnosticExempleCible {
  const DiagnosticExempleCible({
    required this.original,
    required this.texte,
    required this.segments,
    this.niveauVise,
  });

  /// La phrase du candidat, **sous-chaîne exacte** de sa production écrite.
  final String original;

  /// La même chose, réécrite au niveau visé.
  final String texte;

  /// Passages de [texte] à mettre en évidence. Chaque `extrait` est une
  /// sous-chaîne exacte de [texte] ; introuvable ⇒ le texte reste brut.
  final List<ActionPlanSegment> segments;

  /// Palier visé par la réécriture. **Donnée de logique, pas une étiquette à
  /// coller sur le texte modèle** : la longueur imposée à cette réécriture ne
  /// laisse pas la place de démontrer honnêtement un palier annoncé (mesuré
  /// côté productions — cf. `kActionPlanExempleTitle`).
  final NiveauCecrl? niveauVise;

  /// La partie déjà rendue par `ActionPlanExempleCard` — même contrat
  /// intérieur, même surlignage.
  ActionPlanExempleCible get asActionPlanExemple =>
      ActionPlanExempleCible(texte: texte, segments: segments);

  static DiagnosticExempleCible? fromJsonNullable(Object? json) {
    if (json is! Map) return null;
    final original = _trimmedOrNull(json['original']);
    final texte = _trimmedOrNull(json['texte']);
    if (original == null || texte == null) return null;
    final raw = json['segments'];
    return DiagnosticExempleCible(
      original: original,
      texte: texte,
      segments: raw is! List
          ? const <ActionPlanSegment>[]
          : raw
              .map(ActionPlanSegment.fromJsonNullable)
              .whereType<ActionPlanSegment>()
              .toList(growable: false),
      niveauVise: _niveau(json['niveauVise']),
    );
  }
}

class DiagnosticResult {
  const DiagnosticResult({
    required this.strengths,
    required this.priorities,
    this.written,
    this.oral,
    this.mainPriorityExplanation,
    this.nextAction,
    this.exempleCible,
    this.fragileSkillCount = 0,
    this.solidSkillCount = 0,
  });

  final DiagnosticProductionResult? written;
  final DiagnosticProductionResult? oral;
  final List<String> strengths;
  final List<DiagnosticSkillObservation> priorities;
  final String? mainPriorityExplanation;
  final PlanRecommendedExercise? nextAction;

  /// Écrit seulement, best-effort : `null` est un cas normal, le bloc
  /// avant/après n'est simplement pas rendu.
  final DiagnosticExempleCible? exempleCible;

  /// Combien de compétences **distinctes** les deux productions ont réellement
  /// montrées fragiles (observées, `PRIORITY` ou `TO_REINFORCE`).
  ///
  /// 🛑 **Seule source du « + N autres » de l'écran de résultat.** [priorities]
  /// est plafonné à 3 par règle produit : un compteur calculé dessus ne dirait
  /// jamais mieux que « + 2 », un chiffre de plafond et non une réalité. Le
  /// serveur fait foi — aucun front ne recompte, deux dérivations finiraient
  /// par afficher deux nombres différents pour la même chose.
  ///
  /// `0` est un état normal : aucun bloc « + N autres » n'est rendu.
  final int fragileSkillCount;

  /// Le compte réel des points forts : compétences distinctes observées
  /// `SOLID`. ⚠️ [strengths] ne peut pas rendre ce service — la liste est
  /// plafonnée à 3 **à l'écriture** du résumé côté serveur.
  final int solidSkillCount;

  factory DiagnosticResult.fromJson(Map<String, dynamic> json) =>
      DiagnosticResult(
        written: json['written'] == null
            ? null
            : DiagnosticProductionResult.fromJson(
                json['written'] as Map<String, dynamic>,
              ),
        oral: json['oral'] == null
            ? null
            : DiagnosticProductionResult.fromJson(
                json['oral'] as Map<String, dynamic>,
              ),
        strengths: _stringList(json['strengths']),
        priorities: _objectList(json['priorities'])
            .map(DiagnosticSkillObservation.fromJson)
            .take(3)
            .toList(growable: false),
        mainPriorityExplanation:
            _trimmedOrNull(json['mainPriorityExplanation']),
        nextAction: json['nextAction'] == null
            ? null
            : PlanRecommendedExercise.fromJson(
                json['nextAction'] as Map<String, dynamic>,
              ),
        exempleCible:
            DiagnosticExempleCible.fromJsonNullable(json['exempleCible']),
        fragileSkillCount: _count(json['fragileSkillCount']),
        solidSkillCount: _count(json['solidSkillCount']),
      );
}

class DiagnosticJourney {
  const DiagnosticJourney({
    required this.diagnosticCode,
    required this.diagnosticVersion,
    required this.status,
    required this.nextStep,
    required this.canRetry,
    this.sessionId,
    this.written,
    this.oral,
    this.result,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
  });

  final String? sessionId;
  final String diagnosticCode;
  final int diagnosticVersion;
  final DiagnosticJourneyStatus status;
  final DiagnosticStep nextStep;
  final DiagnosticExercise? written;
  final DiagnosticExercise? oral;
  final DiagnosticResult? result;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final bool canRetry;

  int get completedExerciseCount =>
      (written?.submissionId == null ? 0 : 1) +
      (oral?.submissionId == null ? 0 : 1);

  factory DiagnosticJourney.fromJson(Map<String, dynamic> json) =>
      DiagnosticJourney(
        sessionId: json['sessionId'] as String?,
        diagnosticCode: json['diagnosticCode'] as String? ?? '',
        diagnosticVersion: (json['diagnosticVersion'] as num? ?? 0).toInt(),
        status: DiagnosticJourneyStatus.fromWire(
          json['status'] as String? ?? 'NOT_STARTED',
        ),
        nextStep: DiagnosticStep.fromWire(
          json['nextStep'] as String? ?? 'PRESENTATION',
        ),
        written: json['written'] == null
            ? null
            : DiagnosticExercise.fromJson(
                json['written'] as Map<String, dynamic>,
              ),
        oral: json['oral'] == null
            ? null
            : DiagnosticExercise.fromJson(
                json['oral'] as Map<String, dynamic>,
              ),
        result: json['result'] == null
            ? null
            : DiagnosticResult.fromJson(
                json['result'] as Map<String, dynamic>,
              ),
        startedAt: _date(json['startedAt']),
        completedAt: _date(json['completedAt']),
        errorMessage: _trimmedOrNull(json['errorMessage']),
        canRetry: json['canRetry'] as bool? ?? false,
      );
}

class LearningPlanPriority {
  const LearningPlanPriority({
    required this.skillId,
    required this.skillCode,
    required this.title,
    required this.section,
    required this.nature,
    this.status,
    this.confidence,
    this.observedAt,
    this.explanation,
    this.evidence,
    this.recommendedExercise,
    this.promptCount = 0,
    this.attemptedCount = 0,
    this.validatedCount = 0,
    this.stepPromptCount = 0,
    this.stepAttemptedCount = 0,
    this.stepValidatedCount = 0,
    this.stepCompleted = false,
    this.stepPromptIds = const <String>[],
    this.masteryState,
    this.readyForReassessment = false,
    this.locked = false,
  });

  final String skillId;
  final String skillCode;
  final String title;
  final SkillSection section;

  /// **Ce que le Plan demande de faire ici** — réparer une fragilité, vérifier
  /// une étape terminée, ou **acquérir** une compétence du palier en
  /// construction. C'est **ce champ** que les écrans lisent pour qualifier la
  /// carte, jamais la nullité d'un autre.
  ///
  /// 🛑 Une entrée [PlanActionNature.aAcquerir] n'a **rien d'observé** : ni
  /// [status], ni [explanation], ni [evidence], ni [confidence], ni
  /// [observedAt], ni [masteryState]. Ce n'est pas un trou de donnée, c'est le
  /// fait même — rien n'a été constaté, donc rien n'a échoué.
  final PlanActionNature nature;

  /// Verdict de la **dernière production** observée. `null` sur une compétence
  /// jamais travaillée ([PlanActionNature.aAcquerir]) : on n'invente pas un
  /// verdict pour remplir un champ.
  final LearningPlanSkillStatus? status;
  final String? explanation;
  final String? evidence;

  /// Certitude du correcteur sur cette observation. `null` quand il n'y en a
  /// aucune.
  final ObservationConfidence? confidence;

  /// Date de la dernière observation probante. `null` quand la compétence n'a
  /// jamais été observée.
  final DateTime? observedAt;
  final PlanRecommendedExercise? recommendedExercise;

  /// Compteurs de petits sujets de la compétence, **servis par le serveur** —
  /// mêmes champs que `SkillDto` du module Compétences, pour que le Plan et
  /// « Réviser → Compétences » parlent de la même progression.
  final int promptCount;
  final int attemptedCount;
  final int validatedCount;

  /// Compteurs de l'**étape** : les 5 premiers sujets actifs de la compétence,
  /// et rien d'autre. ⚠️ C'est ce couple que l'anneau d'une étape affiche
  /// (« 2/5 »), jamais les compteurs de la compétence entière ci-dessus, qui
  /// restent ceux des cartes « compétences observées ». Dérivés serveur.
  final int stepPromptCount;
  final int stepAttemptedCount;
  final int stepValidatedCount;

  /// `true` quand les sujets de l'étape ont **tous** été traités. Terminée ≠
  /// tout validé, d'où [stepValidatedCount] à côté. Une étape terminée **reste
  /// affichée** : les priorités ne changent qu'à la prochaine production.
  final bool stepCompleted;

  /// **Le périmètre de l'étape** : les identifiants de ses sujets, dans l'ordre
  /// de l'étape (rang d'affichage croissant). **Jamais `null`**, et
  /// `stepPromptIds.length == stepPromptCount` par construction — on ne
  /// recompte rien à partir de là.
  ///
  /// Il permet à l'écran d'une compétence ouverte **depuis le Plan** de rester
  /// dans l'étape (les mêmes 5 sujets, « 2/5 ») au lieu de retomber sur la
  /// fiche complète et son « 1/15 ». La règle « les 5 premiers sujets actifs »
  /// vit côté serveur : elle ne se réimplémente nulle part.
  ///
  /// Liste **vide** quand la compétence n'a aucun sujet actif — cas normal.
  final List<String> stepPromptIds;

  /// État de maîtrise agrégé de la compétence, identique à
  /// `SkillDto.masteryState` et issu du même moteur. À ne pas confondre avec
  /// [status], verdict de la **dernière** production.
  final SkillMasteryState? masteryState;

  /// `true` quand la compétence a assez été travaillée en exercices ciblés,
  /// sans preuve de transfert récente : l'étape devient une **vérification**
  /// (`recommendedExercise.kind == PlanExerciseKind.reassessment`).
  final bool readyForReassessment;

  /// Verrou freemium servi par le serveur. L'étape reste **entièrement
  /// lisible** — masquer une priorité priverait le candidat du résultat de sa
  /// propre production ; seul le passage à l'exercice est verrouillé.
  final bool locked;

  factory LearningPlanPriority.fromJson(Map<String, dynamic> json) =>
      LearningPlanPriority(
        skillId: json['skillId'] as String,
        skillCode: json['skillCode'] as String? ?? '',
        title: json['title'] as String? ?? '',
        section: SkillSection.fromWire(json['section'] as String),
        nature: PlanActionNature.fromWire(json['nature'] as String?),
        status:
            LearningPlanSkillStatus.fromWireNullable(json['status'] as String?),
        explanation: _trimmedOrNull(json['explanation']),
        evidence: _trimmedOrNull(json['evidence']),
        confidence:
            ObservationConfidence.fromWireNullable(json['confidence'] as String?),
        observedAt: _date(json['observedAt']),
        recommendedExercise: json['recommendedExercise'] == null
            ? null
            : PlanRecommendedExercise.fromJson(
                json['recommendedExercise'] as Map<String, dynamic>,
              ),
        promptCount: (json['promptCount'] as num? ?? 0).toInt(),
        attemptedCount: (json['attemptedCount'] as num? ?? 0).toInt(),
        validatedCount: (json['validatedCount'] as num? ?? 0).toInt(),
        stepPromptCount: (json['stepPromptCount'] as num? ?? 0).toInt(),
        stepAttemptedCount: (json['stepAttemptedCount'] as num? ?? 0).toInt(),
        stepValidatedCount: (json['stepValidatedCount'] as num? ?? 0).toInt(),
        stepCompleted: json['stepCompleted'] as bool? ?? false,
        stepPromptIds: (json['stepPromptIds'] as List<dynamic>? ?? const [])
            .map((id) => id.toString())
            .toList(growable: false),
        masteryState:
            SkillMasteryState.fromWireNullable(json['masteryState'] as String?),
        readyForReassessment: json['readyForReassessment'] as bool? ?? false,
        locked: json['locked'] as bool? ?? false,
      );
}

/// Une **étape franchie** du parcours : une compétence dont le transfert est
/// prouvé, donc qui n'est plus une priorité.
///
/// Jusqu'ici une compétence réussie sortait simplement des priorités et son
/// étape **disparaissait** du Plan — le candidat perdait la trace de ce qu'il
/// avait passé. Elles sont désormais servies pour être affichées **avant**
/// l'étape courante et les suivantes, dans le même parcours numéroté, et
/// **cochées**.
///
/// ⚠️ **Ni exercice recommandé, ni `locked`** : il n'y a plus rien à y faire, et
/// une étape franchie n'est pas une porte commerciale. Ne pas en inventer.
///
/// ⚠️ **[masteryState] n'est PAS toujours `solid`** : une preuve de transfert
/// récente suffit à franchir l'étape. **L'appartenance à cette liste EST la
/// coche** — ne jamais conditionner l'affichage à un état de maîtrise.
class LearningPlanCompletedStep {
  const LearningPlanCompletedStep({
    required this.skillId,
    required this.skillCode,
    required this.title,
    required this.section,
    required this.observedAt,
    this.stepPromptCount = 0,
    this.stepAttemptedCount = 0,
    this.stepValidatedCount = 0,
    this.stepPromptIds = const <String>[],
    this.masteryState,
  });

  final String skillId;
  final String skillCode;
  final String title;
  final SkillSection section;

  /// Dernière observation probante : c'est elle qui ordonne les étapes
  /// franchies entre elles (ordre déjà appliqué par le serveur).
  final DateTime observedAt;

  /// Compteurs de l'**étape** — les 5 premiers sujets actifs de la compétence.
  /// Une étape franchie n'est pas forcément à 5/5.
  final int stepPromptCount;
  final int stepAttemptedCount;
  final int stepValidatedCount;

  /// Périmètre de l'étape, dans l'ordre. **Jamais `null`**, éventuellement vide.
  /// Même sémantique que [LearningPlanPriority.stepPromptIds] : rouvrir une
  /// étape franchie doit mener aux mêmes sujets.
  final List<String> stepPromptIds;

  final SkillMasteryState? masteryState;

  factory LearningPlanCompletedStep.fromJson(Map<String, dynamic> json) =>
      LearningPlanCompletedStep(
        skillId: json['skillId'] as String,
        skillCode: json['skillCode'] as String? ?? '',
        title: json['title'] as String? ?? '',
        section: SkillSection.fromWire(json['section'] as String),
        observedAt: _date(json['observedAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        stepPromptCount: (json['stepPromptCount'] as num? ?? 0).toInt(),
        stepAttemptedCount: (json['stepAttemptedCount'] as num? ?? 0).toInt(),
        stepValidatedCount: (json['stepValidatedCount'] as num? ?? 0).toInt(),
        stepPromptIds: (json['stepPromptIds'] as List<dynamic>? ?? const [])
            .map((id) => id.toString())
            .toList(growable: false),
        masteryState:
            SkillMasteryState.fromWireNullable(json['masteryState'] as String?),
      );
}

class LearningPlanSkill {
  const LearningPlanSkill({
    required this.skillId,
    required this.skillCode,
    required this.title,
    required this.section,
    required this.status,
    required this.lastObservedAt,
    this.promptCount = 0,
    this.attemptedCount = 0,
    this.validatedCount = 0,
    this.masteryState,
    this.locked = false,
  });

  final String skillId;
  final String skillCode;
  final String title;
  final SkillSection section;
  final LearningPlanSkillStatus status;
  final DateTime lastObservedAt;

  /// Même état agrégé que `SkillDto.masteryState` : un candidat ne doit pas
  /// lire deux états différents pour une même compétence.
  final SkillMasteryState? masteryState;

  /// Cf. [LearningPlanPriority.promptCount] — mêmes compteurs, même source.
  final int promptCount;
  final int attemptedCount;
  final int validatedCount;

  /// Cf. [LearningPlanPriority.locked]. La carte reste lisible : le candidat
  /// garde le résultat de ses propres productions, seul l'entraînement est
  /// verrouillé.
  final bool locked;

  factory LearningPlanSkill.fromJson(Map<String, dynamic> json) =>
      LearningPlanSkill(
        skillId: json['skillId'] as String,
        skillCode: json['skillCode'] as String? ?? '',
        title: json['title'] as String? ?? '',
        section: SkillSection.fromWire(json['section'] as String),
        status: LearningPlanSkillStatus.fromWire(
          json['status'] as String? ?? 'NOT_OBSERVED',
        ),
        lastObservedAt: _date(json['lastObservedAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        promptCount: (json['promptCount'] as num? ?? 0).toInt(),
        attemptedCount: (json['attemptedCount'] as num? ?? 0).toInt(),
        validatedCount: (json['validatedCount'] as num? ?? 0).toInt(),
        masteryState:
            SkillMasteryState.fromWireNullable(json['masteryState'] as String?),
        locked: json['locked'] as bool? ?? false,
      );
}

/// Ce que le Plan fait d'un domaine du TCF. Miroir de `PlanDomainPriority`.
///
/// 🛑 **L'ordre de déclaration est l'ordre d'URGENCE** — et le serveur trie
/// déjà `LearningPlan.domaines` avec : aucun front ne retrie.
///
/// [aEvaluer] n'est pas une faiblesse : un domaine jamais mesuré est
/// **inconnu**, jamais mauvais.
enum PlanDomainPriority {
  forte('FORTE', 'Priorité forte'),
  aTravailler('A_TRAVAILLER', 'À travailler'),
  entretien('ENTRETIEN', 'Entretien'),
  pasEncorePrioritaire('PAS_ENCORE_PRIORITAIRE', 'Pas encore prioritaire'),
  aEvaluer('A_EVALUER', 'À évaluer');

  const PlanDomainPriority(this.wire, this.label);

  final String wire;

  /// Libellé **gelé côté serveur** (`PlanDomainPriority.getLabel()`), recopié
  /// mot pour mot. Jamais une chaîne écrite dans un widget.
  final String label;

  static PlanDomainPriority? fromWireNullable(String? value) {
    if (value == null) return null;
    for (final priority in PlanDomainPriority.values) {
      if (priority.wire == value) return priority;
    }
    return null;
  }
}

/// La fenêtre **réellement appliquée** par le serveur à « ce qui a changé
/// récemment ». Miroir de `PlanRecentChangesWindow`.
///
/// L'écran affiche la période d'après le **serveur**, jamais d'après ce que le
/// client croit avoir demandé.
enum PlanRecentChangesWindow {
  cetteSemaine('CETTE_SEMAINE', 'Cette semaine'),
  deuxSemaines('DEUX_SEMAINES', 'Ces deux dernières semaines'),
  ceMois('CE_MOIS', 'Ce mois-ci');

  const PlanRecentChangesWindow(this.wire, this.label);

  final String wire;

  /// Libellé **gelé côté serveur** (`PlanRecentChangesWindow.getLabel()`),
  /// recopié mot pour mot.
  final String label;

  static PlanRecentChangesWindow? fromWireNullable(String? value) {
    if (value == null) return null;
    for (final window in PlanRecentChangesWindow.values) {
      if (window.wire == value) return window;
    }
    return null;
  }
}

/// Où en est le **cycle de palier** en cours. Miroir de `PlanCycleState`.
///
/// Aucun libellé serveur : cet état pilote une mise en page, la phrase
/// appartient au front.
enum PlanCycleState {
  /// Le profil n'est pas complet : on mesure avant de construire.
  buildingBaseline('BUILDING_BASELINE'),

  /// Le cycle construit son palier.
  training('TRAINING'),

  /// Assez de compétences tiennent : un examen blanc peut trancher.
  readyForGateMock('READY_FOR_GATE_MOCK'),

  /// Le palier visé est atteint : on le stabilise.
  targetStabilization('TARGET_STABILIZATION');

  const PlanCycleState(this.wire);

  final String wire;

  static PlanCycleState? fromWireNullable(String? value) {
    if (value == null) return null;
    for (final state in PlanCycleState.values) {
      if (state.wire == value) return state;
    }
    return null;
  }
}

/// Nature d'une étape du chemin vers l'objectif. Miroir de `PlanPathStepKind`.
///
/// Aucun libellé serveur : « Construire votre B1 » appartient au front.
enum PlanPathStepKind {
  completeProfile('COMPLETE_PROFILE'),
  buildLevel('BUILD_LEVEL'),
  stabilize('STABILIZE');

  const PlanPathStepKind(this.wire);

  final String wire;

  static PlanPathStepKind? fromWireNullable(String? value) {
    if (value == null) return null;
    for (final kind in PlanPathStepKind.values) {
      if (kind.wire == value) return kind;
    }
    return null;
  }
}

/// Où en est une étape du chemin. Miroir de `PlanPathStepStatus`.
enum PlanPathStepStatus {
  done('DONE'),
  current('CURRENT'),
  upcoming('UPCOMING');

  const PlanPathStepStatus(this.wire);

  final String wire;

  static PlanPathStepStatus? fromWireNullable(String? value) {
    if (value == null) return null;
    for (final status in PlanPathStepStatus.values) {
      if (status.wire == value) return status;
    }
    return null;
  }
}

/// Le parcours **déjà existant** par lequel se mesure un domaine jamais évalué.
/// Miroir de `PlanDomainAssessmentKind`.
enum PlanDomainAssessmentKind {
  /// Le diagnostic initial (EE + EO). Ni slot, ni durée.
  diagnostic('DIAGNOSTIC'),

  /// Un examen blanc de module QCM : `moduleExamQuestionType` + `slotNumber`
  /// + `estimatedMinutes` sont alors renseignés.
  moduleMockExam('MODULE_MOCK_EXAM'),

  /// Une production EE/EO. Ni slot, ni durée d'épreuve.
  production('PRODUCTION');

  const PlanDomainAssessmentKind(this.wire);

  final String wire;

  static PlanDomainAssessmentKind? fromWireNullable(String? value) {
    if (value == null) return null;
    for (final kind in PlanDomainAssessmentKind.values) {
      if (kind.wire == value) return kind;
    }
    return null;
  }
}

/// Un des quatre domaines du TCF **vu par le Plan** : son niveau, ce que le
/// Plan en fait, et de quoi ouvrir sa fiche. Miroir de `PlanDomainDto`.
///
/// ⚠️ À ne pas confondre avec `TcfDomain` (dashboard) : celui-là répond à
/// « quel est mon niveau ? », celui-ci à « qu'est-ce que j'en fais
/// maintenant ? ». **Le niveau est le même**, calculé par la même autorité
/// serveur — aucun front n'en dérive un second.
///
/// **Les deux blocs de détail s'excluent** : compréhension ⇒ [paliers] +
/// [blockingLevel] ; expression ⇒ [taches]. Les deux listes sont **toujours
/// présentes**, jamais `null`.
class PlanDomain {
  const PlanDomain({
    required this.epreuve,
    required this.evaluated,
    required this.priority,
    this.niveau,
    this.consolidatedLevel,
    this.blockingLevel,
    this.paliers = const <PlanDomainLevel>[],
    this.taches = const <PlanDomainTask>[],
    this.skills = const <PlanDomainSkill>[],
    this.fragileSkillCount = 0,
    this.solidSkillCount = 0,
    this.notObservedSkillCount = 0,
  });

  /// `TCF_CO` | `TCF_CE` | `TCF_EO` | `TCF_EE`.
  final EpreuveType epreuve;

  /// `evaluated == false` ⇔ [niveau] `== null` : inconnu, **jamais mauvais**.
  final bool evaluated;
  final NiveauCecrl? niveau;

  /// Ce que le Plan décide d'en faire — dérivé serveur, jamais recalculé.
  final PlanDomainPriority priority;

  /// Compréhension : plus haut palier consolidé (prérequis compris), `null` si
  /// aucun ne l'est. Toujours `null` en expression.
  final TargetLevel? consolidatedLevel;

  /// Compréhension : **premier** palier non consolidé — celui qui bloque.
  /// `null` quand les trois le sont, et toujours `null` en expression.
  final TargetLevel? blockingLevel;

  /// Compréhension : A2, B1, B2 dans cet ordre. Vide en expression.
  final List<PlanDomainLevel> paliers;

  /// Expression : tâches 1, 2, 3 dans cet ordre. Vide en compréhension.
  final List<PlanDomainTask> taches;

  /// **Toutes** les compétences actives du domaine, dans l'ordre du serveur :
  /// les 24 des trois tâches en expression, les 3 paliers en compréhension.
  ///
  /// Contrairement à [paliers] / [taches], cette liste est **uniforme sur les
  /// quatre domaines** — c'est ce qui permet à l'écran « Mon diagnostic » de
  /// n'avoir qu'**une** façon de rendre une carte d'épreuve.
  ///
  /// 🛑 **L'ordre vient du serveur, on ne retrie jamais** : deux copies de la
  /// règle désigneraient deux ordres.
  final List<PlanDomainSkill> skills;

  /// Compétences observées `PRIORITY` ou `TO_REINFORCE`.
  final int fragileSkillCount;

  /// Compétences observées `SOLID`.
  final int solidSkillCount;

  /// Compétences **jamais observées** — ce n'est pas une faiblesse, c'est une
  /// absence de mesure.
  ///
  /// 🛑 Les trois compteurs sont **dérivés de [skills] côté serveur** et leur
  /// somme vaut toujours `skills.length` : c'est ce qui rend un « + N autres »
  /// vrai. Ne jamais les recompter ici.
  final int notObservedSkillCount;

  factory PlanDomain.fromJson(Map<String, dynamic> json) => PlanDomain(
        epreuve: EpreuveType.fromWire(json['epreuve'] as String),
        evaluated: json['evaluated'] as bool? ?? false,
        niveau: NiveauCecrl.fromWireNullable(json['niveau'] as String?),
        priority:
            PlanDomainPriority.fromWireNullable(json['priority'] as String?) ??
                PlanDomainPriority.aEvaluer,
        consolidatedLevel:
            TargetLevel.fromWireNullable(json['consolidatedLevel'] as String?),
        blockingLevel:
            TargetLevel.fromWireNullable(json['blockingLevel'] as String?),
        paliers: _objectList(json['paliers'])
            .map(PlanDomainLevel.fromJson)
            .toList(growable: false),
        taches: _objectList(json['taches'])
            .map(PlanDomainTask.fromJson)
            .toList(growable: false),
        // Un backend anterieur au champ ne le sert pas : liste vide et
        // compteurs a zero, jamais une exception.
        skills: _objectList(json['skills'])
            .map(PlanDomainSkill.fromJson)
            .toList(growable: false),
        fragileSkillCount: (json['fragileSkillCount'] as num? ?? 0).toInt(),
        solidSkillCount: (json['solidSkillCount'] as num? ?? 0).toInt(),
        notObservedSkillCount:
            (json['notObservedSkillCount'] as num? ?? 0).toInt(),
      );
}

/// Une compétence du référentiel d'une **épreuve**, vue depuis le Plan : où en
/// est le candidat dessus, et peut-il la travailler. Miroir de
/// `PlanDomainSkillDto`.
///
/// **Trois nullités, trois faits différents.**
/// - [status] vaut `notObserved` quand rien n'a jamais été observé — **jamais
///   `null`** : une compétence est toujours dans un des quatre états, et « non
///   observée » est un état, pas une absence de donnée ;
/// - [masteryState] et [observedAt] valent `null` dans ce même cas : *null =
///   inconnu, jamais mauvais* ;
/// - [nature] vaut `null` dès que le Plan ne demande **rien** dessus — le cas de
///   l'immense majorité des compétences. Une compétence `solid`, ou non
///   observée hors du palier que le cycle construit, **n'est pas une action** :
///   ne pas fabriquer une pastille pour remplir la colonne.
class PlanDomainSkill {
  const PlanDomainSkill({
    required this.skillId,
    required this.skillCode,
    required this.title,
    required this.status,
    required this.locked,
    this.section,
    this.taskCode,
    this.tacheNumero,
    this.targetLevel,
    this.masteryState,
    this.nature,
    this.observedAt,
  });

  final String skillId;

  /// `EE1-C3`, `CO-B1`…
  final String skillCode;
  final String title;

  /// C'est **lui** qui dit le domaine, jamais la tâche.
  final SkillSection? section;

  /// `EE1`..`EO3` ; `null` en compréhension, qui n'a aucune tâche.
  final String? taskCode;

  /// 1, 2 ou 3 ; `null` en compréhension.
  final int? tacheNumero;

  /// Le palier porté par le référentiel ; `null` s'il descend sous `A2`.
  final TargetLevel? targetLevel;

  /// Verdict de la **dernière production probante**, ou `notObserved`.
  final LearningPlanSkillStatus status;

  /// État **agrégé**, `null` sans observation.
  final SkillMasteryState? masteryState;

  /// L'**action** demandée par le Plan, ou `null` s'il n'en demande aucune.
  final PlanActionNature? nature;
  final DateTime? observedAt;

  /// Verrou freemium, décidé par le serveur (`SkillAccessService`).
  final bool locked;

  factory PlanDomainSkill.fromJson(Map<String, dynamic> json) =>
      PlanDomainSkill(
        skillId: json['skillId'] as String? ?? '',
        skillCode: json['skillCode'] as String? ?? '',
        title: json['title'] as String? ?? '',
        section: SkillSection.fromWireNullable(json['section'] as String?),
        taskCode: json['taskCode'] as String?,
        tacheNumero: (json['tacheNumero'] as num?)?.toInt(),
        targetLevel:
            TargetLevel.fromWireNullable(json['targetLevel'] as String?),
        status:
            LearningPlanSkillStatus.fromWireNullable(json['status'] as String?) ??
                LearningPlanSkillStatus.notObserved,
        masteryState:
            SkillMasteryState.fromWireNullable(json['masteryState'] as String?),
        nature: PlanActionNature.fromWireNullable(json['nature'] as String?),
        observedAt: DateTime.tryParse(json['observedAt'] as String? ?? ''),
        locked: json['locked'] as bool? ?? false,
      );
}

/// Un palier d'un domaine de **compréhension** (`CO-A2`, `CE-B1`…). Miroir de
/// `PlanDomainLevelDto`.
///
/// C'est un **état de maîtrise**, jamais un pourcentage : le score interne du
/// moteur n'est exposé à aucun front. `masteryState == null` veut dire « jamais
/// observé » — on n'invente pas un état pour un palier que personne n'a mesuré.
class PlanDomainLevel {
  const PlanDomainLevel({
    required this.niveau,
    required this.skillId,
    required this.skillCode,
    required this.blocking,
    this.masteryState,
  });

  /// `A2` | `B1` | `B2`.
  final TargetLevel niveau;

  /// La compétence du palier — c'est **elle** qu'ouvre la série ciblée.
  final String skillId;
  final String skillCode;
  final SkillMasteryState? masteryState;

  /// Ce palier est le **premier** non consolidé du domaine : c'est lui qui
  /// empêche de compter les paliers supérieurs. Règle serveur, jamais recopiée.
  final bool blocking;

  factory PlanDomainLevel.fromJson(Map<String, dynamic> json) =>
      PlanDomainLevel(
        niveau: TargetLevel.fromWireNullable(json['niveau'] as String?) ??
            TargetLevel.a2,
        skillId: json['skillId'] as String,
        skillCode: json['skillCode'] as String? ?? '',
        masteryState:
            SkillMasteryState.fromWireNullable(json['masteryState'] as String?),
        blocking: json['blocking'] as bool? ?? false,
      );
}

/// Une tâche d'un domaine d'**expression** (EE1..EO3) vue depuis le Plan.
/// Miroir de `PlanDomainTaskDto`.
///
/// « 3 / 8 observées » **n'est pas une note** : une compétence non observée
/// n'est pas une compétence ratée, c'est une compétence que le candidat n'a pas
/// encore eu l'occasion de montrer. Le dénominateur est **lu en base**, jamais
/// la constante 8.
class PlanDomainTask {
  const PlanDomainTask({
    required this.taskCode,
    required this.tacheNumero,
    required this.observedSkills,
    required this.totalSkills,
  });

  /// `EE1`..`EO3`.
  final String taskCode;

  /// 1, 2 ou 3 — ce que les écrans de production attendent.
  final int tacheNumero;
  final int observedSkills;
  final int totalSkills;

  factory PlanDomainTask.fromJson(Map<String, dynamic> json) => PlanDomainTask(
        taskCode: json['taskCode'] as String? ?? '',
        tacheNumero: (json['tacheNumero'] as num? ?? 0).toInt(),
        observedSkills: (json['observedSkills'] as num? ?? 0).toInt(),
        totalSkills: (json['totalSkills'] as num? ?? 0).toInt(),
      );
}

/// Le **cycle de palier** en cours : d'où part le candidat, quel palier le Plan
/// construit maintenant, quel est son objectif, et où il en est sur le chemin.
/// Miroir de `PlanCycleDto`.
///
/// ⚠️ [targetLevel] est le cran **au-dessus** de [startingLevel], jamais
/// l'objectif directement : un A2 qui vise le B2 travaille d'abord le B1.
///
/// 🛑 [objectiveLevel] n'est pas « B2 » en dur — c'est le plancher de la
/// démarche (CSP→A2, CR→B1, NAT→B2), calculé serveur. `null` quand le candidat
/// n'a déclaré ni démarche ni palier : on ne devine jamais à sa place.
class PlanCycle {
  const PlanCycle({
    required this.targetLevel,
    required this.state,
    required this.domainsEvaluated,
    required this.domainsExpected,
    required this.profileComplete,
    this.startingLevel,
    this.objectiveLevel,
    this.path = const <PlanPathStep>[],
  });

  /// Niveau global mesuré d'où part le cycle. `null` tant que rien n'est
  /// mesuré. Exprimé en [NiveauCecrl] parce qu'il peut valoir `A1` ou moins,
  /// ce que [TargetLevel] ne sait pas dire.
  final NiveauCecrl? startingLevel;

  /// Le palier que ce cycle construit, dans `A2..B2`.
  final TargetLevel targetLevel;

  /// Le palier visé par le candidat. `null` si inconnu.
  final TargetLevel? objectiveLevel;

  final PlanCycleState state;

  /// Domaines réellement mesurés (0..4) sur [domainsExpected] (4, toujours).
  final int domainsEvaluated;
  final int domainsExpected;
  final bool profileComplete;

  /// Le chemin, de la première étape à la dernière. Jamais `null` ; une seule
  /// étape y est [PlanPathStepStatus.current].
  final List<PlanPathStep> path;

  factory PlanCycle.fromJson(Map<String, dynamic> json) => PlanCycle(
        startingLevel:
            NiveauCecrl.fromWireNullable(json['startingLevel'] as String?),
        targetLevel:
            TargetLevel.fromWireNullable(json['targetLevel'] as String?) ??
                TargetLevel.a2,
        objectiveLevel:
            TargetLevel.fromWireNullable(json['objectiveLevel'] as String?),
        state: PlanCycleState.fromWireNullable(json['state'] as String?) ??
            PlanCycleState.buildingBaseline,
        domainsEvaluated: (json['domainsEvaluated'] as num? ?? 0).toInt(),
        domainsExpected: (json['domainsExpected'] as num? ?? 0).toInt(),
        profileComplete: json['profileComplete'] as bool? ?? false,
        path: _objectList(json['path'])
            .map(PlanPathStep.fromJson)
            .toList(growable: false),
      );

  static PlanCycle? fromJsonOrNull(Object? value) =>
      value is Map<String, dynamic> ? PlanCycle.fromJson(value) : null;
}

/// Une étape du chemin vers l'objectif. Miroir de `PlanPathStepDto`.
///
/// Le serveur dit **quoi** et **où en est le candidat** ; le titre
/// (« Construire votre B1 ») appartient au front.
class PlanPathStep {
  const PlanPathStep({
    required this.kind,
    required this.status,
    this.level,
  });

  final PlanPathStepKind kind;

  /// Palier concerné — renseigné **uniquement** sur
  /// [PlanPathStepKind.buildLevel], `null` ailleurs.
  final TargetLevel? level;

  final PlanPathStepStatus status;

  factory PlanPathStep.fromJson(Map<String, dynamic> json) => PlanPathStep(
        kind: PlanPathStepKind.fromWireNullable(json['kind'] as String?) ??
            PlanPathStepKind.buildLevel,
        level: TargetLevel.fromWireNullable(json['level'] as String?),
        status:
            PlanPathStepStatus.fromWireNullable(json['status'] as String?) ??
                PlanPathStepStatus.upcoming,
      );
}

/// Ce qu'il faut lancer pour mesurer un domaine du TCF qui ne l'a **jamais**
/// été. Miroir de `PlanDomainAssessmentDto`.
///
/// **Des faits, jamais une phrase** : le serveur dit quelle épreuve et quoi
/// démarrer, le titre appartient au front.
///
/// 🛑 C'est **ce bloc** qui dit par quoi mesurer un domaine manquant — jamais
/// une série ciblée, qui est un `TRAINING` et ne rend aucun domaine « évalué ».
class PlanDomainAssessment {
  const PlanDomainAssessment({
    required this.epreuve,
    required this.kind,
    this.moduleExamQuestionType,
    this.slotNumber,
    this.estimatedMinutes,
  });

  /// Le domaine mesuré : `TCF_CO`, `TCF_CE`, `TCF_EO` ou `TCF_EE`.
  final EpreuveType epreuve;

  /// Le parcours **existant** à ouvrir.
  final PlanDomainAssessmentKind kind;

  /// Ce que `StartAttemptRequest` attend pour composer l'examen d'épreuve :
  /// `CO` ou `CE`, jamais `CO_IMAGE`. Renseigné sur
  /// [PlanDomainAssessmentKind.moduleMockExam] seulement.
  final QuestionType? moduleExamQuestionType;

  /// Slot de la grille d'examens blancs à démarrer — examen de module
  /// seulement.
  final int? slotNumber;

  /// Durée de l'épreuve, **lue serveur** chez `DureeEpreuve`. `null` quand la
  /// durée n'est pas une donnée d'examen (diagnostic, production).
  final int? estimatedMinutes;

  factory PlanDomainAssessment.fromJson(Map<String, dynamic> json) =>
      PlanDomainAssessment(
        epreuve: EpreuveType.fromWire(json['epreuve'] as String),
        kind: PlanDomainAssessmentKind.fromWireNullable(
              json['kind'] as String?,
            ) ??
            PlanDomainAssessmentKind.diagnostic,
        moduleExamQuestionType: _questionType(json['moduleExamQuestionType']),
        slotNumber: (json['slotNumber'] as num?)?.toInt(),
        estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt(),
      );
}

/// **La séance du jour** : ce que le candidat fait maintenant, et rien de plus.
/// Miroir de `PlanSeanceDto`.
///
/// C'est une **vue** du Plan, pas une seconde source de vérité : chaque item
/// reprend un exercice déjà désigné par le serveur.
///
/// 🛑 **Aucune date n'intervient nulle part** : « aujourd'hui » est une
/// présentation, la progression dépend des actions du candidat. Ne jamais
/// filtrer, retrier ni périmer la séance sur l'horloge.
class PlanSeance {
  const PlanSeance({
    required this.items,
    required this.estimatedMinutes,
  });

  /// Dans l'**ordre d'exécution** décidé par le serveur. Jamais `null`, vide
  /// quand le Plan n'a rien à proposer — cas normal.
  final List<PlanSeanceItem> items;

  /// Somme **recalculée serveur** des durées des items ; `0` sur une séance
  /// vide.
  final int estimatedMinutes;

  bool get isEmpty => items.isEmpty;

  factory PlanSeance.fromJson(Map<String, dynamic> json) => PlanSeance(
        items: _objectList(json['items'])
            .map(PlanSeanceItem.fromJsonOrNull)
            .whereType<PlanSeanceItem>()
            .toList(growable: false),
        estimatedMinutes: (json['estimatedMinutes'] as num? ?? 0).toInt(),
      );

  static PlanSeance fromJsonOrEmpty(Object? value) =>
      value is Map<String, dynamic>
          ? PlanSeance.fromJson(value)
          : const PlanSeance(items: <PlanSeanceItem>[], estimatedMinutes: 0);
}

/// Un **entraînement** de la séance : l'action à faire, et les faits qui
/// expliquent pourquoi elle est là. Miroir de `PlanSeanceItemDto`.
///
/// 🛑 **Aucune phrase ne vient du serveur.** Il expose des faits — avancement
/// de l'étape, attente d'une vérification, palier travaillé, état de maîtrise —
/// et c'est le front qui compose « Pourquoi cette séance ? ».
///
/// **Une seule action par item** : soit un [exercise] (ou son [milestone]),
/// soit un [assessment], jamais les deux. Un item [PlanActionNature.aEvaluer]
/// est le seul à porter le second — c'est ce qui permet à la séance de
/// commencer par « votre oral n'a pas pu être analysé, refaites-en un » au lieu
/// d'empiler des micro-exercices sur le domaine qu'on sait déjà mesurer.
///
/// **Le bloc compétence est vide sur un jalon comme sur une mesure** : un
/// examen blanc ne travaille pas une compétence, il les vérifie toutes ; une
/// mesure porte sur une **épreuve entière**. On lit [nature], jamais la nullité
/// d'un champ.
class PlanSeanceItem {
  const PlanSeanceItem({
    required this.nature,
    required this.stepPromptCount,
    required this.stepAttemptedCount,
    required this.stepValidatedCount,
    required this.stepCompleted,
    required this.readyForReassessment,
    required this.locked,
    this.kind,
    this.exercise,
    this.milestone,
    this.assessment,
    this.lastActivityAt,
    this.skillId,
    this.skillCode,
    this.title,
    this.section,
    this.level,
    this.masteryState,
  });

  /// **Ce que le Plan demande de faire ici.** C'est ce champ qu'on lit pour
  /// qualifier la ligne et pour composer le « pourquoi » — jamais la nullité
  /// d'un autre.
  final PlanActionNature nature;

  /// La nature de l'**exercice**, quand il y en a un. `null` sur une mesure de
  /// domaine ([PlanActionNature.aEvaluer]), qui n'est pas un entraînement.
  final PlanExerciseKind? kind;

  /// L'action quand ce n'en est **pas** un jalon (micro-exercice, vérification
  /// en situation, série ciblée). `null` sur un jalon et sur une mesure.
  final PlanRecommendedExercise? exercise;

  /// La **mesure** à lancer, renseignée sur le seul
  /// [PlanActionNature.aEvaluer] : le candidat a rendu une production sur ce
  /// domaine et le correcteur n'a rien pu y observer. On ne lui propose pas un
  /// exercice de plus, on va le mesurer.
  ///
  /// Exclusif de [exercise] et de [milestone].
  final PlanDomainAssessment? assessment;

  /// L'action quand c'en **est** un jalon (examen blanc d'épreuve ou complet).
  /// `null` sinon. Deux classes plutôt qu'une parce qu'un jalon ne porte ni
  /// titre ni compétence — cf. [PlanMilestone].
  final PlanMilestone? milestone;

  /// Bloc compétence — `null` sur un jalon.
  final String? skillId;
  final String? skillCode;
  final String? title;
  final SkillSection? section;

  /// Palier travaillé (`"A1"`..`"B2"`), renseigné en **compréhension** ; `null`
  /// en expression et sur un jalon. Chaîne et non [TargetLevel] : le
  /// référentiel des compétences descend jusqu'à `A1`.
  final String? level;

  /// État agrégé de la compétence. `null` sur un jalon comme sur une
  /// compétence jamais observée.
  final SkillMasteryState? masteryState;

  /// Avancement de l'étape (« 3 sujets sur 5 »). [stepPromptCount] vaut `0` en
  /// compréhension, qui n'a pas d'étape à cinq sujets.
  final int stepPromptCount;
  final int stepAttemptedCount;
  final int stepValidatedCount;
  final bool stepCompleted;

  /// Le moteur juge la compétence prête à être vérifiée **et** l'étape est
  /// terminée.
  final bool readyForReassessment;

  /// Ce candidat ne peut pas lancer cette action. Elle reste **désignée et
  /// visible** : savoir quoi travailler est ce que le Plan apporte.
  final bool locked;

  /// **Date de la dernière activité sur cette compétence.** `null` quand elle
  /// n'a jamais été observée, et sur un jalon.
  ///
  /// C'est un **fait**, pas un verdict : le serveur ne dit jamais « fait
  /// aujourd'hui » — il n'a pas d'horloge dans la construction de la séance.
  /// C'est le front qui compare cette date à sa journée courante
  /// (**Europe/Paris**, `planSeanceItemDone`). La coche vit donc dans le
  /// compte : elle survit au redémarrage de l'app, et elle est la même sur le
  /// web.
  ///
  /// ⚠ Lue sur **toutes** les observations, `NOT_OBSERVED` comprise — le
  /// correcteur n'a rien pu observer, mais le candidat a bien travaillé.
  final DateTime? lastActivityAt;

  /// `null` quand l'item ne porte **aucune** action — ni exercice, ni mesure.
  /// Une ligne sans rien à faire n'est pas un entraînement : on l'écarte.
  static PlanSeanceItem? fromJsonOrNull(Map<String, dynamic> json) {
    final raw = json['exercise'];
    final rawAssessment = json['assessment'];
    final exercise = raw is Map<String, dynamic> ? raw : null;
    final assessment = rawAssessment is Map<String, dynamic>
        ? PlanDomainAssessment.fromJson(rawAssessment)
        : null;
    if (exercise == null && assessment == null) return null;
    final kind = exercise == null
        ? null
        : PlanExerciseKind.fromWire(exercise['kind'] as String?);
    return PlanSeanceItem(
      // Une mesure de domaine sur un serveur qui ne nommerait pas encore la
      // nature reste une mesure : c'est le champ `assessment` qui la porte.
      nature: PlanActionNature.fromWireNullable(json['nature'] as String?) ??
          (assessment != null
              ? PlanActionNature.aEvaluer
              : PlanActionNature.aRenforcer),
      kind: kind,
      exercise: exercise == null || kind == null || kind.isMilestone
          ? null
          : PlanRecommendedExercise.fromJson(exercise),
      milestone: exercise == null || kind == null || !kind.isMilestone
          ? null
          : PlanMilestone.fromJsonOrNull(exercise),
      assessment: assessment,
      skillId: json['skillId'] as String?,
      skillCode: json['skillCode'] as String?,
      title: json['title'] as String?,
      section: SkillSection.fromWireNullable(json['section'] as String?),
      level: _trimmedOrNull(json['level']),
      masteryState:
          SkillMasteryState.fromWireNullable(json['masteryState'] as String?),
      stepPromptCount: (json['stepPromptCount'] as num? ?? 0).toInt(),
      stepAttemptedCount: (json['stepAttemptedCount'] as num? ?? 0).toInt(),
      stepValidatedCount: (json['stepValidatedCount'] as num? ?? 0).toInt(),
      stepCompleted: json['stepCompleted'] as bool? ?? false,
      readyForReassessment: json['readyForReassessment'] as bool? ?? false,
      locked: json['locked'] as bool? ?? false,
      lastActivityAt: _date(json['lastActivityAt']),
    );
  }
}

/// **Ce qui a changé récemment** dans le Plan. Miroir de
/// `PlanRecentChangesDto`.
///
/// 🛑 **Son absence est le cas NORMAL** : quand rien n'a bougé le bloc vaut
/// `null` et l'écran n'affiche **rien**. Aucune ligne n'est jamais fabriquée
/// pour remplir.
///
/// ⚠️ À ne pas confondre avec `PlanChange` (`production_models.dart`), qui
/// répond à « qu'a changé **cette soumission** ? » sur le détail d'une
/// production. Ici c'est l'**état agrégé** d'une compétence qui bouge, là c'est
/// le verdict d'une observation.
class PlanRecentChanges {
  const PlanRecentChanges({
    required this.window,
    required this.transitions,
    this.since,
    this.newPriority,
  });

  /// La fenêtre **réellement appliquée**, choisie par le serveur.
  final PlanRecentChangesWindow window;

  /// Borne basse de cette fenêtre.
  final DateTime? since;

  /// De la plus récente à la plus ancienne, déjà bornée serveur. Jamais
  /// `null` ; éventuellement vide quand seule une nouvelle priorité a été
  /// désignée.
  final List<PlanMasteryTransition> transitions;

  /// La compétence devenue priorité n°1 **dans cette fenêtre**, ou `null` —
  /// cas fréquent, l'étape n°1 ne change pas à chaque production.
  final PlanSkillRef? newPriority;

  bool get isEmpty => transitions.isEmpty && newPriority == null;

  static PlanRecentChanges? fromJsonOrNull(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final window =
        PlanRecentChangesWindow.fromWireNullable(value['window'] as String?);
    if (window == null) return null;
    final newPriority = value['newPriority'];
    return PlanRecentChanges(
      window: window,
      since: _date(value['since']),
      transitions: _objectList(value['transitions'])
          .map(PlanMasteryTransition.fromJson)
          .toList(growable: false),
      newPriority: newPriority is Map<String, dynamic>
          ? PlanSkillRef.fromJson(newPriority)
          : null,
    );
  }
}

/// Une transition d'état de maîtrise **réellement mesurée**. Miroir de
/// `PlanMasteryTransitionDto`.
class PlanMasteryTransition {
  const PlanMasteryTransition({
    required this.skillId,
    required this.skillCode,
    required this.title,
    required this.section,
    required this.after,
    required this.progress,
    this.before,
    this.observedAt,
  });

  final String skillId;
  final String skillCode;
  final String title;
  final SkillSection section;

  /// L'état d'avant. `null` quand la compétence n'avait jamais été observée.
  final SkillMasteryState? before;
  final SkillMasteryState after;

  /// La transition va dans le bon sens. **Dérivé serveur** : ne pas comparer
  /// deux états à la main, l'ordre des paliers n'appartient pas au front.
  final bool progress;

  final DateTime? observedAt;

  factory PlanMasteryTransition.fromJson(Map<String, dynamic> json) =>
      PlanMasteryTransition(
        skillId: json['skillId'] as String,
        skillCode: json['skillCode'] as String? ?? '',
        title: json['title'] as String? ?? '',
        section: SkillSection.fromWire(json['section'] as String),
        before: SkillMasteryState.fromWireNullable(json['before'] as String?),
        after: SkillMasteryState.fromWireNullable(json['after'] as String?) ??
            SkillMasteryState.toReinforce,
        progress: json['progress'] as bool? ?? false,
        observedAt: _date(json['observedAt']),
      );
}

class LearningPlan {
  const LearningPlan({
    required this.state,
    required this.nextPriorities,
    required this.observedSkills,
    required this.observedSkillCount,
    required this.activitiesThisWeek,
    required this.progressionAvailable,
    this.completedSteps = const <LearningPlanCompletedStep>[],
    this.diagnosticSessionId,
    this.diagnosticCompletedAt,
    this.currentPriority,
    this.milestone,
    this.domaines = const <PlanDomain>[],
    this.cycle,
    this.domainesAEvaluer = const <PlanDomainAssessment>[],
    this.seance = const PlanSeance(items: <PlanSeanceItem>[], estimatedMinutes: 0),
    this.recentChanges,
  });

  final LearningPlanState state;
  final String? diagnosticSessionId;
  final DateTime? diagnosticCompletedAt;

  /// Les étapes **déjà franchies**, de la plus ancienne à la plus récente :
  /// elles se lisent **avant** [currentPriority] et [nextPriorities], dans le
  /// même parcours numéroté.
  ///
  /// **Jamais `null`** ; **vide** tant qu'aucune compétence n'a prouvé son
  /// transfert — cas normal, y compris avant le diagnostic. Déjà **bornée par
  /// le serveur** aux plus récentes : ne rien reborner ici.
  final List<LearningPlanCompletedStep> completedSteps;

  final LearningPlanPriority? currentPriority;
  final List<LearningPlanPriority> nextPriorities;
  final List<LearningPlanSkill> observedSkills;
  final int observedSkillCount;
  final int activitiesThisWeek;
  final bool progressionAvailable;

  /// Le **jalon** du parcours, un cran au-dessus des étapes : un examen blanc
  /// d'épreuve puis l'examen blanc TCF complet. Il vit **à côté** des priorités,
  /// il ne les remplace pas — chaque étape garde son `recommendedExercise`.
  ///
  /// **`null` est le cas NORMAL** (comme `PlanChange`) : tant qu'une épreuve n'a
  /// pas majoritairement transféré il n'y a rien à mesurer, et juste après un
  /// examen blanc il n'y a rien à re-mesurer. Rien ne s'affiche alors, ni
  /// indicateur, ni message d'erreur.
  final PlanMilestone? milestone;

  /// Les **quatre domaines** du TCF vus par le Plan — jamais `null`.
  ///
  /// 🛑 **Le serveur les trie déjà par urgence. Aucun front ne retrie.**
  final List<PlanDomain> domaines;

  /// Le cycle de palier en cours. `null` seulement face à un backend antérieur
  /// au champ.
  final PlanCycle? cycle;

  /// Par quoi mesurer les domaines **jamais évalués** — jamais `null`, vide
  /// quand le profil est complet.
  ///
  /// 🛑 C'est **la seule** réponse à « comment compléter mon profil ». Une
  /// série ciblée ([PlanExerciseKind.targetedQcmSeries]) est un `TRAINING` :
  /// elle **ne rend jamais un domaine « évalué »**, seul un examen blanc de
  /// module le fait.
  final List<PlanDomainAssessment> domainesAEvaluer;

  /// La séance du jour — jamais `null`, éventuellement vide.
  final PlanSeance seance;

  /// Ce qui a bougé récemment. **`null` est le cas NORMAL** (rien n'a bougé) :
  /// on n'affiche alors rien, ni indicateur, ni message.
  final PlanRecentChanges? recentChanges;

  factory LearningPlan.fromJson(Map<String, dynamic> json) => LearningPlan(
        state: LearningPlanState.fromWire(
          json['state'] as String? ?? 'NEEDS_DIAGNOSTIC',
        ),
        diagnosticSessionId: json['diagnosticSessionId'] as String?,
        diagnosticCompletedAt: _date(json['diagnosticCompletedAt']),
        completedSteps: _objectList(json['completedSteps'])
            .map(LearningPlanCompletedStep.fromJson)
            .toList(growable: false),
        currentPriority: json['currentPriority'] == null
            ? null
            : LearningPlanPriority.fromJson(
                json['currentPriority'] as Map<String, dynamic>,
              ),
        nextPriorities: _objectList(json['nextPriorities'])
            .map(LearningPlanPriority.fromJson)
            .toList(growable: false),
        observedSkills: _objectList(json['observedSkills'])
            .map(LearningPlanSkill.fromJson)
            .toList(growable: false),
        observedSkillCount: (json['observedSkillCount'] as num? ?? 0).toInt(),
        activitiesThisWeek: (json['activitiesThisWeek'] as num? ?? 0).toInt(),
        progressionAvailable: json['progressionAvailable'] as bool? ?? false,
        milestone: PlanMilestone.fromJsonOrNull(json['milestone']),
        domaines: _objectList(json['domaines'])
            .map(PlanDomain.fromJson)
            .toList(growable: false),
        cycle: PlanCycle.fromJsonOrNull(json['cycle']),
        domainesAEvaluer: _objectList(json['domainesAEvaluer'])
            .map(PlanDomainAssessment.fromJson)
            .toList(growable: false),
        seance: PlanSeance.fromJsonOrEmpty(json['seance']),
        recentChanges: PlanRecentChanges.fromJsonOrNull(json['recentChanges']),
      );
}

/// Un compteur servi par le serveur. Absent ou aberrant ⇒ `0`, c'est-à-dire
/// « rien à annoncer » : un front n'invente jamais un reste à vendre.
int _count(Object? raw) {
  if (raw is int) return raw < 0 ? 0 : raw;
  if (raw is num) return raw < 0 ? 0 : raw.toInt();
  return 0;
}

String? _trimmedOrNull(Object? raw) {
  if (raw is! String) return null;
  final value = raw.trim();
  return value.isEmpty ? null : value;
}

/// Type de question tolérant : une valeur inconnue vaut `null` plutôt qu'une
/// exception — un paramètre de démarrage absent vaut mieux qu'un Plan illisible.
QuestionType? _questionType(Object? raw) {
  if (raw is! String) return null;
  for (final type in QuestionType.values) {
    if (type.wire == raw) return type;
  }
  return null;
}

DateTime? _date(Object? raw) => raw is String ? DateTime.tryParse(raw) : null;

/// Palier CECRL tolérant : une valeur inconnue vaut `null`, jamais une
/// exception — un champ d'affichage ne doit pas faire échouer la lecture d'un
/// résultat entier.
NiveauCecrl? _niveau(Object? raw) {
  if (raw is! String) return null;
  for (final niveau in NiveauCecrl.values) {
    if (niveau.wire == raw) return niveau;
  }
  return null;
}

List<String> _stringList(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<String>()
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}

List<Map<String, dynamic>> _objectList(Object? raw) {
  if (raw is! List) return const [];
  return raw.whereType<Map<String, dynamic>>().toList(growable: false);
}
