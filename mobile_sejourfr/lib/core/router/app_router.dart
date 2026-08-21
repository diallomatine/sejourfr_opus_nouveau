import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sejourfr_mobile/core/router/route_observer.dart';
import 'package:sejourfr_mobile/screens/exam/exam_report_screen.dart';
import 'package:sejourfr_mobile/screens/exam/exam_result_screen.dart';
import 'package:sejourfr_mobile/screens/history/history_screen.dart';
import 'package:sejourfr_mobile/screens/history/tcf_exam_history_screen.dart';

import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/civique/civique_full_exams_screen.dart';
import '../../screens/diagnostic/diagnostic_screen.dart';
import '../../screens/examens/examens_screen.dart';
import '../../screens/reviser/reviser_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/module_detail/civique_theme_detail_screen.dart';
import '../../screens/module_detail/civique_theme_exams_screen.dart';
import '../../screens/module_detail/tcf_full_exams_screen.dart';
import '../../screens/module_detail/tcf_level_lots_screen.dart';
import '../../screens/module_detail/tcf_lot_result_screen.dart';
import '../../screens/tcf_production/competences/competence_detail_screen.dart';
import '../../screens/tcf_production/competences/competence_prompt_screen.dart';
import '../../screens/tcf_production/competences/competence_result_screen.dart';
import '../../screens/tcf_production/production_parcours_screen.dart';
import '../../screens/tcf_production/widgets/production_mode_tabs.dart';
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
import '../../screens/profile/mes_historiques_screen.dart';
import '../../screens/profile/mon_entrainement_screen.dart';
import '../../screens/profile/personal_info_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/plan/plan_domain_screen.dart';
import '../../screens/plan/plan_evolution_screen.dart';
import '../../screens/plan/plan_screen.dart';
import '../../screens/plan/plan_serie_result_screen.dart';
import '../../screens/plan/plan_step_labels.dart';
import '../../screens/question_runner/runner_screen.dart';
import '../../screens/review/review_screen.dart';
import '../../screens/shell/main_shell.dart';
import '../../screens/progres/progres_screen.dart';
import '../../screens/progres/reco_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/target_path/target_path_screen.dart';
import '../../screens/tcf_full_exam/tcf_full_exam_bilan_screen.dart';
import '../../screens/tcf_full_exam/tcf_full_exam_progress_screen.dart';
import '../../screens/tcf_production/ee_briefing_writing_screen.dart';
import '../../screens/tcf_production/ee_results_screen.dart';
import '../../screens/tcf_production/eo_briefing_screen.dart';
import '../../screens/tcf_production/eo_finished_screen.dart';
import '../../screens/tcf_production/eo_results_screen.dart';
import '../../screens/tcf_production/history_session_screen.dart';
import '../../screens/tcf_production/production_history_screen.dart';
import '../../screens/tcf_production/realtime/realtime_eo_controller.dart';
import '../../screens/tcf_production/realtime/realtime_eo_screen.dart';
import '../auth/auth_controller.dart';
import '../models/enums.dart';
import '../models/skill_models.dart';

/// Routes nommées centralisées (utilisées par les écrans).
class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/';

  // Onglets de la refonte 2026 : Réviser (hub fusionné Civique/TCF avec
  // toggle) et Examens (examens blancs complets des deux parcours).
  static const reviser = '/reviser';
  static const examens = '/examens';

  static const civique = '/civique';
  // Page « Examens blancs » civique GLOBAUX (20 slots de 40 Q tous thèmes,
  // 45 min, seuil 32/40). Pushée depuis le hero du hub Civique. Distincte
  // des examens thématiques (20 Q d'un seul thème, route
  // `/civique/theme/:themeId/examens`).
  static const civiqueExamsBlanc = '/civique/examens-blancs';
  static const civiqueThemeDetail = '/civique/theme/:themeId';
  // Page « Examens blancs » d'un thème civique (10 slots de 20 Q / 20 min /
  // seuil 16). Pushé depuis le hero rouge du détail thème.
  static const civiqueThemeExams = '/civique/theme/:themeId/examens';
  static const tcf = '/tcf';
  static const tcfCoDetail = '/tcf/co';
  static const tcfCeDetail = '/tcf/ce';
  static const tcfStructureDetail = '/tcf/structure';
  // Sous-routes des hubs QCM (CO, CE, Structure) : examens blancs.
  static const tcfCoExams = '/tcf/co/examens';
  static const tcfCeExams = '/tcf/ce/examens';
  static const tcfStructureExams = '/tcf/structure/examens';
  // Racine d'une épreuve d'Expression. Le hub d'épreuve qui vivait ici (3
  // cartes de tâche + historique récent) est **supprimé** : le parcours ouvre
  // directement sur l'écran d'accueil de la maquette, et le changement de
  // tâche s'y fait par les pastilles T1/T2/T3. Ces deux paths restent
  // déclarés comme **alias** (redirect → `tcf{Eo,Ee}Entry`) parce que les
  // écrans du parcours les utilisent encore comme « racine de l'épreuve »
  // quand la pile de navigation est vide (résultats, bilan de session,
  // historique).
  static const tcfEoDetail = '/tcf/eo';
  static const tcfEeDetail = '/tcf/ee';

  /// **Entrée du parcours d'Expression** (depuis Réviser, l'Accueil ou les
  /// recommandations) : le mode « Compétences » de la tâche 1, l'écran
  /// d'accueil de la maquette. Littéral parce qu'`AppRoutes` est le registre
  /// des routes ; la forme paramétrée vit dans `productionCompetencesPath`.
  static const tcfEoEntry = '/tcf/eo/tache/1/competences';
  static const tcfEeEntry = '/tcf/ee/tache/1/competences';

  static const tcfEoTaskTraining = '/tcf/eo/tache/:tacheNumero';
  static const tcfEeTaskTraining = '/tcf/ee/tache/:tacheNumero';

  // Modèles corrigés d'une tâche. Ils ne sont plus un onglet de l'écran
  // d'entraînement : ils ont leur écran, atteint par le bouton posé au-dessus
  // de la liste des sujets.
  static const tcfTaskExamples = '/tcf/:moduleKey/tache/:tacheNumero/exemples';

  // Compétences TCF : entraînement d'un critère à la fois sur de petits
  // sujets, à côté (et jamais à la place) des sujets TCF complets.
  // moduleKey ∈ {ee, eo}. Les 4 écrans suivent les 5 niveaux de la spec :
  // tâche → compétences → une compétence → un petit sujet → son résultat.
  static const tcfCompetences =
      '/tcf/:moduleKey/tache/:tacheNumero/competences';
  static const tcfCompetenceDetail = '/tcf/:moduleKey/competences/:skillId';
  static const tcfCompetencePrompt =
      '/tcf/:moduleKey/competences/:skillId/sujet/:promptId';
  static const tcfCompetenceResult =
      '/tcf/:moduleKey/competences/resultat/:attemptId';

  // Examen blanc complet TCF (les 4 épreuves enchaînées). 20 slots dans
  // la liste. Distinct des module exams (CO/CE seul) côté backend via
  // attempts.epreuve = TCF_COMPLET vs attempts.module_exam_question_type.
  static const tcfFullExams = '/tcf/examens-blancs';

  // Hub de progression d'un examen blanc complet en cours (4 étapes).
  // Push après création du parent via POST /api/full-tcf-exams.
  static const tcfFullExamProgress = '/tcf/examen-blanc/:parentId';

  // Bilan final agrégé (niveau CECRL plancher + détail des 4 épreuves).
  static const tcfFullExamBilan = '/tcf/examen-blanc/:parentId/bilan';

  // Liste des lots pour un niveau d'un module TCF QCM.
  // moduleKey ∈ {co, ce}, level ∈ {a2, b1, b2}.
  static const tcfLevelLots = '/tcf/:moduleKey/niveau/:level';

  // Bilan affiché à la fin d'un lot TCF QCM. Push par le runner avec
  // moduleKey + level en query pour reconstruire le retour.
  static const tcfLotResult = '/tcf/lot-result/:attemptId';
  static const runner = '/runner/:attemptId';
  static const diagnostic = '/diagnostic';
  static const plan = '/plan';

  /// Fiche d'un des quatre domaines du TCF **vu par le Plan** (`co|ce|ee|eo`).
  /// Aucun identifiant n'y voyage : la fiche relit le Plan déjà chargé.
  static const planDomain = '/plan/domaine/:domainKey';

  /// « Votre programme évolue » — le détail de ce qui a bougé dans le Plan.
  static const planEvolution = '/plan/evolution';

  /// Bilan d'une **série ciblée de compréhension**, poussé par le runner quand
  /// la route porte `from=planSerie` (même montage que `tcfLotResult`).
  static const planSerieResult = '/plan/serie/:attemptId';

  static const progress = '/progress';

  // Plan de révision personnalisé (catégories les plus faibles d'abord),
  // pushé depuis l'onglet Progrès.
  static const progresReco = '/progress/recommandations';
  // Pages de révision dédiées, poussées depuis le hub "Mon entraînement".
  static const mesQuestions = '/mes-questions';
  static const mesFavoris = '/mes-favoris';
  static const profile = '/profile';
  static const onboarding = '/onboarding';
  static const targetPath = '/target-path';
  static const examResult = '/exam-result/:attemptId';

  /// Historique des examens blancs **civique complets** (40 Q tous thèmes,
  /// pas les examens thématiques ni les lots — ceux-là vivent dans l'onglet
  /// Examens du détail thème). Surchargée dans `HistoryScreen`.
  static const history = '/history';

  /// Historique des examens blancs **TCF complets** (parent `TCF_COMPLET`
  /// + 4 sous-attempts CO/CE/EE/EO). Source : `/api/me/full-tcf-exams`.
  static const tcfExamHistory = '/historiques/tcf';
  static const examReport = '/exam-report/:attemptId';

  // Hub "Mes historiques" : regroupe QCM + EE + EO. Atteint depuis le hub
  // "Mon entraînement" du profil.
  static const historiques = '/historiques';

  // Hub "Mon entraînement" depuis le profil : historique + questions + favoris.
  static const monEntrainement = '/mon-entrainement';

  // Centre d'aide (hub) + contact natif + WebView générique pour FAQ/CGU/Privacy.
  static const helpCenter = '/help';
  static const contact = '/help/contact';
  static const helpWebview = '/help/page';

  // Page « À propos » native (disclaimer de non-affiliation + sources
  // officielles — conformité stores). Publique comme la WebView légale.
  static const about = '/about';

  // Édition des informations personnelles (firstName/lastName/email/password).
  static const personalInfo = '/profile/personal-info';

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
      final isOnPublicPage = loc == AppRoutes.helpWebview ||
          loc == AppRoutes.about ||
          loc == AppRoutes.diagnostic;

      // Si user connecté : pas d'auth flow, pas d'onboarding, pas de splash.
      if (isAuth) {
        final user = auth.user;

        // Onboarding parcours obligatoire (sauf pour les comptes ADMIN).
        if (!user.hasCompletedOnboarding && !isOnTargetPath) {
          return targetPathLocation(
            consumeDestination(state.uri.queryParameters['redirect']),
          );
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
      GoRoute(
        path: AppRoutes.examResult,
        builder: (_, state) {
          final attemptId = state.pathParameters['attemptId']!;
          return ExamResultScreen(attemptId: attemptId);
        },
      ),

      // Historiques (accessibles depuis le profil)
      GoRoute(
        path: AppRoutes.history,
        builder: (_, __) => const HistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.tcfExamHistory,
        builder: (_, __) => const TcfExamHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.historiques,
        builder: (_, __) => const MesHistoriquesScreen(),
      ),
      GoRoute(
        path: AppRoutes.monEntrainement,
        builder: (_, __) => const MonEntrainementScreen(),
      ),
      // Hors shell : poussées depuis le hub "Mon entraînement" (lui-même hors
      // shell). Les garder dans le ShellRoute provoquait une collision de page
      // key (double instanciation du shell) au push depuis un écran hors shell.
      GoRoute(
        path: AppRoutes.mesQuestions,
        builder: (_, __) => const MesQuestionsScreen(),
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
        path: AppRoutes.manageSubscription,
        builder: (_, __) => const ManageSubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoutes.diagnostic,
        builder: (_, __) => const DiagnosticScreen(),
      ),
      GoRoute(
        path: AppRoutes.examReport,
        builder: (_, state) {
          final attemptId = state.pathParameters['attemptId']!;
          return ExamReportScreen(attemptId: attemptId);
        },
      ),

      // Shell avec bottom nav
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.reviser,
            builder: (_, __) => const ReviserScreen(),
          ),
          GoRoute(
            path: AppRoutes.examens,
            builder: (_, __) => const ExamensScreen(),
          ),
          // Anciens hubs Civique/TCF — absorbés par l'onglet Réviser
          // (refonte 2026). Redirects gardés pour les fallbacks/deep links.
          GoRoute(
            path: AppRoutes.civique,
            redirect: (_, state) =>
                state.uri.path == AppRoutes.civique ? AppRoutes.reviser : null,
          ),
          GoRoute(
            path: AppRoutes.tcf,
            redirect: (_, state) =>
                state.uri.path == AppRoutes.tcf ? AppRoutes.reviser : null,
          ),
          GoRoute(
            path: AppRoutes.plan,
            builder: (_, __) => const PlanScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // Écrans secondaires du Plan — hors shell : ils sont poussés au-dessus de
      // l'onglet, qui reste dessous et se ré-hydrate au retour.
      GoRoute(
        path: AppRoutes.planDomain,
        builder: (_, state) => PlanDomainScreen(
          domainKey: state.pathParameters['domainKey'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.planEvolution,
        builder: (_, __) => const PlanEvolutionScreen(),
      ),
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

      // Progression historique conservée comme écran secondaire depuis Plan.
      GoRoute(
        path: AppRoutes.progress,
        builder: (_, __) => const ProgresScreen(),
      ),

      // Recommandations (pushé depuis Progrès, hors shell).
      GoRoute(
        path: AppRoutes.progresReco,
        builder: (_, __) => const RecoScreen(),
      ),

      // Runner hors shell (plein écran)
      GoRoute(
        path: AppRoutes.runner,
        builder: (_, state) {
          final attemptId = state.pathParameters['attemptId']!;
          return RunnerScreen(attemptId: attemptId);
        },
      ),

      // Page « Examens blancs » civique GLOBAUX (20 slots, 40 Q tous thèmes).
      // Pushée depuis le hero du hub Civique. Hors shell pour cohérence avec
      // `tcfFullExams` (même UX 20 slots côté TCF).
      GoRoute(
        path: AppRoutes.civiqueExamsBlanc,
        builder: (_, __) => const CiviqueFullExamsScreen(),
      ),

      // Écrans détail module (hors shell — pas de bottom nav).
      // Civique : un détail par thème (5 thèmes officiels chargés depuis l'API).
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
      // TCF QCM CO — hub + sous-routes examens/erreurs.
      GoRoute(
        path: AppRoutes.tcfCoDetail,
        builder: (_, __) => const TcfQcmDetailScreen(module: TcfQcmModule.co),
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
        builder: (_, __) => const TcfQcmDetailScreen(module: TcfQcmModule.ce),
        routes: [
          GoRoute(
            path: 'examens',
            builder: (_, __) =>
                const TcfQcmExamsScreen(module: TcfQcmModule.ce),
          ),
        ],
      ),
      // TCF Structure de la langue — QCM grammaire / lexique. Non évalué dans
      // le TCF IRN officiel — bannière `_ModuleNoticeBanner` rendue par le hub.
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
      // TCF productions : la racine d'une épreuve n'a plus d'écran à elle.
      // L'ancien hub (`TcfExpressionScreen`) est supprimé — on entre
      // directement sur l'écran d'accueil du parcours, et T1/T2/T3 se choisit
      // par les pastilles. Ces deux routes restent des **alias** : elles
      // absorbent les anciens liens et les retours « racine de l'épreuve »
      // des écrans de résultats / bilan / historique.
      //
      // Aucune sous-route n'est déclarée sous elles (`/tcf/ee/tache/…` sont
      // des routes absolues de premier niveau), donc pas besoin du garde
      // `state.uri.path ==` utilisé plus bas pour `/tcf/expression-{orale,ecrite}`.
      GoRoute(
        path: AppRoutes.tcfEoDetail,
        redirect: (_, __) => AppRoutes.tcfEoEntry,
      ),
      GoRoute(
        path: AppRoutes.tcfEeDetail,
        redirect: (_, __) => AppRoutes.tcfEeEntry,
      ),
      // Les trois modes du parcours (Sujets ici, Compétences plus bas, Examens
      // sous `/tcf/expression-*`) sont servis par **un seul écran** : c'est lui
      // qui garde les modes montés côte à côte et les données en cache. Les
      // chemins restent distincts pour les liens profonds et le retour arrière
      // — seule la bascule cesse d'être une navigation.
      GoRoute(
        path: AppRoutes.tcfEoTaskTraining,
        builder: (_, state) => ProductionParcoursScreen(
          module: TcfProductionModule.eo,
          tab: ProductionModuleTab.sujets,
          tache: (int.tryParse(state.pathParameters['tacheNumero'] ?? '1') ?? 1)
              .clamp(1, 3),
        ),
      ),
      GoRoute(
        path: AppRoutes.tcfEeTaskTraining,
        builder: (_, state) => ProductionParcoursScreen(
          module: TcfProductionModule.ee,
          tab: ProductionModuleTab.sujets,
          tache: (int.tryParse(state.pathParameters['tacheNumero'] ?? '1') ?? 1)
              .clamp(1, 3),
        ),
      ),
      // Modèles corrigés d'une tâche (`moduleKey` ∈ {ee, eo}).
      GoRoute(
        path: AppRoutes.tcfTaskExamples,
        builder: (_, state) => TcfTaskExamplesScreen(
          module: state.pathParameters['moduleKey'] == 'eo'
              ? TcfProductionModule.eo
              : TcfProductionModule.ee,
          tache: (int.tryParse(state.pathParameters['tacheNumero'] ?? '1') ?? 1)
              .clamp(1, 3),
        ),
      ),
      // Compétences TCF — les 4 écrans du parcours (cf. AppRoutes). L'ordre
      // n'est pas ambigu : les patterns ont des longueurs différentes et
      // `resultat` est un littéral.
      GoRoute(
        path: AppRoutes.tcfCompetences,
        builder: (_, state) => ProductionParcoursScreen(
          module: _productionModuleFromKey(state.pathParameters['moduleKey']),
          tab: ProductionModuleTab.competences,
          tache: (int.tryParse(state.pathParameters['tacheNumero'] ?? '1') ?? 1)
              .clamp(1, 3),
        ),
      ),
      GoRoute(
        path: AppRoutes.tcfCompetenceResult,
        builder: (_, state) => CompetenceResultScreen(
          module: _productionModuleFromKey(state.pathParameters['moduleKey']),
          attemptId: state.pathParameters['attemptId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.tcfCompetenceDetail,
        builder: (_, state) => CompetenceDetailScreen(
          module: _productionModuleFromKey(state.pathParameters['moduleKey']),
          skillId: state.pathParameters['skillId']!,
          // Marqueur d'étape du Plan : la compétence s'affiche alors à
          // l'échelle de l'étape (« 2/5 »). Cf. plan_step_labels.dart.
          planStep: isPlanStepQuery(state.uri.queryParameters),
        ),
      ),
      GoRoute(
        path: AppRoutes.tcfCompetencePrompt,
        builder: (_, state) => CompetencePromptScreen(
          module: _productionModuleFromKey(state.pathParameters['moduleKey']),
          skillId: state.pathParameters['skillId']!,
          promptId: state.pathParameters['promptId']!,
        ),
      ),

      // Examen blanc TCF complet : CO + CE + EE + EO, **chacune avec son propre
      // chrono** (~95 min au total, indicatif — il n'y a plus d'enveloppe
      // globale et rien ne se reporte d'une épreuve à l'autre). Pushé depuis la
      // carte sombre du hub TCF.
      GoRoute(
        path: AppRoutes.tcfFullExams,
        builder: (_, __) => const TcfFullExamsScreen(),
      ),
      // Hub de progression : 4 étapes (CO → CE → EE → EO) avec leur état.
      GoRoute(
        path: AppRoutes.tcfFullExamProgress,
        builder: (_, state) => TcfFullExamProgressScreen(
          parentAttemptId: state.pathParameters['parentId']!,
        ),
      ),
      // Bilan final (CECRL plancher + détail par épreuve).
      GoRoute(
        path: AppRoutes.tcfFullExamBilan,
        builder: (_, state) => TcfFullExamBilanScreen(
          parentAttemptId: state.pathParameters['parentId']!,
        ),
      ),
      // Lots d'un niveau pour un module TCF QCM. Pushé depuis l'onglet
      // Séries du détail module quand l'utilisateur tape une carte niveau.
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
      //   /tcf/expression-orale/historique               -> historique des sessions passees
      //   /tcf/expression-orale/sessions/:attemptId      -> bilan détaillé d'une session
      //                                                    (mode `?live=1` après T3 = polling actif)
      //   /tcf/expression-orale/t/:idx                   -> briefing + enregistrement (sur place)
      //   /tcf/expression-orale/t/:idx/termine           -> ecoute + soumission
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
            ? AppRoutes.tcfEoDetail
            : null,
        routes: [
          GoRoute(
            path: 'examens',
            // `?tache=` : la page des examens est portée par l'épreuve, pas par
            // une tâche — on garde d'où l'on vient pour que la barre du module
            // renvoie sur la bonne tâche. Absent (entrée par le hub) → tâche 1.
            builder: (_, state) => ProductionParcoursScreen(
              module: TcfProductionModule.eo,
              tab: ProductionModuleTab.examens,
              tache:
                  (int.tryParse(state.uri.queryParameters['tache'] ?? '1') ?? 1)
                      .clamp(1, 3),
            ),
          ),
          GoRoute(
            path: 'historique',
            builder: (_, __) =>
                const ProductionHistoryScreen(epreuve: EpreuveType.tcfEo),
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
            routes: [
              GoRoute(
                path: 'termine',
                builder: (_, state) {
                  final idx =
                      int.tryParse(state.pathParameters['taskIndex'] ?? '0') ??
                          0;
                  return EoFinishedScreen(taskIndex: idx);
                },
              ),
            ],
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

      // TCF Expression ecrite — mêmes sous-routes qu'EO sans /enregistrement
      // /termine (le briefing + zone d'écriture sont combinés). Le path
      // parent redirige vers le détail EE comme pour l'orale (cf. supra).
      GoRoute(
        path: AppRoutes.tcfExpressionEcrite,
        // Cf. note sur l'analogue EO juste au-dessus : on filtre via
        // `state.uri.path` pour ne pas intercepter les navigations vers
        // les sous-routes (`/historique`, `/sessions/:id`, `/t/:idx`, ...).
        redirect: (_, state) => state.uri.path == AppRoutes.tcfExpressionEcrite
            ? AppRoutes.tcfEeDetail
            : null,
        routes: [
          GoRoute(
            path: 'examens',
            // `?tache=` : la page des examens est portée par l'épreuve, pas par
            // une tâche — on garde d'où l'on vient pour que la barre du module
            // renvoie sur la bonne tâche. Absent (entrée par le hub) → tâche 1.
            builder: (_, state) => ProductionParcoursScreen(
              module: TcfProductionModule.ee,
              tab: ProductionModuleTab.examens,
              tache:
                  (int.tryParse(state.uri.queryParameters['tache'] ?? '1') ?? 1)
                      .clamp(1, 3),
            ),
          ),
          GoRoute(
            path: 'historique',
            builder: (_, __) =>
                const ProductionHistoryScreen(epreuve: EpreuveType.tcfEe),
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
