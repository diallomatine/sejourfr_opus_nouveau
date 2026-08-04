import 'enums.dart';

/// Miroir mobile des DTOs backend du pipeline EO/EE (cf. PRODUCTION_TASKS_SPEC_V2.md
/// section 8 + ProductionTaskDto.java / ProductionSubmissionDto.java).
///
/// Convention : les champs sont en camelCase Dart, parses depuis les noms
/// camelCase renvoyes par Spring (Jackson). En cas de divergence backend, c'est
/// ICI qu'on adapte le mapping.

/// Chaine JSON exploitable, ou null : une chaine vide ne vaut pas mieux qu'un
/// champ absent a l'affichage.
String? _trimmedOrNull(Object? raw) {
  if (raw is! String) return null;
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

class ProductionTaskDto {
  ProductionTaskDto({
    required this.id,
    required this.epreuve,
    required this.tacheNumero,
    required this.niveauCible,
    required this.consigne,
    this.contexte,
    this.dureeMinSec,
    this.dureeMaxSec,
    this.motsMin,
    this.motsMax,
  });

  final String id;
  final EpreuveType epreuve;

  /// Numero de tache au sein de l'epreuve (1, 2 ou 3).
  final int tacheNumero;

  /// "A2" / "B1" / "B2" -- string raw pour rester aligne avec le backend.
  final String niveauCible;

  final String consigne;
  final String? contexte;

  /// EO uniquement : duree minimum conseillée en secondes (backend = 120 s).
  final int? dureeMinSec;

  /// EO uniquement : duree max d'enregistrement en secondes.
  final int? dureeMaxSec;

  /// EE uniquement : bornes du nombre de mots attendu.
  final int? motsMin;
  final int? motsMax;

  /// Libelle court genere cote front (le backend ne fournit pas ce titre).
  String get displayTitle {
    if (epreuve == EpreuveType.tcfEo) {
      return switch (tacheNumero) {
        1 => 'Entretien dirigé',
        2 => 'Jeu de rôle',
        3 => 'Point de vue',
        _ => 'Tâche $tacheNumero',
      };
    }
    if (epreuve == EpreuveType.tcfEe) {
      return switch (tacheNumero) {
        1 => 'Message simple',
        2 => 'Récit d\'expérience',
        3 => 'Point de vue argumenté',
        _ => 'Tâche $tacheNumero',
      };
    }
    return 'Tâche $tacheNumero';
  }

  factory ProductionTaskDto.fromJson(Map<String, dynamic> json) => ProductionTaskDto(
        id: json['id'] as String,
        epreuve: EpreuveType.fromWire(json['epreuve'] as String),
        tacheNumero: (json['tacheNumero'] as num).toInt(),
        niveauCible: json['niveauCible'] as String,
        consigne: json['consigne'] as String,
        contexte: json['contexte'] as String?,
        dureeMinSec: (json['dureeMinSec'] as num?)?.toInt(),
        dureeMaxSec: (json['dureeMaxSec'] as num?)?.toInt(),
        motsMin: (json['motsMin'] as num?)?.toInt(),
        motsMax: (json['motsMax'] as num?)?.toInt(),
      );
}

class ProductionSubmissionDto {
  ProductionSubmissionDto({
    required this.id,
    required this.attemptId,
    required this.productionTaskId,
    required this.statut,
    required this.submittedAt,
    required this.retryCount,
    this.tacheNumero,
    this.mediaUrl,
    this.texteSoumis,
    this.motsCount,
    this.mediaDurationSec,
    this.erreurMessage,
    this.evaluation,
    this.transcription,
  });

  final String id;
  final String? attemptId;
  final String? productionTaskId;

  /// Numero de tache (1, 2 ou 3) de la production_task associee. Renseigne
  /// par le backend depuis Hibernate ; utilise par le hub d'entrainement
  /// pour regrouper la derniere submission par tache.
  final int? tacheNumero;

  final SubmissionStatut statut;

  /// URL pre-signee (TTL court) vers l'audio EO. NULL pour EE.
  final String? mediaUrl;

  final String? texteSoumis;
  final int? motsCount;
  final int? mediaDurationSec;

  final int retryCount;
  final String? erreurMessage;
  final DateTime submittedAt;

  /// Presente uniquement quand `statut == evaluated`.
  final EvaluationResult? evaluation;

  /// Texte transcrit par Whisper (EO uniquement). Null pour EE et tant que la
  /// transcription n'a pas tourne.
  final String? transcription;

  bool get isAudio => mediaUrl != null;

  bool get isText => texteSoumis != null;

  factory ProductionSubmissionDto.fromJson(Map<String, dynamic> json) => ProductionSubmissionDto(
        id: json['id'] as String,
        attemptId: json['attemptId'] as String?,
        productionTaskId: json['productionTaskId'] as String?,
        tacheNumero: (json['tacheNumero'] as num?)?.toInt(),
        statut: SubmissionStatut.fromWire(json['statut'] as String),
        mediaUrl: json['mediaUrl'] as String?,
        texteSoumis: json['texteSoumis'] as String?,
        motsCount: (json['motsCount'] as num?)?.toInt(),
        mediaDurationSec: (json['mediaDurationSec'] as num?)?.toInt(),
        retryCount: (json['retryCount'] as num? ?? 0).toInt(),
        erreurMessage: json['erreurMessage'] as String?,
        submittedAt: DateTime.parse(json['submittedAt'] as String),
        evaluation: json['evaluation'] == null
            ? null
            : EvaluationResult.fromJson(json['evaluation'] as Map<String, dynamic>),
        transcription: json['transcription'] as String?,
      );
}

/// Vue front d'une AiEvaluation. Le bloc `feedback` est passe en l'etat depuis
/// le JSONB persiste cote backend.
///
/// Contrat v4 : `niveauObserve` / `confiance` / `avertissementNiveau` ont ete
/// AJOUTES entre `noteSurVingt` et `feedback` cote Java. Le parsing se fait
/// uniquement par cle JSON — l'ordre du record n'a donc aucun effet ici. Les
/// evaluations deja en base (v3) laissent les trois champs a null : c'est un
/// cas normal, l'ecran retombe sur l'affichage precedent.
class EvaluationResult {
  EvaluationResult({
    required this.feedback,
    this.noteSurVingt,
    this.niveauObserve,
    this.confiance,
    this.avertissementNiveau,
  });

  /// Note 0..20, peut etre nulle si l'IA n'a pas pu noter (ex: production vide).
  final double? noteSurVingt;

  /// Niveau observe SUR CETTE TACHE. Le niveau qui fait foi reste celui du
  /// bilan d'epreuve (`ProductionBilan.niveauGlobal`).
  final NiveauCecrl? niveauObserve;

  /// Certitude de l'evaluation. Null pour une eval anterieure au contrat v4.
  final ConfianceEvaluation? confiance;

  /// Rappel pret a afficher sous le niveau observe (texte fourni par le
  /// backend). Null quand il n'y a pas de niveau.
  final String? avertissementNiveau;

  final EvaluationFeedback feedback;

  /// Garde-fou produit : jamais de niveau sans sa confiance a cote.
  bool get hasNiveauObserve => niveauObserve != null && confiance != null;

  factory EvaluationResult.fromJson(Map<String, dynamic> json) => EvaluationResult(
        noteSurVingt: (json['noteSurVingt'] as num?)?.toDouble(),
        niveauObserve: NiveauCecrl.fromWireNullable(json['niveauObserve'] as String?),
        confiance: ConfianceEvaluation.fromWireNullable(json['confiance'] as String?),
        avertissementNiveau: json['avertissementNiveau'] as String?,
        feedback: EvaluationFeedback.fromJson(
          (json['feedback'] as Map<String, dynamic>?) ?? const {},
        ),
      );
}

/// Detail structure du feedback IA (cf. backend tool_use submit_evaluation).
class EvaluationFeedback {
  EvaluationFeedback({
    this.noteGlobale,
    this.confiance,
    this.confianceRaisons = const [],
    this.accomplissement,
    this.scoresCriteres = const [],
    this.pointsForts = const [],
    this.pointsAAmeliorer = const [],
    this.suggestions = const [],
    this.exemplesCorriges = const [],
    this.avertissements = const [],
  });

  final double? noteGlobale;

  /// Confiance telle que declaree dans le feedback brut. `EvaluationResult`
  /// porte la valeur qui fait foi (plafonnee cote serveur) ; celle-ci sert de
  /// repli et accompagne `confianceRaisons`.
  final ConfianceEvaluation? confiance;

  /// 1 a 3 raisons courtes expliquant le degre de confiance.
  final List<String> confianceRaisons;

  /// Ce que le candidat a traite / oublie par rapport a la consigne. Null pour
  /// les evaluations anterieures au contrat v4.
  final Accomplissement? accomplissement;

  final List<CriterionScore> scoresCriteres;
  final List<String> pointsForts;

  /// Limite a 2 cote backend : ce sont des priorites, pas une liste de reproches.
  final List<PointAAmeliorer> pointsAAmeliorer;
  final List<String> suggestions;
  final List<CorrectionExample> exemplesCorriges;
  final List<String> avertissements;

  factory EvaluationFeedback.fromJson(Map<String, dynamic> json) {
    final accomplissement = json['accomplissement'];
    return EvaluationFeedback(
      noteGlobale: (json['note_globale'] as num?)?.toDouble(),
      confiance: ConfianceEvaluation.fromWireNullable(json['confiance'] as String?),
      confianceRaisons: ((json['confiance_raisons'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      accomplissement: accomplissement is Map<String, dynamic>
          ? Accomplissement.fromJson(accomplissement)
          : null,
      scoresCriteres: ((json['scores_criteres'] as List?) ?? const [])
          .map((e) => CriterionScore.fromJson(e as Map<String, dynamic>))
          .toList(),
      pointsForts: ((json['points_forts'] as List?) ?? const []).map((e) => e.toString()).toList(),
      pointsAAmeliorer: ((json['points_a_ameliorer'] as List?) ?? const [])
          .map(PointAAmeliorer.fromJsonNullable)
          .whereType<PointAAmeliorer>()
          .toList(),
      suggestions: ((json['suggestions'] as List?) ?? const []).map((e) => e.toString()).toList(),
      exemplesCorriges: ((json['exemples_corriges'] as List?) ?? const [])
          .map((e) => CorrectionExample.fromJson(e as Map<String, dynamic>))
          .toList(),
      avertissements: ((json['avertissements'] as List?) ?? const []).map((e) => e.toString()).toList(),
    );
  }
}

/// Une priorite de travail. Un rapport doit ENSEIGNER, pas constater : le
/// `constat` dit ce qui ne va pas, le `comment` donne la technique reutilisable,
/// l'`exemple` la demontre sur une phrase du candidat.
///
/// Deux formes coexistent en base et sont toutes deux acceptees : la chaine
/// simple des evaluations anterieures (rendue comme un constat seul) et l'objet
/// du contrat courant.
class PointAAmeliorer {
  PointAAmeliorer({required this.constat, this.comment, this.exemple});

  final String constat;

  /// Technique a appliquer, formulee a l'imperatif et reutilisable ailleurs.
  final String? comment;

  /// Demonstration avant/apres sur la production du candidat.
  final ExempleReecriture? exemple;

  bool get isTeaching => comment != null || exemple != null;

  static PointAAmeliorer? fromJsonNullable(Object? raw) {
    if (raw is String) {
      final constat = raw.trim();
      return constat.isEmpty ? null : PointAAmeliorer(constat: constat);
    }
    if (raw is Map<String, dynamic>) {
      // `libelle`/`texte` : formes intermediaires vues chez certains modeles.
      final constat =
          _trimmedOrNull(raw['constat']) ??
              _trimmedOrNull(raw['libelle']) ??
              _trimmedOrNull(raw['texte']);
      if (constat == null) return null;
      return PointAAmeliorer(
        constat: constat,
        comment: _trimmedOrNull(raw['comment']),
        exemple: ExempleReecriture.fromJsonNullable(raw['exemple']),
      );
    }
    return null;
  }
}

/// Reecriture d'une phrase du candidat : sa version, puis la meme phrase une
/// fois la technique appliquee.
class ExempleReecriture {
  ExempleReecriture({required this.avant, required this.apres});

  final String avant;
  final String apres;

  static ExempleReecriture? fromJsonNullable(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final avant = _trimmedOrNull(raw['avant']);
    final apres = _trimmedOrNull(raw['apres']);
    if (avant == null || apres == null) return null;
    return ExempleReecriture(avant: avant, apres: apres);
  }
}

/// Check-list « accomplissement » : ce que le candidat a traite ou non par
/// rapport a la consigne. Affichee AVANT le detail de langue.
class Accomplissement {
  Accomplissement({
    this.pointsTraites = const [],
    this.pointsOublies = const [],
  });

  final List<AccomplissementPoint> pointsTraites;
  final List<AccomplissementPoint> pointsOublies;

  bool get isEmpty => pointsTraites.isEmpty && pointsOublies.isEmpty;

  /// Manques reels : seuls les points obligatoires non traites pesent sur la
  /// note. Les pistes non abordees sont informatives.
  List<AccomplissementPoint> get manques =>
      pointsOublies.where((p) => p.obligatoire).toList();

  List<AccomplissementPoint> get pistesNonAbordees =>
      pointsOublies.where((p) => !p.obligatoire).toList();

  static List<AccomplissementPoint> _points(Object? raw) =>
      ((raw as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AccomplissementPoint.fromJson)
          .where((p) => p.libelle.isNotEmpty)
          .toList();

  factory Accomplissement.fromJson(Map<String, dynamic> json) => Accomplissement(
        pointsTraites: _points(json['points_traites']),
        pointsOublies: _points(json['points_oublies']),
      );
}

/// Un point de la consigne. `obligatoire == false` = simple piste suggeree par
/// le sujet : ne pas la traiter n'est PAS une faute et n'influence pas la note.
class AccomplissementPoint {
  AccomplissementPoint({required this.libelle, required this.obligatoire});

  final String libelle;
  final bool obligatoire;

  factory AccomplissementPoint.fromJson(Map<String, dynamic> json) =>
      AccomplissementPoint(
        libelle: (json['libelle'] as String? ?? '').trim(),
        obligatoire: json['obligatoire'] as bool? ?? false,
      );
}

class CriterionScore {
  CriterionScore({
    required this.code,
    this.label,
    required this.noteSurVingt,
    required this.commentaire,
    this.bande,
    this.preuve,
  });

  final String code;

  /// Libelle lisible joint cote serveur depuis la grille de la tache.
  /// Null pour les anciennes evaluations : le widget retombe sur une table
  /// locale dans `CriterionRow._labelForCode`.
  final String? label;

  /// Note interne /20 : sert au calcul cote backend, plus a l'affichage des
  /// que `bande` est renseignee (contrat v4).
  final double noteSurVingt;
  final String commentaire;

  /// Bande qualitative calculee cote serveur. Null sur les evaluations v3 —
  /// le widget retombe alors sur l'affichage chiffre historique.
  final BandeCritere? bande;

  /// Citation litterale et courte de la production, justifiant le critere.
  final String? preuve;

  factory CriterionScore.fromJson(Map<String, dynamic> json) {
    final raw = json['label'] as String?;
    final cleaned = raw == null || raw.trim().isEmpty ? null : raw.trim();
    final preuve = (json['preuve'] as String?)?.trim();
    return CriterionScore(
      code: json['code'] as String,
      label: cleaned,
      noteSurVingt: (json['note_sur_20'] as num?)?.toDouble() ?? 0,
      commentaire: json['commentaire'] as String? ?? '',
      bande: BandeCritere.fromWireNullable(json['bande'] as String?),
      preuve: preuve == null || preuve.isEmpty ? null : preuve,
    );
  }
}

class CorrectionExample {
  CorrectionExample({
    required this.original,
    required this.corrige,
    required this.explication,
    this.gain,
  });

  final String original;
  final String corrige;
  final String explication;

  /// Ce que la reformulation DEMONTRE de plus (« emploie une subordonnee
  /// relative, marqueur attendu au B1 »). Absent des evaluations anterieures.
  final String? gain;

  factory CorrectionExample.fromJson(Map<String, dynamic> json) => CorrectionExample(
        original: json['original'] as String? ?? '',
        corrige: json['corrige'] as String? ?? '',
        explication: json['explication'] as String? ?? '',
        gain: _trimmedOrNull(json['gain']),
      );
}

/// Reponse modele rattachee a une tache (modele illustratif). `audioUrl`
/// renseigne pour l'EO une fois l'audio publie, null sinon. `explications` =
/// commentaire pedagogique affiche sous le contenu.
class ProductionExampleDto {
  ProductionExampleDto({
    required this.id,
    required this.titre,
    required this.contenu,
    this.resume,
    this.explications,
    this.audioUrl,
    this.planPoints = const [],
    this.niveauIndicatif,
  });

  final String id;
  final String titre;
  final String? resume;
  final String contenu;
  final String? explications;
  final String? audioUrl;
  final List<String> planPoints;
  final String? niveauIndicatif;

  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;

  factory ProductionExampleDto.fromJson(Map<String, dynamic> json) => ProductionExampleDto(
        id: json['id'] as String,
        titre: json['titre'] as String,
        resume: json['resume'] as String?,
        contenu: json['contenu'] as String,
        explications: json['explications'] as String?,
        audioUrl: json['audioUrl'] as String?,
        planPoints:
            ((json['planPoints'] as List?) ?? const []).map((e) => e.toString()).toList(),
        niveauIndicatif: json['niveauIndicatif'] as String?,
      );
}

/// Fourchette de note officielle du TCF IRN correspondant a un niveau CECRL, sur
/// les epreuves d'expression — miroir de CorrespondanceTcfDto.
///
/// Grille officielle : 0 → A1 non atteint, 1 → A1, 2-5 → A2, 6-9 → B1,
/// 10-20 → B2. Ce n'est PAS une conversion de notre note : notre echelle est
/// pedagogique et bien plus fine (10/20 chez nous n'est pas B2). A n'afficher
/// qu'au bilan d'une epreuve entiere — au TCF, une tache isolee n'a pas de note.
class CorrespondanceTcf {
  const CorrespondanceTcf({
    required this.niveau,
    required this.scoreTcfMin,
    required this.scoreTcfMax,
  });

  final NiveauCecrl niveau;
  final int scoreTcfMin;
  final int scoreTcfMax;

  /// Phrase prete a afficher, identique au web (parite non negociable).
  String get phrase {
    final plage = scoreTcfMin == scoreTcfMax
        ? 'la note de $scoreTcfMin sur 20'
        : 'une note de $scoreTcfMin à $scoreTcfMax sur 20';
    return 'Au TCF, le niveau ${niveau.displayName} correspond à $plage.';
  }

  static CorrespondanceTcf? fromJsonNullable(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final niveau = NiveauCecrl.fromWireNullable(json['niveau'] as String?);
    final min = (json['scoreTcfMin'] as num?)?.toInt();
    final max = (json['scoreTcfMax'] as num?)?.toInt();
    if (niveau == null || min == null || max == null) return null;
    return CorrespondanceTcf(niveau: niveau, scoreTcfMin: min, scoreTcfMax: max);
  }
}

/// Bilan d'epreuve de production EO/EE — miroir de ProductionBilanResponse.
/// Le `niveauGlobal` n'est calcule (cote backend) qu'en session d'examen blanc
/// (`exam == true`) et quand les evaluations sont completes ; il reste null en
/// entrainement libre ou tant qu'une tache n'est pas evaluee.
///
///   GET /api/attempts/{attemptId}/production-bilan
class ProductionBilan {
  ProductionBilan({
    required this.attemptId,
    required this.epreuve,
    required this.exam,
    required this.evaluatedCount,
    required this.expectedCount,
    required this.finished,
    this.moyenneSur20,
    this.niveauGlobal,
    this.slotNumber,
    this.correspondanceTcf,
  });

  final String attemptId;
  final EpreuveType epreuve;

  /// True quand l'attempt est une session d'examen blanc (slot ou sous-attempt
  /// d'un TCF complet) — seul cas ou `niveauGlobal` est renseigne.
  final bool exam;

  final int evaluatedCount;
  final int expectedCount;

  /// True quand l'attempt a `finishedAt` posé (3 tâches soumises, chrono écoulé
  /// ou abandon). Quand `finished && evaluatedCount < 3`, les tâches manquantes
  /// sont comptées 0 et `niveauGlobal` est calculé dès que le pipeline IA est
  /// vide — les tâches jamais rendues s'affichent « Non rendue ».
  final bool finished;

  /// Slot d'examen blanc (1-10) sur lequel mapper la session dans la grille.
  /// Null hors examen module.
  final int? slotNumber;

  /// Moyenne ponderee /20 ; null si aucune evaluation.
  final double? moyenneSur20;

  /// Niveau CECRL global ; null si `!exam` ou evaluations incompletes.
  final NiveauCecrl? niveauGlobal;

  /// Fourchette officielle TCF du `niveauGlobal` ; null exactement quand
  /// `niveauGlobal` l'est.
  final CorrespondanceTcf? correspondanceTcf;

  bool get isComplete => evaluatedCount >= expectedCount && expectedCount > 0;

  factory ProductionBilan.fromJson(Map<String, dynamic> json) => ProductionBilan(
        attemptId: json['attemptId'] as String,
        epreuve: EpreuveType.fromWire(json['epreuve'] as String),
        exam: json['exam'] as bool? ?? false,
        evaluatedCount: (json['evaluatedCount'] as num?)?.toInt() ?? 0,
        expectedCount: (json['expectedCount'] as num?)?.toInt() ?? 0,
        finished: json['finished'] as bool? ?? false,
        slotNumber: (json['slotNumber'] as num?)?.toInt(),
        moyenneSur20: (json['moyenneSur20'] as num?)?.toDouble(),
        niveauGlobal: NiveauCecrl.fromWireNullable(json['niveauGlobal'] as String?),
        correspondanceTcf: CorrespondanceTcf.fromJsonNullable(json['correspondanceTcf']),
      );
}
