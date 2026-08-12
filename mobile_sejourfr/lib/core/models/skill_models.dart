/// Miroirs Dart des DTOs du module « Compétences TCF » (backend
/// `SkillController` / `SkillAttemptController`).
///
/// Sérialisation **manuelle**, comme partout dans `core/models/` : casts
/// explicites, aucun codegen.
///
/// ⚠ L'enum `Difficulty` de `enums.dart` porte les paliers CSP/CR/NAT/A2/B1/B2
/// (le « niveau » côté produit) et n'a rien à voir avec le `Difficulty`
/// EASY/MEDIUM/HARD du backend. Le second vit donc ici sous le nom
/// [SkillDifficulty] pour que les deux ne se confondent jamais.
library;

import 'action_plan.dart';
import 'diagnostic_models.dart';
import 'enums.dart';

/// Épreuve productive d'une compétence. Miroir de `SkillSection` (backend).
enum SkillSection {
  ee('EE'),
  eo('EO');

  const SkillSection(this.wire);

  final String wire;

  static SkillSection fromWire(String value) =>
      SkillSection.values.firstWhere((e) => e.wire == value);

  bool get isEo => this == SkillSection.eo;

  /// `EE1`, `EO3`… le code de tâche attendu par `GET /api/skills`.
  String taskCode(int tacheNumero) => '$wire$tacheNumero';
}

/// Palier de difficulté d'un petit sujet (backend `Difficulty`).
enum SkillDifficulty {
  easy('EASY', 'Accessible'),
  medium('MEDIUM', 'Intermédiaire'),
  hard('HARD', 'Exigeant');

  const SkillDifficulty(this.wire, this.label);

  final String wire;
  final String label;

  static SkillDifficulty fromWire(String value) =>
      SkillDifficulty.values.firstWhere(
        (e) => e.wire == value,
        orElse: () => SkillDifficulty.medium,
      );
}

/// Les trois références comparatives d'un petit sujet.
enum SkillReferenceLevel {
  insufficient('INSUFFICIENT', 'Insuffisant'),
  expected('EXPECTED', 'Attendu'),
  excellent('EXCELLENT', 'Très réussi');

  const SkillReferenceLevel(this.wire, this.label);

  final String wire;
  final String label;

  static SkillReferenceLevel fromWire(String value) =>
      SkillReferenceLevel.values.firstWhere((e) => e.wire == value);
}

/// Auto-évaluation déclarative du candidat. **N'influence jamais** le verdict
/// de l'IA — c'est un miroir, pas une note.
enum SkillSelfEvaluation {
  reussi('REUSSI', 'Je pense avoir réussi'),
  incertain('INCERTAIN', 'Je ne suis pas sûr'),
  difficile('DIFFICILE', "J'ai eu du mal");

  const SkillSelfEvaluation(this.wire, this.label);

  final String wire;
  final String label;

  static SkillSelfEvaluation fromWire(String value) =>
      SkillSelfEvaluation.values.firstWhere((e) => e.wire == value);

  static SkillSelfEvaluation? fromWireNullable(String? value) =>
      value == null ? null : fromWire(value);
}

/// Verdict de l'IA sur le **critère unique** du sujet.
enum SkillCriterionStatus {
  validated('VALIDATED', 'Critère validé'),
  partial('PARTIAL', 'Critère partiellement atteint'),
  notValidated('NOT_VALIDATED', 'Critère non atteint');

  const SkillCriterionStatus(this.wire, this.label);

  final String wire;
  final String label;

  static SkillCriterionStatus fromWire(String value) =>
      SkillCriterionStatus.values.firstWhere((e) => e.wire == value);

  static SkillCriterionStatus? fromWireNullable(String? value) =>
      value == null ? null : fromWire(value);
}

/// Statut d'un petit sujet pour l'utilisateur courant. **Dérivé côté serveur**
/// (jamais persisté, jamais recalculé par un front).
enum SkillPromptStatus {
  todo('TODO', 'À faire'),
  treated('TREATED', 'Fait'),
  validated('VALIDATED', 'Validé'),
  toReinforce('TO_REINFORCE', 'À renforcer');

  const SkillPromptStatus(this.wire, this.label);

  final String wire;
  final String label;

  static SkillPromptStatus fromWire(String value) =>
      SkillPromptStatus.values.firstWhere(
        (e) => e.wire == value,
        orElse: () => SkillPromptStatus.todo,
      );

  /// Un sujet « traité » au sens de la progression : tout sauf `TODO`.
  bool get isTreated => this != SkillPromptStatus.todo;
}

/// Où en est le candidat sur UNE compétence, tout son historique confondu.
///
/// À ne pas confondre avec `LearningPlanSkillStatus`, verdict d'**une**
/// production : celui-ci est l'état **agrégé**, dérivé serveur à la lecture et
/// jamais recalculé ici. `null` quand aucune observation n'existe — on
/// n'invente pas un état pour une compétence que le serveur n'a jamais vue.
///
/// Libellés **gelés**, miroir mot pour mot de `SKILL_MASTERY_STATE_LABEL`
/// (`web_sejoufr/lib/types.ts`).
enum SkillMasteryState {
  priority('PRIORITY', 'Priorité'),
  toReinforce('TO_REINFORCE', 'À renforcer'),
  consolidating('CONSOLIDATING', 'En consolidation'),
  solid('SOLID', 'Solide');

  const SkillMasteryState(this.wire, this.label);

  final String wire;
  final String label;

  /// Valeur inconnue ⇒ `null` : mieux vaut retomber sur le compteur de sujets
  /// que d'afficher un état qu'on n'a pas compris.
  static SkillMasteryState? fromWireNullable(String? value) {
    if (value == null) return null;
    for (final state in SkillMasteryState.values) {
      if (state.wire == value) return state;
    }
    return null;
  }
}

/// Cycle de vie d'une tentative. `RECORDED` = production enregistrée sans
/// analyse IA (état **final**, pas une attente).
enum SkillAttemptStatut {
  recorded('RECORDED'),
  submitted('SUBMITTED'),
  transcribing('TRANSCRIBING'),
  evaluating('EVALUATING'),
  evaluated('EVALUATED'),
  failed('FAILED');

  const SkillAttemptStatut(this.wire);

  final String wire;

  static SkillAttemptStatut fromWire(String value) =>
      SkillAttemptStatut.values.firstWhere(
        (e) => e.wire == value,
        orElse: () => SkillAttemptStatut.recorded,
      );

  bool get isFinal =>
      this == SkillAttemptStatut.recorded ||
      this == SkillAttemptStatut.evaluated ||
      this == SkillAttemptStatut.failed;

  bool get isInProgress => !isFinal;
}

/// Icône d'une étiquette de contrainte d'un petit sujet. **Liste fermée**,
/// identique au backend, au web et à l'admin.
///
/// [unknown] n'est pas une valeur du contrat : c'est le repli d'un code non
/// prévu (contenu créé depuis la console d'administration). Il existe pour que
/// le `switch` de la table d'icônes reste exhaustif sans jamais planter.
enum SkillConstraintIcon {
  tone('TONE'),
  person('PERSON'),
  time('TIME'),
  place('PLACE'),
  number('NUMBER'),
  tense('TENSE'),
  structure('STRUCTURE'),
  example('EXAMPLE'),
  unknown('');

  const SkillConstraintIcon(this.wire);

  final String wire;

  static SkillConstraintIcon fromWire(String? value) =>
      SkillConstraintIcon.values.firstWhere(
        (e) => e.wire == value,
        orElse: () => SkillConstraintIcon.unknown,
      );
}

/// Une étiquette de contrainte : ce qu'il faut respecter *dans la manière*
/// d'écrire ou de parler (« Vouvoiement », « Ton poli », « Passé composé »).
///
/// ⚠ Ne porte **jamais** la longueur : la puce `≈ 15–35 mots` / `≈ 45 secondes`
/// est générée par le front depuis les bornes déjà en base.
class SkillConstraintTag {
  const SkillConstraintTag({required this.label, required this.icon});

  final String label;
  final SkillConstraintIcon icon;

  /// `null` quand l'entrée est inexploitable (pas un objet, libellé vide) :
  /// une étiquette sans texte ne doit jamais devenir une pilule vide.
  static SkillConstraintTag? fromJsonNullable(Object? json) {
    if (json is! Map) return null;
    final label = _trimmedOrNull(json['label']);
    if (label == null) return null;
    return SkillConstraintTag(
      label: label,
      icon: SkillConstraintIcon.fromWire(json['icon'] as String?),
    );
  }
}

/// `null` plutôt qu'une chaîne vide : les blocs de guidage se retirent de
/// l'écran au lieu d'afficher un cadre sans contenu.
String? _trimmedOrNull(Object? raw) {
  if (raw is! String) return null;
  final value = raw.trim();
  return value.isEmpty ? null : value;
}

/// Lectures **tolérantes** des deux enums de niveau : `fromWire` lève sur une
/// valeur inconnue, ce qu'on ne veut jamais sur un bloc best-effort — un palier
/// non reconnu doit faire disparaître la carte, pas planter l'écran.
NiveauCecrl? _niveauOrNull(Object? raw) {
  if (raw is! String) return null;
  for (final niveau in NiveauCecrl.values) {
    if (niveau.wire == raw) return niveau;
  }
  return null;
}

TargetLevel? _targetLevelOrNull(Object? raw) {
  if (raw is! String) return null;
  for (final level in TargetLevel.values) {
    if (level.wire == raw) return level;
  }
  return null;
}

List<String> _stringList(Object? raw) {
  if (raw is! List) return const <String>[];
  return raw
      .map(_trimmedOrNull)
      .whereType<String>()
      .toList(growable: false);
}

List<SkillConstraintTag> _constraintTags(Object? raw) {
  if (raw is! List) return const <SkillConstraintTag>[];
  return raw
      .map(SkillConstraintTag.fromJsonNullable)
      .whereType<SkillConstraintTag>()
      .toList(growable: false);
}

/// Une compétence (8 par tâche) + la progression du user courant.
class SkillDto {
  const SkillDto({
    required this.id,
    required this.section,
    required this.taskCode,
    required this.code,
    required this.title,
    required this.description,
    required this.generalCriterion,
    required this.targetLevel,
    required this.displayOrder,
    required this.promptCount,
    required this.attemptedCount,
    required this.validatedCount,
    required this.toReinforceCount,
    this.masteryState,
    this.locked = false,
  });

  final String id;
  final SkillSection section;
  final String taskCode;
  final String code;
  final String title;

  /// Courte explication de ce que la compétence apporte au TCF → encart
  /// « Pourquoi cet exercice ? ». **Distincte** de [generalCriterion].
  final String description;

  /// Le critère général travaillé par la compétence → encart « Critère
  /// travaillé ». À ne pas confondre avec `SkillPromptDto.uniqueCriterion`,
  /// qui est le critère précis d'UN petit sujet.
  final String generalCriterion;
  final String targetLevel;
  final int displayOrder;
  final int promptCount;
  final int attemptedCount;
  final int validatedCount;
  final int toReinforceCount;

  /// Ce que la carte de compétence affiche **à la place** du compteur de sujets
  /// traités : un nombre dit ce que le candidat a fait, cet état dit ce qu'il
  /// maîtrise. Dérivé serveur, jamais persisté. `null` sans observation — le
  /// compteur reprend alors sa place.
  final SkillMasteryState? masteryState;

  /// Verrou freemium **calculé par le serveur** : ce candidat ne peut pas
  /// produire sur cette compétence. Aucun front ne recalcule la règle (quelle
  /// compétence est offerte, combien de sujets sont ouverts) — on reflète ce
  /// booléen, et un 403 reste l'arbitre final.
  final bool locked;

  /// Progression 0..1 sur les sujets **traités** (pas sur les sujets validés :
  /// la spec §12 demande de ne pas laisser croire qu'il faut tout valider).
  double get progress =>
      promptCount == 0 ? 0 : (attemptedCount / promptCount).clamp(0.0, 1.0);

  bool get isComplete => promptCount > 0 && attemptedCount >= promptCount;

  factory SkillDto.fromJson(Map<String, dynamic> json) => SkillDto(
        id: json['id'] as String,
        section: SkillSection.fromWire(json['section'] as String),
        taskCode: json['taskCode'] as String,
        code: json['code'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        generalCriterion: json['generalCriterion'] as String? ?? '',
        targetLevel: json['targetLevel'] as String,
        displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
        promptCount: (json['promptCount'] as num?)?.toInt() ?? 0,
        attemptedCount: (json['attemptedCount'] as num?)?.toInt() ?? 0,
        validatedCount: (json['validatedCount'] as num?)?.toInt() ?? 0,
        toReinforceCount: (json['toReinforceCount'] as num?)?.toInt() ?? 0,
        masteryState:
            SkillMasteryState.fromWireNullable(json['masteryState'] as String?),
        locked: json['locked'] as bool? ?? false,
      );
}

/// Un petit sujet dans la liste d'une compétence.
class SkillPromptSummary {
  const SkillPromptSummary({
    required this.id,
    required this.code,
    required this.title,
    required this.uniqueCriterion,
    required this.difficultyLevel,
    required this.displayOrder,
    required this.status,
    required this.attemptCount,
    this.recommendedMinWords,
    this.recommendedMaxWords,
    this.recommendedDurationSeconds,
    this.lastAttemptAt,
    this.locked = false,
  });

  final String id;
  final String code;
  final String title;
  final String uniqueCriterion;
  final SkillDifficulty difficultyLevel;
  final int displayOrder;
  final SkillPromptStatus status;
  final int attemptCount;
  final int? recommendedMinWords;
  final int? recommendedMaxWords;
  final int? recommendedDurationSeconds;
  final DateTime? lastAttemptAt;

  /// Cf. [SkillDto.locked] — verrou freemium servi par le serveur, jamais
  /// déduit du rang du sujet dans sa compétence.
  final bool locked;

  factory SkillPromptSummary.fromJson(Map<String, dynamic> json) =>
      SkillPromptSummary(
        id: json['id'] as String,
        code: json['code'] as String,
        title: json['title'] as String,
        uniqueCriterion: json['uniqueCriterion'] as String,
        difficultyLevel:
            SkillDifficulty.fromWire(json['difficultyLevel'] as String),
        displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
        status: SkillPromptStatus.fromWire(json['status'] as String),
        attemptCount: (json['attemptCount'] as num?)?.toInt() ?? 0,
        recommendedMinWords: (json['recommendedMinWords'] as num?)?.toInt(),
        recommendedMaxWords: (json['recommendedMaxWords'] as num?)?.toInt(),
        recommendedDurationSeconds:
            (json['recommendedDurationSeconds'] as num?)?.toInt(),
        lastAttemptAt: json['lastAttemptAt'] == null
            ? null
            : DateTime.tryParse(json['lastAttemptAt'] as String)?.toLocal(),
        locked: json['locked'] as bool? ?? false,
      );
}

/// Un point de la **frise** d'une compétence : ce qui a été constaté, quand, et
/// dans quoi.
///
/// [status] est le verdict de **cette production-là**, à ne pas confondre avec
/// l'état agrégé de la compétence ([SkillDto.masteryState]). [confidence] est la
/// certitude du correcteur : elle n'est **jamais** montrée au candidat, elle ne
/// dit rien de son niveau.
class SkillObservationPoint {
  const SkillObservationPoint({
    required this.observedAt,
    required this.source,
    required this.status,
    required this.confidence,
    required this.baseline,
    this.explanation,
  });

  final DateTime observedAt;
  final LearningPlanSourceType source;
  final LearningPlanSkillStatus status;

  /// L'explication courte du correcteur, telle qu'enregistrée.
  final String? explanation;
  final ObservationConfidence confidence;

  /// `true` pour les deux productions du diagnostic initial : le point de départ.
  final bool baseline;

  factory SkillObservationPoint.fromJson(Map<String, dynamic> json) =>
      SkillObservationPoint(
        observedAt:
            DateTime.tryParse(json['observedAt'] as String? ?? '')?.toLocal() ??
                DateTime.now(),
        source: LearningPlanSourceType.fromWire(json['source'] as String?),
        status: LearningPlanSkillStatus.fromWire(
          json['status'] as String? ?? 'NOT_OBSERVED',
        ),
        explanation: json['explanation'] as String?,
        confidence: ObservationConfidence.fromWire(
          json['confidence'] as String? ?? 'LOW',
        ),
        baseline: json['baseline'] as bool? ?? false,
      );
}

/// Détail d'une compétence : la compétence, ses 15 petits sujets et sa
/// **trajectoire**.
class SkillDetail {
  const SkillDetail({
    required this.skill,
    required this.prompts,
    this.trajectory = const [],
  });

  final SkillDto skill;
  final List<SkillPromptSummary> prompts;

  /// Les observations probantes de la compétence, **de la plus ancienne à la
  /// plus récente** — le sens dans lequel une frise se lit. Jamais nulle,
  /// souvent vide : l'écran n'affiche alors aucune section.
  final List<SkillObservationPoint> trajectory;

  /// Premier sujet jamais traité, sinon `null` (tout a été vu au moins une fois).
  SkillPromptSummary? get firstTodo {
    for (final p in prompts) {
      if (p.status == SkillPromptStatus.todo) return p;
    }
    return null;
  }

  factory SkillDetail.fromJson(Map<String, dynamic> json) => SkillDetail(
        skill: SkillDto.fromJson(json['skill'] as Map<String, dynamic>),
        prompts: ((json['prompts'] as List<dynamic>?) ?? const [])
            .map((e) => SkillPromptSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        trajectory: ((json['trajectory'] as List<dynamic>?) ?? const [])
            .map((e) =>
                SkillObservationPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Le sujet complet, pour l'écran de production. **Ne porte jamais les
/// références** (elles n'arrivent qu'après la production, cf. §13.2).
class SkillPromptDto {
  const SkillPromptDto({
    required this.id,
    required this.skillId,
    required this.skillCode,
    required this.skillTitle,
    required this.skillPromptCount,
    required this.skillDescription,
    required this.skillGeneralCriterion,
    required this.skillTargetLevel,
    required this.section,
    required this.taskCode,
    required this.taskTitle,
    required this.code,
    required this.title,
    required this.context,
    required this.instruction,
    required this.uniqueCriterion,
    required this.difficultyLevel,
    required this.displayOrder,
    required this.status,
    required this.attemptCount,
    this.checklist = const <String>[],
    this.constraintTags = const <SkillConstraintTag>[],
    this.answerStarter,
    this.tip,
    this.recommendedMinWords,
    this.recommendedMaxWords,
    this.recommendedDurationSeconds,
    this.lastAttemptAt,
    this.lastAttemptId,
    this.nextPromptId,
    this.locked = false,
  });

  final String id;
  final String skillId;
  final String skillCode;
  final String skillTitle;

  /// Nombre de petits sujets de la compétence : le dénominateur du fil
  /// d'Ariane « Sujet i/N », sans avoir à charger le détail de la compétence.
  final int skillPromptCount;

  /// `skill.description` reportée ici → encart « Pourquoi cet exercice ? ».
  final String skillDescription;

  /// `skill.generalCriterion` reporté ici. Le critère **général** de la
  /// compétence, à ne pas confondre avec [uniqueCriterion], celui de ce sujet.
  final String skillGeneralCriterion;

  /// Palier CECRL de la compétence (`A1`…`B2`), exigé sur l'écran d'un petit
  /// sujet (spec §3 niveau 5). Porté par le sujet pour que la suppression du
  /// second appel réseau ne coûte pas un affichage.
  final String skillTargetLevel;
  final SkillSection section;
  final String taskCode;
  final String taskTitle;
  final String code;
  final String title;
  final String context;
  final String instruction;
  final String uniqueCriterion;
  final SkillDifficulty difficultyLevel;
  final int displayOrder;
  final SkillPromptStatus status;
  final int attemptCount;

  /// Les 2 à 4 gestes à l'impératif de la carte « Ce qu'il faut faire ».
  /// **Vide** = sujet créé sans guidage : la carte retombe sur [instruction].
  final List<String> checklist;

  /// Les 1 à 3 étiquettes de contrainte. **Vide** = seule la puce de longueur
  /// s'affiche.
  final List<SkillConstraintTag> constraintTags;

  /// L'amorce grisée du champ (EE) ou la suggestion de démarrage (EO).
  /// `null` = texte grisé neutre.
  final String? answerStarter;

  /// L'astuce du pied de la carte de réponse. `null` = seul le compteur reste.
  /// Le mot « Astuce : » est ajouté par le front, jamais porté par la valeur.
  final String? tip;

  final int? recommendedMinWords;
  final int? recommendedMaxWords;
  final int? recommendedDurationSeconds;
  final DateTime? lastAttemptAt;
  final String? lastAttemptId;
  final String? nextPromptId;

  /// Cf. [SkillDto.locked]. Un lien profond sur un sujet verrouillé ouvre
  /// l'écran **sans zone de production** : le serveur refuserait la soumission
  /// de toute façon (403), autant ne pas laisser produire pour rien.
  final bool locked;

  factory SkillPromptDto.fromJson(Map<String, dynamic> json) => SkillPromptDto(
        id: json['id'] as String,
        skillId: json['skillId'] as String,
        skillCode: json['skillCode'] as String,
        skillTitle: json['skillTitle'] as String,
        skillPromptCount: (json['skillPromptCount'] as num?)?.toInt() ?? 0,
        skillDescription: json['skillDescription'] as String? ?? '',
        skillGeneralCriterion: json['skillGeneralCriterion'] as String? ?? '',
        skillTargetLevel: json['skillTargetLevel'] as String? ?? '',
        section: SkillSection.fromWire(json['section'] as String),
        taskCode: json['taskCode'] as String,
        taskTitle: json['taskTitle'] as String,
        code: json['code'] as String,
        title: json['title'] as String,
        context: json['context'] as String,
        instruction: json['instruction'] as String,
        uniqueCriterion: json['uniqueCriterion'] as String,
        difficultyLevel:
            SkillDifficulty.fromWire(json['difficultyLevel'] as String),
        displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
        status: SkillPromptStatus.fromWire(json['status'] as String),
        attemptCount: (json['attemptCount'] as num?)?.toInt() ?? 0,
        checklist: _stringList(json['checklist']),
        constraintTags: _constraintTags(json['constraintTags']),
        answerStarter: _trimmedOrNull(json['answerStarter']),
        tip: _trimmedOrNull(json['tip']),
        recommendedMinWords: (json['recommendedMinWords'] as num?)?.toInt(),
        recommendedMaxWords: (json['recommendedMaxWords'] as num?)?.toInt(),
        recommendedDurationSeconds:
            (json['recommendedDurationSeconds'] as num?)?.toInt(),
        lastAttemptAt: json['lastAttemptAt'] == null
            ? null
            : DateTime.tryParse(json['lastAttemptAt'] as String)?.toLocal(),
        lastAttemptId: json['lastAttemptId'] as String?,
        nextPromptId: json['nextPromptId'] as String?,
        locked: json['locked'] as bool? ?? false,
      );
}

/// Une des trois références comparatives, écrites en base (jamais générées
/// par l'IA).
class SkillReferenceDto {
  const SkillReferenceDto({
    required this.level,
    required this.text,
    required this.pedagogicalNote,
  });

  final SkillReferenceLevel level;
  final String text;
  final String pedagogicalNote;

  factory SkillReferenceDto.fromJson(Map<String, dynamic> json) =>
      SkillReferenceDto(
        level: SkillReferenceLevel.fromWire(json['level'] as String),
        text: json['text'] as String,
        pedagogicalNote: json['pedagogicalNote'] as String,
      );
}

/// Où en est le candidat **par rapport au palier qu'il vise**, après une
/// micro-production. Miroir de `SituationNiveauVise` (backend).
///
/// ⚠ Le serveur envoie déjà `situationLabel` prêt à afficher : c'est **lui**
/// qu'on rend. [label] n'est qu'un repli local, gelé sur les mêmes chaînes que
/// `SkillLabelsTest` — aucun front ne recompose cette phrase.
///
/// Aucun libellé ne nomme un manque : « Encore du chemin » décrit une distance,
/// pas un échec.
enum SituationNiveauVise {
  objectifAtteint('OBJECTIF_ATTEINT', 'Tu as atteint ton objectif'),
  proche('PROCHE', 'Tu es proche du niveau visé'),
  enChemin('EN_CHEMIN', 'Encore du chemin vers ton objectif');

  const SituationNiveauVise(this.wire, this.label);

  final String wire;
  final String label;

  static SituationNiveauVise? fromWireNullable(Object? raw) {
    if (raw is! String) return null;
    for (final situation in SituationNiveauVise.values) {
      if (situation.wire == raw) return situation;
    }
    return null;
  }

  bool get isObjectifAtteint => this == SituationNiveauVise.objectifAtteint;
}

/// Le niveau démontré par une micro-production, son objectif et la jauge.
///
/// **Tout est dérivé serveur** (`SkillLevelProgressResolver`) : la situation,
/// son libellé, les trois crans de l'échelle et la position du curseur. L'app
/// n'ordonne rien, ne devine aucun palier et ne recalcule aucune position —
/// cette table de correspondance a déjà vécu en six copies divergentes.
class SkillLevelProgressDto {
  const SkillLevelProgressDto({
    required this.levelReached,
    required this.targetLevel,
    required this.situation,
    required this.situationLabel,
    required this.scale,
    required this.cursorIndex,
  });

  /// Le niveau démontré par CETTE production (jamais C1/C2 : profil TCF IRN).
  final NiveauCecrl levelReached;

  /// Le palier visé, plancher posé par la démarche du candidat.
  final TargetLevel targetLevel;
  final SituationNiveauVise situation;

  /// Libellé FR **posé par le serveur**, affiché tel quel.
  final String situationLabel;

  /// Les trois crans de la jauge, du plus bas au plus haut ; le dernier est
  /// toujours le niveau visé.
  final List<NiveauCecrl> scale;

  /// Index du niveau démontré dans [scale] (0..2), déjà borné par le serveur.
  final int cursorIndex;

  static SkillLevelProgressDto? fromJsonNullable(Object? json) {
    if (json is! Map) return null;
    final reached = _niveauOrNull(json['levelReached']);
    final target = _targetLevelOrNull(json['targetLevel']);
    final situation = SituationNiveauVise.fromWireNullable(json['situation']);
    if (reached == null || target == null || situation == null) return null;
    final raw = json['scale'];
    return SkillLevelProgressDto(
      levelReached: reached,
      targetLevel: target,
      situation: situation,
      situationLabel:
          _trimmedOrNull(json['situationLabel']) ?? situation.label,
      scale: raw is! List
          ? const <NiveauCecrl>[]
          : raw.map(_niveauOrNull).whereType<NiveauCecrl>().toList(
                growable: false,
              ),
      cursorIndex: (json['cursorIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Le plan d'action « pour viser X », produit par un **second appel LLM** séparé
/// de l'analyse.
///
/// **Son absence est un cas NORMAL, jamais une erreur** : l'appel est
/// best-effort, et il n'a pas lieu quand l'objectif est déjà atteint. Aucun
/// écran ne doit afficher de message d'échec, de spinner ni d'excuse quand ce
/// bloc manque.
class SkillNiveauViseDto {
  const SkillNiveauViseDto({
    required this.niveauVise,
    required this.niveauConstate,
    required this.leviers,
    required this.exempleCible,
    required this.aRetenir,
  });

  final TargetLevel niveauVise;
  final NiveauCecrl? niveauConstate;

  /// 2 à 3 leviers, du plus rentable au moins rentable.
  final List<ActionPlanLevier> leviers;
  final ActionPlanExempleCible? exempleCible;
  final ActionPlanMemo? aRetenir;

  static SkillNiveauViseDto? fromJsonNullable(Object? json) {
    if (json is! Map) return null;
    final niveauVise = _targetLevelOrNull(json['niveauVise']);
    if (niveauVise == null) return null;
    final leviers = ActionPlanLevier.listFrom(json['leviers']);
    final exempleCible =
        ActionPlanExempleCible.fromJsonNullable(json['exempleCible']);
    final aRetenir = ActionPlanMemo.fromJsonNullable(json['aRetenir']);
    // Un bloc vide de bout en bout vaut son absence : les trois sections
    // disparaissent au lieu de laisser trois intertitres orphelins.
    if (leviers.isEmpty && exempleCible == null && aRetenir == null) return null;
    return SkillNiveauViseDto(
      niveauVise: niveauVise,
      niveauConstate: _niveauOrNull(json['niveauConstate']),
      leviers: leviers,
      exempleCible: exempleCible,
      aRetenir: aRetenir,
    );
  }
}

/// L'analyse IA ciblée. **Aucune note /20** : un micro-exercice n'en porte pas,
/// et le tool-schema de sortie ne prévoit aucun champ pour en loger une. Le
/// **niveau CECRL**, lui, est rendu depuis le contrat v3 ([levelProgress]).
///
/// **Deux générations de champs cohabitent, sans migration** : les analyses
/// persistées sous v1/v2 portent [successPoint] / [improvementPriority] /
/// [improvedVersion] ; celles produites sous v3 portent [strengthTag],
/// [focusTag] et [levelProgress]. Tout est nullable sauf `status` et `verdict` —
/// on affiche ce qu'on trouve, on ne suppose jamais qu'un champ est présent.
class SkillAnalysisDto {
  const SkillAnalysisDto({
    required this.status,
    required this.verdict,
    this.strengthTag,
    this.focusTag,
    this.levelProgress,
    this.niveauVise,
    this.successPoint,
    this.improvementPriority,
    this.improvedVersion,
  });

  final SkillCriterionStatus status;
  final String verdict;

  /// v3 : ce qui est réussi, en 3 mots. Une étiquette, pas une phrase.
  final String? strengthTag;

  /// v3 : l'axe de progrès, en 3 mots.
  final String? focusTag;

  /// v3 : le niveau démontré, l'objectif, la situation et la jauge.
  final SkillLevelProgressDto? levelProgress;

  /// Le plan d'action du second appel. `null` = cas normal.
  final SkillNiveauViseDto? niveauVise;

  final String? successPoint;
  final String? improvementPriority;
  final String? improvedVersion;

  /// Une analyse d'avant le contrat v3 : elle ne porte ni niveau, ni étiquettes,
  /// et c'est son trio de textes longs qu'il faut rendre.
  bool get isLegacy => levelProgress == null;

  factory SkillAnalysisDto.fromJson(Map<String, dynamic> json) =>
      SkillAnalysisDto(
        status: SkillCriterionStatus.fromWire(json['status'] as String),
        verdict: json['verdict'] as String? ?? '',
        strengthTag: _trimmedOrNull(json['strengthTag']),
        focusTag: _trimmedOrNull(json['focusTag']),
        levelProgress:
            SkillLevelProgressDto.fromJsonNullable(json['levelProgress']),
        niveauVise: SkillNiveauViseDto.fromJsonNullable(json['niveauVise']),
        successPoint: _trimmedOrNull(json['successPoint']),
        improvementPriority: _trimmedOrNull(json['improvementPriority']),
        improvedVersion: _trimmedOrNull(json['improvedVersion']),
      );
}

/// Une tentative sur un petit sujet.
class SkillAttemptDto {
  const SkillAttemptDto({
    required this.id,
    required this.skillPromptId,
    required this.skillPromptCode,
    required this.statut,
    required this.analysisRequested,
    required this.createdAt,
    this.writtenProduction,
    this.audioUrl,
    this.audioDurationSec,
    this.transcript,
    this.wordsCount,
    this.selfEvaluation,
    this.criterionStatus,
    this.analysis,
    this.errorMessage,
  });

  final String id;
  final String skillPromptId;
  final String skillPromptCode;
  final SkillAttemptStatut statut;
  final bool analysisRequested;
  final DateTime createdAt;
  final String? writtenProduction;
  final String? audioUrl;
  final int? audioDurationSec;
  final String? transcript;
  final int? wordsCount;
  final SkillSelfEvaluation? selfEvaluation;
  final SkillCriterionStatus? criterionStatus;
  final SkillAnalysisDto? analysis;
  final String? errorMessage;

  /// Le texte à relire : la rédaction en EE, la transcription en EO (absente
  /// tant qu'aucune analyse n'a été demandée — on ne paie pas Whisper pour
  /// rien).
  String? get productionText =>
      (writtenProduction?.trim().isNotEmpty ?? false)
          ? writtenProduction
          : (transcript?.trim().isNotEmpty ?? false)
              ? transcript
              : null;

  factory SkillAttemptDto.fromJson(Map<String, dynamic> json) =>
      SkillAttemptDto(
        id: json['id'] as String,
        skillPromptId: json['skillPromptId'] as String,
        skillPromptCode: json['skillPromptCode'] as String? ?? '',
        statut: SkillAttemptStatut.fromWire(json['statut'] as String),
        analysisRequested: json['analysisRequested'] as bool? ?? false,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
                DateTime.now(),
        writtenProduction: json['writtenProduction'] as String?,
        audioUrl: json['audioUrl'] as String?,
        audioDurationSec: (json['audioDurationSec'] as num?)?.toInt(),
        transcript: json['transcript'] as String?,
        wordsCount: (json['wordsCount'] as num?)?.toInt(),
        selfEvaluation:
            SkillSelfEvaluation.fromWireNullable(json['selfEvaluation'] as String?),
        criterionStatus: SkillCriterionStatus.fromWireNullable(
            json['criterionStatus'] as String?),
        analysis: json['analysis'] == null
            ? null
            : SkillAnalysisDto.fromJson(json['analysis'] as Map<String, dynamic>),
        errorMessage: json['errorMessage'] as String?,
      );
}

/// Quota d'analyses IA. `remaining == -1` signifie **illimité** : à ne jamais
/// afficher tel quel.
class SkillAnalysisQuotaDto {
  const SkillAnalysisQuotaDto({
    required this.premium,
    required this.unlimited,
    required this.freeAnalysesTotal,
    required this.freeAnalysesUsed,
    required this.remaining,
  });

  final bool premium;
  final bool unlimited;
  final int freeAnalysesTotal;
  final int freeAnalysesUsed;
  final int remaining;

  bool get isUnlimited => unlimited || premium || remaining < 0;

  bool get canAnalyse => isUnlimited || remaining > 0;

  factory SkillAnalysisQuotaDto.fromJson(Map<String, dynamic> json) =>
      SkillAnalysisQuotaDto(
        premium: json['premium'] as bool? ?? false,
        unlimited: json['unlimited'] as bool? ?? false,
        freeAnalysesTotal: (json['freeAnalysesTotal'] as num?)?.toInt() ?? 0,
        freeAnalysesUsed: (json['freeAnalysesUsed'] as num?)?.toInt() ?? 0,
        remaining: (json['remaining'] as num?)?.toInt() ?? 0,
      );
}
