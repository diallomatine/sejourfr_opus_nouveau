import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sejourfr_mobile/core/router/route_observer.dart';
import 'package:sejourfr_mobile/screens/exam/exam_report_screen.dart';
import 'package:sejourfr_mobile/screens/exam/exam_result_screen.dart';

import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/diagnostic/diagnostic_rapport_screen.dart';
import '../../screens/diagnostic/diagnostic_reponse_screen.dart';
import '../../screens/diagnostic/diagnostic_transition_screen.dart';
import '../../screens/diagnostic/diagnostic_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/module_detail/civique_theme_detail_screen.dart';
import '../../screens/module_detail/civique_theme_exams_screen.dart';
import '../../screens/module_detail/tcf_level_lots_screen.dart';
import '../../screens/module_detail/tcf_lot_result_screen.dart';
import '../../screens/tcf_production/competences/competence_detail_screen.dart';
import '../../screens/tcf_production/competences/competences_screen.dart';
import '../../screens/tcf_production/competences/competence_prompt_screen.dart';
import '../../screens/tcf_production/competences/competence_result_screen.dart';
import '../../screens/tcf_production/production_exams_screen.dart';
import '../../screens/tcf_production/production_task_screen.dart';
import '../../screens/tcf_production/production_tasks_screen.dart';
import '../../screens/tcf_production/tcf_task_examples_screen.dart';
import '../../screens/tcf_production/tcf_production_module.dart';
import '../../screens/module_detail/tcf_qcm_detail_screen.dart';
import '../../screens/module_detail/tcf_qcm_exams_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/help/about_screen.dart';
import '../../screens/help/contact_screen.dart';
import '../../screens/help/help_center_screen.dart';
import '../../screens/help/in_app_webview_screen.dart';
import '../../screens/profile/manage_subscription_screen.dart';
import '../../screens/profile/change_email_screen.dart';
import '../../screens/profile/change_password_screen.dart';
import '../../screens/profile/edit_identity_screen.dart';
import '../../screens/profile/notifications_screen.dart';
import '../../screens/profile/personal_info_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/plan/plan_domain_screen.dart';
import '../../screens/plan/plan_etape_screen.dart';
import '../../screens/plan/plan_labels.dart';
import '../../screens/plan/plan_cycle_archive_screen.dart';
import '../../screens/plan/plan_history_screen.dart';
import '../../screens/plan/plan_unlock_labels.dart';
import '../../screens/plan/plan_unlock_screen.dart';
import '../../screens/plan/plan_serie_result_screen.dart';
import '../../screens/plan/plan_step_labels.dart';
import '../../screens/diagnostic_civique/civic_diagnostic_screen.dart';
import '../../screens/diagnostic_civique/civic_diagnostic_result_screen.dart';
import '../../screens/question_runner/runner_screen.dart';
import '../../screens/favoris/mes_favoris_screen.dart';
import '../../screens/module/module_screen.dart';
import '../../screens/shell/main_shell.dart';
import '../../screens/progression/progression_civique_screen.dart';
import '../../screens/progression/progression_epreuve_screen.dart';
import '../../screens/progression/progression_tcf_screen.dart';
import '../../screens/progression/progression_theme_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/target_path/target_path_screen.dart';
import '../../screens/tcf_full_exam/tcf_full_exam_bilan_screen.dart';
import '../../screens/tcf_full_exam/tcf_full_exam_progress_screen.dart';
import '../../screens/tcf_production/ee_briefing_writing_screen.dart';
import '../../screens/tcf_production/ee_results_screen.dart';
import '../../screens/tcf_production/eo_briefing_screen.dart';
import '../../screens/tcf_production/eo_results_screen.dart';
import '../../screens/tcf_production/history_session_screen.dart';
import '../../screens/tcf_production/realtime/realtime_eo_controller.dart';
import '../../screens/tcf_production/realtime/realtime_eo_screen.dart';
import '../analytics/analytics.dart';
import '../analytics/diagnostic_run_tracker.dart';
import '../analytics/screen_view_tracker.dart';
import '../auth/auth_controller.dart';
import '../models/diagnostic_run_models.dart';
import '../models/enums.dart';
import '../models/skill_models.dart';
import 'shell_navigation.dart';

/// Routes nommées centralisées (utilisées par les écrans).
class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/';

  /// **Anciennes adresses des onglets** de la refonte 2026 (Réviser, Examens),
  /// supprimés par Navigation v2 : elles ne portent plus d'écran et
  /// **redirigent** vers le segment TCF — un lien déjà émis aboutit.
  static const reviser = '/reviser';
  static const examens = '/examens';

  /// **Les écrans de module** (Navigation v2, 2026-10-03) — racines des
  /// onglets TCF et Civique, un segment par sous-route. `/tcf` et `/civique`
  /// mènent au segment Plan.
  static const tcfPlan = '/tcf/plan';
  static const tcfEntrainement = '/tcf/entrainement';
  static const tcfExamens = '/tcf/examens';
  static const civiquePlan = '/civique/plan';
  static const civiqueEntrainement = '/civique/entrainement';
  static const civiqueExamens = '/civique/examens';

  static String modulePlan({required bool civique}) =>
      civique ? civiquePlan : tcfPlan;
  static String moduleEntrainement({required bool civique}) =>
      civique ? civiqueEntrainement : tcfEntrainement;
  static String moduleExamens({required bool civique}) =>
      civique ? civiqueExamens : tcfExamens;

  static const civique = '/civique';

  /// Ancienne page plein écran des examens blancs civiques GLOBAUX : elle
  /// **redirige** vers le segment Examens du module Civique (X10).
  static const civiqueExamsBlanc = '/civique/examens-blancs';
  static const civiqueThemeDetail = '/civique/theme/:themeId';
  // Page « Examens blancs » d'un thème civique (10 slots de 20 Q / 20 min /
  // seuil 16). Pushée depuis le hero rouge du détail thème et, depuis le
  // 2026-09-19, depuis la ligne d'un thème sur l'Accueil (« Voir mes
  // résultats »).
  static const civiqueThemeExams = '/civique/theme/:themeId/examens';

  /// 🛑 **Un seul endroit substitue `:themeId`.** Le `replaceFirst` s'écrivait
  /// à la main chez chaque appelant ; à la 2ᵉ surface, on extrait. Miroir web :
  /// `civicThemeExamsHref` (`lib/themes.ts`).
  static String civiqueThemeExamsPath(String themeId) =>
      '/civique/theme/$themeId/examens';
  static const tcf = '/tcf';
  static const tcfCoDetail = '/tcf/co';
  static const tcfCeDetail = '/tcf/ce';
  static const tcfStructureDetail = '/tcf/structure';
  // Sous-routes des hubs QCM (CO, CE, Structure) : examens blancs.
  static const tcfCoExams = '/tcf/co/examens';
  static const tcfCeExams = '/tcf/ce/examens';
  static const tcfStructureExams = '/tcf/structure/examens';

  /// **Entrée d'une épreuve d'Expression** (depuis Réviser, l'Accueil ou le
  /// Plan) : la **liste de ses trois tâches**, niveau 1 du
  /// parcours. C'est aussi la « racine de l'épreuve » sur laquelle retombent
  /// les écrans de résultats et de bilan quand la pile est vide. Littéral,
  /// sans paramètre : c'est l'épreuve entière.
  static const tcfEoEntry = '/tcf/eo';
  static const tcfEeEntry = '/tcf/ee';

  /// Niveau 2 : **une** tâche et ses deux onglets (Compétences · Sujets
  /// d'examen). Ouvre sur les compétences ; `tcfCompetences` est la forme
  /// explicite du même onglet, celle que le Plan emprunte.
  static const tcfEoTaskTraining = '/tcf/eo/tache/:tacheNumero';
  static const tcfEeTaskTraining = '/tcf/ee/tache/:tacheNumero';

  // Modèles corrigés d'une tâche. Ils ne sont plus un onglet de l'écran
  // d'entraînement : ils ont leur écran, atteint par le bouton posé au-dessus
  // de la liste des sujets.
  static const tcfTaskExamples = '/tcf/:moduleKey/tache/:tacheNumero/exemples';

  // Compétences TCF : entraînement d'un critère à la fois sur de petits
  // sujets, à côté (et jamais à la place) des sujets TCF complets.
  // moduleKey ∈ {ee, eo}. 🛑 `tcfCompetences` (les 8 compétences d'une tâche)
  // ne s'atteint plus que DEPUIS LE PLAN : l'écran d'une tâche n'a plus
  // d'onglet « Compétences » (2026-09-20).
  static const tcfCompetences =
      '/tcf/:moduleKey/tache/:tacheNumero/competences';
  static const tcfCompetenceDetail = '/tcf/:moduleKey/competences/:skillId';
  static const tcfCompetencePrompt =
      '/tcf/:moduleKey/competences/:skillId/sujet/:promptId';
  static const tcfCompetenceResult =
      '/tcf/:moduleKey/competences/resultat/:attemptId';

  /// Ancienne page plein écran des examens blancs TCF complets : elle
  /// **redirige** vers le segment Examens du module TCF (X10).
  static const tcfFullExams = '/tcf/examens-blancs';

  // Hub de progression d'un examen blanc complet en cours (4 étapes).
  // Push après création du parent via POST /api/full-tcf-exams.
  static const tcfFullExamProgress = '/tcf/examen-blanc/:parentId';

  // Bilan final agrégé (niveau CECRL plancher + détail des 4 épreuves).
  static const tcfFullExamBilan = '/tcf/examen-blanc/:parentId/bilan';

  static String tcfFullExamBilanPath(String parentId) =>
      '/tcf/examen-blanc/$parentId/bilan';

  // Liste des lots pour un niveau d'un module TCF QCM.
  // moduleKey ∈ {co, ce}, level ∈ {a2, b1, b2}.
  static const tcfLevelLots = '/tcf/:moduleKey/niveau/:level';

  // Bilan affiché à la fin d'un lot TCF QCM. Push par le runner avec
  // moduleKey + level en query pour reconstruire le retour.
  static const tcfLotResult = '/tcf/lot-result/:attemptId';
  static const runner = '/runner/:attemptId';
  static const diagnostic = '/diagnostic';

  /// **La relecture d'un diagnostic TCF CLOS**, par son identifiant — la
  /// destination de « Mon diagnostic » du Plan. Jamais [diagnostic], qui lit
  /// la session COURANTE. Miroir web : `diagnosticRapportHref`.
  static const diagnosticRapport = '/diagnostic/rapport/:sessionId';

  static String diagnosticRapportPath(String sessionId) =>
      '/diagnostic/rapport/${Uri.encodeComponent(sessionId)}';

  /// **La transition « Votre plan commence ici »** du rapport (2026-10-04).
  /// Miroir web : `/diagnostic/rapport/[sessionId]/plan`.
  static const diagnosticRapportPlan = '/diagnostic/rapport/:sessionId/plan';

  static String diagnosticRapportPlanPath(String sessionId) =>
      '${diagnosticRapportPath(sessionId)}/plan';

  /// **« Revoir ma réponse »** du rapport (2026-10-04). Miroir web :
  /// `/diagnostic/rapport/[sessionId]/reponse`.
  static const diagnosticRapportReponse =
      '/diagnostic/rapport/:sessionId/reponse';

  static String diagnosticRapportReponsePath(String sessionId) =>
      '${diagnosticRapportPath(sessionId)}/reponse';

  /// **Le lien « Continuer sur l'application »** du diagnostic web (lot 3b) :
  /// universal link iOS / App Link Android, `#run=…&token=…`. Jamais un
  /// écran : le `redirect` le consomme ([AppLinkClaim]) et repart aussitôt.
  static const continuerSurApp = AppLinkClaim.path;

  /// `/diagnostic?demarrer=1` — le diagnostic **part tout de suite**, sans
  /// écran de présentation.
  static const diagnosticDemarrer = '/diagnostic?demarrer=1';

  /// L'ancienne adresse du diagnostic TCF **4 épreuves** (L4) — parcours
  /// **retiré des fronts le 2026-09-26** (décision du propriétaire). Elle ne
  /// porte plus d'écran : elle **redirige vers le Plan**, pour qu'un lien
  /// profond déjà émis aboutisse. Les épreuves que le diagnostic rapide ne
  /// mesure pas se mesurent par l'examen blanc que propose le Plan.
  static const tcfDiagnosticRetire = '/diagnostic-tcf';

  /// Le diagnostic CIVIQUE (L9). 🛑 Un seul, comme le TCF depuis le retrait de
  /// son diagnostic complet (2026-09-26).
  static const civicDiagnostic = '/diagnostic-civique';
  static const civicDiagnosticResult =
      '/diagnostic-civique/:sessionId/resultat';

  static String civicDiagnosticResultPath(String sessionId) =>
      '/diagnostic-civique/$sessionId/resultat';

  /// L'ancienne adresse de l'onglet Plan : **redirige** vers le segment Plan
  /// du module (`?module=CIVIQUE` ⇒ civique, sinon TCF).
  static const plan = '/plan';

  /// `true` quand une ancienne adresse `/plan…` porte `?module=CIVIQUE`.
  static bool planCiviqueQuery(Map<String, String> query) =>
      query['module'] == 'CIVIQUE';

  /// Fiche d'un des quatre domaines du TCF **vu par le Plan** (`co|ce|ee|eo`).
  /// Aucun identifiant n'y voyage : la fiche relit le Plan déjà chargé.
  static const planDomain = '/plan/domaine/:domainKey';

  /// **L'écran de transition « Débloquer mon plan »** — ce que le diagnostic a
  /// trouvé, puis le prix d'entrée du module. Poussé par le geste de
  /// déblocage du Plan, et **hors shell** : on s'y ferme par la croix.
  /// Le module voyage en query (`?module=CIVIQUE`), comme côté web.
  static const planUnlock = '/plan/debloquer';

  static String planUnlockPath({required bool civique}) =>
      civique ? '$planUnlock?module=CIVIQUE' : planUnlock;

  /// Bilan d'une **série ciblée de compréhension**, poussé par le runner quand
  /// la route porte `from=planSerie` (même montage que `tcfLotResult`).
  static const planSerieResult = '/plan/serie/:attemptId';

  /// **Le détail d'une étape de séries** — l'écran intermédiaire du Plan
  /// (2026-09-20). Une étape d'entraînement de compréhension (CO/CE) ou une
  /// étape civique ouvre CET écran depuis la ligne du cycle, au lieu de lancer
  /// la série. 🛑 Les étapes d'**expression** ne passent pas par ici.
  ///
  /// Navigation v2 : l'écran vit **sous le Plan de son module**
  /// (`/tcf/plan/etape/:stepId`, `/civique/plan/etape/:stepId`), donc dans
  /// l'onglet du module. [planEtape] est l'ancienne adresse, redirigée.
  static const planEtape = '/plan/etape/:stepId';
  static const tcfPlanEtape = '$tcfPlan/etape/:stepId';
  static const civiquePlanEtape = '$civiquePlan/etape/:stepId';

  static String planEtapePath(String stepId, {required bool civique}) =>
      '${modulePlan(civique: civique)}/etape/$stepId';

  /// **« Mes cycles »** — l'historique des cycles du Plan (D16, 2026-09-24 :
  /// renommé à l'écran, chemin inchangé). 🛑 **À ne pas confondre avec les
  /// écrans de progression** ([progressionTcf] …), qui lisent des examens
  /// blancs. Aucun identifiant n'y voyage : l'écran relit le Plan déjà chargé.
  ///
  /// Navigation v2 : sous le Plan de son module (`/tcf/plan/progression`,
  /// `/civique/plan/progression`) ; [planProgress] est l'ancienne adresse,
  /// redirigée.
  static const planProgress = '/plan/progression';
  static const tcfPlanProgress = '$tcfPlan/progression';
  static const civiquePlanProgress = '$civiquePlan/progression';

  static String planProgressPath({required bool civique}) =>
      '${modulePlan(civique: civique)}/progression';

  /// **Un cycle terminé, en consultation** (2026-09-27) — ouvert depuis « Mes
  /// cycles » : son plan tel qu'il était, en lecture seule. Même déménagement
  /// que [planProgress].
  static const planCycleArchive = '/plan/progression/cycle/:journeyId';

  static String planCycleArchivePath(
    String journeyId, {
    required bool civique,
  }) =>
      '${planProgressPath(civique: civique)}/cycle/'
      '${Uri.encodeComponent(journeyId)}';

  /// **Les écrans de progression** (2026-09-24, maquettes
  /// `docs/progression/maquettes-progression/`) — ouverts depuis la carte
  /// « Ma progression » du module, le Profil, l'Accueil et entre eux.
  /// Navigation v2 : dans l'onglet de leur module (TCF / Civique).
  static const progressionTcf = '/progression/tcf';

  /// La même page, avec **tout** l'historique des examens complets (D8).
  static const progressionTcfTous = '/progression/tcf?tous=true';

  /// Une épreuve TCF — clé `co|ce|ee|eo`, la même que [planDomain].
  static const progressionEpreuve = '/progression/tcf/:domainKey';

  /// 🛑 Toujours **poussé** (`context.push`) : son retour dépile vers l'écran
  /// d'où l'on vient, quel qu'il soit (`retourOuRepli`).
  static String progressionEpreuvePath(String domainKey) =>
      '/progression/tcf/$domainKey';

  static const progressionCivique = '/progression/civique';
  static const progressionCiviqueTous = '/progression/civique?tous=true';

  /// Un thème civique — l'identifiant **servi**, jamais inventé.
  static const progressionTheme = '/progression/civique/:themeId';

  /// 🛑 Toujours **poussé**, comme [progressionEpreuvePath].
  static String progressionThemePath(String themeId) =>
      '/progression/civique/$themeId';

  /// « Mes favoris », poussé depuis le Profil (miroir web : `/favoris`).
  static const mesFavoris = '/mes-favoris';
  static const profile = '/profile';
  static const onboarding = '/onboarding';
  static const targetPath = '/target-path';

  /// L'écran de parcours, et **où revenir** une fois l'objectif enregistré.
  /// 🛑 Sans `from`, il renvoyait à l'Accueil le candidat venu du Plan. Miroir
  /// web : `journeyTargetPathHref` (`lib/journey.ts`).
  static String targetPathFrom(String from) =>
      '$targetPath?from=${Uri.encodeComponent(from)}';
  static const examResult = '/exam-result/:attemptId';

  static const examReport = '/exam-report/:attemptId';

  static String examReportPath(String attemptId) => '/exam-report/$attemptId';

  /// **Le contexte d'une série lancée depuis un écran qui l'attend** — une
  /// étape du Plan, le Plan civique, Réviser. 🛑 Le runner pousse alors le
  /// rapport de série complet ([ExamReportScreen], « Bilan de la série »),
  /// dont le bouton « Continuer » redépile sur l'écran de lancement. Aucune
  /// variante de rapport n'existe pour le Plan : c'est ce contexte qui en
  /// tient lieu. Miroir web : `sessionHref` (`?retour=`, `lib/retour.ts`).
  static const fromPlan = 'plan';

  /// Le runner d'une série lancée avec [fromPlan].
  static String runnerDepuisPlan(String attemptId) =>
      '/runner/$attemptId?from=$fromPlan';

  /// Le rapport d'une série jouée avec [fromPlan] — à chaud comme depuis
  /// « Voir mon résultat ».
  static String examReportDepuisPlan(String attemptId) =>
      '${examReportPath(attemptId)}?from=$fromPlan';

  // Centre d'aide (hub) + contact natif + WebView générique pour FAQ/CGU/Privacy.
  static const helpCenter = '/help';
  static const contact = '/help/contact';
  static const helpWebview = '/help/page';

  // Page « À propos » native (disclaimer de non-affiliation + sources
  // officielles — conformité stores). Publique comme la WebView légale.
  static const about = '/about';

  // « Mes informations » (hub) et ses trois écrans d'édition — miroirs des
  // pages web `/profil/informations{,/identite,/email,/mot-de-passe}`.
  static const personalInfo = '/profile/personal-info';
  static const personalInfoIdentity = '/profile/personal-info/identity';
  static const personalInfoEmail = '/profile/personal-info/email';
  static const personalInfoPassword = '/profile/personal-info/password';

  // « Notifications par e-mail » — miroir de la page web `/profil/notifications`.
  static const notifications = '/profile/notifications';

  // Gestion de l'abonnement Premium en cours (détails + résiliation). Le
  // routing serveur/store est décidé côté backend selon la source (Stripe,
  // Apple, Google).
  static const manageSubscription = '/profile/abonnement';

  // TCF Expression orale / ecrite (Lot A : briefing seul, soumission a venir).
  static const tcfExpressionOrale = '/tcf/expression-orale';
  static const tcfExpressionEcrite = '/tcf/expression-ecrite';
}

/// Destination interne autorisée après une authentification. Le contrôle est
/// volontairement strict : aucun schéma, hôte ni chemin d'authentification ne
/// peut être injecté depuis le paramètre `redirect` d'un lien profond.
String? safePostLoginDestination(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final uri = Uri.tryParse(raw);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      !uri.path.startsWith('/') ||
      uri.path.startsWith('//')) {
    return null;
  }
  if (uri.path == AppRoutes.login ||
      uri.path == AppRoutes.register ||
      uri.path == AppRoutes.forgotPassword ||
      uri.path == AppRoutes.splash ||
      uri.path == AppRoutes.onboarding ||
      uri.path == AppRoutes.targetPath) {
    return null;
  }
  return uri.toString();
}

String authFlowLocation(String path, String? destination) {
  final safeDestination = safePostLoginDestination(destination);
  return Uri(
    path: path,
    queryParameters:
        safeDestination == null ? null : {'redirect': safeDestination},
  ).toString();
}

String loginLocationFor(String destination) =>
    authFlowLocation(AppRoutes.login, destination);

String targetPathLocation(String? destination) {
  final safeDestination = safePostLoginDestination(destination);
  return Uri(
    path: AppRoutes.targetPath,
    queryParameters: safeDestination == null ? null : {'from': safeDestination},
  ).toString();
}

/// Mémoire éphémère du lien profond reçu pendant la restauration du token.
/// Une valeur n'est rendue qu'une fois et passe toujours par l'allowlist des
/// destinations internes ci-dessus.
class PendingAuthDestination {
  String? _value;

  String? get value => _value;

  void remember(String? raw) {
    final safe = safePostLoginDestination(raw);
    if (safe != null) _value = safe;
  }

  String? take() {
    final result = _value;
    _value = null;
    return result;
  }
}

/// `moduleKey` des routes `/tcf/:moduleKey/…` → module productif. Tout ce qui
/// n'est pas `eo` retombe sur l'EE (deep link malformé), jamais une exception.
TcfProductionModule _productionModuleFromKey(String? key) =>
    key == TcfProductionModule.eo.routeKey
        ? TcfProductionModule.eo
        : TcfProductionModule.ee;

/// Le numéro de tâche d'une route `/tcf/…/tache/:tacheNumero`, borné à 1-3.
int _tacheNumero(GoRouterState state) =>
    (int.tryParse(state.pathParameters['tacheNumero'] ?? '1') ?? 1).clamp(1, 3);

/// **La racine d'un onglet de module** : `/tcf` ou `/civique` (→ segment
/// Plan), puis un segment par sous-route. Les trois segments partagent **la
/// même page** (même clé, sans transition) : changer de segment met à jour
/// l'écran au lieu d'en empiler un autre. Les écrans secondaires du Plan qui
/// servent les DEUX modules (étape de séries, « Mes cycles », cycle archivé)
/// vivent sous le segment Plan de leur module.
GoRoute _moduleRoute({required bool civique}) {
  final racine = civique ? AppRoutes.civique : AppRoutes.tcf;
  Page<void> page(ModuleSegment segment) => NoTransitionPage<void>(
        key: ValueKey<String>('module-$racine'),
        child: ModuleScreen(civique: civique, segment: segment),
      );
  return GoRoute(
    path: racine,
    redirect: (_, state) => state.uri.path == racine
        ? ModuleSegment.plan.path(civique: civique)
        : null,
    routes: [
      GoRoute(
        path: ModuleSegment.plan.slug,
        pageBuilder: (_, __) => page(ModuleSegment.plan),
        routes: [
          GoRoute(
            path: 'etape/:stepId',
            builder: (_, state) => PlanEtapeScreen(
              stepId: state.pathParameters['stepId']!,
              civique: civique,
            ),
          ),
          GoRoute(
            path: 'progression',
            builder: (_, __) => PlanHistoryScreen(civique: civique),
            routes: [
              GoRoute(
                path: 'cycle/:journeyId',
                builder: (_, state) => PlanCycleArchiveScreen(
                  journeyId: state.pathParameters['journeyId']!,
                  civique: civique,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: ModuleSegment.entrainement.slug,
        pageBuilder: (_, __) => page(ModuleSegment.entrainement),
      ),
      GoRoute(
        path: ModuleSegment.examens.slug,
        pageBuilder: (_, __) => page(ModuleSegment.examens),
      ),
    ],
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);
  final pendingDestination = PendingAuthDestination();
  late final GoRouter router;

  String? consumeDestination(String? raw) {
    final direct = safePostLoginDestination(raw);
    final pending = pendingDestination.take();
    return direct ?? pending;
  }

  // Force la navigation vers /login dès qu'un 401 fait passer l'auth en
  // Unauthenticated (forceLogout) ou qu'un logout explicite est déclenché.
  // Le redirect du router gérerait déjà le cas pour la route active, mais
  // appeler `go` explicitement garantit qu'on vide la back-stack des
  // routes pushées (runner, target-path, etc.).
  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    if (previous is AuthAuthenticated && next is AuthUnauthenticated) {
      router.go(AppRoutes.login);
    }
  });

  router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    observers: [appRouteObserver],
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      // Lien web → app (lot 3b) : la run et son jeton sont gardés pour la
      // prochaine authentification, puis on quitte l'adresse. 🛑 Avant la
      // branche du boot : ce lien porte un secret, il ne doit jamais devenir
      // une « destination après connexion ».
      if (state.uri.path == AppRoutes.continuerSurApp) {
        final claim = AppLinkClaim.fromUri(state.uri);
        if (claim != null) {
          unawaited(
              ref.read(diagnosticRunTrackerProvider).receiveAppLink(claim));
        }
        if (auth is AuthLoading) return AppRoutes.splash;
        return auth is AuthAuthenticated ? AppRoutes.home : AppRoutes.register;
      }

      // Pendant le boot, on reste sur le splash le temps d'avoir un verdict.
      if (auth is AuthLoading) {
        pendingDestination.remember(
          state.uri.queryParameters['redirect'] ??
              state.uri.queryParameters['from'],
        );
        pendingDestination.remember(state.uri.toString());
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final isAuth = auth is AuthAuthenticated;
      final isOnAuthFlow = loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.forgotPassword;
      final isOnOnboarding = loc == AppRoutes.onboarding;
      final isOnTargetPath = loc == AppRoutes.targetPath;
      final isOnSplash = loc == AppRoutes.splash;
      // Pages publiques : la WebView légale (CGU / confidentialité) est
      // ouverte depuis login & inscription, la page « À propos » (disclaimer
      // non-affiliation) doit rester consultable sans compte, et le
      // **diagnostic** se fait entièrement avant l'inscription — le compte
      // n'est demandé qu'au moment d'envoyer les deux productions à l'analyse.
      // Le Plan (`/plan`), lui, reste authentifié : il n'existe qu'après.
      // Le **diagnostic civique** se passe lui aussi avant l'inscription
      // (V053, arbitrage du propriétaire du 2026-09-10) : son accueil, son
      // écran de résultat — qui n'affiche alors QUE la demande de compte — et
      // le **runner**, puisque la passation réutilise l'écran de questions
      // existant plutôt que d'en dupliquer un second.
      final isOnPublicPage = loc == AppRoutes.helpWebview ||
          loc == AppRoutes.about ||
          loc == AppRoutes.diagnostic ||
          loc == AppRoutes.civicDiagnostic ||
          loc.startsWith('/diagnostic-civique/') ||
          loc.startsWith('/runner/');

      // Si user connecté : pas d'auth flow, pas d'onboarding, pas de splash.
      if (isAuth) {
        final user = auth.user;

        // Profil obligatoire incomplet — fait SERVI (`profileIncomplete`) :
        // compte né d'une connexion Google/Apple, ou compte sans démarche. Il
        // répond aux questions de l'inscription (`/target-path`) avant l'app.
        // Seules les pages légales restent ouvertes. La destination survit :
        // celle de l'écran d'auth (`redirect`), sinon la page demandée.
        // Miroir web : `ProfileCompletionGuard`.
        final isOnLegalPage =
            loc == AppRoutes.helpWebview || loc == AppRoutes.about;
        if (user.profileIncomplete && !isOnTargetPath && !isOnLegalPage) {
          final demandee = isOnAuthFlow || isOnOnboarding || isOnSplash
              ? state.uri.queryParameters['redirect'] ??
                  state.uri.queryParameters['from']
              : state.uri.toString();
          return targetPathLocation(consumeDestination(demandee));
        }

        if (isOnAuthFlow || isOnOnboarding || isOnSplash) {
          return consumeDestination(
                state.uri.queryParameters['redirect'] ??
                    state.uri.queryParameters['from'],
              ) ??
              AppRoutes.home;
        }
        return null;
      }

      // User non connecté : on regarde si l'onboarding a déjà été vu.
      // Lecture synchrone : la valeur est préchargée depuis les prefs au boot
      // (main.dart) donc disponible dès le premier frame.
      final onboardingSeen = ref.read(onboardingSeenProvider);

      // Une page publique reste atteignable même sur une installation neuve :
      // un lien profond vers le diagnostic ne doit pas se perdre dans
      // l'onboarding puis l'écran de connexion.
      if (!onboardingSeen && !isOnOnboarding && !isOnPublicPage) {
        return authFlowLocation(
          AppRoutes.onboarding,
          consumeDestination(state.uri.toString()),
        );
      }

      if (onboardingSeen &&
          !isOnAuthFlow &&
          !isOnOnboarding &&
          !isOnPublicPage) {
        return authFlowLocation(
          AppRoutes.login,
          consumeDestination(state.uri.toString()),
        );
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      // Déclarée pour que l'adresse soit reconnue ; le `redirect` la quitte
      // toujours avant tout affichage.
      GoRoute(
        path: AppRoutes.continuerSurApp,
        builder: (_, __) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.targetPath,
        builder: (_, __) => const TargetPathScreen(),
      ),

      // ── Navigation v2 (2026-10-03) : le shell à 4 onglets ──────────────
      //
      // Une pile par onglet. Un écran déclaré dans une branche s'affiche
      // AVEC la barre d'onglets, sous l'onglet de son module ; tout ce qui
      // est plein écran (passation, résultats, paywall, diagnostic, auth)
      // reste sur le navigateur racine, plus bas.
      //
      // 🛑 Ouvrir un écran d'une branche depuis un écran plein écran ou
      // depuis un autre onglet passe par `pousserOuAller`
      // (`shell_navigation.dart`) : un `push` y empilerait un second shell
      // portant la même clé de page.
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: shellBranchKeys[ShellBranch.accueil],
            observers: [brancheRouteObservers[ShellBranch.accueil.index]],
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellBranchKeys[ShellBranch.tcf],
            observers: [brancheRouteObservers[ShellBranch.tcf.index]],
            initialLocation: AppRoutes.tcfPlan,
            routes: [
              _moduleRoute(civique: false),
              // Fiche d'un des quatre domaines du TCF vu par le Plan : TCF
              // seulement, chemin inchangé.
              GoRoute(
                path: AppRoutes.planDomain,
                builder: (_, state) => PlanDomainScreen(
                  domainKey: state.pathParameters['domainKey'] ?? '',
                ),
              ),
              GoRoute(
                path: AppRoutes.progressionTcf,
                builder: (_, state) => ProgressionTcfScreen(
                  tous: state.uri.queryParameters['tous'] == 'true',
                ),
              ),
              GoRoute(
                path: AppRoutes.progressionEpreuve,
                builder: (_, state) {
                  final epreuve = planDomainFromKey(
                      state.pathParameters['domainKey'] ?? '');
                  // Une clé inconnue ne fabrique pas d'épreuve : on retombe
                  // sur la progression globale plutôt que d'inventer un
                  // domaine.
                  if (epreuve == null) return const ProgressionTcfScreen();
                  return ProgressionEpreuveScreen(epreuve: epreuve);
                },
              ),
              // TCF QCM CO — hub + sous-route examens.
              GoRoute(
                path: AppRoutes.tcfCoDetail,
                builder: (_, __) =>
                    const TcfQcmDetailScreen(module: TcfQcmModule.co),
                routes: [
                  GoRoute(
                    path: 'examens',
                    builder: (_, __) =>
                        const TcfQcmExamsScreen(module: TcfQcmModule.co),
                  ),
                ],
              ),
              // TCF QCM CE — hub + sous-route examens.
              GoRoute(
                path: AppRoutes.tcfCeDetail,
                builder: (_, __) =>
                    const TcfQcmDetailScreen(module: TcfQcmModule.ce),
                routes: [
                  GoRoute(
                    path: 'examens',
                    builder: (_, __) =>
                        const TcfQcmExamsScreen(module: TcfQcmModule.ce),
                  ),
                ],
              ),
              // TCF Structure de la langue — QCM grammaire / lexique. Non
              // évalué dans le TCF IRN officiel — bannière rendue par le hub.
              GoRoute(
                path: AppRoutes.tcfStructureDetail,
                builder: (_, __) =>
                    const TcfQcmDetailScreen(module: TcfQcmModule.structure),
                routes: [
                  GoRoute(
                    path: 'examens',
                    builder: (_, __) =>
                        const TcfQcmExamsScreen(module: TcfQcmModule.structure),
                  ),
                ],
              ),
              // Lots d'un niveau pour un module TCF QCM.
              GoRoute(
                path: AppRoutes.tcfLevelLots,
                builder: (_, state) {
                  final moduleKey = state.pathParameters['moduleKey']!;
                  final levelKey = state.pathParameters['level']!.toUpperCase();
                  final module = switch (moduleKey) {
                    'ce' => TcfQcmModule.ce,
                    'structure' => TcfQcmModule.structure,
                    _ => TcfQcmModule.co,
                  };
                  final level = Difficulty.values.firstWhere(
                    (d) => d.wire == levelKey,
                    orElse: () => Difficulty.a2,
                  );
                  return TcfLevelLotsScreen(module: module, level: level);
                },
              ),
              // TCF productions — niveau 1 : l'épreuve et ses trois tâches.
              GoRoute(
                path: AppRoutes.tcfEoEntry,
                builder: (_, __) =>
                    const ProductionTasksScreen(module: TcfProductionModule.eo),
              ),
              GoRoute(
                path: AppRoutes.tcfEeEntry,
                builder: (_, __) =>
                    const ProductionTasksScreen(module: TcfProductionModule.ee),
              ),
              // Niveau 2 : une tâche et ses sujets complets.
              GoRoute(
                path: AppRoutes.tcfEoTaskTraining,
                builder: (_, state) => ProductionTaskScreen(
                  module: TcfProductionModule.eo,
                  tache: _tacheNumero(state),
                  planStep: isPlanStepQuery(state.uri.queryParameters),
                ),
              ),
              GoRoute(
                path: AppRoutes.tcfEeTaskTraining,
                builder: (_, state) => ProductionTaskScreen(
                  module: TcfProductionModule.ee,
                  tache: _tacheNumero(state),
                  planStep: isPlanStepQuery(state.uri.queryParameters),
                ),
              ),
              // Modèles corrigés d'une tâche (`moduleKey` ∈ {ee, eo}).
              GoRoute(
                path: AppRoutes.tcfTaskExamples,
                builder: (_, state) => TcfTaskExamplesScreen(
                  module: _productionModuleFromKey(
                      state.pathParameters['moduleKey']),
                  tache: _tacheNumero(state),
                ),
              ),
              // Compétences TCF : le catalogue d'une tâche et la fiche d'une
              // compétence. Le petit sujet (production en cours) et son
              // résultat sont plein écran, plus bas.
              GoRoute(
                path: AppRoutes.tcfCompetences,
                builder: (_, state) => CompetencesScreen(
                  module: _productionModuleFromKey(
                      state.pathParameters['moduleKey']),
                  tache: _tacheNumero(state),
                ),
              ),
              GoRoute(
                path: AppRoutes.tcfCompetenceDetail,
                builder: (_, state) => CompetenceDetailScreen(
                  module: _productionModuleFromKey(
                      state.pathParameters['moduleKey']),
                  skillId: state.pathParameters['skillId']!,
                  // Marqueur d'étape du Plan : la compétence s'affiche alors à
                  // l'échelle de l'étape (« 2/5 »). Cf. plan_step_labels.dart.
                  planStep: isPlanStepQuery(state.uri.queryParameters),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellBranchKeys[ShellBranch.civique],
            observers: [brancheRouteObservers[ShellBranch.civique.index]],
            initialLocation: AppRoutes.civiquePlan,
            routes: [
              _moduleRoute(civique: true),
              GoRoute(
                path: AppRoutes.progressionCivique,
                builder: (_, state) => ProgressionCiviqueScreen(
                  tous: state.uri.queryParameters['tous'] == 'true',
                ),
              ),
              GoRoute(
                path: AppRoutes.progressionTheme,
                builder: (_, state) => ProgressionThemeScreen(
                  themeId: state.pathParameters['themeId']!,
                ),
              ),
              // Un thème civique et ses examens blancs de thème.
              GoRoute(
                path: AppRoutes.civiqueThemeDetail,
                builder: (_, state) => CiviqueThemeDetailScreen(
                  themeId: state.pathParameters['themeId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'examens',
                    builder: (_, state) => CiviqueThemeExamsScreen(
                      themeId: state.pathParameters['themeId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: shellBranchKeys[ShellBranch.profil],
            observers: [brancheRouteObservers[ShellBranch.profil.index]],
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Anciennes adresses (redirections, aucun écran) ────────────────
      //
      // Navigation v2 supprime les onglets Plan / Réviser / Examens et les
      // pages plein écran des examens blancs : leurs adresses mènent au
      // segment du module, pour qu'un lien déjà émis aboutisse.
      GoRoute(
        path: AppRoutes.plan,
        redirect: (_, state) => AppRoutes.modulePlan(
          civique: AppRoutes.planCiviqueQuery(state.uri.queryParameters),
        ),
      ),
      GoRoute(
        path: AppRoutes.planEtape,
        redirect: (_, state) => AppRoutes.planEtapePath(
          state.pathParameters['stepId']!,
          civique: AppRoutes.planCiviqueQuery(state.uri.queryParameters),
        ),
      ),
      GoRoute(
        path: AppRoutes.planProgress,
        redirect: (_, state) => state.uri.path == AppRoutes.planProgress
            ? AppRoutes.planProgressPath(
                civique: AppRoutes.planCiviqueQuery(state.uri.queryParameters),
              )
            : null,
        routes: [
          GoRoute(
            path: 'cycle/:journeyId',
            redirect: (_, state) => AppRoutes.planCycleArchivePath(
              state.pathParameters['journeyId']!,
              civique: AppRoutes.planCiviqueQuery(state.uri.queryParameters),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.reviser,
        redirect: (_, state) => AppRoutes.moduleEntrainement(
          civique: AppRoutes.planCiviqueQuery(state.uri.queryParameters),
        ),
      ),
      GoRoute(
        path: AppRoutes.examens,
        redirect: (_, state) => AppRoutes.moduleExamens(
          civique: AppRoutes.planCiviqueQuery(state.uri.queryParameters),
        ),
      ),
      GoRoute(
        path: AppRoutes.tcfFullExams,
        redirect: (_, __) => AppRoutes.tcfExamens,
      ),
      GoRoute(
        path: AppRoutes.civiqueExamsBlanc,
        redirect: (_, __) => AppRoutes.civiqueExamens,
      ),
      // Diagnostic complet retiré (2026-09-26) : l'ancienne adresse et ses
      // sous-routes (`/diagnostic-tcf/{id}/resultat`) mènent au Plan TCF.
      GoRoute(
        path: AppRoutes.tcfDiagnosticRetire,
        redirect: (_, __) => AppRoutes.tcfPlan,
        routes: [
          GoRoute(
            path: ':sessionId/resultat',
            redirect: (_, __) => AppRoutes.tcfPlan,
          ),
        ],
      ),

      // ── Plein écran (navigateur racine, sans barre d'onglets) ─────────
      GoRoute(
        path: AppRoutes.examResult,
        builder: (_, state) {
          final attemptId = state.pathParameters['attemptId']!;
          return ExamResultScreen(attemptId: attemptId);
        },
      ),
      GoRoute(
        path: AppRoutes.mesFavoris,
        builder: (_, __) => const MesFavorisScreen(),
      ),
      GoRoute(
        path: AppRoutes.helpCenter,
        builder: (_, __) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: AppRoutes.contact,
        builder: (_, __) => const ContactScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (_, __) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.helpWebview,
        builder: (_, state) {
          final url = state.uri.queryParameters['url'] ?? '';
          final title = state.uri.queryParameters['title'] ?? '';
          return InAppWebViewScreen(title: title, url: url);
        },
      ),
      GoRoute(
        path: AppRoutes.personalInfo,
        builder: (_, __) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: AppRoutes.personalInfoIdentity,
        builder: (_, __) => const EditIdentityScreen(),
      ),
      GoRoute(
        path: AppRoutes.personalInfoEmail,
        builder: (_, __) => const ChangeEmailScreen(),
      ),
      GoRoute(
        path: AppRoutes.personalInfoPassword,
        builder: (_, __) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.manageSubscription,
        builder: (_, __) => const ManageSubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoutes.diagnostic,
        builder: (_, __) => const DiagnosticScreen(),
      ),
      GoRoute(
        path: AppRoutes.diagnosticRapport,
        builder: (_, state) => DiagnosticRapportScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.diagnosticRapportPlan,
        builder: (_, state) => DiagnosticTransitionScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.diagnosticRapportReponse,
        builder: (_, state) => DiagnosticReponseScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.civicDiagnostic,
        builder: (_, __) => const CivicDiagnosticScreen(),
      ),
      GoRoute(
        path: AppRoutes.civicDiagnosticResult,
        builder: (_, state) => CivicDiagnosticResultScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.examReport,
        builder: (_, state) {
          final attemptId = state.pathParameters['attemptId']!;
          return ExamReportScreen(attemptId: attemptId);
        },
      ),
      // « Débloquer mon plan » : un écran de transition vers l'offre, qu'on
      // ferme par la croix — plein écran comme le paywall.
      GoRoute(
        path: AppRoutes.planUnlock,
        builder: (_, state) => PlanUnlockScreen(
          module: state.uri.queryParameters['module'] == 'CIVIQUE'
              ? PlanUnlockModule.civique
              : PlanUnlockModule.tcf,
        ),
      ),
      // Bilan d'une série ciblée, poussé par le runner.
      GoRoute(
        path: AppRoutes.planSerieResult,
        builder: (_, state) => PlanSerieResultScreen(
          attemptId: state.pathParameters['attemptId']!,
          skillId: state.uri.queryParameters['skillId'],
          masteryBefore: SkillMasteryState.fromWireNullable(
            state.uri.queryParameters['avant'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.runner,
        builder: (_, state) {
          final attemptId = state.pathParameters['attemptId']!;
          return RunnerScreen(attemptId: attemptId);
        },
      ),
      // Petit sujet de compétence (une production en cours) et son résultat.
      GoRoute(
        path: AppRoutes.tcfCompetenceResult,
        builder: (_, state) => CompetenceResultScreen(
          module: _productionModuleFromKey(state.pathParameters['moduleKey']),
          attemptId: state.pathParameters['attemptId']!,
          // Marqueur d'étape : le sujet suivant reste alors DANS les 5.
          planStep: isPlanStepQuery(state.uri.queryParameters),
        ),
      ),
      GoRoute(
        path: AppRoutes.tcfCompetencePrompt,
        builder: (_, state) => CompetencePromptScreen(
          module: _productionModuleFromKey(state.pathParameters['moduleKey']),
          skillId: state.pathParameters['skillId']!,
          promptId: state.pathParameters['promptId']!,
          // Marqueur d'étape : le repère devient « Sujet 1/5 » et le retour
          // ramène à l'étape, pas à la fiche des 15.
          planStep: isPlanStepQuery(state.uri.queryParameters),
        ),
      ),

      // Examen blanc TCF complet : CO + CE + EE + EO, chacune avec son propre
      // chrono. Hub de progression puis bilan, plein écran.
      GoRoute(
        path: AppRoutes.tcfFullExamProgress,
        builder: (_, state) => TcfFullExamProgressScreen(
          parentAttemptId: state.pathParameters['parentId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.tcfFullExamBilan,
        builder: (_, state) => TcfFullExamBilanScreen(
          parentAttemptId: state.pathParameters['parentId']!,
        ),
      ),
      // Bilan d'un lot terminé. moduleKey + level passés en query par le
      // runner pour permettre au CTA "Retour aux lots" de revenir au bon écran.
      GoRoute(
        path: AppRoutes.tcfLotResult,
        builder: (_, state) {
          final attemptId = state.pathParameters['attemptId']!;
          final moduleKey = state.uri.queryParameters['moduleKey'] ?? 'co';
          final level = state.uri.queryParameters['level'] ?? 'a2';
          return TcfLotResultScreen(
            attemptId: attemptId,
            moduleKey: moduleKey,
            level: level,
          );
        },
      ),

      // TCF Expression orale — sous-routes des écrans de session.
      //   /tcf/expression-orale                          -> [supprimé] redirige vers le détail EO
      //   /tcf/expression-orale/sessions/:attemptId      -> bilan détaillé d'une session
      //                                                    (mode `?live=1` après T3 = polling actif)
      //   /tcf/expression-orale/t/:idx                   -> consigne + enregistrement + revue
      //                                                    (réécoute locale, recommencer, envoi)
      //   /tcf/expression-orale/resultats/:id?taskIndex=N&history=1  -> resultats (live ou history)
      //
      // L'ancien hub `ProductionHubScreen` a été supprimé : la sélection
      // T1/T2/T3 vit désormais sur les pastilles des écrans du parcours.
      // On garde le path parent pour absorber les anciens liens (deep links,
      // historiques) via un redirect — mais uniquement quand l'URL exacte
      // est la racine ; les sous-routes restent atteignables. Il chaîne sur
      // l'alias `/tcf/eo`, qui redirige à son tour vers l'entrée du parcours.
      GoRoute(
        path: AppRoutes.tcfExpressionOrale,
        // `state.matchedLocation` est parfois la path du parent (et pas l'URL
        // complète) pendant l'évaluation d'une navigation vers sous-route
        // dans go_router 14 — ce qui ferait fire la redirection alors qu'on
        // navigue en fait vers `/tcf/expression-orale/t/0` ou similaire. On
        // teste donc `state.uri.path` (URL réelle de destination) pour ne
        // rediriger QUE quand l'utilisateur cible l'ancien path racine du hub.
        redirect: (_, state) => state.uri.path == AppRoutes.tcfExpressionOrale
            ? AppRoutes.tcfEoEntry
            : null,
        routes: [
          GoRoute(
            path: 'examens',
            // Chemin **inchangé** depuis que les examens blancs ont quitté
            // l'écran des tâches : les liens profonds existants aboutissent
            // toujours ici. L'ancien `?tache=` n'a plus d'objet — on revient
            // désormais en dépilant.
            builder: (_, __) => const ProductionExamsScreen(
              module: TcfProductionModule.eo,
            ),
          ),
          GoRoute(
            path: 'sessions/:attemptId',
            builder: (_, state) => HistorySessionScreen(
              epreuve: EpreuveType.tcfEo,
              attemptId: state.pathParameters['attemptId']!,
            ),
          ),
          // Session EO temps réel (examinateur vocal). Les arguments (descripteur
          // + tâche + attempt) passent par `state.extra`.
          GoRoute(
            path: 'realtime',
            builder: (_, state) =>
                RealtimeEoScreen(args: state.extra as RealtimeRunnerArgs),
          ),
          GoRoute(
            path: 't/:taskIndex',
            builder: (_, state) {
              final idx =
                  int.tryParse(state.pathParameters['taskIndex'] ?? '0') ?? 0;
              return EoBriefingScreen(taskIndex: idx);
            },
          ),
          GoRoute(
            path: 'resultats/:submissionId',
            builder: (_, state) {
              final id = state.pathParameters['submissionId']!;
              final idx =
                  int.tryParse(state.uri.queryParameters['taskIndex'] ?? '0') ??
                      0;
              final history = state.uri.queryParameters['history'] == '1';
              return EoResultsScreen(
                submissionId: id,
                taskIndex: idx,
                isHistory: history,
              );
            },
          ),
        ],
      ),

      // TCF Expression ecrite — mêmes sous-routes qu'EO (le briefing + zone
      // d'écriture sont combinés). Le path
      // parent redirige vers le détail EE comme pour l'orale (cf. supra).
      GoRoute(
        path: AppRoutes.tcfExpressionEcrite,
        // Cf. note sur l'analogue EO juste au-dessus : on filtre via
        // `state.uri.path` pour ne pas intercepter les navigations vers
        // les sous-routes (`/sessions/:id`, `/t/:idx`, ...).
        redirect: (_, state) => state.uri.path == AppRoutes.tcfExpressionEcrite
            ? AppRoutes.tcfEeEntry
            : null,
        routes: [
          GoRoute(
            path: 'examens',
            // Chemin **inchangé** depuis que les examens blancs ont quitté
            // l'écran des tâches : les liens profonds existants aboutissent
            // toujours ici. L'ancien `?tache=` n'a plus d'objet — on revient
            // désormais en dépilant.
            builder: (_, __) => const ProductionExamsScreen(
              module: TcfProductionModule.ee,
            ),
          ),
          GoRoute(
            path: 'sessions/:attemptId',
            builder: (_, state) => HistorySessionScreen(
              epreuve: EpreuveType.tcfEe,
              attemptId: state.pathParameters['attemptId']!,
            ),
          ),
          GoRoute(
            path: 't/:taskIndex',
            builder: (_, state) {
              final idx =
                  int.tryParse(state.pathParameters['taskIndex'] ?? '0') ?? 0;
              return EeBriefingWritingScreen(taskIndex: idx);
            },
          ),
          GoRoute(
            path: 'resultats/:submissionId',
            builder: (_, state) {
              final id = state.pathParameters['submissionId']!;
              final idx =
                  int.tryParse(state.uri.queryParameters['taskIndex'] ?? '0') ??
                      0;
              final history = state.uri.queryParameters['history'] == '1';
              return EeResultsScreen(
                submissionId: id,
                taskIndex: idx,
                isHistory: history,
              );
            },
          ),
        ],
      ),
    ],
  );
  final screenViews = ScreenViewTracker(ref.read(analyticsServiceProvider));
  void onRouteChanged() => screenViews.onRouteChanged(router);
  router.routerDelegate.addListener(onRouteChanged);
  ref.onDispose(() => router.routerDelegate.removeListener(onRouteChanged));
  return router;
});

/// Pont entre Riverpod et go_router : on rafraîchit le router à chaque
/// changement d'AuthState pour appliquer les redirections.
class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(this._ref) {
    _authSub = _ref.listen<AuthState>(
      authControllerProvider,
      (_, __) => notifyListeners(),
    );
    _onboardingSub = _ref.listen<bool>(
      onboardingSeenProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _authSub;
  late final ProviderSubscription<bool> _onboardingSub;

  @override
  void dispose() {
    _authSub.close();
    _onboardingSub.close();
    super.dispose();
  }
}
