import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sejourfr_mobile/screens/exam/exam_report_screen.dart';
import 'package:sejourfr_mobile/screens/exam/exam_result_screen.dart';
import 'package:sejourfr_mobile/screens/history/history_screen.dart';

import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/civique/civique_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/module_detail/civique_theme_detail_screen.dart';
import '../../screens/module_detail/tcf_level_lots_screen.dart';
import '../../screens/module_detail/tcf_lot_result_screen.dart';
import '../../screens/module_detail/tcf_full_exams_screen.dart';
import '../../screens/module_detail/tcf_production_detail_screen.dart';
import '../../screens/module_detail/tcf_production_task_subjects_screen.dart';
import '../../screens/module_detail/tcf_qcm_detail_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/profile/mes_historiques_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/question_runner/runner_screen.dart';
import '../../screens/review/review_screen.dart';
import '../../screens/shell/main_shell.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/stats/stats_screen.dart';
import '../../screens/target_path/target_path_screen.dart';
import '../../screens/tcf/tcf_screen.dart';
import '../../screens/tcf_production/ee_briefing_writing_screen.dart';
import '../../screens/tcf_production/ee_results_screen.dart';
import '../../screens/tcf_production/eo_briefing_screen.dart';
import '../../screens/tcf_production/eo_finished_screen.dart';
import '../../screens/tcf_production/eo_recording_screen.dart';
import '../../screens/tcf_production/eo_results_screen.dart';
import '../../screens/tcf_production/history_session_screen.dart';
import '../../screens/tcf_production/production_history_screen.dart';
import '../../screens/tcf_production/production_hub_screen.dart';
import '../../screens/tcf_production/session_bilan_screen.dart';
import '../../screens/tcf_production/session_progress_screen.dart';
import '../auth/auth_controller.dart';
import '../models/enums.dart';

/// Routes nommées centralisées (utilisées par les écrans).
class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/';
  static const civique = '/civique';
  static const civiqueThemeDetail = '/civique/theme/:themeId';
  static const tcf = '/tcf';
  static const tcfCoDetail = '/tcf/co';
  static const tcfCeDetail = '/tcf/ce';
  static const tcfEoDetail = '/tcf/eo';
  static const tcfEeDetail = '/tcf/ee';
  // Sujets d'une tâche EE ou EO (route hors shell). tacheNumero ∈ {1,2,3}.
  // Cf. `TcfProductionTaskSubjectsScreen` — affichage groupé par lots de 5
  // si > 15 sujets, sinon liste plate. Bypass pour EO T1 (consigne fixe).
  static const tcfEoTaskSubjects = '/tcf/eo/tache/:tacheNumero';
  static const tcfEeTaskSubjects = '/tcf/ee/tache/:tacheNumero';
  // Examen blanc complet TCF (les 4 épreuves enchaînées). 20 slots dans
  // la liste. Distinct des module exams (CO/CE seul) côté backend via
  // attempts.epreuve = TCF_COMPLET vs attempts.module_exam_question_type.
  static const tcfFullExams = '/tcf/examens-blancs';
  // Liste des lots pour un niveau d'un module TCF QCM.
  // moduleKey ∈ {co, ce}, level ∈ {a2, b1, b2}.
  static const tcfLevelLots = '/tcf/:moduleKey/niveau/:level';
  // Bilan affiché à la fin d'un lot TCF QCM. Push par le runner avec
  // moduleKey + level en query pour reconstruire le retour.
  static const tcfLotResult = '/tcf/lot-result/:attemptId';
  static const runner = '/runner/:attemptId';
  static const progress = '/progress';
  static const review = '/review';
  static const profile = '/profile';
  static const onboarding = '/onboarding';
  static const targetPath = '/target-path';
  static const examResult = '/exam-result/:attemptId';
  static const history = '/history';
  static const examReport = '/exam-report/:attemptId';

  // Hub "Mes historiques" depuis le profil : regroupe QCM + EE + EO.
  static const historiques = '/historiques';

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

      if (onboardingSeen && !isOnAuthFlow && !isOnOnboarding) {
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

      // Historique des examens (accessible depuis le profil)
      GoRoute(
        path: AppRoutes.history,
        builder: (_, __) => const HistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.historiques,
        builder: (_, __) => const MesHistoriquesScreen(),
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
            path: AppRoutes.civique,
            builder: (_, __) => const CiviqueScreen(),
          ),
          GoRoute(
            path: AppRoutes.tcf,
            builder: (_, __) => const TcfScreen(),
          ),
          GoRoute(
            path: AppRoutes.progress,
            builder: (_, __) => const StatsScreen(),
          ),
          GoRoute(
            path: AppRoutes.review,
            builder: (_, __) => const ReviewScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // Runner hors shell (plein écran)
      GoRoute(
        path: AppRoutes.runner,
        builder: (_, state) {
          final attemptId = state.pathParameters['attemptId']!;
          return RunnerScreen(attemptId: attemptId);
        },
      ),

      // Écrans détail module (hors shell — pas de bottom nav).
      // Civique : un détail par thème (5 thèmes officiels chargés depuis l'API).
      GoRoute(
        path: AppRoutes.civiqueThemeDetail,
        builder: (_, state) => CiviqueThemeDetailScreen(
          themeId: state.pathParameters['themeId']!,
        ),
      ),
      // TCF QCM : un détail par épreuve (CO, CE) → push runner après attempt.
      GoRoute(
        path: AppRoutes.tcfCoDetail,
        builder: (_, __) => const TcfQcmDetailScreen(module: TcfQcmModule.co),
      ),
      GoRoute(
        path: AppRoutes.tcfCeDetail,
        builder: (_, __) => const TcfQcmDetailScreen(module: TcfQcmModule.ce),
      ),
      // TCF productions : un détail par épreuve (EO, EE) → push
      // `ProductionHubScreen` (sélection T1/T2/T3) via le CTA.
      GoRoute(
        path: AppRoutes.tcfEoDetail,
        builder: (_, __) =>
            const TcfProductionDetailScreen(module: TcfProductionModule.eo),
      ),
      GoRoute(
        path: AppRoutes.tcfEeDetail,
        builder: (_, __) =>
            const TcfProductionDetailScreen(module: TcfProductionModule.ee),
      ),
      // Sujets d'une tâche EE / EO. Pushé depuis l'onglet Tâches du détail
      // production quand l'utilisateur tape une card tâche.
      GoRoute(
        path: AppRoutes.tcfEoTaskSubjects,
        builder: (_, state) {
          final n = int.tryParse(state.pathParameters['tacheNumero'] ?? '1') ?? 1;
          return TcfProductionTaskSubjectsScreen(
            epreuve: EpreuveType.tcfEo,
            tacheNumero: n.clamp(1, 3),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.tcfEeTaskSubjects,
        builder: (_, state) {
          final n = int.tryParse(state.pathParameters['tacheNumero'] ?? '1') ?? 1;
          return TcfProductionTaskSubjectsScreen(
            epreuve: EpreuveType.tcfEe,
            tacheNumero: n.clamp(1, 3),
          );
        },
      ),
      // Examen blanc TCF complet (CO + CE + EE + EO en 90 min). Pushé
      // depuis la carte sombre du hub TCF. Orchestration des 4 épreuves
      // enchaînées à finaliser en lot dédié.
      GoRoute(
        path: AppRoutes.tcfFullExams,
        builder: (_, __) => const TcfFullExamsScreen(),
      ),
      // Lots d'un niveau pour un module TCF QCM. Pushé depuis l'onglet
      // Séries du détail module quand l'utilisateur tape une carte niveau.
      GoRoute(
        path: AppRoutes.tcfLevelLots,
        builder: (_, state) {
          final moduleKey = state.pathParameters['moduleKey']!;
          final levelKey = state.pathParameters['level']!.toUpperCase();
          final module = moduleKey == 'ce' ? TcfQcmModule.ce : TcfQcmModule.co;
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

      // TCF Expression orale (Lot G : entry = hub d'entrainement libre, 3 cards T1/T2/T3)
      //   /tcf/expression-orale                          -> hub d'entrainement
      //   /tcf/expression-orale/historique               -> historique des sessions passees
      //   /tcf/expression-orale/sessions/:attemptId      -> bilan d'une session passee (lecture seule)
      //   /tcf/expression-orale/nouvelle                 -> [legacy] briefing T1 d'une session 3-taches
      //   /tcf/expression-orale/t/:idx                   -> briefing T(idx+1)
      //   /tcf/expression-orale/t/:idx/enregistrement    -> capture audio
      //   /tcf/expression-orale/t/:idx/termine           -> ecoute + soumission
      //   /tcf/expression-orale/resultats/:id?taskIndex=N&history=1  -> resultats (live ou history)
      //   /tcf/expression-orale/progression              -> [legacy] entre les taches (session 3-taches)
      //   /tcf/expression-orale/bilan                    -> [legacy] bilan session 3-taches
      GoRoute(
        path: AppRoutes.tcfExpressionOrale,
        builder: (_, __) =>
            const ProductionHubScreen(epreuve: EpreuveType.tcfEo),
        routes: [
          GoRoute(
            path: 'historique',
            builder: (_, __) =>
                const ProductionHistoryScreen(epreuve: EpreuveType.tcfEo),
          ),
          GoRoute(
            path: 'nouvelle',
            builder: (_, __) => const EoBriefingScreen(taskIndex: 0),
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
          GoRoute(
            path: 'progression',
            builder: (_, __) =>
                const SessionProgressScreen(epreuve: EpreuveType.tcfEo),
          ),
          GoRoute(
            path: 'bilan',
            builder: (_, __) =>
                const SessionBilanScreen(epreuve: EpreuveType.tcfEo),
          ),
        ],
      ),

      // TCF Expression ecrite (Lot G : entry = hub d'entrainement libre, 3 cards T1/T2/T3)
      //   /tcf/expression-ecrite                          -> hub d'entrainement
      //   /tcf/expression-ecrite/historique               -> historique des sessions passees
      //   /tcf/expression-ecrite/sessions/:attemptId      -> bilan d'une session passee (lecture seule)
      //   /tcf/expression-ecrite/nouvelle                 -> [legacy] briefing+writing T1 d'une session 3-taches
      //   /tcf/expression-ecrite/t/:idx                   -> briefing+writing pour cette tache
      //   /tcf/expression-ecrite/resultats/:id?taskIndex=N&history=1 -> resultats (live ou history)
      //   /tcf/expression-ecrite/progression              -> [legacy] entre taches (session 3-taches)
      //   /tcf/expression-ecrite/bilan                    -> [legacy] bilan session 3-taches
      GoRoute(
        path: AppRoutes.tcfExpressionEcrite,
        builder: (_, __) =>
            const ProductionHubScreen(epreuve: EpreuveType.tcfEe),
        routes: [
          GoRoute(
            path: 'historique',
            builder: (_, __) =>
                const ProductionHistoryScreen(epreuve: EpreuveType.tcfEe),
          ),
          GoRoute(
            path: 'nouvelle',
            builder: (_, __) => const EeBriefingWritingScreen(taskIndex: 0),
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
          GoRoute(
            path: 'progression',
            builder: (_, __) =>
                const SessionProgressScreen(epreuve: EpreuveType.tcfEe),
          ),
          GoRoute(
            path: 'bilan',
            builder: (_, __) =>
                const SessionBilanScreen(epreuve: EpreuveType.tcfEe),
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
