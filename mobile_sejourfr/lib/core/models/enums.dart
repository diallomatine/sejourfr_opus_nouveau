/// Mappings 1-1 avec les enums Java du backend.
/// On garde des string raw pour faciliter (de)serialization et matchs réseau.

enum AppModule {
  civique('CIVIQUE'),
  tcf('TCF');

  const AppModule(this.wire);
  final String wire;

  static AppModule fromWire(String value) =>
      AppModule.values.firstWhere((e) => e.wire == value);
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

  /// Niveau TCF requis pour cette procédure.
  String get tcfLevel => switch (this) {
        TargetProcedure.csp => 'A2',
        TargetProcedure.cr => 'B1',
        TargetProcedure.nat => 'B2',
      };
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

  bool get isProduction => this == EpreuveType.tcfEo || this == EpreuveType.tcfEe;
  bool get isAudio => this == EpreuveType.tcfEo;
  bool get isWriting => this == EpreuveType.tcfEe;
}

/// Niveau CECRL renvoyé par l'évaluation IA EO/EE. Distinct de `TargetLevel`
/// qui représente le palier visé par l'utilisateur (limité à A2/B1/B2).
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

  /// Index 0..5 pour positionner un curseur sur la barre A1→C2.
  int get scaleIndex => switch (this) {
        NiveauCecrl.a1NonAtteint || NiveauCecrl.a1 => 0,
        NiveauCecrl.a2 => 1,
        NiveauCecrl.b1 => 2,
        NiveauCecrl.b2 => 3,
        NiveauCecrl.c1 => 4,
        NiveauCecrl.c2 => 5,
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

  bool get isFinal => this == SubmissionStatut.evaluated || this == SubmissionStatut.failed;
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
}
