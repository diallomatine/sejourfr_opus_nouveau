import '../router/app_router.dart';

/// Les écrans métier suivis par `SCREEN_VIEWED` — **le seul endroit de l'app
/// où ils sont déclarés**. Miroir de `web_sejoufr/lib/tracked-screens.ts`
/// (mêmes clés) et de `enums/TrackedScreen.java` côté serveur, qui fait
/// autorité et alimente `AnalyticsPaths.KNOWN`.
///
/// [path] est le chemin suivi côté app (colonne « app » du contrat), en
/// minuscules : jamais l'adresse concrète, jamais un identifiant. [routes]
/// sont les **gabarits go_router** (`GoRouterState.fullPath`) qui y mènent.
/// Un écran sans équivalent dans l'app garde la clé, sans chemin ni route.
///
/// Une route absente de la table part avec `path: null` (« écran non
/// déclaré »). Ajouter un écran = une ligne ici, une dans le fichier web et une
/// dans `TrackedScreen`, dans la même passe.
enum TrackedScreen {
  vitrine('VITRINE', null, []),
  landingReussir('LANDING_REUSSIR', null, []),
  accueil('ACCUEIL', '/home', [AppRoutes.home]),
  connexion('CONNEXION', '/login', [AppRoutes.login]),
  inscription('INSCRIPTION', '/register', [AppRoutes.register]),
  diagnosticTcf('DIAGNOSTIC_TCF', '/diagnostic', [AppRoutes.diagnostic]),
  diagnosticTcfResultat('DIAGNOSTIC_TCF_RESULTAT', null, []),
  diagnosticCivique(
    'DIAGNOSTIC_CIVIQUE',
    '/diagnostic-civique',
    [AppRoutes.civicDiagnostic],
  ),
  diagnosticCiviqueResultat(
    'DIAGNOSTIC_CIVIQUE_RESULTAT',
    '/diagnostic-civique/resultat',
    [AppRoutes.civicDiagnosticResult],
  ),
  plan('PLAN', '/plan', [AppRoutes.plan]),
  planEtape('PLAN_ETAPE', '/plan/etape/:id', [AppRoutes.planEtape]),
  planDomaine('PLAN_DOMAINE', '/plan/domaine/:domaine', [AppRoutes.planDomain]),
  planDebloquer('PLAN_DEBLOQUER', '/plan/debloquer', [AppRoutes.planUnlock]),
  planProgression(
    'PLAN_PROGRESSION',
    '/plan/progression',
    [AppRoutes.planProgress],
  ),
  progressionTcf('PROGRESSION_TCF', '/progression/tcf', [AppRoutes.progressionTcf]),
  progressionTcfEpreuve(
    'PROGRESSION_TCF_EPREUVE',
    '/progression/tcf/:epreuve',
    [AppRoutes.progressionEpreuve],
  ),
  progressionCivique(
    'PROGRESSION_CIVIQUE',
    '/progression/civique',
    [AppRoutes.progressionCivique],
  ),
  progressionCiviqueTheme(
    'PROGRESSION_CIVIQUE_THEME',
    '/progression/civique/:theme',
    [AppRoutes.progressionTheme],
  ),
  reviser('REVISER', '/reviser', [AppRoutes.reviser]),
  themeCivique(
    'THEME_CIVIQUE',
    '/civique/theme/:theme',
    [AppRoutes.civiqueThemeDetail],
  ),
  epreuveTcf('EPREUVE_TCF', '/tcf/:epreuve', [
    AppRoutes.tcfCoDetail,
    AppRoutes.tcfCeDetail,
    AppRoutes.tcfStructureDetail,
  ]),
  lotsNiveau(
    'LOTS_NIVEAU',
    '/tcf/:epreuve/niveau/:niveau',
    [AppRoutes.tcfLevelLots],
  ),
  eeHub('EE_HUB', '/tcf/ee', [AppRoutes.tcfEeEntry]),
  eoHub('EO_HUB', '/tcf/eo', [AppRoutes.tcfEoEntry]),
  eeTache('EE_TACHE', '/tcf/ee/tache/:tache', [AppRoutes.tcfEeTaskTraining]),
  eoTache('EO_TACHE', '/tcf/eo/tache/:tache', [AppRoutes.tcfEoTaskTraining]),
  competencesTache(
    'COMPETENCES_TACHE',
    '/tcf/:epreuve/tache/:tache/competences',
    [AppRoutes.tcfCompetences],
  ),
  seanceQcm('SEANCE_QCM', '/runner/:id', [AppRoutes.runner]),
  resultatEe(
    'RESULTAT_EE',
    '/tcf/expression-ecrite/resultats/:id',
    ['${AppRoutes.tcfExpressionEcrite}/resultats/:submissionId'],
  ),
  resultatEo(
    'RESULTAT_EO',
    '/tcf/expression-orale/resultats/:id',
    ['${AppRoutes.tcfExpressionOrale}/resultats/:submissionId'],
  ),
  examensBlancs('EXAMENS_BLANCS', '/examens', [AppRoutes.examens]),
  examenTcf(
    'EXAMEN_TCF',
    '/tcf/examen-blanc/:id',
    [AppRoutes.tcfFullExamProgress],
  ),
  examenTcfBilan(
    'EXAMEN_TCF_BILAN',
    '/tcf/examen-blanc/:id/bilan',
    [AppRoutes.tcfFullExamBilan],
  ),
  tarifs('TARIFS', null, []),
  paiement('PAIEMENT', null, []),
  profil('PROFIL', '/profile', [AppRoutes.profile]);

  const TrackedScreen(this.key, this.path, this.routes);

  /// La clé partagée avec le web et le serveur.
  final String key;
  final String? path;
  final List<String> routes;

  static final Map<String, String> _pathByRoute = {
    for (final screen in values)
      if (screen.path != null)
        for (final route in screen.routes) route: screen.path!,
  };

  /// Chemin suivi du gabarit go_router [route], ou `null` (écran non déclaré).
  static String? pathForRoute(String route) => _pathByRoute[route];
}
