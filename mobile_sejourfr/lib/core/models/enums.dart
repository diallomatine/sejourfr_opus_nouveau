// Mappings 1-1 avec les enums Java du backend.
// On garde des string raw pour faciliter (de)serialization et matchs réseau.

enum AppModule {
  civique('CIVIQUE'),
  tcf('TCF');

  const AppModule(this.wire);
  final String wire;

  static AppModule fromWire(String value) =>
      AppModule.values.firstWhere((e) => e.wire == value);
}

/// Moyen par lequel un compte a ete cree cote backend. Renvoye par
/// `/api/auth/me` et present dans le user retourne au login.
enum AuthProvider {
  local('LOCAL'),
  google('GOOGLE'),
  apple('APPLE');

  const AuthProvider(this.wire);
  final String wire;

  static AuthProvider fromWire(String value) => AuthProvider.values.firstWhere(
        (e) => e.wire == value,
        orElse: () => AuthProvider.local,
      );
}

enum Difficulty {
  csp('CSP'),
  cr('CR'),
  nat('NAT'),
  a2('A2'),
  b1('B1'),
  b2('B2');

  const Difficulty(this.wire);
  final String wire;

  static Difficulty fromWire(String value) =>
      Difficulty.values.firstWhere((e) => e.wire == value);

  /// Niveaux de mention civique.
  static const civique = [csp, cr, nat];

  /// Niveaux TCF.
  static const tcf = [a2, b1, b2];
}

enum QuestionType {
  connaissance('CONNAISSANCE'),
  miseSituation('MISE_SITUATION'),
  co('CO'),
  coImage('CO_IMAGE'),
  ce('CE'),
  structure('STRUCTURE');

  const QuestionType(this.wire);
  final String wire;

  static QuestionType fromWire(String value) =>
      QuestionType.values.firstWhere((e) => e.wire == value);

  String get displayLabel {
    switch (this) {
      case QuestionType.connaissance:
        return 'Connaissance';
      case QuestionType.miseSituation:
        return 'Mise en situation';
      case QuestionType.co:
        return 'Compréhension orale';
      case QuestionType.coImage:
        return 'Compréhension orale (image)';
      case QuestionType.ce:
        return 'Compréhension écrite';
      case QuestionType.structure:
        return 'Structure de la langue';
    }
  }
}

enum MediaType {
  audio('AUDIO'),
  image('IMAGE'),
  video('VIDEO');

  const MediaType(this.wire);
  final String wire;

  static MediaType fromWire(String value) =>
      MediaType.values.firstWhere((e) => e.wire == value);
}

/// Parcours administratif visé par l'utilisateur.
/// - CSP : Carte de séjour pluriannuelle (niveau TCF A2)
/// - CR  : Carte de résident (niveau TCF B1)
/// - NAT : Naturalisation française (niveau TCF B2)
enum TargetProcedure {
  csp('CSP'),
  cr('CR'),
  nat('NAT');

  const TargetProcedure(this.wire);
  final String wire;

  static TargetProcedure fromWire(String value) =>
      TargetProcedure.values.firstWhere((e) => e.wire == value);

  /// Libellé court "Carte de séjour", "Carte de résident", "Naturalisation".
  String get shortLabel => switch (this) {
        TargetProcedure.csp => 'Carte de séjour',
        TargetProcedure.cr => 'Carte de résident',
        TargetProcedure.nat => 'Naturalisation',
      };

  /// Libellé complet pour affichage profil.
  String get fullLabel => switch (this) {
        TargetProcedure.csp => 'Carte de séjour pluriannuelle',
        TargetProcedure.cr => 'Carte de résident',
        TargetProcedure.nat => 'Naturalisation française',
      };

  /// **Le palier de français que cette démarche exige.**
  ///
  /// Seuils en vigueur au 1ᵉʳ janvier 2026 : CSP → A2, CR → B1, NAT → B2.
  /// Donnée légale de trois lignes, pas un réglage — miroir **gelé par test**
  /// (`test/target_level_test.dart`) de l'enum `TargetProcedure` côté backend,
  /// comme `skill_models_test.dart` l'est des libellés Compétences.
  ///
  /// ⚠️ Ne jamais réécrire cette table dans un écran.
  TargetLevel get requiredLevel => switch (this) {
        TargetProcedure.csp => TargetLevel.a2,
        TargetProcedure.cr => TargetLevel.b1,
        TargetProcedure.nat => TargetLevel.b2,
      };

  /// Forme courte affichable du palier exigé. Dérive de [requiredLevel] : une
  /// seule table, pas deux qui pourraient diverger.
  String get tcfLevel => requiredLevel.wire;

  /// **Le palier réellement VISÉ** : le plus haut entre ce que la démarche
  /// exige et ce que le candidat a déclaré viser. Miroir de
  /// `TargetProcedure.niveauVise` côté backend et de `niveauViseTcf` côté web.
  ///
  /// La démarche fait **plancher**, jamais plafond :
  /// - `nat` + `b1` déclaré ⇒ **b2** (la naturalisation en demande un de plus :
  ///   le féliciter d'avoir « atteint son objectif » à B1 ne le tirerait jamais
  ///   vers le niveau dont il a besoin) ;
  /// - `csp` + `b2` déclaré ⇒ **b2** (viser plus haut est un choix légitime) ;
  /// - démarche absente ⇒ le niveau déclaré seul ; les deux absents ⇒ `null`,
  ///   et l'appelant décide de son repli. On ne devine jamais une démarche.
  ///
  /// Comparaison sur l'**index CECRL** (l'ordre de déclaration de
  /// [TargetLevel]), jamais sur l'ordre alphabétique.
  static TargetLevel? niveauVise(
    TargetProcedure? procedure,
    TargetLevel? declare,
  ) {
    if (procedure == null) return declare;
    final exige = procedure.requiredLevel;
    if (declare == null) return exige;
    return declare.index > exige.index ? declare : exige;
  }
}

enum UserRole {
  user('USER'),
  admin('ADMIN');

  const UserRole(this.wire);
  final String wire;

  static UserRole fromWire(String value) =>
      UserRole.values.firstWhere((e) => e.wire == value);
}

/// Granularité fine d'une attempt côté backend (orthogonale à `AppModule`).
/// Le mobile en exploite surtout `tcfEo` et `tcfEe` pour les épreuves productives.
enum EpreuveType {
  civique('CIVIQUE'),
  tcfCo('TCF_CO'),
  tcfCe('TCF_CE'),
  tcfStructure('TCF_STRUCTURE'),
  tcfEo('TCF_EO'),
  tcfEe('TCF_EE'),
  tcfComplet('TCF_COMPLET');

  const EpreuveType(this.wire);
  final String wire;

  static EpreuveType fromWire(String value) =>
      EpreuveType.values.firstWhere((e) => e.wire == value);

  bool get isProduction =>
      this == EpreuveType.tcfEo || this == EpreuveType.tcfEe;
  bool get isAudio => this == EpreuveType.tcfEo;
  bool get isWriting => this == EpreuveType.tcfEe;
}

/// Niveau CECRL renvoyé par l'évaluation IA EO/EE. Le contrat TCF IRN actif
/// s'arrête à B2 ; C1/C2 sont conservés uniquement pour décoder l'historique.
enum NiveauCecrl {
  a1NonAtteint('A1_NON_ATTEINT'),
  a1('A1'),
  a2('A2'),
  b1('B1'),
  b2('B2'),
  c1('C1'),
  c2('C2');

  const NiveauCecrl(this.wire);
  final String wire;

  static NiveauCecrl fromWire(String value) =>
      NiveauCecrl.values.firstWhere((e) => e.wire == value);

  static NiveauCecrl? fromWireNullable(String? value) =>
      value == null ? null : fromWire(value);

  String get displayName => switch (this) {
        NiveauCecrl.a1NonAtteint => 'A1 non atteint',
        NiveauCecrl.a1 => 'A1',
        NiveauCecrl.a2 => 'A2',
        NiveauCecrl.b1 => 'B1',
        NiveauCecrl.b2 => 'B2',
        NiveauCecrl.c1 => 'C1',
        NiveauCecrl.c2 => 'C2',
      };

  /// Forme courte pour les pastilles et badges étroits. `A1_NON_ATTEINT` se
  /// rend **« <A1 »** : le tronquer en « A1 » annoncerait au candidat un
  /// niveau qu'il n'a justement pas atteint. Helper canonique — tout écran qui
  /// affiche un niveau dans un badge passe par ici, jamais par un `switch`
  /// local ni par un `replaceAll(' non atteint', '')`.
  String get shortName => switch (this) {
        NiveauCecrl.a1NonAtteint => '<A1',
        NiveauCecrl.a1 => 'A1',
        NiveauCecrl.a2 => 'A2',
        NiveauCecrl.b1 => 'B1',
        NiveauCecrl.b2 => 'B2',
        NiveauCecrl.c1 => 'C1',
        NiveauCecrl.c2 => 'C2',
      };

  /// Index 0..3 sur la barre TCF IRN A1→B2. Les valeurs historiques C1/C2
  /// sont rabattues sur le plafond B2.
  int get scaleIndex => switch (this) {
        NiveauCecrl.a1NonAtteint || NiveauCecrl.a1 => 0,
        NiveauCecrl.a2 => 1,
        NiveauCecrl.b1 => 2,
        NiveauCecrl.b2 => 3,
        NiveauCecrl.c1 || NiveauCecrl.c2 => 3,
      };

  /// Rang du palier sur l'échelle du TCF IRN (0 = A1 non atteint … 4 = B2),
  /// **cinq crans distincts** — contrairement à [scaleIndex], qui dessine une
  /// barre à quatre libellés et confond donc « A1 » et « A1 non atteint ».
  ///
  /// C'est lui qui situe le palier atteint sur la barre du rapport de tâche et
  /// qui compare le niveau obtenu au niveau exigé par la démarche du candidat.
  /// Miroir de `tcfPalierIndex` côté web (`lib/production-feedback.ts`).
  int get tcfPalierIndex => switch (this) {
        NiveauCecrl.a1NonAtteint => 0,
        NiveauCecrl.a1 => 1,
        NiveauCecrl.a2 => 2,
        NiveauCecrl.b1 => 3,
        NiveauCecrl.b2 || NiveauCecrl.c1 || NiveauCecrl.c2 => 4,
      };
}

/// Les cinq paliers du TCF IRN, dans l'ordre. C'est la suite affichée par la
/// barre de niveau du rapport de tâche : elle situe un **palier**, jamais une
/// note. Miroir de `TCF_NOTE_BANDS` côté web.
const List<NiveauCecrl> kTcfPaliers = [
  NiveauCecrl.a1NonAtteint,
  NiveauCecrl.a1,
  NiveauCecrl.a2,
  NiveauCecrl.b1,
  NiveauCecrl.b2,
];

/// Degré de certitude d'une évaluation IA (contrat de notation v4). Un niveau
/// par tâche n'est JAMAIS affiché sans sa confiance à côté.
enum ConfianceEvaluation {
  haute('HAUTE'),
  moyenne('MOYENNE'),
  faible('FAIBLE');

  const ConfianceEvaluation(this.wire);
  final String wire;

  static ConfianceEvaluation? fromWireNullable(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toUpperCase();
    for (final c in ConfianceEvaluation.values) {
      if (c.wire == normalized) return c;
    }
    return null;
  }

  String get displayName => switch (this) {
        ConfianceEvaluation.haute => 'confiance haute',
        ConfianceEvaluation.moyenne => 'confiance moyenne',
        ConfianceEvaluation.faible => 'confiance faible',
      };
}

/// Où se situe une production **à l'intérieur de son propre palier**, en trois
/// crans. Dérivé serveur (`SituationDansNiveau` côté Java), jamais recalculé
/// ici — les bornes de bande viennent de la grille de notation active.
///
/// C'est ce qui remplace, sur le résultat d'une TÂCHE, la note /20 qui n'y est
/// plus affichée : sans lui, un A2 à 2 et un A2 à 5 voyaient exactement le même
/// écran, et le candidat n'avait plus aucun signal de progression entre deux
/// tentatives.
///
/// Absent (null) sur les évaluations antérieures, sur `A1_NON_ATTEINT` (bande
/// d'une seule valeur) et sur C1/C2 (hors profil TCF IRN).
enum SituationDansNiveau {
  entreeDePalier('ENTREE_DE_PALIER'),
  palierConfirme('PALIER_CONFIRME'),
  palierSolide('PALIER_SOLIDE');

  const SituationDansNiveau(this.wire);
  final String wire;

  static SituationDansNiveau? fromWireNullable(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toUpperCase();
    for (final s in SituationDansNiveau.values) {
      if (s.wire == normalized) return s;
    }
    return null;
  }
}

/// Bande qualitative d'un critère, calculée côté serveur depuis sa note /20.
/// Les fronts affichent la bande, plus le nombre : une IA ne distingue pas
/// honnêtement un 13 d'un 14.
/// Absente des évaluations antérieures au contrat v4.
enum BandeCritere {
  tresBonneMaitrise('TRES_BONNE_MAITRISE'),
  satisfaisant('SATISFAISANT'),
  enCoursAcquisition('EN_COURS_ACQUISITION'),
  fragile('FRAGILE'),
  nonEvaluable('NON_EVALUABLE');

  const BandeCritere(this.wire);
  final String wire;

  static BandeCritere? fromWireNullable(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toUpperCase();
    for (final b in BandeCritere.values) {
      if (b.wire == normalized) return b;
    }
    return null;
  }

  /// Le **palier atteint sur ce critère**, pas un déficit.
  ///
  /// Les bornes des bandes (10 / 6 / 2) sont exactement celles des paliers du
  /// TCF. Conséquence structurelle du vocabulaire précédent (« En cours
  /// d'acquisition », « Fragile ») : la bande d'un candidat A2 était son niveau
  /// CECRL renommé en échec, et **aucune production ne pouvait lui faire
  /// afficher autre chose**. On nomme donc la bande par ce qu'elle est.
  ///
  /// ⚠️ Contrat gelé, écrit à la main sur les deux fronts (le réseau ne
  /// transporte que l'enum) : miroir mot pour mot de `bandeCritereLabel`
  /// (`web_sejoufr/lib/types.ts`), verrouillé des deux côtés par test.
  String get displayName => switch (this) {
        BandeCritere.tresBonneMaitrise => 'Niveau B2',
        BandeCritere.satisfaisant => 'Niveau B1',
        BandeCritere.enCoursAcquisition => 'Niveau A2',
        BandeCritere.fragile => 'Niveau A1',
        BandeCritere.nonEvaluable => 'Non évaluable',
      };

  /// Remplissage 0..1 de la barre du critère (5 crans, pas une note).
  double get fillRatio => switch (this) {
        BandeCritere.tresBonneMaitrise => 1.0,
        BandeCritere.satisfaisant => 0.75,
        BandeCritere.enCoursAcquisition => 0.5,
        BandeCritere.fragile => 0.25,
        BandeCritere.nonEvaluable => 0.0,
      };
}

/// Verdict d'accomplissement de la tâche (rubriques v8) : la question que le
/// candidat se pose en premier — « est-ce que j'ai fait ce qu'on me demandait ? ».
/// Absent des évaluations antérieures : le bloc disparaît alors entièrement,
/// il n'y a rien à deviner.
enum ObjectifAccomplissement {
  atteint('ATTEINT'),
  partiellementAtteint('PARTIELLEMENT_ATTEINT'),
  nonAtteint('NON_ATTEINT');

  const ObjectifAccomplissement(this.wire);
  final String wire;

  static ObjectifAccomplissement? fromWireNullable(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toUpperCase();
    for (final o in ObjectifAccomplissement.values) {
      if (o.wire == normalized) return o;
    }
    return null;
  }

  String get displayName => switch (this) {
        ObjectifAccomplissement.atteint => 'Atteint',
        ObjectifAccomplissement.partiellementAtteint => 'Partiellement atteint',
        ObjectifAccomplissement.nonAtteint => 'Non atteint',
      };
}

/// Cycle de vie d'une `production_submissions` côté backend.
enum SubmissionStatut {
  submitted('SUBMITTED'),
  transcribing('TRANSCRIBING'),
  evaluating('EVALUATING'),
  evaluated('EVALUATED'),
  failed('FAILED');

  const SubmissionStatut(this.wire);
  final String wire;

  static SubmissionStatut fromWire(String value) =>
      SubmissionStatut.values.firstWhere((e) => e.wire == value);

  bool get isFinal =>
      this == SubmissionStatut.evaluated || this == SubmissionStatut.failed;
  bool get isInProgress => !isFinal;
}

/// Niveau CECRL atteint en TCF, calculé côté backend à la finalisation
/// d'un examen blanc TCF (taux de bonnes réponses ≥ 60 % sur la strate).
enum TargetLevel {
  a2('A2'),
  b1('B1'),
  b2('B2');

  const TargetLevel(this.wire);
  final String wire;

  static TargetLevel? fromWireNullable(String? value) {
    if (value == null) return null;
    return TargetLevel.values.firstWhere((e) => e.wire == value);
  }

  /// Le même palier, lu sur l'échelle des niveaux évalués : c'est ce qui permet
  /// de comparer « ce que la démarche exige » à « ce que la production vaut ».
  NiveauCecrl get asNiveau => switch (this) {
        TargetLevel.a2 => NiveauCecrl.a2,
        TargetLevel.b1 => NiveauCecrl.b1,
        TargetLevel.b2 => NiveauCecrl.b2,
      };

  /// Ce que ce palier ouvre comme démarche. Seuils en vigueur au
  /// 1ᵉʳ janvier 2026. Miroir de `DEMARCHE_PAR_NIVEAU` côté web.
  String get demarcheLabel => switch (this) {
        TargetLevel.a2 => 'la carte de séjour pluriannuelle',
        TargetLevel.b1 => 'la carte de résident',
        TargetLevel.b2 => 'la naturalisation',
      };
}
