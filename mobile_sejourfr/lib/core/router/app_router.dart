import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sejourfr_mobile/screens/exam/exam_report_screen.dart';
import 'package:sejourfr_mobile/screens/exam/exam_result_screen.dart';
import 'package:sejourfr_mobile/screens/history/history_screen.dart';
import 'package:sejourfr_mobile/screens/history/tcf_exam_history_screen.dart';

import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/civique/civique_full_exams_screen.dart';
import '../../screens/examens/examens_screen.dart';
import '../../screens/reviser/reviser_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/module_detail/civique_theme_detail_screen.dart';
import '../../screens/module_detail/civique_theme_exams_screen.dart';
import '../../screens/module_detail/tcf_full_exams_screen.dart';
import '../../screens/module_detail/tcf_level_lots_screen.dart';
import '../../screens/module_detail/tcf_lot_result_screen.dart';
import '../../screens/tcf_production/tcf_expression_screen.dart';
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
import '../../screens/tcf_production/eo_recording_screen.dart';
import '../../screens/tcf_production/eo_results_screen.dart';
import '../../screens/tcf_production/history_session_screen.dart';
import '../../screens/tcf_production/production_exams_screen.dart';
import '../../screens/tcf_production/production_history_screen.dart';
import '../auth/auth_controller.dart';
import '../models/enums.dart';

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
  // Hub d'épreuve Expression (`TcfExpressionScreen`) : carte examen blanc + 3
  // tâches + historique. Tap une tâche → `TcfTaskTrainingScreen` (sujets +
  // exemples) sur les routes `…/tache/:tacheNumero`.
  static const tcfEoDetail = '/tcf/eo';
  static const tcfEeDetail = '/tcf/ee';
  static const tcfEoTaskTraining = '/tcf/eo/tache/:tacheNumero';
  static const tcfEeTaskTraining = '/tcf/ee/tache/:tacheNumero';

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

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);
  late final GoRouter router;

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
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      // Pendant le boot, on reste sur le splash le temps d'avoir un verdict.
      if (auth is AuthLoading) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final isAuth = auth is AuthAuthenticated;
      final isOnAuthFlow =
          loc == AppRoutes.login || loc == AppRoutes.register || loc == AppRoutes.forgotPassword;
      final isOnOnboarding = loc == AppRoutes.onboarding;
      final isOnTargetPath = loc == AppRoutes.targetPath;
      final isOnSplash = loc == AppRoutes.splash;
      // Pages publiques : la WebView légale (CGU / confidentialité) est
      // ouverte depuis login & inscription, et la page « À propos »
      // (disclaimer non-affiliation) doit rester consultable sans compte.
      final isOnPublicPage =
          loc == AppRoutes.helpWebview || loc == AppRoutes.about;

      // Si user connecté : pas d'auth flow, pas d'onboarding, pas de splash.
      if (isAuth) {
        final user = auth.user;

        // Onboarding parcours obligatoire (sauf pour les comptes ADMIN).
        if (!user.hasCompletedOnboarding && !isOnTargetPath) {
          return AppRoutes.targetPath;
        }

        if (isOnAuthFlow || isOnOnboarding || isOnSplash) {
          return AppRoutes.home;
        }
        return null;
      }

      // User non connecté : on regarde si l'onboarding a déjà été vu.
      // Lecture synchrone : la valeur est préchargée depuis les prefs au boot
      // (main.dart) donc disponible dès le premier frame.
      final onboardingSeen = ref.read(onboardingSeenProvider);

      if (!onboardingSeen && !isOnOnboarding) {
        return AppRoutes.onboarding;
      }

      if (onboardingSeen && !isOnAuthFlow && !isOnOnboarding && !isOnPublicPage) {
        return AppRoutes.login;
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
            path: AppRoutes.progress,
            builder: (_, __) => const ProgresScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
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
            builder: (_, __) => const TcfQcmExamsScreen(module: TcfQcmModule.co),
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
            builder: (_, __) => const TcfQcmExamsScreen(module: TcfQcmModule.ce),
          ),
        ],
      ),
      // TCF Structure de la langue — QCM grammaire / lexique. Non évalué dans
      // le TCF IRN officiel — bannière `_ModuleNoticeBanner` rendue par le hub.
      GoRoute(
        path: AppRoutes.tcfStructureDetail,
        builder: (_, __) => const TcfQcmDetailScreen(module: TcfQcmModule.structure),
        routes: [
          GoRoute(
            path: 'examens',
            builder: (_, __) => const TcfQcmExamsScreen(module: TcfQcmModule.structure),
          ),
        ],
      ),
      // TCF productions : hub d'épreuve (examen blanc + 3 tâches + historique).
      GoRoute(
        path: AppRoutes.tcfEoDetail,
        builder: (_, __) => const TcfExpressionScreen(module: TcfProductionModule.eo),
      ),
      GoRoute(
        path: AppRoutes.tcfEeDetail,
        builder: (_, __) => const TcfExpressionScreen(module: TcfProductionModule.ee),
      ),
      // Entraînement d'une tâche (sujets + exemples).
      GoRoute(
        path: AppRoutes.tcfEoTaskTraining,
        builder: (_, state) => TcfTaskTrainingScreen(
          module: TcfProductionModule.eo,
          tache: (int.tryParse(state.pathParameters['tacheNumero'] ?? '1') ?? 1).clamp(1, 3),
        ),
      ),
      GoRoute(
        path: AppRoutes.tcfEeTaskTraining,
        builder: (_, state) => TcfTaskTrainingScreen(
          module: TcfProductionModule.ee,
          tache: (int.tryParse(state.pathParameters['tacheNumero'] ?? '1') ?? 1).clamp(1, 3),
        ),
      ),
      // Examen blanc TCF complet (CO + CE + EE + EO en 90 min). Pushé
      // depuis la carte sombre du hub TCF. Orchestration des 4 épreuves
      // enchaînées à finaliser en lot dédié.
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
      //   /tcf/expression-orale/t/:idx                   -> briefing T(idx+1)
      //   /tcf/expression-orale/t/:idx/enregistrement    -> capture audio
      //   /tcf/expression-orale/t/:idx/termine           -> ecoute + soumission
      //   /tcf/expression-orale/resultats/:id?taskIndex=N&history=1  -> resultats (live ou history)
      //
      // L'ancien hub `ProductionHubScreen` a été supprimé : la sélection
      // T1/T2/T3 vit désormais sur `TcfProductionDetailScreen` (/tcf/eo).
      // On garde le path parent pour absorber les anciens liens (deep links,
      // historiques) via un redirect — mais uniquement quand l'URL exacte
      // est la racine ; les sous-routes restent atteignables.
      GoRoute(
        path: AppRoutes.tcfExpressionOrale,
        // `state.matchedLocation` est parfois la path du parent (et pas l'URL
        // complète) pendant l'évaluation d'une navigation vers sous-route
        // dans go_router 14 — ce qui ferait fire la redirection alors qu'on
        // navigue en fait vers `/tcf/expression-orale/t/0` ou similaire. On
        // teste donc `state.uri.path` (URL réelle de destination) pour ne
        // rediriger QUE quand l'utilisateur cible l'ancien path racine du hub.
        redirect: (_, state) => state.uri.path == AppRoutes.tcfExpressionOrale ? AppRoutes.tcfEoDetail : null,
        routes: [
          GoRoute(
            path: 'examens',
            builder: (_, __) => const ProductionExamsScreen(
                module: TcfProductionModule.eo),
          ),
          GoRoute(
            path: 'historique',
            builder: (_, __) => const ProductionHistoryScreen(epreuve: EpreuveType.tcfEo),
          ),
          GoRoute(
            path: 'sessions/:attemptId',
            builder: (_, state) => HistorySessionScreen(
              epreuve: EpreuveType.tcfEo,
              attemptId: state.pathParameters['attemptId']!,
            ),
          ),
          GoRoute(
            path: 't/:taskIndex',
            builder: (_, state) {
              final idx = int.tryParse(state.pathParameters['taskIndex'] ?? '0') ?? 0;
              return EoBriefingScreen(taskIndex: idx);
            },
            routes: [
              GoRoute(
                path: 'enregistrement',
                builder: (_, state) {
                  final idx = int.tryParse(state.pathParameters['taskIndex'] ?? '0') ?? 0;
                  return EoRecordingScreen(taskIndex: idx);
                },
              ),
              GoRoute(
                path: 'termine',
                builder: (_, state) {
                  final idx = int.tryParse(state.pathParameters['taskIndex'] ?? '0') ?? 0;
                  return EoFinishedScreen(taskIndex: idx);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'resultats/:submissionId',
            builder: (_, state) {
              final id = state.pathParameters['submissionId']!;
              final idx = int.tryParse(state.uri.queryParameters['taskIndex'] ?? '0') ?? 0;
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
        redirect: (_, state) =>
            state.uri.path == AppRoutes.tcfExpressionEcrite ? AppRoutes.tcfEeDetail : null,
        routes: [
          GoRoute(
            path: 'examens',
            builder: (_, __) => const ProductionExamsScreen(
                module: TcfProductionModule.ee),
          ),
          GoRoute(
            path: 'historique',
            builder: (_, __) => const ProductionHistoryScreen(epreuve: EpreuveType.tcfEe),
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
              final idx = int.tryParse(state.pathParameters['taskIndex'] ?? '0') ?? 0;
              return EeBriefingWritingScreen(taskIndex: idx);
            },
          ),
          GoRoute(
            path: 'resultats/:submissionId',
            builder: (_, state) {
              final id = state.pathParameters['submissionId']!;
              final idx = int.tryParse(state.uri.queryParameters['taskIndex'] ?? '0') ?? 0;
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
