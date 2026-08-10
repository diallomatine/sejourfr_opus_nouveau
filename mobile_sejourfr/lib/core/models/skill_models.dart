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

/// Détail d'une compétence : la compétence + ses 5 petits sujets.
class SkillDetail {
  const SkillDetail({required this.skill, required this.prompts});

  final SkillDto skill;
  final List<SkillPromptSummary> prompts;

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

/// L'analyse IA ciblée : 4 champs courts, **aucune note /20, aucun niveau
/// CECRL** (interdits sur un micro-exercice, cf. §9 de la spec).
class SkillAnalysisDto {
  const SkillAnalysisDto({
    required this.status,
    required this.verdict,
    required this.successPoint,
    required this.improvementPriority,
    required this.improvedVersion,
  });

  final SkillCriterionStatus status;
  final String verdict;
  final String successPoint;
  final String improvementPriority;
  final String improvedVersion;

  factory SkillAnalysisDto.fromJson(Map<String, dynamic> json) =>
      SkillAnalysisDto(
        status: SkillCriterionStatus.fromWire(json['status'] as String),
        verdict: json['verdict'] as String? ?? '',
        successPoint: json['successPoint'] as String? ?? '',
        improvementPriority: json['improvementPriority'] as String? ?? '',
        improvedVersion: json['improvedVersion'] as String? ?? '',
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
