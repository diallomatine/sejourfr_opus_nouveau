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

enum UserRole {
  user('USER'),
  admin('ADMIN');

  const UserRole(this.wire);
  final String wire;

  static UserRole fromWire(String value) =>
      UserRole.values.firstWhere((e) => e.wire == value);
}
