import 'action_plan.dart';
import 'enums.dart';
import 'skill_models.dart';

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
    this.titre,
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

  /// Intitule editorial du sujet (`production_tasks.titre`, V028) --
  /// « Message a un ami », « Invitation a un pique-nique ».
  ///
  /// **Peut manquer** (contenu anterieur a V028, sujet cree en console sans
  /// titre) : les cartes retombent alors sur `productionSubjectTitle`, qui
  /// rend « Sujet N ». Aucun ecran ne suppose qu'il est present.
  final String? titre;

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

  factory ProductionTaskDto.fromJson(Map<String, dynamic> json) =>
      ProductionTaskDto(
        id: json['id'] as String,
        epreuve: EpreuveType.fromWire(json['epreuve'] as String),
        tacheNumero: (json['tacheNumero'] as num).toInt(),
        niveauCible: json['niveauCible'] as String,
        titre: _trimmedOrNull(json['titre']),
        consigne: json['consigne'] as String,
        contexte: json['contexte'] as String?,
        dureeMinSec: (json['dureeMinSec'] as num?)?.toInt(),
        dureeMaxSec: (json['dureeMaxSec'] as num?)?.toInt(),
        motsMin: (json['motsMin'] as num?)?.toInt(),
        motsMax: (json['motsMax'] as num?)?.toInt(),
      );
}

/// Les bornes EE du TCF IRN sont strictes : T1 30–60 mots, T2/T3 40–90
/// d'après la tâche reçue du backend. Aucune marge, ni sous le minimum ni
/// au-delà du maximum — les valeurs viennent de la base, jamais du code.
bool isEeWordCountWithinBounds(ProductionTaskDto task, int wordCount) =>
    task.motsMin != null &&
    task.motsMax != null &&
    wordCount >= task.motsMin! &&
    wordCount <= task.motsMax!;

class ProductionSubmissionDto {
  ProductionSubmissionDto({
    required this.id,
    required this.attemptId,
    required this.productionTaskId,
    required this.statut,
    required this.submittedAt,
    required this.retryCount,
    this.tacheNumero,
    this.texteSoumis,
    this.motsCount,
    this.mediaDurationSec,
    this.erreurMessage,
    this.evaluation,
    this.transcription,
    this.planChange,
  });

  final String id;
  final String? attemptId;
  final String? productionTaskId;

  /// Numero de tache (1, 2 ou 3) de la production_task associee. Renseigne
  /// par le backend depuis Hibernate ; utilise par le hub d'entrainement
  /// pour regrouper la derniere submission par tache.
  final int? tacheNumero;

  final SubmissionStatut statut;

  final String? texteSoumis;
  final int? motsCount;

  /// Duree de l'enregistrement (EO). Seule trace qui subsiste de l'audio : il
  /// n'est pas conserve, donc aucune URL n'est servie — ce qui reste d'une
  /// production orale, c'est [transcription].
  final int? mediaDurationSec;

  final int retryCount;
  final String? erreurMessage;
  final DateTime submittedAt;

  /// Presente uniquement quand `statut == evaluated`.
  final EvaluationResult? evaluation;

  /// Texte transcrit par Whisper (EO uniquement) — **LA production orale
  /// conservee**, ecrite pendant la requete de soumission. Null pour EE.
  final String? transcription;

  /// Ce que cette production a change dans le Plan — **une ligne, pas un
  /// rapport**. `null` est un cas NORMAL : rien n'a bouge, ou les observations
  /// (ecrites APRES la correction) ne sont pas encore la. Servi seulement sur
  /// le detail d'une soumission.
  final PlanChange? planChange;

  bool get isText => texteSoumis != null;

  factory ProductionSubmissionDto.fromJson(Map<String, dynamic> json) =>
      ProductionSubmissionDto(
        id: json['id'] as String,
        attemptId: json['attemptId'] as String?,
        productionTaskId: json['productionTaskId'] as String?,
        tacheNumero: (json['tacheNumero'] as num?)?.toInt(),
        statut: SubmissionStatut.fromWire(json['statut'] as String),
        texteSoumis: json['texteSoumis'] as String?,
        motsCount: (json['motsCount'] as num?)?.toInt(),
        mediaDurationSec: (json['mediaDurationSec'] as num?)?.toInt(),
        retryCount: (json['retryCount'] as num? ?? 0).toInt(),
        erreurMessage: json['erreurMessage'] as String?,
        submittedAt: DateTime.parse(json['submittedAt'] as String),
        evaluation: json['evaluation'] == null
            ? null
            : EvaluationResult.fromJson(
                json['evaluation'] as Map<String, dynamic>),
        transcription: json['transcription'] as String?,
        planChange: json['planChange'] == null
            ? null
            : PlanChange.fromJson(json['planChange'] as Map<String, dynamic>),
      );
}

/// De quoi nommer une competence du Plan et y renvoyer, sans embarquer tout son
/// etat.
class PlanSkillRef {
  const PlanSkillRef({
    required this.skillId,
    required this.skillCode,
    required this.title,
    required this.section,
  });

  final String skillId;
  final String skillCode;
  final String title;
  final SkillSection section;

  factory PlanSkillRef.fromJson(Map<String, dynamic> json) => PlanSkillRef(
        skillId: json['skillId'] as String,
        skillCode: json['skillCode'] as String? ?? '',
        title: json['title'] as String? ?? '',
        section: SkillSection.fromWire(json['section'] as String),
      );
}

/// Ce qu'une production a change dans le Plan. Les deux champs sont
/// **independamment nullables** : on n'affiche que celui qui existe.
class PlanChange {
  const PlanChange({this.confirmedSkill, this.newPriority});

  /// Competence que cette production vient de confirmer en situation.
  final PlanSkillRef? confirmedSkill;

  /// Nouvelle priorite n°1 issue de cette meme production.
  final PlanSkillRef? newPriority;

  bool get isEmpty => confirmedSkill == null && newPriority == null;

  factory PlanChange.fromJson(Map<String, dynamic> json) => PlanChange(
        confirmedSkill: json['confirmedSkill'] == null
            ? null
            : PlanSkillRef.fromJson(
                json['confirmedSkill'] as Map<String, dynamic>),
        newPriority: json['newPriority'] == null
            ? null
            : PlanSkillRef.fromJson(
                json['newPriority'] as Map<String, dynamic>),
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
    this.evaluabilite = ProductionEvaluabilite.evaluable,
    this.noteSurVingt,
    this.niveauObserve,
    this.confiance,
    this.avertissementNiveau,
    this.situationDansNiveau,
    this.situationDansNiveauLabel,
  });

  /// La production a-t-elle pu etre OBSERVEE ? **Jamais null** — le defaut
  /// [ProductionEvaluabilite.evaluable] couvre toute evaluation anterieure au
  /// champ, y compris celles qui portent encore quatre criteres a zero : elles
  /// ne sont PAS des productions inexploitables, rien n'a ete migre.
  ///
  /// ⚠️ **Trois etats, pas deux** : `submission.evaluation == null` dit « pas
  /// encore evaluee », cet enum dit « rendue, rien a observer ». Voir
  /// [estNonEvaluable], le seul point de lecture des ecrans.
  final ProductionEvaluabilite evaluabilite;

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

  /// Position de la production DANS la bande du niveau annonce (3 crans).
  /// Null quand il n'y a rien a situer (eval ancienne, `A1_NON_ATTEINT`,
  /// C1/C2) : l'affichage disparait alors, sans placeholder.
  final SituationDansNiveau? situationDansNiveau;

  /// Libelle compose pret a afficher (« A2 solide »), pose par le serveur.
  /// Null exactement en meme temps que [situationDansNiveau].
  final String? situationDansNiveauLabel;

  final EvaluationFeedback feedback;

  /// Garde-fou produit : jamais de niveau sans sa confiance a cote. Une
  /// production inexploitable n'a de toute facon aucun niveau a montrer.
  bool get hasNiveauObserve =>
      !estNonEvaluable && niveauObserve != null && confiance != null;

  /// La production a ete rendue, mais **rien n'a pu y etre observe**. Aucun
  /// ecran n'affiche alors de note, de niveau ni de critere : il n'y a pas de
  /// verdict a rendre, seulement un fait a dire — sans reproche.
  bool get estNonEvaluable =>
      evaluabilite == ProductionEvaluabilite.nonEvaluable;

  factory EvaluationResult.fromJson(Map<String, dynamic> json) =>
      EvaluationResult(
        evaluabilite:
            ProductionEvaluabilite.fromWire(json['evaluabilite'] as String?),
        noteSurVingt: (json['noteSurVingt'] as num?)?.toDouble(),
        niveauObserve:
            NiveauCecrl.fromWireNullable(json['niveauObserve'] as String?),
        confiance:
            ConfianceEvaluation.fromWireNullable(json['confiance'] as String?),
        avertissementNiveau: json['avertissementNiveau'] as String?,
        situationDansNiveau: SituationDansNiveau.fromWireNullable(
          json['situationDansNiveau'] as String?,
        ),
        situationDansNiveauLabel: _trimmedOrNull(json['situationDansNiveauLabel']),
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
    this.versionAmelioree,
    this.versionCiblee,
    this.niveauViseAtteint,
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

  /// Production reecrite au niveau **deja constate**. ⚠️ **N'est plus affichee
  /// nulle part depuis le 2026-08-08** : recopiee puis resoumise, elle rendait
  /// la meme note et le meme niveau, alors qu'elle etait le texte le plus
  /// copiable du rapport. Le champ reste decode parce que l'API le sert encore
  /// (le retirer imposerait une version de tool-schema). Ne pas le rebrancher
  /// dans un widget : le seul modele affiche est [versionCiblee].
  final String? versionAmelioree;

  /// La meme reponse redigee au palier que le candidat VISE, plus les 2 a 3
  /// leviers qui l'en separent — le seul texte modele rendu au candidat.
  /// **EE uniquement**, et absente aussi quand le niveau vise est deja atteint
  /// ou quand le second appel LLM a echoue : cas normaux.
  final VersionCiblee? versionCiblee;

  /// Exclusif du precedent : le palier vise est **deja atteint**, et le serveur
  /// le dit pour qu'on l'annonce au lieu de laisser un trou.
  final NiveauViseAtteint? niveauViseAtteint;

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
      confiance:
          ConfianceEvaluation.fromWireNullable(json['confiance'] as String?),
      confianceRaisons: ((json['confiance_raisons'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      accomplissement: accomplissement is Map<String, dynamic>
          ? Accomplissement.fromJson(accomplissement)
          : null,
      versionAmelioree: _trimmedOrNull(json['version_amelioree']),
      versionCiblee: VersionCiblee.fromJsonNullable(json['version_ciblee']),
      niveauViseAtteint:
          NiveauViseAtteint.fromJsonNullable(json['niveau_vise_atteint']),
      scoresCriteres: ((json['scores_criteres'] as List?) ?? const [])
          .map((e) => CriterionScore.fromJson(e as Map<String, dynamic>))
          .toList(),
      pointsForts: ((json['points_forts'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      pointsAAmeliorer: ((json['points_a_ameliorer'] as List?) ?? const [])
          .map(PointAAmeliorer.fromJsonNullable)
          .whereType<PointAAmeliorer>()
          .toList(),
      suggestions: ((json['suggestions'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      exemplesCorriges: ((json['exemples_corriges'] as List?) ?? const [])
          .map((e) => CorrectionExample.fromJson(e as Map<String, dynamic>))
          .toList(),
      avertissements: ((json['avertissements'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// Le **plan d'action** du candidat vers le palier qu'il vise. Produit par un
/// SECOND appel LLM, totalement separe de la correction : le correcteur
/// n'apprend jamais quel niveau vise le candidat, sinon il alignerait sa note
/// dessus.
///
/// **EE et EO.** Le bloc est absent dans tous ces cas parfaitement normaux :
/// evaluations anterieures, second appel en echec, et — a l'oral —
/// transcription trop abimee pour reformuler quoi que ce soit. Rien ne
/// s'affiche alors : ni squelette, ni « non disponible ».
///
/// **Trois formes, une seule cle** — on distingue l'ecrit de l'oral a la
/// presence de [exempleCible] ou de [reformulations] :
/// - **v2, ecrit** : [leviers] + [exempleCible] + [aRetenir] ;
/// - **v2, oral** : [leviers] + [reformulations] + [aRetenir]. **Aucun texte
///   modele complet** — la production orale n'est jamais reecrite en entier ;
/// - **v1** (une centaine d'evaluations deja en base) : [texte] +
///   [ceQuiManque], ecrit seulement.
///
/// Quand le palier vise est **deja atteint**, ce n'est pas ce bloc qui manque :
/// c'est [NiveauViseAtteint] qui prend sa place. Les deux sont exclusifs.
class VersionCiblee {
  const VersionCiblee({
    required this.niveauVise,
    this.niveauConstate,
    this.leviers = const [],
    this.exempleCible,
    this.reformulations = const [],
    this.aRetenir,
    this.texte,
    this.ceQuiManque = const [],
  });

  /// Palier vise : `max(exige par la demarche, targetLevel declare)`, a defaut
  /// celui du sujet. Pose par le serveur (`TargetProcedure.niveauVise`).
  final TargetLevel niveauVise;

  /// Palier reellement observe sur cette tache. Absent si inconnu.
  final NiveauCecrl? niveauConstate;

  /// v2 : 2 a 3 leviers, **dans l'ordre du backend** (du plus rentable au moins
  /// rentable) — ne jamais retrier cote front.
  final List<ActionPlanLevier> leviers;

  /// v2, ECRIT : la reponse reecrite au niveau vise, segments surlignables.
  final ActionPlanExempleCible? exempleCible;

  /// v2, ORAL : 2 a 3 passages redits au niveau vise. Exclusif du precedent.
  final List<ActionPlanReformulation> reformulations;

  /// v2 : la tournure a emporter ailleurs.
  final ActionPlanMemo? aRetenir;

  /// v1 (legacy) : le modele redige au niveau vise. **Jamais la production du
  /// candidat.** Null sous le contrat v2.
  final String? texte;

  /// v1 (legacy) : les leviers en texte libre, ordre du backend preserve.
  final List<String> ceQuiManque;

  /// Null des qu'il manque de quoi l'afficher honnetement : sans palier vise on
  /// ne saurait pas au nom de quoi ce plan est montre, et sans la moindre
  /// section il n'y a rien a montrer.
  static VersionCiblee? fromJsonNullable(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final vise = _targetLevelOrNull(_trimmedOrNull(raw['niveau_vise']));
    if (vise == null) return null;

    final leviers = ActionPlanLevier.listFrom(raw['leviers']);
    final exempleCible =
        ActionPlanExempleCible.fromJsonNullable(raw['exemple_cible']);
    final reformulations =
        ActionPlanReformulation.listFrom(raw['reformulations']);
    final aRetenir = ActionPlanMemo.fromJsonNullable(raw['a_retenir']);
    final texte = _trimmedOrNull(raw['texte']);
    final ceQuiManque = ((raw['ce_qui_manque'] as List?) ?? const [])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    final vide = leviers.isEmpty &&
        exempleCible == null &&
        reformulations.isEmpty &&
        aRetenir == null &&
        texte == null &&
        ceQuiManque.isEmpty;
    if (vide) return null;

    return VersionCiblee(
      niveauVise: vise,
      niveauConstate: _niveauCecrlOrNull(_trimmedOrNull(raw['niveau_constate'])),
      leviers: leviers,
      exempleCible: exempleCible,
      reformulations: reformulations,
      aRetenir: aRetenir,
      texte: texte,
      ceQuiManque: ceQuiManque,
    );
  }
}

/// **Le palier vise est atteint** — un signal SERVEUR, pas une deduction.
///
/// Sans lui, un front ne pouvait pas distinguer « objectif atteint » (une
/// victoire, a annoncer) de « le second appel LLM a echoue » (un incident, a
/// taire) : la section modele disparaissait en silence dans les deux cas, et
/// depuis le retrait de `version_amelioree` le candidat qui REUSSIT se
/// retrouvait avec un rapport plus vide que celui qui echoue.
///
/// Exclusif de [VersionCiblee]. Absent en EO et sur toutes les evaluations
/// anterieures.
class NiveauViseAtteint {
  const NiveauViseAtteint({required this.niveauVise, this.niveauConstate});

  /// Le palier que la production atteint (ou depasse).
  final TargetLevel niveauVise;

  /// Palier reellement observe sur cette tache. Absent si inconnu.
  final NiveauCecrl? niveauConstate;

  /// Null sans palier vise : il n'y aurait rien a feliciter.
  static NiveauViseAtteint? fromJsonNullable(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final vise = _targetLevelOrNull(_trimmedOrNull(raw['niveau_vise']));
    if (vise == null) return null;
    return NiveauViseAtteint(
      niveauVise: vise,
      niveauConstate: _niveauCecrlOrNull(_trimmedOrNull(raw['niveau_constate'])),
    );
  }
}

/// Lectures **tolerantes** des deux enums de niveau : le bloc est facultatif et
/// ne doit jamais faire echouer le parsing d'une evaluation par ailleurs
/// valide. `TargetLevel.fromWireNullable` leve sur une valeur inconnue.
TargetLevel? _targetLevelOrNull(String? wire) {
  if (wire == null) return null;
  for (final t in TargetLevel.values) {
    if (t.wire == wire.toUpperCase()) return t;
  }
  return null;
}

NiveauCecrl? _niveauCecrlOrNull(String? wire) {
  if (wire == null) return null;
  for (final n in NiveauCecrl.values) {
    if (n.wire == wire.toUpperCase()) return n;
  }
  return null;
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
      final constat = _trimmedOrNull(raw['constat']) ??
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
/// rapport a la consigne.
///
/// Deux niveaux de lecture, volontairement separes a l'ecran : le **verdict**
/// (`objectif` + `objectifResume`) ouvre le rapport, la **check-list** detaillee
/// vit dans l'analyse complete. Les evaluations deja en base n'ont ni l'un ni
/// l'autre : chaque bloc disparait de son cote sans laisser de trou.
class Accomplissement {
  Accomplissement({
    this.objectif,
    this.objectifResume,
    this.pointsTraites = const [],
    this.pointsOublies = const [],
  });

  /// Verdict d'ensemble. Null sur les evaluations anterieures aux rubriques v8.
  final ObjectifAccomplissement? objectif;

  /// Phrase courte adressee au candidat, qui dit ce qu'il a fait.
  final String? objectifResume;

  final List<AccomplissementPoint> pointsTraites;
  final List<AccomplissementPoint> pointsOublies;

  /// Vrai quand la check-list detaillee n'a rien a montrer. Le verdict, lui,
  /// se teste avec [hasObjectif] : il peut exister sans check-list.
  bool get isEmpty => pointsTraites.isEmpty && pointsOublies.isEmpty;

  bool get hasObjectif => objectif != null;

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

  factory Accomplissement.fromJson(Map<String, dynamic> json) =>
      Accomplissement(
        objectif: ObjectifAccomplissement.fromWireNullable(
          _trimmedOrNull(json['objectif']),
        ),
        objectifResume: _trimmedOrNull(json['objectif_resume']),
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
        // Absent/non booleen => obligatoire : on ne minimise jamais un manque.
        // Miroir web (`r.obligatoire !== false`) ; inatteignable si le champ
        // `required` du tool-schema v9 est respecte.
        obligatoire: json['obligatoire'] != false,
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

  factory CorrectionExample.fromJson(Map<String, dynamic> json) =>
      CorrectionExample(
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

  factory ProductionExampleDto.fromJson(Map<String, dynamic> json) =>
      ProductionExampleDto(
        id: json['id'] as String,
        titre: json['titre'] as String,
        resume: json['resume'] as String?,
        contenu: json['contenu'] as String,
        explications: json['explications'] as String?,
        audioUrl: json['audioUrl'] as String?,
        planPoints: ((json['planPoints'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        niveauIndicatif: json['niveauIndicatif'] as String?,
      );
}

/// Fourchette de note officielle du TCF IRN correspondant a un niveau CECRL, sur
/// les epreuves d'expression — miroir de CorrespondanceTcfDto.
///
/// Table officielle : 0 → A1 non atteint, 1 → A1, 2-5 → A2, 6-9 → B1,
/// 10-20 → B2. Nos notes sont des ESTIMATIONS exprimees sur cette MEME echelle :
/// la fourchette se lit directement, sans conversion — ce qui est officiel ici,
/// c'est l'echelle, pas la correction, qui reste la notre. A n'afficher qu'au
/// bilan d'une epreuve entiere — au TCF, une tache isolee n'a pas de note.
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
    return CorrespondanceTcf(
        niveau: niveau, scoreTcfMin: min, scoreTcfMax: max);
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

  factory ProductionBilan.fromJson(Map<String, dynamic> json) =>
      ProductionBilan(
        attemptId: json['attemptId'] as String,
        epreuve: EpreuveType.fromWire(json['epreuve'] as String),
        exam: json['exam'] as bool? ?? false,
        evaluatedCount: (json['evaluatedCount'] as num?)?.toInt() ?? 0,
        expectedCount: (json['expectedCount'] as num?)?.toInt() ?? 0,
        finished: json['finished'] as bool? ?? false,
        slotNumber: (json['slotNumber'] as num?)?.toInt(),
        moyenneSur20: (json['moyenneSur20'] as num?)?.toDouble(),
        niveauGlobal:
            NiveauCecrl.fromWireNullable(json['niveauGlobal'] as String?),
        correspondanceTcf:
            CorrespondanceTcf.fromJsonNullable(json['correspondanceTcf']),
      );
}
