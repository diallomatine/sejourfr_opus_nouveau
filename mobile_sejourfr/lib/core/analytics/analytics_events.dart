/// **Miroir Dart de l'allowlist serveur d'analytics.**
///
/// L'endpoint d'ingestion est public : le serveur borne donc les noms
/// d'événements ET les clés de propriétés, et refuse tout le reste en 400
/// nommé. Ce fichier est la copie fidèle de cette allowlist — il n'invente
/// aucune dimension, et un événement absent d'ici est un événement que le
/// mobile ne peut pas produire par construction.
///
/// 🛑 **`CHECKOUT_STARTED` n'y figure pas, et ne doit jamais y figurer** : il
/// est posé **serveur** par `BillingService` après création réelle du paiement.
/// Venant d'un client, ce serait une intention, pas un fait — le serveur le
/// refuse d'ailleurs en 422.
///
/// 🛑 **N'existent pas non plus comme événements** : inscription, paiement et
/// diagnostic terminé. Ils se lisent sur les vraies tables (`users`,
/// `user_subscriptions`, `diagnostic_sessions`). Un événement n'existe que pour
/// ce qui n'existe QUE dans l'application.
library;

enum AnalyticsEvent {
  landingViewed('LANDING_VIEWED'),
  diagnosticCtaClicked('DIAGNOSTIC_CTA_CLICKED'),
  pricingViewed('PRICING_VIEWED'),
  pricingCtaClicked('PRICING_CTA_CLICKED'),
  signupCtaClicked('SIGNUP_CTA_CLICKED'),
  loginClicked('LOGIN_CLICKED'),
  signupStarted('SIGNUP_STARTED'),
  diagnosticStarted('DIAGNOSTIC_STARTED'),
  diagnosticEeStarted('DIAGNOSTIC_EE_STARTED'),
  diagnosticEeCompleted('DIAGNOSTIC_EE_COMPLETED'),
  diagnosticEoStarted('DIAGNOSTIC_EO_STARTED'),
  diagnosticEoCompleted('DIAGNOSTIC_EO_COMPLETED'),
  diagnosticCoStarted('DIAGNOSTIC_CO_STARTED'),
  diagnosticCoCompleted('DIAGNOSTIC_CO_COMPLETED'),
  diagnosticCeStarted('DIAGNOSTIC_CE_STARTED'),
  diagnosticCeCompleted('DIAGNOSTIC_CE_COMPLETED'),
  diagnosticReportViewed('DIAGNOSTIC_REPORT_VIEWED'),
  premiumCtaClicked('PREMIUM_CTA_CLICKED'),

  /// L'écran qui demande un compte en fin de diagnostic invité, les deux
  /// productions déjà faites. **LA** mesure de conversion du parcours invité :
  /// ce n'est pas le même fait que `diagnosticEoCompleted`, entre les deux se
  /// joue la décision de créer un compte.
  diagnosticAccountRequired('DIAGNOSTIC_ACCOUNT_REQUIRED'),

  /// Ouverture de l'écran Plan. Ne sert aucun bloc d'écran : c'est une mesure
  /// d'usage, à ne pas perdre en migrant depuis l'ancien `page_views`.
  planOpened('PLAN_OPENED'),

  /// Lancement réel d'un exercice recommandé par le Plan — jamais émis pour un
  /// exercice verrouillé, qui ouvre l'offre au lieu de démarrer quoi que ce
  /// soit.
  planExerciseStarted('PLAN_EXERCISE_STARTED');

  const AnalyticsEvent(this.wire);

  final String wire;
}

/// D'où part un clic. Allowlist fermée côté serveur (`AnalyticsCtaLocation`).
enum AnalyticsCtaLocation {
  diagnosticReport('DIAGNOSTIC_REPORT'),
  lockedPlan('LOCKED_PLAN'),
  pricing('PRICING'),
  aiCorrection('AI_CORRECTION'),
  mockExam('MOCK_EXAM'),
  hero('HERO'),
  middle('MIDDLE'),
  sticky('STICKY'),
  footer('FOOTER'),
  other('OTHER');

  const AnalyticsCtaLocation(this.wire);

  final String wire;
}

/// La variante de diagnostic choisie. `UNKNOWN` quand le parcours n'en porte
/// pas — jamais une valeur inventée.
enum AnalyticsDiagnosticType {
  rapid('RAPID'),
  complete('COMPLETE'),
  unknown('UNKNOWN');

  const AnalyticsDiagnosticType(this.wire);

  final String wire;
}

/// Le contexte de création d'un compte. Une inscription faite dans
/// l'application vaut `MOBILE_APP` : c'est le seul contexte que le mobile
/// puisse constater honnêtement.
enum AnalyticsRegistrationContext {
  landing('LANDING'),
  beforeDiagnostic('BEFORE_DIAGNOSTIC'),
  duringDiagnostic('DURING_DIAGNOSTIC'),
  afterDiagnostic('AFTER_DIAGNOSTIC'),
  diagnosticReport('DIAGNOSTIC_REPORT'),
  pricing('PRICING'),
  mobileApp('MOBILE_APP'),
  other('OTHER');

  const AnalyticsRegistrationContext(this.wire);

  final String wire;
}

/// Clés de propriétés admises **par événement**. Miroir de l'allowlist
/// serveur : une clé hors liste fait refuser l'événement entier, donc on la
/// filtre ici plutôt que de perdre la mesure.
///
/// 🛑 Aucune de ces clés ne peut porter du texte de production, une
/// transcription, un e-mail, un jeton ou une coordonnée. L'allowlist le
/// garantit par construction — ne jamais l'élargir sans repasser sur la règle.
const Map<AnalyticsEvent, Set<String>> kAnalyticsPropertyKeys = {
  AnalyticsEvent.landingViewed: {'landingPath', 'landingVariant'},
  AnalyticsEvent.diagnosticCtaClicked: {'ctaLocation', 'diagnosticType'},
  AnalyticsEvent.pricingViewed: <String>{},
  AnalyticsEvent.pricingCtaClicked: {'planCode'},
  AnalyticsEvent.signupCtaClicked: {'ctaLocation'},
  AnalyticsEvent.loginClicked: <String>{},
  AnalyticsEvent.signupStarted: {'registrationContext'},
  AnalyticsEvent.diagnosticStarted: {'diagnosticType'},
  AnalyticsEvent.diagnosticEeStarted: {'diagnosticType'},
  AnalyticsEvent.diagnosticEeCompleted: {'diagnosticType'},
  AnalyticsEvent.diagnosticEoStarted: {'diagnosticType'},
  AnalyticsEvent.diagnosticEoCompleted: {'diagnosticType'},
  AnalyticsEvent.diagnosticCoStarted: {'diagnosticType'},
  AnalyticsEvent.diagnosticCoCompleted: {'diagnosticType'},
  AnalyticsEvent.diagnosticCeStarted: {'diagnosticType'},
  AnalyticsEvent.diagnosticCeCompleted: {'diagnosticType'},
  AnalyticsEvent.diagnosticReportViewed: {'diagnosticType'},
  AnalyticsEvent.premiumCtaClicked: {'ctaLocation', 'planCode', 'screen'},
  AnalyticsEvent.diagnosticAccountRequired: {'diagnosticType'},
  AnalyticsEvent.planOpened: <String>{},
  AnalyticsEvent.planExerciseStarted: {'exerciseKind'},
};

/// Chemins admis par le serveur. Le mobile n'a pas d'URL, mais ses écrans ont
/// un équivalent web exact : c'est **cet** équivalent qu'on envoie, pour que le
/// même écran se compte du même côté des deux plateformes.
///
/// 🛑 **L'allowlist est fermée côté serveur** (`util/AnalyticsPaths`) : un
/// chemin non déclaré est refusé en 400 nommé, jamais rangé en « autre ».
/// Ajouter un écran suivi, c'est ajouter une ligne des deux côtés dans la même
/// passe. `null` est un cas normal : un écran non suivi n'invente pas de chemin.
class AnalyticsPath {
  const AnalyticsPath._();

  static const String diagnostic = '/diagnostic';
  static const String plan = '/plan';

  /// L'écran paywall natif. Déclaré côté serveur dans la section « Mobile »
  /// d'`AnalyticsPaths` : il n'a pas d'URL, mais il a une place dans le
  /// tableau, à côté du `/paiement` du web.
  static const String paywall = '/paywall';
}
